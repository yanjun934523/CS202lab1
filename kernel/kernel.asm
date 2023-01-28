
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	8d070713          	addi	a4,a4,-1840 # 80008920 <timer_scratch>
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
    80000066:	b8e78793          	addi	a5,a5,-1138 # 80005bf0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca6f>
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
    8000018e:	8d650513          	addi	a0,a0,-1834 # 80010a60 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8c648493          	addi	s1,s1,-1850 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	95690913          	addi	s2,s2,-1706 # 80010af8 <cons+0x98>
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
    8000022a:	83a50513          	addi	a0,a0,-1990 # 80010a60 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	82450513          	addi	a0,a0,-2012 # 80010a60 <cons>
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
    80000276:	88f72323          	sw	a5,-1914(a4) # 80010af8 <cons+0x98>
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
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	79450513          	addi	a0,a0,1940 # 80010a60 <cons>
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
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	76650513          	addi	a0,a0,1894 # 80010a60 <cons>
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
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	74270713          	addi	a4,a4,1858 # 80010a60 <cons>
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
    8000034c:	71878793          	addi	a5,a5,1816 # 80010a60 <cons>
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
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7827a783          	lw	a5,1922(a5) # 80010af8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6d670713          	addi	a4,a4,1750 # 80010a60 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6c648493          	addi	s1,s1,1734 # 80010a60 <cons>
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
    800003da:	68a70713          	addi	a4,a4,1674 # 80010a60 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72a23          	sw	a5,1812(a4) # 80010b00 <cons+0xa0>
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
    80000416:	64e78793          	addi	a5,a5,1614 # 80010a60 <cons>
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
    8000043a:	6cc7a323          	sw	a2,1734(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ba50513          	addi	a0,a0,1722 # 80010af8 <cons+0x98>
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
    80000464:	60050513          	addi	a0,a0,1536 # 80010a60 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	78078793          	addi	a5,a5,1920 # 80020bf8 <devsw>
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
    80000550:	5c07aa23          	sw	zero,1492(a5) # 80010b20 <pr+0x18>
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
    80000584:	36f72023          	sw	a5,864(a4) # 800088e0 <panicked>
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
    800005c0:	564dad83          	lw	s11,1380(s11) # 80010b20 <pr+0x18>
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
    800005fe:	50e50513          	addi	a0,a0,1294 # 80010b08 <pr>
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
    8000075c:	3b050513          	addi	a0,a0,944 # 80010b08 <pr>
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
    80000778:	39448493          	addi	s1,s1,916 # 80010b08 <pr>
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
    800007d8:	35450513          	addi	a0,a0,852 # 80010b28 <uart_tx_lock>
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
    80000804:	0e07a783          	lw	a5,224(a5) # 800088e0 <panicked>
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
    8000083c:	0b07b783          	ld	a5,176(a5) # 800088e8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0b073703          	ld	a4,176(a4) # 800088f0 <uart_tx_w>
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
    80000866:	2c6a0a13          	addi	s4,s4,710 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	07e48493          	addi	s1,s1,126 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	07e98993          	addi	s3,s3,126 # 800088f0 <uart_tx_w>
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
    800008d4:	25850513          	addi	a0,a0,600 # 80010b28 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0007a783          	lw	a5,0(a5) # 800088e0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	00673703          	ld	a4,6(a4) # 800088f0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	ff67b783          	ld	a5,-10(a5) # 800088e8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	22a98993          	addi	s3,s3,554 # 80010b28 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fe248493          	addi	s1,s1,-30 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fe290913          	addi	s2,s2,-30 # 800088f0 <uart_tx_w>
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
    80000938:	1f448493          	addi	s1,s1,500 # 80010b28 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fae7b423          	sd	a4,-88(a5) # 800088f0 <uart_tx_w>
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
    800009be:	16e48493          	addi	s1,s1,366 # 80010b28 <uart_tx_lock>
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
    80000a00:	39478793          	addi	a5,a5,916 # 80021d90 <end>
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
    80000a20:	14490913          	addi	s2,s2,324 # 80010b60 <kmem>
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
    80000abe:	0a650513          	addi	a0,a0,166 # 80010b60 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	2c250513          	addi	a0,a0,706 # 80021d90 <end>
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
    80000af4:	07048493          	addi	s1,s1,112 # 80010b60 <kmem>
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
    80000b0c:	05850513          	addi	a0,a0,88 # 80010b60 <kmem>
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
    80000b38:	02c50513          	addi	a0,a0,44 # 80010b60 <kmem>
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
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd271>
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
    80000e8c:	a7070713          	addi	a4,a4,-1424 # 800088f8 <started>
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
    80000ebe:	00001097          	auipc	ra,0x1
    80000ec2:	7ae080e7          	jalr	1966(ra) # 8000266c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	d6a080e7          	jalr	-662(ra) # 80005c30 <plicinithart>
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
    80000f3a:	70e080e7          	jalr	1806(ra) # 80002644 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	72e080e7          	jalr	1838(ra) # 8000266c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	cd4080e7          	jalr	-812(ra) # 80005c1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	ce2080e7          	jalr	-798(ra) # 80005c30 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	e7e080e7          	jalr	-386(ra) # 80002dd4 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	51e080e7          	jalr	1310(ra) # 8000347c <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	4c4080e7          	jalr	1220(ra) # 8000442a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	dca080e7          	jalr	-566(ra) # 80005d38 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72a23          	sw	a5,-1676(a4) # 800088f8 <started>
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
    80000f9c:	9687b783          	ld	a5,-1688(a5) # 80008900 <kernel_pagetable>
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
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd267>
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
    80001258:	6aa7b623          	sd	a0,1708(a5) # 80008900 <kernel_pagetable>
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
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd270>
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
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	76448493          	addi	s1,s1,1892 # 80010fb0 <proc>
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
    8000186a:	14aa0a13          	addi	s4,s4,330 # 800169b0 <tickslock>
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
    800018ec:	29850513          	addi	a0,a0,664 # 80010b80 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	29850513          	addi	a0,a0,664 # 80010b98 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6a048493          	addi	s1,s1,1696 # 80010fb0 <proc>
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
    80001936:	07e98993          	addi	s3,s3,126 # 800169b0 <tickslock>
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
    800019a0:	21450513          	addi	a0,a0,532 # 80010bb0 <cpus>
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
    800019c8:	1bc70713          	addi	a4,a4,444 # 80010b80 <pid_lock>
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
    80001a00:	e747a783          	lw	a5,-396(a5) # 80008870 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	c7e080e7          	jalr	-898(ra) # 80002684 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407ad23          	sw	zero,-422(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	9dc080e7          	jalr	-1572(ra) # 800033fc <fsinit>
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
    80001a3a:	14a90913          	addi	s2,s2,330 # 80010b80 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e2c78793          	addi	a5,a5,-468 # 80008874 <nextpid>
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
    80001bc6:	3ee48493          	addi	s1,s1,1006 # 80010fb0 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	de690913          	addi	s2,s2,-538 # 800169b0 <tickslock>
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
    80001c9c:	c6a7b823          	sd	a0,-912(a5) # 80008908 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	bdc58593          	addi	a1,a1,-1060 # 80008880 <initcode>
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
    80001ce6:	144080e7          	jalr	324(ra) # 80003e26 <namei>
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
    80001e16:	6aa080e7          	jalr	1706(ra) # 800044bc <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	818080e7          	jalr	-2024(ra) # 8000363c <idup>
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
    80001e54:	d4848493          	addi	s1,s1,-696 # 80010b98 <wait_lock>
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
    80001ec2:	cc270713          	addi	a4,a4,-830 # 80010b80 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	cec70713          	addi	a4,a4,-788 # 80010bb8 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
        c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	0000fa17          	auipc	s4,0xf
    80001ee0:	ca4a0a13          	addi	s4,s4,-860 # 80010b80 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee6:	00015917          	auipc	s2,0x15
    80001eea:	aca90913          	addi	s2,s2,-1334 # 800169b0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	0b648493          	addi	s1,s1,182 # 80010fb0 <proc>
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
    80001f38:	6a6080e7          	jalr	1702(ra) # 800025da <swtch>
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
    80001f6e:	c1670713          	addi	a4,a4,-1002 # 80010b80 <pid_lock>
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
    80001f94:	bf090913          	addi	s2,s2,-1040 # 80010b80 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f597          	auipc	a1,0xf
    80001fac:	c1058593          	addi	a1,a1,-1008 # 80010bb8 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	06048513          	addi	a0,s1,96
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	624080e7          	jalr	1572(ra) # 800025da <swtch>
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
    800020d0:	ee448493          	addi	s1,s1,-284 # 80010fb0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020d4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020d6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	00015917          	auipc	s2,0x15
    800020dc:	8d890913          	addi	s2,s2,-1832 # 800169b0 <tickslock>
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
    80002144:	e7048493          	addi	s1,s1,-400 # 80010fb0 <proc>
      pp->parent = initproc;
    80002148:	00006a17          	auipc	s4,0x6
    8000214c:	7c0a0a13          	addi	s4,s4,1984 # 80008908 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002150:	00015997          	auipc	s3,0x15
    80002154:	86098993          	addi	s3,s3,-1952 # 800169b0 <tickslock>
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
    800021a4:	00006797          	auipc	a5,0x6
    800021a8:	7647b783          	ld	a5,1892(a5) # 80008908 <initproc>
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
    800021cc:	346080e7          	jalr	838(ra) # 8000450e <fileclose>
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
    800021e4:	e66080e7          	jalr	-410(ra) # 80004046 <begin_op>
  iput(p->cwd);
    800021e8:	1509b503          	ld	a0,336(s3)
    800021ec:	00001097          	auipc	ra,0x1
    800021f0:	648080e7          	jalr	1608(ra) # 80003834 <iput>
  end_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	ed0080e7          	jalr	-304(ra) # 800040c4 <end_op>
  p->cwd = 0;
    800021fc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002200:	0000f497          	auipc	s1,0xf
    80002204:	99848493          	addi	s1,s1,-1640 # 80010b98 <wait_lock>
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
    80002272:	d4248493          	addi	s1,s1,-702 # 80010fb0 <proc>
    80002276:	00014997          	auipc	s3,0x14
    8000227a:	73a98993          	addi	s3,s3,1850 # 800169b0 <tickslock>
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
    80002356:	84650513          	addi	a0,a0,-1978 # 80010b98 <wait_lock>
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
    8000236c:	64898993          	addi	s3,s3,1608 # 800169b0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002370:	0000fc17          	auipc	s8,0xf
    80002374:	828c0c13          	addi	s8,s8,-2008 # 80010b98 <wait_lock>
    havekids = 0;
    80002378:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237a:	0000f497          	auipc	s1,0xf
    8000237e:	c3648493          	addi	s1,s1,-970 # 80010fb0 <proc>
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
    800023b8:	0000e517          	auipc	a0,0xe
    800023bc:	7e050513          	addi	a0,a0,2016 # 80010b98 <wait_lock>
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8ca080e7          	jalr	-1846(ra) # 80000c8a <release>
          return pid;
    800023c8:	a0b5                	j	80002434 <wait+0x106>
            release(&pp->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
            release(&wait_lock);
    800023d4:	0000e517          	auipc	a0,0xe
    800023d8:	7c450513          	addi	a0,a0,1988 # 80010b98 <wait_lock>
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
    80002422:	0000e517          	auipc	a0,0xe
    80002426:	77650513          	addi	a0,a0,1910 # 80010b98 <wait_lock>
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
    80002532:	bda48493          	addi	s1,s1,-1062 # 80011108 <proc+0x158>
    80002536:	00014917          	auipc	s2,0x14
    8000253a:	5d290913          	addi	s2,s2,1490 # 80016b08 <bcache+0x140>
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
    8000255c:	d90b8b93          	addi	s7,s7,-624 # 800082e8 <states.0>
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

void print_hello(int n)
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

00000000800025da <swtch>:
    800025da:	00153023          	sd	ra,0(a0)
    800025de:	00253423          	sd	sp,8(a0)
    800025e2:	e900                	sd	s0,16(a0)
    800025e4:	ed04                	sd	s1,24(a0)
    800025e6:	03253023          	sd	s2,32(a0)
    800025ea:	03353423          	sd	s3,40(a0)
    800025ee:	03453823          	sd	s4,48(a0)
    800025f2:	03553c23          	sd	s5,56(a0)
    800025f6:	05653023          	sd	s6,64(a0)
    800025fa:	05753423          	sd	s7,72(a0)
    800025fe:	05853823          	sd	s8,80(a0)
    80002602:	05953c23          	sd	s9,88(a0)
    80002606:	07a53023          	sd	s10,96(a0)
    8000260a:	07b53423          	sd	s11,104(a0)
    8000260e:	0005b083          	ld	ra,0(a1)
    80002612:	0085b103          	ld	sp,8(a1)
    80002616:	6980                	ld	s0,16(a1)
    80002618:	6d84                	ld	s1,24(a1)
    8000261a:	0205b903          	ld	s2,32(a1)
    8000261e:	0285b983          	ld	s3,40(a1)
    80002622:	0305ba03          	ld	s4,48(a1)
    80002626:	0385ba83          	ld	s5,56(a1)
    8000262a:	0405bb03          	ld	s6,64(a1)
    8000262e:	0485bb83          	ld	s7,72(a1)
    80002632:	0505bc03          	ld	s8,80(a1)
    80002636:	0585bc83          	ld	s9,88(a1)
    8000263a:	0605bd03          	ld	s10,96(a1)
    8000263e:	0685bd83          	ld	s11,104(a1)
    80002642:	8082                	ret

0000000080002644 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002644:	1141                	addi	sp,sp,-16
    80002646:	e406                	sd	ra,8(sp)
    80002648:	e022                	sd	s0,0(sp)
    8000264a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000264c:	00006597          	auipc	a1,0x6
    80002650:	ccc58593          	addi	a1,a1,-820 # 80008318 <states.0+0x30>
    80002654:	00014517          	auipc	a0,0x14
    80002658:	35c50513          	addi	a0,a0,860 # 800169b0 <tickslock>
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	4ea080e7          	jalr	1258(ra) # 80000b46 <initlock>
}
    80002664:	60a2                	ld	ra,8(sp)
    80002666:	6402                	ld	s0,0(sp)
    80002668:	0141                	addi	sp,sp,16
    8000266a:	8082                	ret

000000008000266c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000266c:	1141                	addi	sp,sp,-16
    8000266e:	e422                	sd	s0,8(sp)
    80002670:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002672:	00003797          	auipc	a5,0x3
    80002676:	4ee78793          	addi	a5,a5,1262 # 80005b60 <kernelvec>
    8000267a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000267e:	6422                	ld	s0,8(sp)
    80002680:	0141                	addi	sp,sp,16
    80002682:	8082                	ret

0000000080002684 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002684:	1141                	addi	sp,sp,-16
    80002686:	e406                	sd	ra,8(sp)
    80002688:	e022                	sd	s0,0(sp)
    8000268a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000268c:	fffff097          	auipc	ra,0xfffff
    80002690:	320080e7          	jalr	800(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002694:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002698:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000269a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000269e:	00005697          	auipc	a3,0x5
    800026a2:	96268693          	addi	a3,a3,-1694 # 80007000 <_trampoline>
    800026a6:	00005717          	auipc	a4,0x5
    800026aa:	95a70713          	addi	a4,a4,-1702 # 80007000 <_trampoline>
    800026ae:	8f15                	sub	a4,a4,a3
    800026b0:	040007b7          	lui	a5,0x4000
    800026b4:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800026b6:	07b2                	slli	a5,a5,0xc
    800026b8:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026ba:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026be:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026c0:	18002673          	csrr	a2,satp
    800026c4:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026c6:	6d30                	ld	a2,88(a0)
    800026c8:	6138                	ld	a4,64(a0)
    800026ca:	6585                	lui	a1,0x1
    800026cc:	972e                	add	a4,a4,a1
    800026ce:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026d0:	6d38                	ld	a4,88(a0)
    800026d2:	00000617          	auipc	a2,0x0
    800026d6:	13060613          	addi	a2,a2,304 # 80002802 <usertrap>
    800026da:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026dc:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026de:	8612                	mv	a2,tp
    800026e0:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026e2:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026e6:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026ea:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ee:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026f2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026f4:	6f18                	ld	a4,24(a4)
    800026f6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026fa:	6928                	ld	a0,80(a0)
    800026fc:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800026fe:	00005717          	auipc	a4,0x5
    80002702:	99e70713          	addi	a4,a4,-1634 # 8000709c <userret>
    80002706:	8f15                	sub	a4,a4,a3
    80002708:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000270a:	577d                	li	a4,-1
    8000270c:	177e                	slli	a4,a4,0x3f
    8000270e:	8d59                	or	a0,a0,a4
    80002710:	9782                	jalr	a5
}
    80002712:	60a2                	ld	ra,8(sp)
    80002714:	6402                	ld	s0,0(sp)
    80002716:	0141                	addi	sp,sp,16
    80002718:	8082                	ret

000000008000271a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000271a:	1101                	addi	sp,sp,-32
    8000271c:	ec06                	sd	ra,24(sp)
    8000271e:	e822                	sd	s0,16(sp)
    80002720:	e426                	sd	s1,8(sp)
    80002722:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002724:	00014497          	auipc	s1,0x14
    80002728:	28c48493          	addi	s1,s1,652 # 800169b0 <tickslock>
    8000272c:	8526                	mv	a0,s1
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	4a8080e7          	jalr	1192(ra) # 80000bd6 <acquire>
  ticks++;
    80002736:	00006517          	auipc	a0,0x6
    8000273a:	1da50513          	addi	a0,a0,474 # 80008910 <ticks>
    8000273e:	411c                	lw	a5,0(a0)
    80002740:	2785                	addiw	a5,a5,1
    80002742:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002744:	00000097          	auipc	ra,0x0
    80002748:	974080e7          	jalr	-1676(ra) # 800020b8 <wakeup>
  release(&tickslock);
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	53c080e7          	jalr	1340(ra) # 80000c8a <release>
}
    80002756:	60e2                	ld	ra,24(sp)
    80002758:	6442                	ld	s0,16(sp)
    8000275a:	64a2                	ld	s1,8(sp)
    8000275c:	6105                	addi	sp,sp,32
    8000275e:	8082                	ret

0000000080002760 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002760:	1101                	addi	sp,sp,-32
    80002762:	ec06                	sd	ra,24(sp)
    80002764:	e822                	sd	s0,16(sp)
    80002766:	e426                	sd	s1,8(sp)
    80002768:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000276a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000276e:	00074d63          	bltz	a4,80002788 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002772:	57fd                	li	a5,-1
    80002774:	17fe                	slli	a5,a5,0x3f
    80002776:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002778:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000277a:	06f70363          	beq	a4,a5,800027e0 <devintr+0x80>
  }
}
    8000277e:	60e2                	ld	ra,24(sp)
    80002780:	6442                	ld	s0,16(sp)
    80002782:	64a2                	ld	s1,8(sp)
    80002784:	6105                	addi	sp,sp,32
    80002786:	8082                	ret
     (scause & 0xff) == 9){
    80002788:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000278c:	46a5                	li	a3,9
    8000278e:	fed792e3          	bne	a5,a3,80002772 <devintr+0x12>
    int irq = plic_claim();
    80002792:	00003097          	auipc	ra,0x3
    80002796:	4d6080e7          	jalr	1238(ra) # 80005c68 <plic_claim>
    8000279a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000279c:	47a9                	li	a5,10
    8000279e:	02f50763          	beq	a0,a5,800027cc <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027a2:	4785                	li	a5,1
    800027a4:	02f50963          	beq	a0,a5,800027d6 <devintr+0x76>
    return 1;
    800027a8:	4505                	li	a0,1
    } else if(irq){
    800027aa:	d8f1                	beqz	s1,8000277e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027ac:	85a6                	mv	a1,s1
    800027ae:	00006517          	auipc	a0,0x6
    800027b2:	b7250513          	addi	a0,a0,-1166 # 80008320 <states.0+0x38>
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	dd4080e7          	jalr	-556(ra) # 8000058a <printf>
      plic_complete(irq);
    800027be:	8526                	mv	a0,s1
    800027c0:	00003097          	auipc	ra,0x3
    800027c4:	4cc080e7          	jalr	1228(ra) # 80005c8c <plic_complete>
    return 1;
    800027c8:	4505                	li	a0,1
    800027ca:	bf55                	j	8000277e <devintr+0x1e>
      uartintr();
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	1cc080e7          	jalr	460(ra) # 80000998 <uartintr>
    800027d4:	b7ed                	j	800027be <devintr+0x5e>
      virtio_disk_intr();
    800027d6:	00004097          	auipc	ra,0x4
    800027da:	97e080e7          	jalr	-1666(ra) # 80006154 <virtio_disk_intr>
    800027de:	b7c5                	j	800027be <devintr+0x5e>
    if(cpuid() == 0){
    800027e0:	fffff097          	auipc	ra,0xfffff
    800027e4:	1a0080e7          	jalr	416(ra) # 80001980 <cpuid>
    800027e8:	c901                	beqz	a0,800027f8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027ea:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027ee:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027f0:	14479073          	csrw	sip,a5
    return 2;
    800027f4:	4509                	li	a0,2
    800027f6:	b761                	j	8000277e <devintr+0x1e>
      clockintr();
    800027f8:	00000097          	auipc	ra,0x0
    800027fc:	f22080e7          	jalr	-222(ra) # 8000271a <clockintr>
    80002800:	b7ed                	j	800027ea <devintr+0x8a>

0000000080002802 <usertrap>:
{
    80002802:	1101                	addi	sp,sp,-32
    80002804:	ec06                	sd	ra,24(sp)
    80002806:	e822                	sd	s0,16(sp)
    80002808:	e426                	sd	s1,8(sp)
    8000280a:	e04a                	sd	s2,0(sp)
    8000280c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000280e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002812:	1007f793          	andi	a5,a5,256
    80002816:	e3b1                	bnez	a5,8000285a <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002818:	00003797          	auipc	a5,0x3
    8000281c:	34878793          	addi	a5,a5,840 # 80005b60 <kernelvec>
    80002820:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002824:	fffff097          	auipc	ra,0xfffff
    80002828:	188080e7          	jalr	392(ra) # 800019ac <myproc>
    8000282c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000282e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002830:	14102773          	csrr	a4,sepc
    80002834:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002836:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000283a:	47a1                	li	a5,8
    8000283c:	02f70763          	beq	a4,a5,8000286a <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002840:	00000097          	auipc	ra,0x0
    80002844:	f20080e7          	jalr	-224(ra) # 80002760 <devintr>
    80002848:	892a                	mv	s2,a0
    8000284a:	c151                	beqz	a0,800028ce <usertrap+0xcc>
  if(killed(p))
    8000284c:	8526                	mv	a0,s1
    8000284e:	00000097          	auipc	ra,0x0
    80002852:	aae080e7          	jalr	-1362(ra) # 800022fc <killed>
    80002856:	c929                	beqz	a0,800028a8 <usertrap+0xa6>
    80002858:	a099                	j	8000289e <usertrap+0x9c>
    panic("usertrap: not from user mode");
    8000285a:	00006517          	auipc	a0,0x6
    8000285e:	ae650513          	addi	a0,a0,-1306 # 80008340 <states.0+0x58>
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	cde080e7          	jalr	-802(ra) # 80000540 <panic>
    if(killed(p))
    8000286a:	00000097          	auipc	ra,0x0
    8000286e:	a92080e7          	jalr	-1390(ra) # 800022fc <killed>
    80002872:	e921                	bnez	a0,800028c2 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002874:	6cb8                	ld	a4,88(s1)
    80002876:	6f1c                	ld	a5,24(a4)
    80002878:	0791                	addi	a5,a5,4
    8000287a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000287c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002880:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002884:	10079073          	csrw	sstatus,a5
    syscall();
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	2d4080e7          	jalr	724(ra) # 80002b5c <syscall>
  if(killed(p))
    80002890:	8526                	mv	a0,s1
    80002892:	00000097          	auipc	ra,0x0
    80002896:	a6a080e7          	jalr	-1430(ra) # 800022fc <killed>
    8000289a:	c911                	beqz	a0,800028ae <usertrap+0xac>
    8000289c:	4901                	li	s2,0
    exit(-1);
    8000289e:	557d                	li	a0,-1
    800028a0:	00000097          	auipc	ra,0x0
    800028a4:	8e8080e7          	jalr	-1816(ra) # 80002188 <exit>
  if(which_dev == 2)
    800028a8:	4789                	li	a5,2
    800028aa:	04f90f63          	beq	s2,a5,80002908 <usertrap+0x106>
  usertrapret();
    800028ae:	00000097          	auipc	ra,0x0
    800028b2:	dd6080e7          	jalr	-554(ra) # 80002684 <usertrapret>
}
    800028b6:	60e2                	ld	ra,24(sp)
    800028b8:	6442                	ld	s0,16(sp)
    800028ba:	64a2                	ld	s1,8(sp)
    800028bc:	6902                	ld	s2,0(sp)
    800028be:	6105                	addi	sp,sp,32
    800028c0:	8082                	ret
      exit(-1);
    800028c2:	557d                	li	a0,-1
    800028c4:	00000097          	auipc	ra,0x0
    800028c8:	8c4080e7          	jalr	-1852(ra) # 80002188 <exit>
    800028cc:	b765                	j	80002874 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ce:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028d2:	5890                	lw	a2,48(s1)
    800028d4:	00006517          	auipc	a0,0x6
    800028d8:	a8c50513          	addi	a0,a0,-1396 # 80008360 <states.0+0x78>
    800028dc:	ffffe097          	auipc	ra,0xffffe
    800028e0:	cae080e7          	jalr	-850(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028e8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028ec:	00006517          	auipc	a0,0x6
    800028f0:	aa450513          	addi	a0,a0,-1372 # 80008390 <states.0+0xa8>
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	c96080e7          	jalr	-874(ra) # 8000058a <printf>
    setkilled(p);
    800028fc:	8526                	mv	a0,s1
    800028fe:	00000097          	auipc	ra,0x0
    80002902:	9d2080e7          	jalr	-1582(ra) # 800022d0 <setkilled>
    80002906:	b769                	j	80002890 <usertrap+0x8e>
    yield();
    80002908:	fffff097          	auipc	ra,0xfffff
    8000290c:	710080e7          	jalr	1808(ra) # 80002018 <yield>
    80002910:	bf79                	j	800028ae <usertrap+0xac>

0000000080002912 <kerneltrap>:
{
    80002912:	7179                	addi	sp,sp,-48
    80002914:	f406                	sd	ra,40(sp)
    80002916:	f022                	sd	s0,32(sp)
    80002918:	ec26                	sd	s1,24(sp)
    8000291a:	e84a                	sd	s2,16(sp)
    8000291c:	e44e                	sd	s3,8(sp)
    8000291e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002920:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002924:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002928:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000292c:	1004f793          	andi	a5,s1,256
    80002930:	cb85                	beqz	a5,80002960 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002932:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002936:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002938:	ef85                	bnez	a5,80002970 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000293a:	00000097          	auipc	ra,0x0
    8000293e:	e26080e7          	jalr	-474(ra) # 80002760 <devintr>
    80002942:	cd1d                	beqz	a0,80002980 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002944:	4789                	li	a5,2
    80002946:	06f50a63          	beq	a0,a5,800029ba <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000294a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000294e:	10049073          	csrw	sstatus,s1
}
    80002952:	70a2                	ld	ra,40(sp)
    80002954:	7402                	ld	s0,32(sp)
    80002956:	64e2                	ld	s1,24(sp)
    80002958:	6942                	ld	s2,16(sp)
    8000295a:	69a2                	ld	s3,8(sp)
    8000295c:	6145                	addi	sp,sp,48
    8000295e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002960:	00006517          	auipc	a0,0x6
    80002964:	a5050513          	addi	a0,a0,-1456 # 800083b0 <states.0+0xc8>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	bd8080e7          	jalr	-1064(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002970:	00006517          	auipc	a0,0x6
    80002974:	a6850513          	addi	a0,a0,-1432 # 800083d8 <states.0+0xf0>
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	bc8080e7          	jalr	-1080(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002980:	85ce                	mv	a1,s3
    80002982:	00006517          	auipc	a0,0x6
    80002986:	a7650513          	addi	a0,a0,-1418 # 800083f8 <states.0+0x110>
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	c00080e7          	jalr	-1024(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002992:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002996:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000299a:	00006517          	auipc	a0,0x6
    8000299e:	a6e50513          	addi	a0,a0,-1426 # 80008408 <states.0+0x120>
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	be8080e7          	jalr	-1048(ra) # 8000058a <printf>
    panic("kerneltrap");
    800029aa:	00006517          	auipc	a0,0x6
    800029ae:	a7650513          	addi	a0,a0,-1418 # 80008420 <states.0+0x138>
    800029b2:	ffffe097          	auipc	ra,0xffffe
    800029b6:	b8e080e7          	jalr	-1138(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029ba:	fffff097          	auipc	ra,0xfffff
    800029be:	ff2080e7          	jalr	-14(ra) # 800019ac <myproc>
    800029c2:	d541                	beqz	a0,8000294a <kerneltrap+0x38>
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	fe8080e7          	jalr	-24(ra) # 800019ac <myproc>
    800029cc:	4d18                	lw	a4,24(a0)
    800029ce:	4791                	li	a5,4
    800029d0:	f6f71de3          	bne	a4,a5,8000294a <kerneltrap+0x38>
    yield();
    800029d4:	fffff097          	auipc	ra,0xfffff
    800029d8:	644080e7          	jalr	1604(ra) # 80002018 <yield>
    800029dc:	b7bd                	j	8000294a <kerneltrap+0x38>

00000000800029de <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029de:	1101                	addi	sp,sp,-32
    800029e0:	ec06                	sd	ra,24(sp)
    800029e2:	e822                	sd	s0,16(sp)
    800029e4:	e426                	sd	s1,8(sp)
    800029e6:	1000                	addi	s0,sp,32
    800029e8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029ea:	fffff097          	auipc	ra,0xfffff
    800029ee:	fc2080e7          	jalr	-62(ra) # 800019ac <myproc>
  switch (n) {
    800029f2:	4795                	li	a5,5
    800029f4:	0497e163          	bltu	a5,s1,80002a36 <argraw+0x58>
    800029f8:	048a                	slli	s1,s1,0x2
    800029fa:	00006717          	auipc	a4,0x6
    800029fe:	a5e70713          	addi	a4,a4,-1442 # 80008458 <states.0+0x170>
    80002a02:	94ba                	add	s1,s1,a4
    80002a04:	409c                	lw	a5,0(s1)
    80002a06:	97ba                	add	a5,a5,a4
    80002a08:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a0a:	6d3c                	ld	a5,88(a0)
    80002a0c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a0e:	60e2                	ld	ra,24(sp)
    80002a10:	6442                	ld	s0,16(sp)
    80002a12:	64a2                	ld	s1,8(sp)
    80002a14:	6105                	addi	sp,sp,32
    80002a16:	8082                	ret
    return p->trapframe->a1;
    80002a18:	6d3c                	ld	a5,88(a0)
    80002a1a:	7fa8                	ld	a0,120(a5)
    80002a1c:	bfcd                	j	80002a0e <argraw+0x30>
    return p->trapframe->a2;
    80002a1e:	6d3c                	ld	a5,88(a0)
    80002a20:	63c8                	ld	a0,128(a5)
    80002a22:	b7f5                	j	80002a0e <argraw+0x30>
    return p->trapframe->a3;
    80002a24:	6d3c                	ld	a5,88(a0)
    80002a26:	67c8                	ld	a0,136(a5)
    80002a28:	b7dd                	j	80002a0e <argraw+0x30>
    return p->trapframe->a4;
    80002a2a:	6d3c                	ld	a5,88(a0)
    80002a2c:	6bc8                	ld	a0,144(a5)
    80002a2e:	b7c5                	j	80002a0e <argraw+0x30>
    return p->trapframe->a5;
    80002a30:	6d3c                	ld	a5,88(a0)
    80002a32:	6fc8                	ld	a0,152(a5)
    80002a34:	bfe9                	j	80002a0e <argraw+0x30>
  panic("argraw");
    80002a36:	00006517          	auipc	a0,0x6
    80002a3a:	9fa50513          	addi	a0,a0,-1542 # 80008430 <states.0+0x148>
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	b02080e7          	jalr	-1278(ra) # 80000540 <panic>

0000000080002a46 <fetchaddr>:
{
    80002a46:	1101                	addi	sp,sp,-32
    80002a48:	ec06                	sd	ra,24(sp)
    80002a4a:	e822                	sd	s0,16(sp)
    80002a4c:	e426                	sd	s1,8(sp)
    80002a4e:	e04a                	sd	s2,0(sp)
    80002a50:	1000                	addi	s0,sp,32
    80002a52:	84aa                	mv	s1,a0
    80002a54:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a56:	fffff097          	auipc	ra,0xfffff
    80002a5a:	f56080e7          	jalr	-170(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a5e:	653c                	ld	a5,72(a0)
    80002a60:	02f4f863          	bgeu	s1,a5,80002a90 <fetchaddr+0x4a>
    80002a64:	00848713          	addi	a4,s1,8
    80002a68:	02e7e663          	bltu	a5,a4,80002a94 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a6c:	46a1                	li	a3,8
    80002a6e:	8626                	mv	a2,s1
    80002a70:	85ca                	mv	a1,s2
    80002a72:	6928                	ld	a0,80(a0)
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	c84080e7          	jalr	-892(ra) # 800016f8 <copyin>
    80002a7c:	00a03533          	snez	a0,a0
    80002a80:	40a00533          	neg	a0,a0
}
    80002a84:	60e2                	ld	ra,24(sp)
    80002a86:	6442                	ld	s0,16(sp)
    80002a88:	64a2                	ld	s1,8(sp)
    80002a8a:	6902                	ld	s2,0(sp)
    80002a8c:	6105                	addi	sp,sp,32
    80002a8e:	8082                	ret
    return -1;
    80002a90:	557d                	li	a0,-1
    80002a92:	bfcd                	j	80002a84 <fetchaddr+0x3e>
    80002a94:	557d                	li	a0,-1
    80002a96:	b7fd                	j	80002a84 <fetchaddr+0x3e>

0000000080002a98 <fetchstr>:
{
    80002a98:	7179                	addi	sp,sp,-48
    80002a9a:	f406                	sd	ra,40(sp)
    80002a9c:	f022                	sd	s0,32(sp)
    80002a9e:	ec26                	sd	s1,24(sp)
    80002aa0:	e84a                	sd	s2,16(sp)
    80002aa2:	e44e                	sd	s3,8(sp)
    80002aa4:	1800                	addi	s0,sp,48
    80002aa6:	892a                	mv	s2,a0
    80002aa8:	84ae                	mv	s1,a1
    80002aaa:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002aac:	fffff097          	auipc	ra,0xfffff
    80002ab0:	f00080e7          	jalr	-256(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ab4:	86ce                	mv	a3,s3
    80002ab6:	864a                	mv	a2,s2
    80002ab8:	85a6                	mv	a1,s1
    80002aba:	6928                	ld	a0,80(a0)
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	cca080e7          	jalr	-822(ra) # 80001786 <copyinstr>
    80002ac4:	00054e63          	bltz	a0,80002ae0 <fetchstr+0x48>
  return strlen(buf);
    80002ac8:	8526                	mv	a0,s1
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	384080e7          	jalr	900(ra) # 80000e4e <strlen>
}
    80002ad2:	70a2                	ld	ra,40(sp)
    80002ad4:	7402                	ld	s0,32(sp)
    80002ad6:	64e2                	ld	s1,24(sp)
    80002ad8:	6942                	ld	s2,16(sp)
    80002ada:	69a2                	ld	s3,8(sp)
    80002adc:	6145                	addi	sp,sp,48
    80002ade:	8082                	ret
    return -1;
    80002ae0:	557d                	li	a0,-1
    80002ae2:	bfc5                	j	80002ad2 <fetchstr+0x3a>

0000000080002ae4 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002ae4:	1101                	addi	sp,sp,-32
    80002ae6:	ec06                	sd	ra,24(sp)
    80002ae8:	e822                	sd	s0,16(sp)
    80002aea:	e426                	sd	s1,8(sp)
    80002aec:	1000                	addi	s0,sp,32
    80002aee:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002af0:	00000097          	auipc	ra,0x0
    80002af4:	eee080e7          	jalr	-274(ra) # 800029de <argraw>
    80002af8:	c088                	sw	a0,0(s1)
}
    80002afa:	60e2                	ld	ra,24(sp)
    80002afc:	6442                	ld	s0,16(sp)
    80002afe:	64a2                	ld	s1,8(sp)
    80002b00:	6105                	addi	sp,sp,32
    80002b02:	8082                	ret

0000000080002b04 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b04:	1101                	addi	sp,sp,-32
    80002b06:	ec06                	sd	ra,24(sp)
    80002b08:	e822                	sd	s0,16(sp)
    80002b0a:	e426                	sd	s1,8(sp)
    80002b0c:	1000                	addi	s0,sp,32
    80002b0e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b10:	00000097          	auipc	ra,0x0
    80002b14:	ece080e7          	jalr	-306(ra) # 800029de <argraw>
    80002b18:	e088                	sd	a0,0(s1)
}
    80002b1a:	60e2                	ld	ra,24(sp)
    80002b1c:	6442                	ld	s0,16(sp)
    80002b1e:	64a2                	ld	s1,8(sp)
    80002b20:	6105                	addi	sp,sp,32
    80002b22:	8082                	ret

0000000080002b24 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b24:	7179                	addi	sp,sp,-48
    80002b26:	f406                	sd	ra,40(sp)
    80002b28:	f022                	sd	s0,32(sp)
    80002b2a:	ec26                	sd	s1,24(sp)
    80002b2c:	e84a                	sd	s2,16(sp)
    80002b2e:	1800                	addi	s0,sp,48
    80002b30:	84ae                	mv	s1,a1
    80002b32:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b34:	fd840593          	addi	a1,s0,-40
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	fcc080e7          	jalr	-52(ra) # 80002b04 <argaddr>
  return fetchstr(addr, buf, max);
    80002b40:	864a                	mv	a2,s2
    80002b42:	85a6                	mv	a1,s1
    80002b44:	fd843503          	ld	a0,-40(s0)
    80002b48:	00000097          	auipc	ra,0x0
    80002b4c:	f50080e7          	jalr	-176(ra) # 80002a98 <fetchstr>
}
    80002b50:	70a2                	ld	ra,40(sp)
    80002b52:	7402                	ld	s0,32(sp)
    80002b54:	64e2                	ld	s1,24(sp)
    80002b56:	6942                	ld	s2,16(sp)
    80002b58:	6145                	addi	sp,sp,48
    80002b5a:	8082                	ret

0000000080002b5c <syscall>:

};

void
syscall(void)
{
    80002b5c:	1101                	addi	sp,sp,-32
    80002b5e:	ec06                	sd	ra,24(sp)
    80002b60:	e822                	sd	s0,16(sp)
    80002b62:	e426                	sd	s1,8(sp)
    80002b64:	e04a                	sd	s2,0(sp)
    80002b66:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	e44080e7          	jalr	-444(ra) # 800019ac <myproc>
    80002b70:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b72:	05853903          	ld	s2,88(a0)
    80002b76:	0a893783          	ld	a5,168(s2)
    80002b7a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b7e:	37fd                	addiw	a5,a5,-1
    80002b80:	4755                	li	a4,21
    80002b82:	00f76f63          	bltu	a4,a5,80002ba0 <syscall+0x44>
    80002b86:	00369713          	slli	a4,a3,0x3
    80002b8a:	00006797          	auipc	a5,0x6
    80002b8e:	8e678793          	addi	a5,a5,-1818 # 80008470 <syscalls>
    80002b92:	97ba                	add	a5,a5,a4
    80002b94:	639c                	ld	a5,0(a5)
    80002b96:	c789                	beqz	a5,80002ba0 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002b98:	9782                	jalr	a5
    80002b9a:	06a93823          	sd	a0,112(s2)
    80002b9e:	a839                	j	80002bbc <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ba0:	15848613          	addi	a2,s1,344
    80002ba4:	588c                	lw	a1,48(s1)
    80002ba6:	00006517          	auipc	a0,0x6
    80002baa:	89250513          	addi	a0,a0,-1902 # 80008438 <states.0+0x150>
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	9dc080e7          	jalr	-1572(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bb6:	6cbc                	ld	a5,88(s1)
    80002bb8:	577d                	li	a4,-1
    80002bba:	fbb8                	sd	a4,112(a5)
  }
}
    80002bbc:	60e2                	ld	ra,24(sp)
    80002bbe:	6442                	ld	s0,16(sp)
    80002bc0:	64a2                	ld	s1,8(sp)
    80002bc2:	6902                	ld	s2,0(sp)
    80002bc4:	6105                	addi	sp,sp,32
    80002bc6:	8082                	ret

0000000080002bc8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bc8:	1101                	addi	sp,sp,-32
    80002bca:	ec06                	sd	ra,24(sp)
    80002bcc:	e822                	sd	s0,16(sp)
    80002bce:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002bd0:	fec40593          	addi	a1,s0,-20
    80002bd4:	4501                	li	a0,0
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	f0e080e7          	jalr	-242(ra) # 80002ae4 <argint>
  exit(n);
    80002bde:	fec42503          	lw	a0,-20(s0)
    80002be2:	fffff097          	auipc	ra,0xfffff
    80002be6:	5a6080e7          	jalr	1446(ra) # 80002188 <exit>
  return 0;  // not reached
}
    80002bea:	4501                	li	a0,0
    80002bec:	60e2                	ld	ra,24(sp)
    80002bee:	6442                	ld	s0,16(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret

0000000080002bf4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bf4:	1141                	addi	sp,sp,-16
    80002bf6:	e406                	sd	ra,8(sp)
    80002bf8:	e022                	sd	s0,0(sp)
    80002bfa:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	db0080e7          	jalr	-592(ra) # 800019ac <myproc>
}
    80002c04:	5908                	lw	a0,48(a0)
    80002c06:	60a2                	ld	ra,8(sp)
    80002c08:	6402                	ld	s0,0(sp)
    80002c0a:	0141                	addi	sp,sp,16
    80002c0c:	8082                	ret

0000000080002c0e <sys_fork>:

uint64
sys_fork(void)
{
    80002c0e:	1141                	addi	sp,sp,-16
    80002c10:	e406                	sd	ra,8(sp)
    80002c12:	e022                	sd	s0,0(sp)
    80002c14:	0800                	addi	s0,sp,16
  return fork();
    80002c16:	fffff097          	auipc	ra,0xfffff
    80002c1a:	14c080e7          	jalr	332(ra) # 80001d62 <fork>
}
    80002c1e:	60a2                	ld	ra,8(sp)
    80002c20:	6402                	ld	s0,0(sp)
    80002c22:	0141                	addi	sp,sp,16
    80002c24:	8082                	ret

0000000080002c26 <sys_wait>:

uint64
sys_wait(void)
{
    80002c26:	1101                	addi	sp,sp,-32
    80002c28:	ec06                	sd	ra,24(sp)
    80002c2a:	e822                	sd	s0,16(sp)
    80002c2c:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c2e:	fe840593          	addi	a1,s0,-24
    80002c32:	4501                	li	a0,0
    80002c34:	00000097          	auipc	ra,0x0
    80002c38:	ed0080e7          	jalr	-304(ra) # 80002b04 <argaddr>
  return wait(p);
    80002c3c:	fe843503          	ld	a0,-24(s0)
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	6ee080e7          	jalr	1774(ra) # 8000232e <wait>
}
    80002c48:	60e2                	ld	ra,24(sp)
    80002c4a:	6442                	ld	s0,16(sp)
    80002c4c:	6105                	addi	sp,sp,32
    80002c4e:	8082                	ret

0000000080002c50 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c50:	7179                	addi	sp,sp,-48
    80002c52:	f406                	sd	ra,40(sp)
    80002c54:	f022                	sd	s0,32(sp)
    80002c56:	ec26                	sd	s1,24(sp)
    80002c58:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002c5a:	fdc40593          	addi	a1,s0,-36
    80002c5e:	4501                	li	a0,0
    80002c60:	00000097          	auipc	ra,0x0
    80002c64:	e84080e7          	jalr	-380(ra) # 80002ae4 <argint>
  addr = myproc()->sz;
    80002c68:	fffff097          	auipc	ra,0xfffff
    80002c6c:	d44080e7          	jalr	-700(ra) # 800019ac <myproc>
    80002c70:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002c72:	fdc42503          	lw	a0,-36(s0)
    80002c76:	fffff097          	auipc	ra,0xfffff
    80002c7a:	090080e7          	jalr	144(ra) # 80001d06 <growproc>
    80002c7e:	00054863          	bltz	a0,80002c8e <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002c82:	8526                	mv	a0,s1
    80002c84:	70a2                	ld	ra,40(sp)
    80002c86:	7402                	ld	s0,32(sp)
    80002c88:	64e2                	ld	s1,24(sp)
    80002c8a:	6145                	addi	sp,sp,48
    80002c8c:	8082                	ret
    return -1;
    80002c8e:	54fd                	li	s1,-1
    80002c90:	bfcd                	j	80002c82 <sys_sbrk+0x32>

0000000080002c92 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c92:	7139                	addi	sp,sp,-64
    80002c94:	fc06                	sd	ra,56(sp)
    80002c96:	f822                	sd	s0,48(sp)
    80002c98:	f426                	sd	s1,40(sp)
    80002c9a:	f04a                	sd	s2,32(sp)
    80002c9c:	ec4e                	sd	s3,24(sp)
    80002c9e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002ca0:	fcc40593          	addi	a1,s0,-52
    80002ca4:	4501                	li	a0,0
    80002ca6:	00000097          	auipc	ra,0x0
    80002caa:	e3e080e7          	jalr	-450(ra) # 80002ae4 <argint>
  acquire(&tickslock);
    80002cae:	00014517          	auipc	a0,0x14
    80002cb2:	d0250513          	addi	a0,a0,-766 # 800169b0 <tickslock>
    80002cb6:	ffffe097          	auipc	ra,0xffffe
    80002cba:	f20080e7          	jalr	-224(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002cbe:	00006917          	auipc	s2,0x6
    80002cc2:	c5292903          	lw	s2,-942(s2) # 80008910 <ticks>
  while(ticks - ticks0 < n){
    80002cc6:	fcc42783          	lw	a5,-52(s0)
    80002cca:	cf9d                	beqz	a5,80002d08 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ccc:	00014997          	auipc	s3,0x14
    80002cd0:	ce498993          	addi	s3,s3,-796 # 800169b0 <tickslock>
    80002cd4:	00006497          	auipc	s1,0x6
    80002cd8:	c3c48493          	addi	s1,s1,-964 # 80008910 <ticks>
    if(killed(myproc())){
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	cd0080e7          	jalr	-816(ra) # 800019ac <myproc>
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	618080e7          	jalr	1560(ra) # 800022fc <killed>
    80002cec:	ed15                	bnez	a0,80002d28 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002cee:	85ce                	mv	a1,s3
    80002cf0:	8526                	mv	a0,s1
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	362080e7          	jalr	866(ra) # 80002054 <sleep>
  while(ticks - ticks0 < n){
    80002cfa:	409c                	lw	a5,0(s1)
    80002cfc:	412787bb          	subw	a5,a5,s2
    80002d00:	fcc42703          	lw	a4,-52(s0)
    80002d04:	fce7ece3          	bltu	a5,a4,80002cdc <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d08:	00014517          	auipc	a0,0x14
    80002d0c:	ca850513          	addi	a0,a0,-856 # 800169b0 <tickslock>
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	f7a080e7          	jalr	-134(ra) # 80000c8a <release>
  return 0;
    80002d18:	4501                	li	a0,0
}
    80002d1a:	70e2                	ld	ra,56(sp)
    80002d1c:	7442                	ld	s0,48(sp)
    80002d1e:	74a2                	ld	s1,40(sp)
    80002d20:	7902                	ld	s2,32(sp)
    80002d22:	69e2                	ld	s3,24(sp)
    80002d24:	6121                	addi	sp,sp,64
    80002d26:	8082                	ret
      release(&tickslock);
    80002d28:	00014517          	auipc	a0,0x14
    80002d2c:	c8850513          	addi	a0,a0,-888 # 800169b0 <tickslock>
    80002d30:	ffffe097          	auipc	ra,0xffffe
    80002d34:	f5a080e7          	jalr	-166(ra) # 80000c8a <release>
      return -1;
    80002d38:	557d                	li	a0,-1
    80002d3a:	b7c5                	j	80002d1a <sys_sleep+0x88>

0000000080002d3c <sys_kill>:

uint64
sys_kill(void)
{
    80002d3c:	1101                	addi	sp,sp,-32
    80002d3e:	ec06                	sd	ra,24(sp)
    80002d40:	e822                	sd	s0,16(sp)
    80002d42:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d44:	fec40593          	addi	a1,s0,-20
    80002d48:	4501                	li	a0,0
    80002d4a:	00000097          	auipc	ra,0x0
    80002d4e:	d9a080e7          	jalr	-614(ra) # 80002ae4 <argint>
  return kill(pid);
    80002d52:	fec42503          	lw	a0,-20(s0)
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	508080e7          	jalr	1288(ra) # 8000225e <kill>
}
    80002d5e:	60e2                	ld	ra,24(sp)
    80002d60:	6442                	ld	s0,16(sp)
    80002d62:	6105                	addi	sp,sp,32
    80002d64:	8082                	ret

0000000080002d66 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d66:	1101                	addi	sp,sp,-32
    80002d68:	ec06                	sd	ra,24(sp)
    80002d6a:	e822                	sd	s0,16(sp)
    80002d6c:	e426                	sd	s1,8(sp)
    80002d6e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d70:	00014517          	auipc	a0,0x14
    80002d74:	c4050513          	addi	a0,a0,-960 # 800169b0 <tickslock>
    80002d78:	ffffe097          	auipc	ra,0xffffe
    80002d7c:	e5e080e7          	jalr	-418(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002d80:	00006497          	auipc	s1,0x6
    80002d84:	b904a483          	lw	s1,-1136(s1) # 80008910 <ticks>
  release(&tickslock);
    80002d88:	00014517          	auipc	a0,0x14
    80002d8c:	c2850513          	addi	a0,a0,-984 # 800169b0 <tickslock>
    80002d90:	ffffe097          	auipc	ra,0xffffe
    80002d94:	efa080e7          	jalr	-262(ra) # 80000c8a <release>
  return xticks;
}
    80002d98:	02049513          	slli	a0,s1,0x20
    80002d9c:	9101                	srli	a0,a0,0x20
    80002d9e:	60e2                	ld	ra,24(sp)
    80002da0:	6442                	ld	s0,16(sp)
    80002da2:	64a2                	ld	s1,8(sp)
    80002da4:	6105                	addi	sp,sp,32
    80002da6:	8082                	ret

0000000080002da8 <sys_hello>:


uint64
sys_hello(void)
{
    80002da8:	1101                	addi	sp,sp,-32
    80002daa:	ec06                	sd	ra,24(sp)
    80002dac:	e822                	sd	s0,16(sp)
    80002dae:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002db0:	fec40593          	addi	a1,s0,-20
    80002db4:	4501                	li	a0,0
    80002db6:	00000097          	auipc	ra,0x0
    80002dba:	d2e080e7          	jalr	-722(ra) # 80002ae4 <argint>
  print_hello(n);
    80002dbe:	fec42503          	lw	a0,-20(s0)
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	7f6080e7          	jalr	2038(ra) # 800025b8 <print_hello>
  return 0;
}
    80002dca:	4501                	li	a0,0
    80002dcc:	60e2                	ld	ra,24(sp)
    80002dce:	6442                	ld	s0,16(sp)
    80002dd0:	6105                	addi	sp,sp,32
    80002dd2:	8082                	ret

0000000080002dd4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002dd4:	7179                	addi	sp,sp,-48
    80002dd6:	f406                	sd	ra,40(sp)
    80002dd8:	f022                	sd	s0,32(sp)
    80002dda:	ec26                	sd	s1,24(sp)
    80002ddc:	e84a                	sd	s2,16(sp)
    80002dde:	e44e                	sd	s3,8(sp)
    80002de0:	e052                	sd	s4,0(sp)
    80002de2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002de4:	00005597          	auipc	a1,0x5
    80002de8:	74458593          	addi	a1,a1,1860 # 80008528 <syscalls+0xb8>
    80002dec:	00014517          	auipc	a0,0x14
    80002df0:	bdc50513          	addi	a0,a0,-1060 # 800169c8 <bcache>
    80002df4:	ffffe097          	auipc	ra,0xffffe
    80002df8:	d52080e7          	jalr	-686(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002dfc:	0001c797          	auipc	a5,0x1c
    80002e00:	bcc78793          	addi	a5,a5,-1076 # 8001e9c8 <bcache+0x8000>
    80002e04:	0001c717          	auipc	a4,0x1c
    80002e08:	e2c70713          	addi	a4,a4,-468 # 8001ec30 <bcache+0x8268>
    80002e0c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e10:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e14:	00014497          	auipc	s1,0x14
    80002e18:	bcc48493          	addi	s1,s1,-1076 # 800169e0 <bcache+0x18>
    b->next = bcache.head.next;
    80002e1c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e1e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e20:	00005a17          	auipc	s4,0x5
    80002e24:	710a0a13          	addi	s4,s4,1808 # 80008530 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002e28:	2b893783          	ld	a5,696(s2)
    80002e2c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e2e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e32:	85d2                	mv	a1,s4
    80002e34:	01048513          	addi	a0,s1,16
    80002e38:	00001097          	auipc	ra,0x1
    80002e3c:	4c8080e7          	jalr	1224(ra) # 80004300 <initsleeplock>
    bcache.head.next->prev = b;
    80002e40:	2b893783          	ld	a5,696(s2)
    80002e44:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e46:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e4a:	45848493          	addi	s1,s1,1112
    80002e4e:	fd349de3          	bne	s1,s3,80002e28 <binit+0x54>
  }
}
    80002e52:	70a2                	ld	ra,40(sp)
    80002e54:	7402                	ld	s0,32(sp)
    80002e56:	64e2                	ld	s1,24(sp)
    80002e58:	6942                	ld	s2,16(sp)
    80002e5a:	69a2                	ld	s3,8(sp)
    80002e5c:	6a02                	ld	s4,0(sp)
    80002e5e:	6145                	addi	sp,sp,48
    80002e60:	8082                	ret

0000000080002e62 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e62:	7179                	addi	sp,sp,-48
    80002e64:	f406                	sd	ra,40(sp)
    80002e66:	f022                	sd	s0,32(sp)
    80002e68:	ec26                	sd	s1,24(sp)
    80002e6a:	e84a                	sd	s2,16(sp)
    80002e6c:	e44e                	sd	s3,8(sp)
    80002e6e:	1800                	addi	s0,sp,48
    80002e70:	892a                	mv	s2,a0
    80002e72:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e74:	00014517          	auipc	a0,0x14
    80002e78:	b5450513          	addi	a0,a0,-1196 # 800169c8 <bcache>
    80002e7c:	ffffe097          	auipc	ra,0xffffe
    80002e80:	d5a080e7          	jalr	-678(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e84:	0001c497          	auipc	s1,0x1c
    80002e88:	dfc4b483          	ld	s1,-516(s1) # 8001ec80 <bcache+0x82b8>
    80002e8c:	0001c797          	auipc	a5,0x1c
    80002e90:	da478793          	addi	a5,a5,-604 # 8001ec30 <bcache+0x8268>
    80002e94:	02f48f63          	beq	s1,a5,80002ed2 <bread+0x70>
    80002e98:	873e                	mv	a4,a5
    80002e9a:	a021                	j	80002ea2 <bread+0x40>
    80002e9c:	68a4                	ld	s1,80(s1)
    80002e9e:	02e48a63          	beq	s1,a4,80002ed2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ea2:	449c                	lw	a5,8(s1)
    80002ea4:	ff279ce3          	bne	a5,s2,80002e9c <bread+0x3a>
    80002ea8:	44dc                	lw	a5,12(s1)
    80002eaa:	ff3799e3          	bne	a5,s3,80002e9c <bread+0x3a>
      b->refcnt++;
    80002eae:	40bc                	lw	a5,64(s1)
    80002eb0:	2785                	addiw	a5,a5,1
    80002eb2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002eb4:	00014517          	auipc	a0,0x14
    80002eb8:	b1450513          	addi	a0,a0,-1260 # 800169c8 <bcache>
    80002ebc:	ffffe097          	auipc	ra,0xffffe
    80002ec0:	dce080e7          	jalr	-562(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002ec4:	01048513          	addi	a0,s1,16
    80002ec8:	00001097          	auipc	ra,0x1
    80002ecc:	472080e7          	jalr	1138(ra) # 8000433a <acquiresleep>
      return b;
    80002ed0:	a8b9                	j	80002f2e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ed2:	0001c497          	auipc	s1,0x1c
    80002ed6:	da64b483          	ld	s1,-602(s1) # 8001ec78 <bcache+0x82b0>
    80002eda:	0001c797          	auipc	a5,0x1c
    80002ede:	d5678793          	addi	a5,a5,-682 # 8001ec30 <bcache+0x8268>
    80002ee2:	00f48863          	beq	s1,a5,80002ef2 <bread+0x90>
    80002ee6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ee8:	40bc                	lw	a5,64(s1)
    80002eea:	cf81                	beqz	a5,80002f02 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002eec:	64a4                	ld	s1,72(s1)
    80002eee:	fee49de3          	bne	s1,a4,80002ee8 <bread+0x86>
  panic("bget: no buffers");
    80002ef2:	00005517          	auipc	a0,0x5
    80002ef6:	64650513          	addi	a0,a0,1606 # 80008538 <syscalls+0xc8>
    80002efa:	ffffd097          	auipc	ra,0xffffd
    80002efe:	646080e7          	jalr	1606(ra) # 80000540 <panic>
      b->dev = dev;
    80002f02:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f06:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f0a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f0e:	4785                	li	a5,1
    80002f10:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f12:	00014517          	auipc	a0,0x14
    80002f16:	ab650513          	addi	a0,a0,-1354 # 800169c8 <bcache>
    80002f1a:	ffffe097          	auipc	ra,0xffffe
    80002f1e:	d70080e7          	jalr	-656(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002f22:	01048513          	addi	a0,s1,16
    80002f26:	00001097          	auipc	ra,0x1
    80002f2a:	414080e7          	jalr	1044(ra) # 8000433a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f2e:	409c                	lw	a5,0(s1)
    80002f30:	cb89                	beqz	a5,80002f42 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f32:	8526                	mv	a0,s1
    80002f34:	70a2                	ld	ra,40(sp)
    80002f36:	7402                	ld	s0,32(sp)
    80002f38:	64e2                	ld	s1,24(sp)
    80002f3a:	6942                	ld	s2,16(sp)
    80002f3c:	69a2                	ld	s3,8(sp)
    80002f3e:	6145                	addi	sp,sp,48
    80002f40:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f42:	4581                	li	a1,0
    80002f44:	8526                	mv	a0,s1
    80002f46:	00003097          	auipc	ra,0x3
    80002f4a:	fdc080e7          	jalr	-36(ra) # 80005f22 <virtio_disk_rw>
    b->valid = 1;
    80002f4e:	4785                	li	a5,1
    80002f50:	c09c                	sw	a5,0(s1)
  return b;
    80002f52:	b7c5                	j	80002f32 <bread+0xd0>

0000000080002f54 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f54:	1101                	addi	sp,sp,-32
    80002f56:	ec06                	sd	ra,24(sp)
    80002f58:	e822                	sd	s0,16(sp)
    80002f5a:	e426                	sd	s1,8(sp)
    80002f5c:	1000                	addi	s0,sp,32
    80002f5e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f60:	0541                	addi	a0,a0,16
    80002f62:	00001097          	auipc	ra,0x1
    80002f66:	472080e7          	jalr	1138(ra) # 800043d4 <holdingsleep>
    80002f6a:	cd01                	beqz	a0,80002f82 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f6c:	4585                	li	a1,1
    80002f6e:	8526                	mv	a0,s1
    80002f70:	00003097          	auipc	ra,0x3
    80002f74:	fb2080e7          	jalr	-78(ra) # 80005f22 <virtio_disk_rw>
}
    80002f78:	60e2                	ld	ra,24(sp)
    80002f7a:	6442                	ld	s0,16(sp)
    80002f7c:	64a2                	ld	s1,8(sp)
    80002f7e:	6105                	addi	sp,sp,32
    80002f80:	8082                	ret
    panic("bwrite");
    80002f82:	00005517          	auipc	a0,0x5
    80002f86:	5ce50513          	addi	a0,a0,1486 # 80008550 <syscalls+0xe0>
    80002f8a:	ffffd097          	auipc	ra,0xffffd
    80002f8e:	5b6080e7          	jalr	1462(ra) # 80000540 <panic>

0000000080002f92 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f92:	1101                	addi	sp,sp,-32
    80002f94:	ec06                	sd	ra,24(sp)
    80002f96:	e822                	sd	s0,16(sp)
    80002f98:	e426                	sd	s1,8(sp)
    80002f9a:	e04a                	sd	s2,0(sp)
    80002f9c:	1000                	addi	s0,sp,32
    80002f9e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fa0:	01050913          	addi	s2,a0,16
    80002fa4:	854a                	mv	a0,s2
    80002fa6:	00001097          	auipc	ra,0x1
    80002faa:	42e080e7          	jalr	1070(ra) # 800043d4 <holdingsleep>
    80002fae:	c92d                	beqz	a0,80003020 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fb0:	854a                	mv	a0,s2
    80002fb2:	00001097          	auipc	ra,0x1
    80002fb6:	3de080e7          	jalr	990(ra) # 80004390 <releasesleep>

  acquire(&bcache.lock);
    80002fba:	00014517          	auipc	a0,0x14
    80002fbe:	a0e50513          	addi	a0,a0,-1522 # 800169c8 <bcache>
    80002fc2:	ffffe097          	auipc	ra,0xffffe
    80002fc6:	c14080e7          	jalr	-1004(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80002fca:	40bc                	lw	a5,64(s1)
    80002fcc:	37fd                	addiw	a5,a5,-1
    80002fce:	0007871b          	sext.w	a4,a5
    80002fd2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fd4:	eb05                	bnez	a4,80003004 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fd6:	68bc                	ld	a5,80(s1)
    80002fd8:	64b8                	ld	a4,72(s1)
    80002fda:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fdc:	64bc                	ld	a5,72(s1)
    80002fde:	68b8                	ld	a4,80(s1)
    80002fe0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002fe2:	0001c797          	auipc	a5,0x1c
    80002fe6:	9e678793          	addi	a5,a5,-1562 # 8001e9c8 <bcache+0x8000>
    80002fea:	2b87b703          	ld	a4,696(a5)
    80002fee:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002ff0:	0001c717          	auipc	a4,0x1c
    80002ff4:	c4070713          	addi	a4,a4,-960 # 8001ec30 <bcache+0x8268>
    80002ff8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002ffa:	2b87b703          	ld	a4,696(a5)
    80002ffe:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003000:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003004:	00014517          	auipc	a0,0x14
    80003008:	9c450513          	addi	a0,a0,-1596 # 800169c8 <bcache>
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	c7e080e7          	jalr	-898(ra) # 80000c8a <release>
}
    80003014:	60e2                	ld	ra,24(sp)
    80003016:	6442                	ld	s0,16(sp)
    80003018:	64a2                	ld	s1,8(sp)
    8000301a:	6902                	ld	s2,0(sp)
    8000301c:	6105                	addi	sp,sp,32
    8000301e:	8082                	ret
    panic("brelse");
    80003020:	00005517          	auipc	a0,0x5
    80003024:	53850513          	addi	a0,a0,1336 # 80008558 <syscalls+0xe8>
    80003028:	ffffd097          	auipc	ra,0xffffd
    8000302c:	518080e7          	jalr	1304(ra) # 80000540 <panic>

0000000080003030 <bpin>:

void
bpin(struct buf *b) {
    80003030:	1101                	addi	sp,sp,-32
    80003032:	ec06                	sd	ra,24(sp)
    80003034:	e822                	sd	s0,16(sp)
    80003036:	e426                	sd	s1,8(sp)
    80003038:	1000                	addi	s0,sp,32
    8000303a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000303c:	00014517          	auipc	a0,0x14
    80003040:	98c50513          	addi	a0,a0,-1652 # 800169c8 <bcache>
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	b92080e7          	jalr	-1134(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000304c:	40bc                	lw	a5,64(s1)
    8000304e:	2785                	addiw	a5,a5,1
    80003050:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003052:	00014517          	auipc	a0,0x14
    80003056:	97650513          	addi	a0,a0,-1674 # 800169c8 <bcache>
    8000305a:	ffffe097          	auipc	ra,0xffffe
    8000305e:	c30080e7          	jalr	-976(ra) # 80000c8a <release>
}
    80003062:	60e2                	ld	ra,24(sp)
    80003064:	6442                	ld	s0,16(sp)
    80003066:	64a2                	ld	s1,8(sp)
    80003068:	6105                	addi	sp,sp,32
    8000306a:	8082                	ret

000000008000306c <bunpin>:

void
bunpin(struct buf *b) {
    8000306c:	1101                	addi	sp,sp,-32
    8000306e:	ec06                	sd	ra,24(sp)
    80003070:	e822                	sd	s0,16(sp)
    80003072:	e426                	sd	s1,8(sp)
    80003074:	1000                	addi	s0,sp,32
    80003076:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003078:	00014517          	auipc	a0,0x14
    8000307c:	95050513          	addi	a0,a0,-1712 # 800169c8 <bcache>
    80003080:	ffffe097          	auipc	ra,0xffffe
    80003084:	b56080e7          	jalr	-1194(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003088:	40bc                	lw	a5,64(s1)
    8000308a:	37fd                	addiw	a5,a5,-1
    8000308c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000308e:	00014517          	auipc	a0,0x14
    80003092:	93a50513          	addi	a0,a0,-1734 # 800169c8 <bcache>
    80003096:	ffffe097          	auipc	ra,0xffffe
    8000309a:	bf4080e7          	jalr	-1036(ra) # 80000c8a <release>
}
    8000309e:	60e2                	ld	ra,24(sp)
    800030a0:	6442                	ld	s0,16(sp)
    800030a2:	64a2                	ld	s1,8(sp)
    800030a4:	6105                	addi	sp,sp,32
    800030a6:	8082                	ret

00000000800030a8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030a8:	1101                	addi	sp,sp,-32
    800030aa:	ec06                	sd	ra,24(sp)
    800030ac:	e822                	sd	s0,16(sp)
    800030ae:	e426                	sd	s1,8(sp)
    800030b0:	e04a                	sd	s2,0(sp)
    800030b2:	1000                	addi	s0,sp,32
    800030b4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030b6:	00d5d59b          	srliw	a1,a1,0xd
    800030ba:	0001c797          	auipc	a5,0x1c
    800030be:	fea7a783          	lw	a5,-22(a5) # 8001f0a4 <sb+0x1c>
    800030c2:	9dbd                	addw	a1,a1,a5
    800030c4:	00000097          	auipc	ra,0x0
    800030c8:	d9e080e7          	jalr	-610(ra) # 80002e62 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030cc:	0074f713          	andi	a4,s1,7
    800030d0:	4785                	li	a5,1
    800030d2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030d6:	14ce                	slli	s1,s1,0x33
    800030d8:	90d9                	srli	s1,s1,0x36
    800030da:	00950733          	add	a4,a0,s1
    800030de:	05874703          	lbu	a4,88(a4)
    800030e2:	00e7f6b3          	and	a3,a5,a4
    800030e6:	c69d                	beqz	a3,80003114 <bfree+0x6c>
    800030e8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030ea:	94aa                	add	s1,s1,a0
    800030ec:	fff7c793          	not	a5,a5
    800030f0:	8f7d                	and	a4,a4,a5
    800030f2:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800030f6:	00001097          	auipc	ra,0x1
    800030fa:	126080e7          	jalr	294(ra) # 8000421c <log_write>
  brelse(bp);
    800030fe:	854a                	mv	a0,s2
    80003100:	00000097          	auipc	ra,0x0
    80003104:	e92080e7          	jalr	-366(ra) # 80002f92 <brelse>
}
    80003108:	60e2                	ld	ra,24(sp)
    8000310a:	6442                	ld	s0,16(sp)
    8000310c:	64a2                	ld	s1,8(sp)
    8000310e:	6902                	ld	s2,0(sp)
    80003110:	6105                	addi	sp,sp,32
    80003112:	8082                	ret
    panic("freeing free block");
    80003114:	00005517          	auipc	a0,0x5
    80003118:	44c50513          	addi	a0,a0,1100 # 80008560 <syscalls+0xf0>
    8000311c:	ffffd097          	auipc	ra,0xffffd
    80003120:	424080e7          	jalr	1060(ra) # 80000540 <panic>

0000000080003124 <balloc>:
{
    80003124:	711d                	addi	sp,sp,-96
    80003126:	ec86                	sd	ra,88(sp)
    80003128:	e8a2                	sd	s0,80(sp)
    8000312a:	e4a6                	sd	s1,72(sp)
    8000312c:	e0ca                	sd	s2,64(sp)
    8000312e:	fc4e                	sd	s3,56(sp)
    80003130:	f852                	sd	s4,48(sp)
    80003132:	f456                	sd	s5,40(sp)
    80003134:	f05a                	sd	s6,32(sp)
    80003136:	ec5e                	sd	s7,24(sp)
    80003138:	e862                	sd	s8,16(sp)
    8000313a:	e466                	sd	s9,8(sp)
    8000313c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000313e:	0001c797          	auipc	a5,0x1c
    80003142:	f4e7a783          	lw	a5,-178(a5) # 8001f08c <sb+0x4>
    80003146:	cff5                	beqz	a5,80003242 <balloc+0x11e>
    80003148:	8baa                	mv	s7,a0
    8000314a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000314c:	0001cb17          	auipc	s6,0x1c
    80003150:	f3cb0b13          	addi	s6,s6,-196 # 8001f088 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003154:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003156:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003158:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000315a:	6c89                	lui	s9,0x2
    8000315c:	a061                	j	800031e4 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000315e:	97ca                	add	a5,a5,s2
    80003160:	8e55                	or	a2,a2,a3
    80003162:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003166:	854a                	mv	a0,s2
    80003168:	00001097          	auipc	ra,0x1
    8000316c:	0b4080e7          	jalr	180(ra) # 8000421c <log_write>
        brelse(bp);
    80003170:	854a                	mv	a0,s2
    80003172:	00000097          	auipc	ra,0x0
    80003176:	e20080e7          	jalr	-480(ra) # 80002f92 <brelse>
  bp = bread(dev, bno);
    8000317a:	85a6                	mv	a1,s1
    8000317c:	855e                	mv	a0,s7
    8000317e:	00000097          	auipc	ra,0x0
    80003182:	ce4080e7          	jalr	-796(ra) # 80002e62 <bread>
    80003186:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003188:	40000613          	li	a2,1024
    8000318c:	4581                	li	a1,0
    8000318e:	05850513          	addi	a0,a0,88
    80003192:	ffffe097          	auipc	ra,0xffffe
    80003196:	b40080e7          	jalr	-1216(ra) # 80000cd2 <memset>
  log_write(bp);
    8000319a:	854a                	mv	a0,s2
    8000319c:	00001097          	auipc	ra,0x1
    800031a0:	080080e7          	jalr	128(ra) # 8000421c <log_write>
  brelse(bp);
    800031a4:	854a                	mv	a0,s2
    800031a6:	00000097          	auipc	ra,0x0
    800031aa:	dec080e7          	jalr	-532(ra) # 80002f92 <brelse>
}
    800031ae:	8526                	mv	a0,s1
    800031b0:	60e6                	ld	ra,88(sp)
    800031b2:	6446                	ld	s0,80(sp)
    800031b4:	64a6                	ld	s1,72(sp)
    800031b6:	6906                	ld	s2,64(sp)
    800031b8:	79e2                	ld	s3,56(sp)
    800031ba:	7a42                	ld	s4,48(sp)
    800031bc:	7aa2                	ld	s5,40(sp)
    800031be:	7b02                	ld	s6,32(sp)
    800031c0:	6be2                	ld	s7,24(sp)
    800031c2:	6c42                	ld	s8,16(sp)
    800031c4:	6ca2                	ld	s9,8(sp)
    800031c6:	6125                	addi	sp,sp,96
    800031c8:	8082                	ret
    brelse(bp);
    800031ca:	854a                	mv	a0,s2
    800031cc:	00000097          	auipc	ra,0x0
    800031d0:	dc6080e7          	jalr	-570(ra) # 80002f92 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031d4:	015c87bb          	addw	a5,s9,s5
    800031d8:	00078a9b          	sext.w	s5,a5
    800031dc:	004b2703          	lw	a4,4(s6)
    800031e0:	06eaf163          	bgeu	s5,a4,80003242 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800031e4:	41fad79b          	sraiw	a5,s5,0x1f
    800031e8:	0137d79b          	srliw	a5,a5,0x13
    800031ec:	015787bb          	addw	a5,a5,s5
    800031f0:	40d7d79b          	sraiw	a5,a5,0xd
    800031f4:	01cb2583          	lw	a1,28(s6)
    800031f8:	9dbd                	addw	a1,a1,a5
    800031fa:	855e                	mv	a0,s7
    800031fc:	00000097          	auipc	ra,0x0
    80003200:	c66080e7          	jalr	-922(ra) # 80002e62 <bread>
    80003204:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003206:	004b2503          	lw	a0,4(s6)
    8000320a:	000a849b          	sext.w	s1,s5
    8000320e:	8762                	mv	a4,s8
    80003210:	faa4fde3          	bgeu	s1,a0,800031ca <balloc+0xa6>
      m = 1 << (bi % 8);
    80003214:	00777693          	andi	a3,a4,7
    80003218:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000321c:	41f7579b          	sraiw	a5,a4,0x1f
    80003220:	01d7d79b          	srliw	a5,a5,0x1d
    80003224:	9fb9                	addw	a5,a5,a4
    80003226:	4037d79b          	sraiw	a5,a5,0x3
    8000322a:	00f90633          	add	a2,s2,a5
    8000322e:	05864603          	lbu	a2,88(a2)
    80003232:	00c6f5b3          	and	a1,a3,a2
    80003236:	d585                	beqz	a1,8000315e <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003238:	2705                	addiw	a4,a4,1
    8000323a:	2485                	addiw	s1,s1,1
    8000323c:	fd471ae3          	bne	a4,s4,80003210 <balloc+0xec>
    80003240:	b769                	j	800031ca <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003242:	00005517          	auipc	a0,0x5
    80003246:	33650513          	addi	a0,a0,822 # 80008578 <syscalls+0x108>
    8000324a:	ffffd097          	auipc	ra,0xffffd
    8000324e:	340080e7          	jalr	832(ra) # 8000058a <printf>
  return 0;
    80003252:	4481                	li	s1,0
    80003254:	bfa9                	j	800031ae <balloc+0x8a>

0000000080003256 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003256:	7179                	addi	sp,sp,-48
    80003258:	f406                	sd	ra,40(sp)
    8000325a:	f022                	sd	s0,32(sp)
    8000325c:	ec26                	sd	s1,24(sp)
    8000325e:	e84a                	sd	s2,16(sp)
    80003260:	e44e                	sd	s3,8(sp)
    80003262:	e052                	sd	s4,0(sp)
    80003264:	1800                	addi	s0,sp,48
    80003266:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003268:	47ad                	li	a5,11
    8000326a:	02b7e863          	bltu	a5,a1,8000329a <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000326e:	02059793          	slli	a5,a1,0x20
    80003272:	01e7d593          	srli	a1,a5,0x1e
    80003276:	00b504b3          	add	s1,a0,a1
    8000327a:	0504a903          	lw	s2,80(s1)
    8000327e:	06091e63          	bnez	s2,800032fa <bmap+0xa4>
      addr = balloc(ip->dev);
    80003282:	4108                	lw	a0,0(a0)
    80003284:	00000097          	auipc	ra,0x0
    80003288:	ea0080e7          	jalr	-352(ra) # 80003124 <balloc>
    8000328c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003290:	06090563          	beqz	s2,800032fa <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003294:	0524a823          	sw	s2,80(s1)
    80003298:	a08d                	j	800032fa <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000329a:	ff45849b          	addiw	s1,a1,-12
    8000329e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032a2:	0ff00793          	li	a5,255
    800032a6:	08e7e563          	bltu	a5,a4,80003330 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800032aa:	08052903          	lw	s2,128(a0)
    800032ae:	00091d63          	bnez	s2,800032c8 <bmap+0x72>
      addr = balloc(ip->dev);
    800032b2:	4108                	lw	a0,0(a0)
    800032b4:	00000097          	auipc	ra,0x0
    800032b8:	e70080e7          	jalr	-400(ra) # 80003124 <balloc>
    800032bc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032c0:	02090d63          	beqz	s2,800032fa <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800032c4:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800032c8:	85ca                	mv	a1,s2
    800032ca:	0009a503          	lw	a0,0(s3)
    800032ce:	00000097          	auipc	ra,0x0
    800032d2:	b94080e7          	jalr	-1132(ra) # 80002e62 <bread>
    800032d6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032d8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032dc:	02049713          	slli	a4,s1,0x20
    800032e0:	01e75593          	srli	a1,a4,0x1e
    800032e4:	00b784b3          	add	s1,a5,a1
    800032e8:	0004a903          	lw	s2,0(s1)
    800032ec:	02090063          	beqz	s2,8000330c <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800032f0:	8552                	mv	a0,s4
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	ca0080e7          	jalr	-864(ra) # 80002f92 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032fa:	854a                	mv	a0,s2
    800032fc:	70a2                	ld	ra,40(sp)
    800032fe:	7402                	ld	s0,32(sp)
    80003300:	64e2                	ld	s1,24(sp)
    80003302:	6942                	ld	s2,16(sp)
    80003304:	69a2                	ld	s3,8(sp)
    80003306:	6a02                	ld	s4,0(sp)
    80003308:	6145                	addi	sp,sp,48
    8000330a:	8082                	ret
      addr = balloc(ip->dev);
    8000330c:	0009a503          	lw	a0,0(s3)
    80003310:	00000097          	auipc	ra,0x0
    80003314:	e14080e7          	jalr	-492(ra) # 80003124 <balloc>
    80003318:	0005091b          	sext.w	s2,a0
      if(addr){
    8000331c:	fc090ae3          	beqz	s2,800032f0 <bmap+0x9a>
        a[bn] = addr;
    80003320:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003324:	8552                	mv	a0,s4
    80003326:	00001097          	auipc	ra,0x1
    8000332a:	ef6080e7          	jalr	-266(ra) # 8000421c <log_write>
    8000332e:	b7c9                	j	800032f0 <bmap+0x9a>
  panic("bmap: out of range");
    80003330:	00005517          	auipc	a0,0x5
    80003334:	26050513          	addi	a0,a0,608 # 80008590 <syscalls+0x120>
    80003338:	ffffd097          	auipc	ra,0xffffd
    8000333c:	208080e7          	jalr	520(ra) # 80000540 <panic>

0000000080003340 <iget>:
{
    80003340:	7179                	addi	sp,sp,-48
    80003342:	f406                	sd	ra,40(sp)
    80003344:	f022                	sd	s0,32(sp)
    80003346:	ec26                	sd	s1,24(sp)
    80003348:	e84a                	sd	s2,16(sp)
    8000334a:	e44e                	sd	s3,8(sp)
    8000334c:	e052                	sd	s4,0(sp)
    8000334e:	1800                	addi	s0,sp,48
    80003350:	89aa                	mv	s3,a0
    80003352:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003354:	0001c517          	auipc	a0,0x1c
    80003358:	d5450513          	addi	a0,a0,-684 # 8001f0a8 <itable>
    8000335c:	ffffe097          	auipc	ra,0xffffe
    80003360:	87a080e7          	jalr	-1926(ra) # 80000bd6 <acquire>
  empty = 0;
    80003364:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003366:	0001c497          	auipc	s1,0x1c
    8000336a:	d5a48493          	addi	s1,s1,-678 # 8001f0c0 <itable+0x18>
    8000336e:	0001d697          	auipc	a3,0x1d
    80003372:	7e268693          	addi	a3,a3,2018 # 80020b50 <log>
    80003376:	a039                	j	80003384 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003378:	02090b63          	beqz	s2,800033ae <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000337c:	08848493          	addi	s1,s1,136
    80003380:	02d48a63          	beq	s1,a3,800033b4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003384:	449c                	lw	a5,8(s1)
    80003386:	fef059e3          	blez	a5,80003378 <iget+0x38>
    8000338a:	4098                	lw	a4,0(s1)
    8000338c:	ff3716e3          	bne	a4,s3,80003378 <iget+0x38>
    80003390:	40d8                	lw	a4,4(s1)
    80003392:	ff4713e3          	bne	a4,s4,80003378 <iget+0x38>
      ip->ref++;
    80003396:	2785                	addiw	a5,a5,1
    80003398:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000339a:	0001c517          	auipc	a0,0x1c
    8000339e:	d0e50513          	addi	a0,a0,-754 # 8001f0a8 <itable>
    800033a2:	ffffe097          	auipc	ra,0xffffe
    800033a6:	8e8080e7          	jalr	-1816(ra) # 80000c8a <release>
      return ip;
    800033aa:	8926                	mv	s2,s1
    800033ac:	a03d                	j	800033da <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033ae:	f7f9                	bnez	a5,8000337c <iget+0x3c>
    800033b0:	8926                	mv	s2,s1
    800033b2:	b7e9                	j	8000337c <iget+0x3c>
  if(empty == 0)
    800033b4:	02090c63          	beqz	s2,800033ec <iget+0xac>
  ip->dev = dev;
    800033b8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033bc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033c0:	4785                	li	a5,1
    800033c2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033c6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033ca:	0001c517          	auipc	a0,0x1c
    800033ce:	cde50513          	addi	a0,a0,-802 # 8001f0a8 <itable>
    800033d2:	ffffe097          	auipc	ra,0xffffe
    800033d6:	8b8080e7          	jalr	-1864(ra) # 80000c8a <release>
}
    800033da:	854a                	mv	a0,s2
    800033dc:	70a2                	ld	ra,40(sp)
    800033de:	7402                	ld	s0,32(sp)
    800033e0:	64e2                	ld	s1,24(sp)
    800033e2:	6942                	ld	s2,16(sp)
    800033e4:	69a2                	ld	s3,8(sp)
    800033e6:	6a02                	ld	s4,0(sp)
    800033e8:	6145                	addi	sp,sp,48
    800033ea:	8082                	ret
    panic("iget: no inodes");
    800033ec:	00005517          	auipc	a0,0x5
    800033f0:	1bc50513          	addi	a0,a0,444 # 800085a8 <syscalls+0x138>
    800033f4:	ffffd097          	auipc	ra,0xffffd
    800033f8:	14c080e7          	jalr	332(ra) # 80000540 <panic>

00000000800033fc <fsinit>:
fsinit(int dev) {
    800033fc:	7179                	addi	sp,sp,-48
    800033fe:	f406                	sd	ra,40(sp)
    80003400:	f022                	sd	s0,32(sp)
    80003402:	ec26                	sd	s1,24(sp)
    80003404:	e84a                	sd	s2,16(sp)
    80003406:	e44e                	sd	s3,8(sp)
    80003408:	1800                	addi	s0,sp,48
    8000340a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000340c:	4585                	li	a1,1
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	a54080e7          	jalr	-1452(ra) # 80002e62 <bread>
    80003416:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003418:	0001c997          	auipc	s3,0x1c
    8000341c:	c7098993          	addi	s3,s3,-912 # 8001f088 <sb>
    80003420:	02000613          	li	a2,32
    80003424:	05850593          	addi	a1,a0,88
    80003428:	854e                	mv	a0,s3
    8000342a:	ffffe097          	auipc	ra,0xffffe
    8000342e:	904080e7          	jalr	-1788(ra) # 80000d2e <memmove>
  brelse(bp);
    80003432:	8526                	mv	a0,s1
    80003434:	00000097          	auipc	ra,0x0
    80003438:	b5e080e7          	jalr	-1186(ra) # 80002f92 <brelse>
  if(sb.magic != FSMAGIC)
    8000343c:	0009a703          	lw	a4,0(s3)
    80003440:	102037b7          	lui	a5,0x10203
    80003444:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003448:	02f71263          	bne	a4,a5,8000346c <fsinit+0x70>
  initlog(dev, &sb);
    8000344c:	0001c597          	auipc	a1,0x1c
    80003450:	c3c58593          	addi	a1,a1,-964 # 8001f088 <sb>
    80003454:	854a                	mv	a0,s2
    80003456:	00001097          	auipc	ra,0x1
    8000345a:	b4a080e7          	jalr	-1206(ra) # 80003fa0 <initlog>
}
    8000345e:	70a2                	ld	ra,40(sp)
    80003460:	7402                	ld	s0,32(sp)
    80003462:	64e2                	ld	s1,24(sp)
    80003464:	6942                	ld	s2,16(sp)
    80003466:	69a2                	ld	s3,8(sp)
    80003468:	6145                	addi	sp,sp,48
    8000346a:	8082                	ret
    panic("invalid file system");
    8000346c:	00005517          	auipc	a0,0x5
    80003470:	14c50513          	addi	a0,a0,332 # 800085b8 <syscalls+0x148>
    80003474:	ffffd097          	auipc	ra,0xffffd
    80003478:	0cc080e7          	jalr	204(ra) # 80000540 <panic>

000000008000347c <iinit>:
{
    8000347c:	7179                	addi	sp,sp,-48
    8000347e:	f406                	sd	ra,40(sp)
    80003480:	f022                	sd	s0,32(sp)
    80003482:	ec26                	sd	s1,24(sp)
    80003484:	e84a                	sd	s2,16(sp)
    80003486:	e44e                	sd	s3,8(sp)
    80003488:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000348a:	00005597          	auipc	a1,0x5
    8000348e:	14658593          	addi	a1,a1,326 # 800085d0 <syscalls+0x160>
    80003492:	0001c517          	auipc	a0,0x1c
    80003496:	c1650513          	addi	a0,a0,-1002 # 8001f0a8 <itable>
    8000349a:	ffffd097          	auipc	ra,0xffffd
    8000349e:	6ac080e7          	jalr	1708(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034a2:	0001c497          	auipc	s1,0x1c
    800034a6:	c2e48493          	addi	s1,s1,-978 # 8001f0d0 <itable+0x28>
    800034aa:	0001d997          	auipc	s3,0x1d
    800034ae:	6b698993          	addi	s3,s3,1718 # 80020b60 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800034b2:	00005917          	auipc	s2,0x5
    800034b6:	12690913          	addi	s2,s2,294 # 800085d8 <syscalls+0x168>
    800034ba:	85ca                	mv	a1,s2
    800034bc:	8526                	mv	a0,s1
    800034be:	00001097          	auipc	ra,0x1
    800034c2:	e42080e7          	jalr	-446(ra) # 80004300 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034c6:	08848493          	addi	s1,s1,136
    800034ca:	ff3498e3          	bne	s1,s3,800034ba <iinit+0x3e>
}
    800034ce:	70a2                	ld	ra,40(sp)
    800034d0:	7402                	ld	s0,32(sp)
    800034d2:	64e2                	ld	s1,24(sp)
    800034d4:	6942                	ld	s2,16(sp)
    800034d6:	69a2                	ld	s3,8(sp)
    800034d8:	6145                	addi	sp,sp,48
    800034da:	8082                	ret

00000000800034dc <ialloc>:
{
    800034dc:	715d                	addi	sp,sp,-80
    800034de:	e486                	sd	ra,72(sp)
    800034e0:	e0a2                	sd	s0,64(sp)
    800034e2:	fc26                	sd	s1,56(sp)
    800034e4:	f84a                	sd	s2,48(sp)
    800034e6:	f44e                	sd	s3,40(sp)
    800034e8:	f052                	sd	s4,32(sp)
    800034ea:	ec56                	sd	s5,24(sp)
    800034ec:	e85a                	sd	s6,16(sp)
    800034ee:	e45e                	sd	s7,8(sp)
    800034f0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034f2:	0001c717          	auipc	a4,0x1c
    800034f6:	ba272703          	lw	a4,-1118(a4) # 8001f094 <sb+0xc>
    800034fa:	4785                	li	a5,1
    800034fc:	04e7fa63          	bgeu	a5,a4,80003550 <ialloc+0x74>
    80003500:	8aaa                	mv	s5,a0
    80003502:	8bae                	mv	s7,a1
    80003504:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003506:	0001ca17          	auipc	s4,0x1c
    8000350a:	b82a0a13          	addi	s4,s4,-1150 # 8001f088 <sb>
    8000350e:	00048b1b          	sext.w	s6,s1
    80003512:	0044d593          	srli	a1,s1,0x4
    80003516:	018a2783          	lw	a5,24(s4)
    8000351a:	9dbd                	addw	a1,a1,a5
    8000351c:	8556                	mv	a0,s5
    8000351e:	00000097          	auipc	ra,0x0
    80003522:	944080e7          	jalr	-1724(ra) # 80002e62 <bread>
    80003526:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003528:	05850993          	addi	s3,a0,88
    8000352c:	00f4f793          	andi	a5,s1,15
    80003530:	079a                	slli	a5,a5,0x6
    80003532:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003534:	00099783          	lh	a5,0(s3)
    80003538:	c3a1                	beqz	a5,80003578 <ialloc+0x9c>
    brelse(bp);
    8000353a:	00000097          	auipc	ra,0x0
    8000353e:	a58080e7          	jalr	-1448(ra) # 80002f92 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003542:	0485                	addi	s1,s1,1
    80003544:	00ca2703          	lw	a4,12(s4)
    80003548:	0004879b          	sext.w	a5,s1
    8000354c:	fce7e1e3          	bltu	a5,a4,8000350e <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003550:	00005517          	auipc	a0,0x5
    80003554:	09050513          	addi	a0,a0,144 # 800085e0 <syscalls+0x170>
    80003558:	ffffd097          	auipc	ra,0xffffd
    8000355c:	032080e7          	jalr	50(ra) # 8000058a <printf>
  return 0;
    80003560:	4501                	li	a0,0
}
    80003562:	60a6                	ld	ra,72(sp)
    80003564:	6406                	ld	s0,64(sp)
    80003566:	74e2                	ld	s1,56(sp)
    80003568:	7942                	ld	s2,48(sp)
    8000356a:	79a2                	ld	s3,40(sp)
    8000356c:	7a02                	ld	s4,32(sp)
    8000356e:	6ae2                	ld	s5,24(sp)
    80003570:	6b42                	ld	s6,16(sp)
    80003572:	6ba2                	ld	s7,8(sp)
    80003574:	6161                	addi	sp,sp,80
    80003576:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003578:	04000613          	li	a2,64
    8000357c:	4581                	li	a1,0
    8000357e:	854e                	mv	a0,s3
    80003580:	ffffd097          	auipc	ra,0xffffd
    80003584:	752080e7          	jalr	1874(ra) # 80000cd2 <memset>
      dip->type = type;
    80003588:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000358c:	854a                	mv	a0,s2
    8000358e:	00001097          	auipc	ra,0x1
    80003592:	c8e080e7          	jalr	-882(ra) # 8000421c <log_write>
      brelse(bp);
    80003596:	854a                	mv	a0,s2
    80003598:	00000097          	auipc	ra,0x0
    8000359c:	9fa080e7          	jalr	-1542(ra) # 80002f92 <brelse>
      return iget(dev, inum);
    800035a0:	85da                	mv	a1,s6
    800035a2:	8556                	mv	a0,s5
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	d9c080e7          	jalr	-612(ra) # 80003340 <iget>
    800035ac:	bf5d                	j	80003562 <ialloc+0x86>

00000000800035ae <iupdate>:
{
    800035ae:	1101                	addi	sp,sp,-32
    800035b0:	ec06                	sd	ra,24(sp)
    800035b2:	e822                	sd	s0,16(sp)
    800035b4:	e426                	sd	s1,8(sp)
    800035b6:	e04a                	sd	s2,0(sp)
    800035b8:	1000                	addi	s0,sp,32
    800035ba:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035bc:	415c                	lw	a5,4(a0)
    800035be:	0047d79b          	srliw	a5,a5,0x4
    800035c2:	0001c597          	auipc	a1,0x1c
    800035c6:	ade5a583          	lw	a1,-1314(a1) # 8001f0a0 <sb+0x18>
    800035ca:	9dbd                	addw	a1,a1,a5
    800035cc:	4108                	lw	a0,0(a0)
    800035ce:	00000097          	auipc	ra,0x0
    800035d2:	894080e7          	jalr	-1900(ra) # 80002e62 <bread>
    800035d6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035d8:	05850793          	addi	a5,a0,88
    800035dc:	40d8                	lw	a4,4(s1)
    800035de:	8b3d                	andi	a4,a4,15
    800035e0:	071a                	slli	a4,a4,0x6
    800035e2:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800035e4:	04449703          	lh	a4,68(s1)
    800035e8:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800035ec:	04649703          	lh	a4,70(s1)
    800035f0:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800035f4:	04849703          	lh	a4,72(s1)
    800035f8:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800035fc:	04a49703          	lh	a4,74(s1)
    80003600:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003604:	44f8                	lw	a4,76(s1)
    80003606:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003608:	03400613          	li	a2,52
    8000360c:	05048593          	addi	a1,s1,80
    80003610:	00c78513          	addi	a0,a5,12
    80003614:	ffffd097          	auipc	ra,0xffffd
    80003618:	71a080e7          	jalr	1818(ra) # 80000d2e <memmove>
  log_write(bp);
    8000361c:	854a                	mv	a0,s2
    8000361e:	00001097          	auipc	ra,0x1
    80003622:	bfe080e7          	jalr	-1026(ra) # 8000421c <log_write>
  brelse(bp);
    80003626:	854a                	mv	a0,s2
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	96a080e7          	jalr	-1686(ra) # 80002f92 <brelse>
}
    80003630:	60e2                	ld	ra,24(sp)
    80003632:	6442                	ld	s0,16(sp)
    80003634:	64a2                	ld	s1,8(sp)
    80003636:	6902                	ld	s2,0(sp)
    80003638:	6105                	addi	sp,sp,32
    8000363a:	8082                	ret

000000008000363c <idup>:
{
    8000363c:	1101                	addi	sp,sp,-32
    8000363e:	ec06                	sd	ra,24(sp)
    80003640:	e822                	sd	s0,16(sp)
    80003642:	e426                	sd	s1,8(sp)
    80003644:	1000                	addi	s0,sp,32
    80003646:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003648:	0001c517          	auipc	a0,0x1c
    8000364c:	a6050513          	addi	a0,a0,-1440 # 8001f0a8 <itable>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	586080e7          	jalr	1414(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003658:	449c                	lw	a5,8(s1)
    8000365a:	2785                	addiw	a5,a5,1
    8000365c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000365e:	0001c517          	auipc	a0,0x1c
    80003662:	a4a50513          	addi	a0,a0,-1462 # 8001f0a8 <itable>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	624080e7          	jalr	1572(ra) # 80000c8a <release>
}
    8000366e:	8526                	mv	a0,s1
    80003670:	60e2                	ld	ra,24(sp)
    80003672:	6442                	ld	s0,16(sp)
    80003674:	64a2                	ld	s1,8(sp)
    80003676:	6105                	addi	sp,sp,32
    80003678:	8082                	ret

000000008000367a <ilock>:
{
    8000367a:	1101                	addi	sp,sp,-32
    8000367c:	ec06                	sd	ra,24(sp)
    8000367e:	e822                	sd	s0,16(sp)
    80003680:	e426                	sd	s1,8(sp)
    80003682:	e04a                	sd	s2,0(sp)
    80003684:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003686:	c115                	beqz	a0,800036aa <ilock+0x30>
    80003688:	84aa                	mv	s1,a0
    8000368a:	451c                	lw	a5,8(a0)
    8000368c:	00f05f63          	blez	a5,800036aa <ilock+0x30>
  acquiresleep(&ip->lock);
    80003690:	0541                	addi	a0,a0,16
    80003692:	00001097          	auipc	ra,0x1
    80003696:	ca8080e7          	jalr	-856(ra) # 8000433a <acquiresleep>
  if(ip->valid == 0){
    8000369a:	40bc                	lw	a5,64(s1)
    8000369c:	cf99                	beqz	a5,800036ba <ilock+0x40>
}
    8000369e:	60e2                	ld	ra,24(sp)
    800036a0:	6442                	ld	s0,16(sp)
    800036a2:	64a2                	ld	s1,8(sp)
    800036a4:	6902                	ld	s2,0(sp)
    800036a6:	6105                	addi	sp,sp,32
    800036a8:	8082                	ret
    panic("ilock");
    800036aa:	00005517          	auipc	a0,0x5
    800036ae:	f4e50513          	addi	a0,a0,-178 # 800085f8 <syscalls+0x188>
    800036b2:	ffffd097          	auipc	ra,0xffffd
    800036b6:	e8e080e7          	jalr	-370(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036ba:	40dc                	lw	a5,4(s1)
    800036bc:	0047d79b          	srliw	a5,a5,0x4
    800036c0:	0001c597          	auipc	a1,0x1c
    800036c4:	9e05a583          	lw	a1,-1568(a1) # 8001f0a0 <sb+0x18>
    800036c8:	9dbd                	addw	a1,a1,a5
    800036ca:	4088                	lw	a0,0(s1)
    800036cc:	fffff097          	auipc	ra,0xfffff
    800036d0:	796080e7          	jalr	1942(ra) # 80002e62 <bread>
    800036d4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036d6:	05850593          	addi	a1,a0,88
    800036da:	40dc                	lw	a5,4(s1)
    800036dc:	8bbd                	andi	a5,a5,15
    800036de:	079a                	slli	a5,a5,0x6
    800036e0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036e2:	00059783          	lh	a5,0(a1)
    800036e6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036ea:	00259783          	lh	a5,2(a1)
    800036ee:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036f2:	00459783          	lh	a5,4(a1)
    800036f6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036fa:	00659783          	lh	a5,6(a1)
    800036fe:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003702:	459c                	lw	a5,8(a1)
    80003704:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003706:	03400613          	li	a2,52
    8000370a:	05b1                	addi	a1,a1,12
    8000370c:	05048513          	addi	a0,s1,80
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	61e080e7          	jalr	1566(ra) # 80000d2e <memmove>
    brelse(bp);
    80003718:	854a                	mv	a0,s2
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	878080e7          	jalr	-1928(ra) # 80002f92 <brelse>
    ip->valid = 1;
    80003722:	4785                	li	a5,1
    80003724:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003726:	04449783          	lh	a5,68(s1)
    8000372a:	fbb5                	bnez	a5,8000369e <ilock+0x24>
      panic("ilock: no type");
    8000372c:	00005517          	auipc	a0,0x5
    80003730:	ed450513          	addi	a0,a0,-300 # 80008600 <syscalls+0x190>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	e0c080e7          	jalr	-500(ra) # 80000540 <panic>

000000008000373c <iunlock>:
{
    8000373c:	1101                	addi	sp,sp,-32
    8000373e:	ec06                	sd	ra,24(sp)
    80003740:	e822                	sd	s0,16(sp)
    80003742:	e426                	sd	s1,8(sp)
    80003744:	e04a                	sd	s2,0(sp)
    80003746:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003748:	c905                	beqz	a0,80003778 <iunlock+0x3c>
    8000374a:	84aa                	mv	s1,a0
    8000374c:	01050913          	addi	s2,a0,16
    80003750:	854a                	mv	a0,s2
    80003752:	00001097          	auipc	ra,0x1
    80003756:	c82080e7          	jalr	-894(ra) # 800043d4 <holdingsleep>
    8000375a:	cd19                	beqz	a0,80003778 <iunlock+0x3c>
    8000375c:	449c                	lw	a5,8(s1)
    8000375e:	00f05d63          	blez	a5,80003778 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003762:	854a                	mv	a0,s2
    80003764:	00001097          	auipc	ra,0x1
    80003768:	c2c080e7          	jalr	-980(ra) # 80004390 <releasesleep>
}
    8000376c:	60e2                	ld	ra,24(sp)
    8000376e:	6442                	ld	s0,16(sp)
    80003770:	64a2                	ld	s1,8(sp)
    80003772:	6902                	ld	s2,0(sp)
    80003774:	6105                	addi	sp,sp,32
    80003776:	8082                	ret
    panic("iunlock");
    80003778:	00005517          	auipc	a0,0x5
    8000377c:	e9850513          	addi	a0,a0,-360 # 80008610 <syscalls+0x1a0>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	dc0080e7          	jalr	-576(ra) # 80000540 <panic>

0000000080003788 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003788:	7179                	addi	sp,sp,-48
    8000378a:	f406                	sd	ra,40(sp)
    8000378c:	f022                	sd	s0,32(sp)
    8000378e:	ec26                	sd	s1,24(sp)
    80003790:	e84a                	sd	s2,16(sp)
    80003792:	e44e                	sd	s3,8(sp)
    80003794:	e052                	sd	s4,0(sp)
    80003796:	1800                	addi	s0,sp,48
    80003798:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000379a:	05050493          	addi	s1,a0,80
    8000379e:	08050913          	addi	s2,a0,128
    800037a2:	a021                	j	800037aa <itrunc+0x22>
    800037a4:	0491                	addi	s1,s1,4
    800037a6:	01248d63          	beq	s1,s2,800037c0 <itrunc+0x38>
    if(ip->addrs[i]){
    800037aa:	408c                	lw	a1,0(s1)
    800037ac:	dde5                	beqz	a1,800037a4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037ae:	0009a503          	lw	a0,0(s3)
    800037b2:	00000097          	auipc	ra,0x0
    800037b6:	8f6080e7          	jalr	-1802(ra) # 800030a8 <bfree>
      ip->addrs[i] = 0;
    800037ba:	0004a023          	sw	zero,0(s1)
    800037be:	b7dd                	j	800037a4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037c0:	0809a583          	lw	a1,128(s3)
    800037c4:	e185                	bnez	a1,800037e4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037c6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037ca:	854e                	mv	a0,s3
    800037cc:	00000097          	auipc	ra,0x0
    800037d0:	de2080e7          	jalr	-542(ra) # 800035ae <iupdate>
}
    800037d4:	70a2                	ld	ra,40(sp)
    800037d6:	7402                	ld	s0,32(sp)
    800037d8:	64e2                	ld	s1,24(sp)
    800037da:	6942                	ld	s2,16(sp)
    800037dc:	69a2                	ld	s3,8(sp)
    800037de:	6a02                	ld	s4,0(sp)
    800037e0:	6145                	addi	sp,sp,48
    800037e2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037e4:	0009a503          	lw	a0,0(s3)
    800037e8:	fffff097          	auipc	ra,0xfffff
    800037ec:	67a080e7          	jalr	1658(ra) # 80002e62 <bread>
    800037f0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037f2:	05850493          	addi	s1,a0,88
    800037f6:	45850913          	addi	s2,a0,1112
    800037fa:	a021                	j	80003802 <itrunc+0x7a>
    800037fc:	0491                	addi	s1,s1,4
    800037fe:	01248b63          	beq	s1,s2,80003814 <itrunc+0x8c>
      if(a[j])
    80003802:	408c                	lw	a1,0(s1)
    80003804:	dde5                	beqz	a1,800037fc <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003806:	0009a503          	lw	a0,0(s3)
    8000380a:	00000097          	auipc	ra,0x0
    8000380e:	89e080e7          	jalr	-1890(ra) # 800030a8 <bfree>
    80003812:	b7ed                	j	800037fc <itrunc+0x74>
    brelse(bp);
    80003814:	8552                	mv	a0,s4
    80003816:	fffff097          	auipc	ra,0xfffff
    8000381a:	77c080e7          	jalr	1916(ra) # 80002f92 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000381e:	0809a583          	lw	a1,128(s3)
    80003822:	0009a503          	lw	a0,0(s3)
    80003826:	00000097          	auipc	ra,0x0
    8000382a:	882080e7          	jalr	-1918(ra) # 800030a8 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000382e:	0809a023          	sw	zero,128(s3)
    80003832:	bf51                	j	800037c6 <itrunc+0x3e>

0000000080003834 <iput>:
{
    80003834:	1101                	addi	sp,sp,-32
    80003836:	ec06                	sd	ra,24(sp)
    80003838:	e822                	sd	s0,16(sp)
    8000383a:	e426                	sd	s1,8(sp)
    8000383c:	e04a                	sd	s2,0(sp)
    8000383e:	1000                	addi	s0,sp,32
    80003840:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003842:	0001c517          	auipc	a0,0x1c
    80003846:	86650513          	addi	a0,a0,-1946 # 8001f0a8 <itable>
    8000384a:	ffffd097          	auipc	ra,0xffffd
    8000384e:	38c080e7          	jalr	908(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003852:	4498                	lw	a4,8(s1)
    80003854:	4785                	li	a5,1
    80003856:	02f70363          	beq	a4,a5,8000387c <iput+0x48>
  ip->ref--;
    8000385a:	449c                	lw	a5,8(s1)
    8000385c:	37fd                	addiw	a5,a5,-1
    8000385e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003860:	0001c517          	auipc	a0,0x1c
    80003864:	84850513          	addi	a0,a0,-1976 # 8001f0a8 <itable>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	422080e7          	jalr	1058(ra) # 80000c8a <release>
}
    80003870:	60e2                	ld	ra,24(sp)
    80003872:	6442                	ld	s0,16(sp)
    80003874:	64a2                	ld	s1,8(sp)
    80003876:	6902                	ld	s2,0(sp)
    80003878:	6105                	addi	sp,sp,32
    8000387a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000387c:	40bc                	lw	a5,64(s1)
    8000387e:	dff1                	beqz	a5,8000385a <iput+0x26>
    80003880:	04a49783          	lh	a5,74(s1)
    80003884:	fbf9                	bnez	a5,8000385a <iput+0x26>
    acquiresleep(&ip->lock);
    80003886:	01048913          	addi	s2,s1,16
    8000388a:	854a                	mv	a0,s2
    8000388c:	00001097          	auipc	ra,0x1
    80003890:	aae080e7          	jalr	-1362(ra) # 8000433a <acquiresleep>
    release(&itable.lock);
    80003894:	0001c517          	auipc	a0,0x1c
    80003898:	81450513          	addi	a0,a0,-2028 # 8001f0a8 <itable>
    8000389c:	ffffd097          	auipc	ra,0xffffd
    800038a0:	3ee080e7          	jalr	1006(ra) # 80000c8a <release>
    itrunc(ip);
    800038a4:	8526                	mv	a0,s1
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	ee2080e7          	jalr	-286(ra) # 80003788 <itrunc>
    ip->type = 0;
    800038ae:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038b2:	8526                	mv	a0,s1
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	cfa080e7          	jalr	-774(ra) # 800035ae <iupdate>
    ip->valid = 0;
    800038bc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038c0:	854a                	mv	a0,s2
    800038c2:	00001097          	auipc	ra,0x1
    800038c6:	ace080e7          	jalr	-1330(ra) # 80004390 <releasesleep>
    acquire(&itable.lock);
    800038ca:	0001b517          	auipc	a0,0x1b
    800038ce:	7de50513          	addi	a0,a0,2014 # 8001f0a8 <itable>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	304080e7          	jalr	772(ra) # 80000bd6 <acquire>
    800038da:	b741                	j	8000385a <iput+0x26>

00000000800038dc <iunlockput>:
{
    800038dc:	1101                	addi	sp,sp,-32
    800038de:	ec06                	sd	ra,24(sp)
    800038e0:	e822                	sd	s0,16(sp)
    800038e2:	e426                	sd	s1,8(sp)
    800038e4:	1000                	addi	s0,sp,32
    800038e6:	84aa                	mv	s1,a0
  iunlock(ip);
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	e54080e7          	jalr	-428(ra) # 8000373c <iunlock>
  iput(ip);
    800038f0:	8526                	mv	a0,s1
    800038f2:	00000097          	auipc	ra,0x0
    800038f6:	f42080e7          	jalr	-190(ra) # 80003834 <iput>
}
    800038fa:	60e2                	ld	ra,24(sp)
    800038fc:	6442                	ld	s0,16(sp)
    800038fe:	64a2                	ld	s1,8(sp)
    80003900:	6105                	addi	sp,sp,32
    80003902:	8082                	ret

0000000080003904 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003904:	1141                	addi	sp,sp,-16
    80003906:	e422                	sd	s0,8(sp)
    80003908:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000390a:	411c                	lw	a5,0(a0)
    8000390c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000390e:	415c                	lw	a5,4(a0)
    80003910:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003912:	04451783          	lh	a5,68(a0)
    80003916:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000391a:	04a51783          	lh	a5,74(a0)
    8000391e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003922:	04c56783          	lwu	a5,76(a0)
    80003926:	e99c                	sd	a5,16(a1)
}
    80003928:	6422                	ld	s0,8(sp)
    8000392a:	0141                	addi	sp,sp,16
    8000392c:	8082                	ret

000000008000392e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000392e:	457c                	lw	a5,76(a0)
    80003930:	0ed7e963          	bltu	a5,a3,80003a22 <readi+0xf4>
{
    80003934:	7159                	addi	sp,sp,-112
    80003936:	f486                	sd	ra,104(sp)
    80003938:	f0a2                	sd	s0,96(sp)
    8000393a:	eca6                	sd	s1,88(sp)
    8000393c:	e8ca                	sd	s2,80(sp)
    8000393e:	e4ce                	sd	s3,72(sp)
    80003940:	e0d2                	sd	s4,64(sp)
    80003942:	fc56                	sd	s5,56(sp)
    80003944:	f85a                	sd	s6,48(sp)
    80003946:	f45e                	sd	s7,40(sp)
    80003948:	f062                	sd	s8,32(sp)
    8000394a:	ec66                	sd	s9,24(sp)
    8000394c:	e86a                	sd	s10,16(sp)
    8000394e:	e46e                	sd	s11,8(sp)
    80003950:	1880                	addi	s0,sp,112
    80003952:	8b2a                	mv	s6,a0
    80003954:	8bae                	mv	s7,a1
    80003956:	8a32                	mv	s4,a2
    80003958:	84b6                	mv	s1,a3
    8000395a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000395c:	9f35                	addw	a4,a4,a3
    return 0;
    8000395e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003960:	0ad76063          	bltu	a4,a3,80003a00 <readi+0xd2>
  if(off + n > ip->size)
    80003964:	00e7f463          	bgeu	a5,a4,8000396c <readi+0x3e>
    n = ip->size - off;
    80003968:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000396c:	0a0a8963          	beqz	s5,80003a1e <readi+0xf0>
    80003970:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003972:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003976:	5c7d                	li	s8,-1
    80003978:	a82d                	j	800039b2 <readi+0x84>
    8000397a:	020d1d93          	slli	s11,s10,0x20
    8000397e:	020ddd93          	srli	s11,s11,0x20
    80003982:	05890613          	addi	a2,s2,88
    80003986:	86ee                	mv	a3,s11
    80003988:	963a                	add	a2,a2,a4
    8000398a:	85d2                	mv	a1,s4
    8000398c:	855e                	mv	a0,s7
    8000398e:	fffff097          	auipc	ra,0xfffff
    80003992:	ace080e7          	jalr	-1330(ra) # 8000245c <either_copyout>
    80003996:	05850d63          	beq	a0,s8,800039f0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000399a:	854a                	mv	a0,s2
    8000399c:	fffff097          	auipc	ra,0xfffff
    800039a0:	5f6080e7          	jalr	1526(ra) # 80002f92 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039a4:	013d09bb          	addw	s3,s10,s3
    800039a8:	009d04bb          	addw	s1,s10,s1
    800039ac:	9a6e                	add	s4,s4,s11
    800039ae:	0559f763          	bgeu	s3,s5,800039fc <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800039b2:	00a4d59b          	srliw	a1,s1,0xa
    800039b6:	855a                	mv	a0,s6
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	89e080e7          	jalr	-1890(ra) # 80003256 <bmap>
    800039c0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800039c4:	cd85                	beqz	a1,800039fc <readi+0xce>
    bp = bread(ip->dev, addr);
    800039c6:	000b2503          	lw	a0,0(s6)
    800039ca:	fffff097          	auipc	ra,0xfffff
    800039ce:	498080e7          	jalr	1176(ra) # 80002e62 <bread>
    800039d2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039d4:	3ff4f713          	andi	a4,s1,1023
    800039d8:	40ec87bb          	subw	a5,s9,a4
    800039dc:	413a86bb          	subw	a3,s5,s3
    800039e0:	8d3e                	mv	s10,a5
    800039e2:	2781                	sext.w	a5,a5
    800039e4:	0006861b          	sext.w	a2,a3
    800039e8:	f8f679e3          	bgeu	a2,a5,8000397a <readi+0x4c>
    800039ec:	8d36                	mv	s10,a3
    800039ee:	b771                	j	8000397a <readi+0x4c>
      brelse(bp);
    800039f0:	854a                	mv	a0,s2
    800039f2:	fffff097          	auipc	ra,0xfffff
    800039f6:	5a0080e7          	jalr	1440(ra) # 80002f92 <brelse>
      tot = -1;
    800039fa:	59fd                	li	s3,-1
  }
  return tot;
    800039fc:	0009851b          	sext.w	a0,s3
}
    80003a00:	70a6                	ld	ra,104(sp)
    80003a02:	7406                	ld	s0,96(sp)
    80003a04:	64e6                	ld	s1,88(sp)
    80003a06:	6946                	ld	s2,80(sp)
    80003a08:	69a6                	ld	s3,72(sp)
    80003a0a:	6a06                	ld	s4,64(sp)
    80003a0c:	7ae2                	ld	s5,56(sp)
    80003a0e:	7b42                	ld	s6,48(sp)
    80003a10:	7ba2                	ld	s7,40(sp)
    80003a12:	7c02                	ld	s8,32(sp)
    80003a14:	6ce2                	ld	s9,24(sp)
    80003a16:	6d42                	ld	s10,16(sp)
    80003a18:	6da2                	ld	s11,8(sp)
    80003a1a:	6165                	addi	sp,sp,112
    80003a1c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a1e:	89d6                	mv	s3,s5
    80003a20:	bff1                	j	800039fc <readi+0xce>
    return 0;
    80003a22:	4501                	li	a0,0
}
    80003a24:	8082                	ret

0000000080003a26 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a26:	457c                	lw	a5,76(a0)
    80003a28:	10d7e863          	bltu	a5,a3,80003b38 <writei+0x112>
{
    80003a2c:	7159                	addi	sp,sp,-112
    80003a2e:	f486                	sd	ra,104(sp)
    80003a30:	f0a2                	sd	s0,96(sp)
    80003a32:	eca6                	sd	s1,88(sp)
    80003a34:	e8ca                	sd	s2,80(sp)
    80003a36:	e4ce                	sd	s3,72(sp)
    80003a38:	e0d2                	sd	s4,64(sp)
    80003a3a:	fc56                	sd	s5,56(sp)
    80003a3c:	f85a                	sd	s6,48(sp)
    80003a3e:	f45e                	sd	s7,40(sp)
    80003a40:	f062                	sd	s8,32(sp)
    80003a42:	ec66                	sd	s9,24(sp)
    80003a44:	e86a                	sd	s10,16(sp)
    80003a46:	e46e                	sd	s11,8(sp)
    80003a48:	1880                	addi	s0,sp,112
    80003a4a:	8aaa                	mv	s5,a0
    80003a4c:	8bae                	mv	s7,a1
    80003a4e:	8a32                	mv	s4,a2
    80003a50:	8936                	mv	s2,a3
    80003a52:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a54:	00e687bb          	addw	a5,a3,a4
    80003a58:	0ed7e263          	bltu	a5,a3,80003b3c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a5c:	00043737          	lui	a4,0x43
    80003a60:	0ef76063          	bltu	a4,a5,80003b40 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a64:	0c0b0863          	beqz	s6,80003b34 <writei+0x10e>
    80003a68:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a6a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a6e:	5c7d                	li	s8,-1
    80003a70:	a091                	j	80003ab4 <writei+0x8e>
    80003a72:	020d1d93          	slli	s11,s10,0x20
    80003a76:	020ddd93          	srli	s11,s11,0x20
    80003a7a:	05848513          	addi	a0,s1,88
    80003a7e:	86ee                	mv	a3,s11
    80003a80:	8652                	mv	a2,s4
    80003a82:	85de                	mv	a1,s7
    80003a84:	953a                	add	a0,a0,a4
    80003a86:	fffff097          	auipc	ra,0xfffff
    80003a8a:	a2c080e7          	jalr	-1492(ra) # 800024b2 <either_copyin>
    80003a8e:	07850263          	beq	a0,s8,80003af2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a92:	8526                	mv	a0,s1
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	788080e7          	jalr	1928(ra) # 8000421c <log_write>
    brelse(bp);
    80003a9c:	8526                	mv	a0,s1
    80003a9e:	fffff097          	auipc	ra,0xfffff
    80003aa2:	4f4080e7          	jalr	1268(ra) # 80002f92 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aa6:	013d09bb          	addw	s3,s10,s3
    80003aaa:	012d093b          	addw	s2,s10,s2
    80003aae:	9a6e                	add	s4,s4,s11
    80003ab0:	0569f663          	bgeu	s3,s6,80003afc <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003ab4:	00a9559b          	srliw	a1,s2,0xa
    80003ab8:	8556                	mv	a0,s5
    80003aba:	fffff097          	auipc	ra,0xfffff
    80003abe:	79c080e7          	jalr	1948(ra) # 80003256 <bmap>
    80003ac2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ac6:	c99d                	beqz	a1,80003afc <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003ac8:	000aa503          	lw	a0,0(s5)
    80003acc:	fffff097          	auipc	ra,0xfffff
    80003ad0:	396080e7          	jalr	918(ra) # 80002e62 <bread>
    80003ad4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ad6:	3ff97713          	andi	a4,s2,1023
    80003ada:	40ec87bb          	subw	a5,s9,a4
    80003ade:	413b06bb          	subw	a3,s6,s3
    80003ae2:	8d3e                	mv	s10,a5
    80003ae4:	2781                	sext.w	a5,a5
    80003ae6:	0006861b          	sext.w	a2,a3
    80003aea:	f8f674e3          	bgeu	a2,a5,80003a72 <writei+0x4c>
    80003aee:	8d36                	mv	s10,a3
    80003af0:	b749                	j	80003a72 <writei+0x4c>
      brelse(bp);
    80003af2:	8526                	mv	a0,s1
    80003af4:	fffff097          	auipc	ra,0xfffff
    80003af8:	49e080e7          	jalr	1182(ra) # 80002f92 <brelse>
  }

  if(off > ip->size)
    80003afc:	04caa783          	lw	a5,76(s5)
    80003b00:	0127f463          	bgeu	a5,s2,80003b08 <writei+0xe2>
    ip->size = off;
    80003b04:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b08:	8556                	mv	a0,s5
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	aa4080e7          	jalr	-1372(ra) # 800035ae <iupdate>

  return tot;
    80003b12:	0009851b          	sext.w	a0,s3
}
    80003b16:	70a6                	ld	ra,104(sp)
    80003b18:	7406                	ld	s0,96(sp)
    80003b1a:	64e6                	ld	s1,88(sp)
    80003b1c:	6946                	ld	s2,80(sp)
    80003b1e:	69a6                	ld	s3,72(sp)
    80003b20:	6a06                	ld	s4,64(sp)
    80003b22:	7ae2                	ld	s5,56(sp)
    80003b24:	7b42                	ld	s6,48(sp)
    80003b26:	7ba2                	ld	s7,40(sp)
    80003b28:	7c02                	ld	s8,32(sp)
    80003b2a:	6ce2                	ld	s9,24(sp)
    80003b2c:	6d42                	ld	s10,16(sp)
    80003b2e:	6da2                	ld	s11,8(sp)
    80003b30:	6165                	addi	sp,sp,112
    80003b32:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b34:	89da                	mv	s3,s6
    80003b36:	bfc9                	j	80003b08 <writei+0xe2>
    return -1;
    80003b38:	557d                	li	a0,-1
}
    80003b3a:	8082                	ret
    return -1;
    80003b3c:	557d                	li	a0,-1
    80003b3e:	bfe1                	j	80003b16 <writei+0xf0>
    return -1;
    80003b40:	557d                	li	a0,-1
    80003b42:	bfd1                	j	80003b16 <writei+0xf0>

0000000080003b44 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b44:	1141                	addi	sp,sp,-16
    80003b46:	e406                	sd	ra,8(sp)
    80003b48:	e022                	sd	s0,0(sp)
    80003b4a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b4c:	4639                	li	a2,14
    80003b4e:	ffffd097          	auipc	ra,0xffffd
    80003b52:	254080e7          	jalr	596(ra) # 80000da2 <strncmp>
}
    80003b56:	60a2                	ld	ra,8(sp)
    80003b58:	6402                	ld	s0,0(sp)
    80003b5a:	0141                	addi	sp,sp,16
    80003b5c:	8082                	ret

0000000080003b5e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b5e:	7139                	addi	sp,sp,-64
    80003b60:	fc06                	sd	ra,56(sp)
    80003b62:	f822                	sd	s0,48(sp)
    80003b64:	f426                	sd	s1,40(sp)
    80003b66:	f04a                	sd	s2,32(sp)
    80003b68:	ec4e                	sd	s3,24(sp)
    80003b6a:	e852                	sd	s4,16(sp)
    80003b6c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b6e:	04451703          	lh	a4,68(a0)
    80003b72:	4785                	li	a5,1
    80003b74:	00f71a63          	bne	a4,a5,80003b88 <dirlookup+0x2a>
    80003b78:	892a                	mv	s2,a0
    80003b7a:	89ae                	mv	s3,a1
    80003b7c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b7e:	457c                	lw	a5,76(a0)
    80003b80:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b82:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b84:	e79d                	bnez	a5,80003bb2 <dirlookup+0x54>
    80003b86:	a8a5                	j	80003bfe <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b88:	00005517          	auipc	a0,0x5
    80003b8c:	a9050513          	addi	a0,a0,-1392 # 80008618 <syscalls+0x1a8>
    80003b90:	ffffd097          	auipc	ra,0xffffd
    80003b94:	9b0080e7          	jalr	-1616(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003b98:	00005517          	auipc	a0,0x5
    80003b9c:	a9850513          	addi	a0,a0,-1384 # 80008630 <syscalls+0x1c0>
    80003ba0:	ffffd097          	auipc	ra,0xffffd
    80003ba4:	9a0080e7          	jalr	-1632(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ba8:	24c1                	addiw	s1,s1,16
    80003baa:	04c92783          	lw	a5,76(s2)
    80003bae:	04f4f763          	bgeu	s1,a5,80003bfc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bb2:	4741                	li	a4,16
    80003bb4:	86a6                	mv	a3,s1
    80003bb6:	fc040613          	addi	a2,s0,-64
    80003bba:	4581                	li	a1,0
    80003bbc:	854a                	mv	a0,s2
    80003bbe:	00000097          	auipc	ra,0x0
    80003bc2:	d70080e7          	jalr	-656(ra) # 8000392e <readi>
    80003bc6:	47c1                	li	a5,16
    80003bc8:	fcf518e3          	bne	a0,a5,80003b98 <dirlookup+0x3a>
    if(de.inum == 0)
    80003bcc:	fc045783          	lhu	a5,-64(s0)
    80003bd0:	dfe1                	beqz	a5,80003ba8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003bd2:	fc240593          	addi	a1,s0,-62
    80003bd6:	854e                	mv	a0,s3
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	f6c080e7          	jalr	-148(ra) # 80003b44 <namecmp>
    80003be0:	f561                	bnez	a0,80003ba8 <dirlookup+0x4a>
      if(poff)
    80003be2:	000a0463          	beqz	s4,80003bea <dirlookup+0x8c>
        *poff = off;
    80003be6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bea:	fc045583          	lhu	a1,-64(s0)
    80003bee:	00092503          	lw	a0,0(s2)
    80003bf2:	fffff097          	auipc	ra,0xfffff
    80003bf6:	74e080e7          	jalr	1870(ra) # 80003340 <iget>
    80003bfa:	a011                	j	80003bfe <dirlookup+0xa0>
  return 0;
    80003bfc:	4501                	li	a0,0
}
    80003bfe:	70e2                	ld	ra,56(sp)
    80003c00:	7442                	ld	s0,48(sp)
    80003c02:	74a2                	ld	s1,40(sp)
    80003c04:	7902                	ld	s2,32(sp)
    80003c06:	69e2                	ld	s3,24(sp)
    80003c08:	6a42                	ld	s4,16(sp)
    80003c0a:	6121                	addi	sp,sp,64
    80003c0c:	8082                	ret

0000000080003c0e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c0e:	711d                	addi	sp,sp,-96
    80003c10:	ec86                	sd	ra,88(sp)
    80003c12:	e8a2                	sd	s0,80(sp)
    80003c14:	e4a6                	sd	s1,72(sp)
    80003c16:	e0ca                	sd	s2,64(sp)
    80003c18:	fc4e                	sd	s3,56(sp)
    80003c1a:	f852                	sd	s4,48(sp)
    80003c1c:	f456                	sd	s5,40(sp)
    80003c1e:	f05a                	sd	s6,32(sp)
    80003c20:	ec5e                	sd	s7,24(sp)
    80003c22:	e862                	sd	s8,16(sp)
    80003c24:	e466                	sd	s9,8(sp)
    80003c26:	e06a                	sd	s10,0(sp)
    80003c28:	1080                	addi	s0,sp,96
    80003c2a:	84aa                	mv	s1,a0
    80003c2c:	8b2e                	mv	s6,a1
    80003c2e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c30:	00054703          	lbu	a4,0(a0)
    80003c34:	02f00793          	li	a5,47
    80003c38:	02f70363          	beq	a4,a5,80003c5e <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c3c:	ffffe097          	auipc	ra,0xffffe
    80003c40:	d70080e7          	jalr	-656(ra) # 800019ac <myproc>
    80003c44:	15053503          	ld	a0,336(a0)
    80003c48:	00000097          	auipc	ra,0x0
    80003c4c:	9f4080e7          	jalr	-1548(ra) # 8000363c <idup>
    80003c50:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003c52:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003c56:	4cb5                	li	s9,13
  len = path - s;
    80003c58:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c5a:	4c05                	li	s8,1
    80003c5c:	a87d                	j	80003d1a <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003c5e:	4585                	li	a1,1
    80003c60:	4505                	li	a0,1
    80003c62:	fffff097          	auipc	ra,0xfffff
    80003c66:	6de080e7          	jalr	1758(ra) # 80003340 <iget>
    80003c6a:	8a2a                	mv	s4,a0
    80003c6c:	b7dd                	j	80003c52 <namex+0x44>
      iunlockput(ip);
    80003c6e:	8552                	mv	a0,s4
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	c6c080e7          	jalr	-916(ra) # 800038dc <iunlockput>
      return 0;
    80003c78:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c7a:	8552                	mv	a0,s4
    80003c7c:	60e6                	ld	ra,88(sp)
    80003c7e:	6446                	ld	s0,80(sp)
    80003c80:	64a6                	ld	s1,72(sp)
    80003c82:	6906                	ld	s2,64(sp)
    80003c84:	79e2                	ld	s3,56(sp)
    80003c86:	7a42                	ld	s4,48(sp)
    80003c88:	7aa2                	ld	s5,40(sp)
    80003c8a:	7b02                	ld	s6,32(sp)
    80003c8c:	6be2                	ld	s7,24(sp)
    80003c8e:	6c42                	ld	s8,16(sp)
    80003c90:	6ca2                	ld	s9,8(sp)
    80003c92:	6d02                	ld	s10,0(sp)
    80003c94:	6125                	addi	sp,sp,96
    80003c96:	8082                	ret
      iunlock(ip);
    80003c98:	8552                	mv	a0,s4
    80003c9a:	00000097          	auipc	ra,0x0
    80003c9e:	aa2080e7          	jalr	-1374(ra) # 8000373c <iunlock>
      return ip;
    80003ca2:	bfe1                	j	80003c7a <namex+0x6c>
      iunlockput(ip);
    80003ca4:	8552                	mv	a0,s4
    80003ca6:	00000097          	auipc	ra,0x0
    80003caa:	c36080e7          	jalr	-970(ra) # 800038dc <iunlockput>
      return 0;
    80003cae:	8a4e                	mv	s4,s3
    80003cb0:	b7e9                	j	80003c7a <namex+0x6c>
  len = path - s;
    80003cb2:	40998633          	sub	a2,s3,s1
    80003cb6:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003cba:	09acd863          	bge	s9,s10,80003d4a <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003cbe:	4639                	li	a2,14
    80003cc0:	85a6                	mv	a1,s1
    80003cc2:	8556                	mv	a0,s5
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	06a080e7          	jalr	106(ra) # 80000d2e <memmove>
    80003ccc:	84ce                	mv	s1,s3
  while(*path == '/')
    80003cce:	0004c783          	lbu	a5,0(s1)
    80003cd2:	01279763          	bne	a5,s2,80003ce0 <namex+0xd2>
    path++;
    80003cd6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cd8:	0004c783          	lbu	a5,0(s1)
    80003cdc:	ff278de3          	beq	a5,s2,80003cd6 <namex+0xc8>
    ilock(ip);
    80003ce0:	8552                	mv	a0,s4
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	998080e7          	jalr	-1640(ra) # 8000367a <ilock>
    if(ip->type != T_DIR){
    80003cea:	044a1783          	lh	a5,68(s4)
    80003cee:	f98790e3          	bne	a5,s8,80003c6e <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003cf2:	000b0563          	beqz	s6,80003cfc <namex+0xee>
    80003cf6:	0004c783          	lbu	a5,0(s1)
    80003cfa:	dfd9                	beqz	a5,80003c98 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cfc:	865e                	mv	a2,s7
    80003cfe:	85d6                	mv	a1,s5
    80003d00:	8552                	mv	a0,s4
    80003d02:	00000097          	auipc	ra,0x0
    80003d06:	e5c080e7          	jalr	-420(ra) # 80003b5e <dirlookup>
    80003d0a:	89aa                	mv	s3,a0
    80003d0c:	dd41                	beqz	a0,80003ca4 <namex+0x96>
    iunlockput(ip);
    80003d0e:	8552                	mv	a0,s4
    80003d10:	00000097          	auipc	ra,0x0
    80003d14:	bcc080e7          	jalr	-1076(ra) # 800038dc <iunlockput>
    ip = next;
    80003d18:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003d1a:	0004c783          	lbu	a5,0(s1)
    80003d1e:	01279763          	bne	a5,s2,80003d2c <namex+0x11e>
    path++;
    80003d22:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d24:	0004c783          	lbu	a5,0(s1)
    80003d28:	ff278de3          	beq	a5,s2,80003d22 <namex+0x114>
  if(*path == 0)
    80003d2c:	cb9d                	beqz	a5,80003d62 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003d2e:	0004c783          	lbu	a5,0(s1)
    80003d32:	89a6                	mv	s3,s1
  len = path - s;
    80003d34:	8d5e                	mv	s10,s7
    80003d36:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d38:	01278963          	beq	a5,s2,80003d4a <namex+0x13c>
    80003d3c:	dbbd                	beqz	a5,80003cb2 <namex+0xa4>
    path++;
    80003d3e:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003d40:	0009c783          	lbu	a5,0(s3)
    80003d44:	ff279ce3          	bne	a5,s2,80003d3c <namex+0x12e>
    80003d48:	b7ad                	j	80003cb2 <namex+0xa4>
    memmove(name, s, len);
    80003d4a:	2601                	sext.w	a2,a2
    80003d4c:	85a6                	mv	a1,s1
    80003d4e:	8556                	mv	a0,s5
    80003d50:	ffffd097          	auipc	ra,0xffffd
    80003d54:	fde080e7          	jalr	-34(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003d58:	9d56                	add	s10,s10,s5
    80003d5a:	000d0023          	sb	zero,0(s10)
    80003d5e:	84ce                	mv	s1,s3
    80003d60:	b7bd                	j	80003cce <namex+0xc0>
  if(nameiparent){
    80003d62:	f00b0ce3          	beqz	s6,80003c7a <namex+0x6c>
    iput(ip);
    80003d66:	8552                	mv	a0,s4
    80003d68:	00000097          	auipc	ra,0x0
    80003d6c:	acc080e7          	jalr	-1332(ra) # 80003834 <iput>
    return 0;
    80003d70:	4a01                	li	s4,0
    80003d72:	b721                	j	80003c7a <namex+0x6c>

0000000080003d74 <dirlink>:
{
    80003d74:	7139                	addi	sp,sp,-64
    80003d76:	fc06                	sd	ra,56(sp)
    80003d78:	f822                	sd	s0,48(sp)
    80003d7a:	f426                	sd	s1,40(sp)
    80003d7c:	f04a                	sd	s2,32(sp)
    80003d7e:	ec4e                	sd	s3,24(sp)
    80003d80:	e852                	sd	s4,16(sp)
    80003d82:	0080                	addi	s0,sp,64
    80003d84:	892a                	mv	s2,a0
    80003d86:	8a2e                	mv	s4,a1
    80003d88:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d8a:	4601                	li	a2,0
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	dd2080e7          	jalr	-558(ra) # 80003b5e <dirlookup>
    80003d94:	e93d                	bnez	a0,80003e0a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d96:	04c92483          	lw	s1,76(s2)
    80003d9a:	c49d                	beqz	s1,80003dc8 <dirlink+0x54>
    80003d9c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d9e:	4741                	li	a4,16
    80003da0:	86a6                	mv	a3,s1
    80003da2:	fc040613          	addi	a2,s0,-64
    80003da6:	4581                	li	a1,0
    80003da8:	854a                	mv	a0,s2
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	b84080e7          	jalr	-1148(ra) # 8000392e <readi>
    80003db2:	47c1                	li	a5,16
    80003db4:	06f51163          	bne	a0,a5,80003e16 <dirlink+0xa2>
    if(de.inum == 0)
    80003db8:	fc045783          	lhu	a5,-64(s0)
    80003dbc:	c791                	beqz	a5,80003dc8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dbe:	24c1                	addiw	s1,s1,16
    80003dc0:	04c92783          	lw	a5,76(s2)
    80003dc4:	fcf4ede3          	bltu	s1,a5,80003d9e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003dc8:	4639                	li	a2,14
    80003dca:	85d2                	mv	a1,s4
    80003dcc:	fc240513          	addi	a0,s0,-62
    80003dd0:	ffffd097          	auipc	ra,0xffffd
    80003dd4:	00e080e7          	jalr	14(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003dd8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ddc:	4741                	li	a4,16
    80003dde:	86a6                	mv	a3,s1
    80003de0:	fc040613          	addi	a2,s0,-64
    80003de4:	4581                	li	a1,0
    80003de6:	854a                	mv	a0,s2
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	c3e080e7          	jalr	-962(ra) # 80003a26 <writei>
    80003df0:	1541                	addi	a0,a0,-16
    80003df2:	00a03533          	snez	a0,a0
    80003df6:	40a00533          	neg	a0,a0
}
    80003dfa:	70e2                	ld	ra,56(sp)
    80003dfc:	7442                	ld	s0,48(sp)
    80003dfe:	74a2                	ld	s1,40(sp)
    80003e00:	7902                	ld	s2,32(sp)
    80003e02:	69e2                	ld	s3,24(sp)
    80003e04:	6a42                	ld	s4,16(sp)
    80003e06:	6121                	addi	sp,sp,64
    80003e08:	8082                	ret
    iput(ip);
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	a2a080e7          	jalr	-1494(ra) # 80003834 <iput>
    return -1;
    80003e12:	557d                	li	a0,-1
    80003e14:	b7dd                	j	80003dfa <dirlink+0x86>
      panic("dirlink read");
    80003e16:	00005517          	auipc	a0,0x5
    80003e1a:	82a50513          	addi	a0,a0,-2006 # 80008640 <syscalls+0x1d0>
    80003e1e:	ffffc097          	auipc	ra,0xffffc
    80003e22:	722080e7          	jalr	1826(ra) # 80000540 <panic>

0000000080003e26 <namei>:

struct inode*
namei(char *path)
{
    80003e26:	1101                	addi	sp,sp,-32
    80003e28:	ec06                	sd	ra,24(sp)
    80003e2a:	e822                	sd	s0,16(sp)
    80003e2c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e2e:	fe040613          	addi	a2,s0,-32
    80003e32:	4581                	li	a1,0
    80003e34:	00000097          	auipc	ra,0x0
    80003e38:	dda080e7          	jalr	-550(ra) # 80003c0e <namex>
}
    80003e3c:	60e2                	ld	ra,24(sp)
    80003e3e:	6442                	ld	s0,16(sp)
    80003e40:	6105                	addi	sp,sp,32
    80003e42:	8082                	ret

0000000080003e44 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e44:	1141                	addi	sp,sp,-16
    80003e46:	e406                	sd	ra,8(sp)
    80003e48:	e022                	sd	s0,0(sp)
    80003e4a:	0800                	addi	s0,sp,16
    80003e4c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e4e:	4585                	li	a1,1
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	dbe080e7          	jalr	-578(ra) # 80003c0e <namex>
}
    80003e58:	60a2                	ld	ra,8(sp)
    80003e5a:	6402                	ld	s0,0(sp)
    80003e5c:	0141                	addi	sp,sp,16
    80003e5e:	8082                	ret

0000000080003e60 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e60:	1101                	addi	sp,sp,-32
    80003e62:	ec06                	sd	ra,24(sp)
    80003e64:	e822                	sd	s0,16(sp)
    80003e66:	e426                	sd	s1,8(sp)
    80003e68:	e04a                	sd	s2,0(sp)
    80003e6a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e6c:	0001d917          	auipc	s2,0x1d
    80003e70:	ce490913          	addi	s2,s2,-796 # 80020b50 <log>
    80003e74:	01892583          	lw	a1,24(s2)
    80003e78:	02892503          	lw	a0,40(s2)
    80003e7c:	fffff097          	auipc	ra,0xfffff
    80003e80:	fe6080e7          	jalr	-26(ra) # 80002e62 <bread>
    80003e84:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e86:	02c92683          	lw	a3,44(s2)
    80003e8a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e8c:	02d05863          	blez	a3,80003ebc <write_head+0x5c>
    80003e90:	0001d797          	auipc	a5,0x1d
    80003e94:	cf078793          	addi	a5,a5,-784 # 80020b80 <log+0x30>
    80003e98:	05c50713          	addi	a4,a0,92
    80003e9c:	36fd                	addiw	a3,a3,-1
    80003e9e:	02069613          	slli	a2,a3,0x20
    80003ea2:	01e65693          	srli	a3,a2,0x1e
    80003ea6:	0001d617          	auipc	a2,0x1d
    80003eaa:	cde60613          	addi	a2,a2,-802 # 80020b84 <log+0x34>
    80003eae:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003eb0:	4390                	lw	a2,0(a5)
    80003eb2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003eb4:	0791                	addi	a5,a5,4
    80003eb6:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003eb8:	fed79ce3          	bne	a5,a3,80003eb0 <write_head+0x50>
  }
  bwrite(buf);
    80003ebc:	8526                	mv	a0,s1
    80003ebe:	fffff097          	auipc	ra,0xfffff
    80003ec2:	096080e7          	jalr	150(ra) # 80002f54 <bwrite>
  brelse(buf);
    80003ec6:	8526                	mv	a0,s1
    80003ec8:	fffff097          	auipc	ra,0xfffff
    80003ecc:	0ca080e7          	jalr	202(ra) # 80002f92 <brelse>
}
    80003ed0:	60e2                	ld	ra,24(sp)
    80003ed2:	6442                	ld	s0,16(sp)
    80003ed4:	64a2                	ld	s1,8(sp)
    80003ed6:	6902                	ld	s2,0(sp)
    80003ed8:	6105                	addi	sp,sp,32
    80003eda:	8082                	ret

0000000080003edc <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003edc:	0001d797          	auipc	a5,0x1d
    80003ee0:	ca07a783          	lw	a5,-864(a5) # 80020b7c <log+0x2c>
    80003ee4:	0af05d63          	blez	a5,80003f9e <install_trans+0xc2>
{
    80003ee8:	7139                	addi	sp,sp,-64
    80003eea:	fc06                	sd	ra,56(sp)
    80003eec:	f822                	sd	s0,48(sp)
    80003eee:	f426                	sd	s1,40(sp)
    80003ef0:	f04a                	sd	s2,32(sp)
    80003ef2:	ec4e                	sd	s3,24(sp)
    80003ef4:	e852                	sd	s4,16(sp)
    80003ef6:	e456                	sd	s5,8(sp)
    80003ef8:	e05a                	sd	s6,0(sp)
    80003efa:	0080                	addi	s0,sp,64
    80003efc:	8b2a                	mv	s6,a0
    80003efe:	0001da97          	auipc	s5,0x1d
    80003f02:	c82a8a93          	addi	s5,s5,-894 # 80020b80 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f06:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f08:	0001d997          	auipc	s3,0x1d
    80003f0c:	c4898993          	addi	s3,s3,-952 # 80020b50 <log>
    80003f10:	a00d                	j	80003f32 <install_trans+0x56>
    brelse(lbuf);
    80003f12:	854a                	mv	a0,s2
    80003f14:	fffff097          	auipc	ra,0xfffff
    80003f18:	07e080e7          	jalr	126(ra) # 80002f92 <brelse>
    brelse(dbuf);
    80003f1c:	8526                	mv	a0,s1
    80003f1e:	fffff097          	auipc	ra,0xfffff
    80003f22:	074080e7          	jalr	116(ra) # 80002f92 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f26:	2a05                	addiw	s4,s4,1
    80003f28:	0a91                	addi	s5,s5,4
    80003f2a:	02c9a783          	lw	a5,44(s3)
    80003f2e:	04fa5e63          	bge	s4,a5,80003f8a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f32:	0189a583          	lw	a1,24(s3)
    80003f36:	014585bb          	addw	a1,a1,s4
    80003f3a:	2585                	addiw	a1,a1,1
    80003f3c:	0289a503          	lw	a0,40(s3)
    80003f40:	fffff097          	auipc	ra,0xfffff
    80003f44:	f22080e7          	jalr	-222(ra) # 80002e62 <bread>
    80003f48:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f4a:	000aa583          	lw	a1,0(s5)
    80003f4e:	0289a503          	lw	a0,40(s3)
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	f10080e7          	jalr	-240(ra) # 80002e62 <bread>
    80003f5a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f5c:	40000613          	li	a2,1024
    80003f60:	05890593          	addi	a1,s2,88
    80003f64:	05850513          	addi	a0,a0,88
    80003f68:	ffffd097          	auipc	ra,0xffffd
    80003f6c:	dc6080e7          	jalr	-570(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f70:	8526                	mv	a0,s1
    80003f72:	fffff097          	auipc	ra,0xfffff
    80003f76:	fe2080e7          	jalr	-30(ra) # 80002f54 <bwrite>
    if(recovering == 0)
    80003f7a:	f80b1ce3          	bnez	s6,80003f12 <install_trans+0x36>
      bunpin(dbuf);
    80003f7e:	8526                	mv	a0,s1
    80003f80:	fffff097          	auipc	ra,0xfffff
    80003f84:	0ec080e7          	jalr	236(ra) # 8000306c <bunpin>
    80003f88:	b769                	j	80003f12 <install_trans+0x36>
}
    80003f8a:	70e2                	ld	ra,56(sp)
    80003f8c:	7442                	ld	s0,48(sp)
    80003f8e:	74a2                	ld	s1,40(sp)
    80003f90:	7902                	ld	s2,32(sp)
    80003f92:	69e2                	ld	s3,24(sp)
    80003f94:	6a42                	ld	s4,16(sp)
    80003f96:	6aa2                	ld	s5,8(sp)
    80003f98:	6b02                	ld	s6,0(sp)
    80003f9a:	6121                	addi	sp,sp,64
    80003f9c:	8082                	ret
    80003f9e:	8082                	ret

0000000080003fa0 <initlog>:
{
    80003fa0:	7179                	addi	sp,sp,-48
    80003fa2:	f406                	sd	ra,40(sp)
    80003fa4:	f022                	sd	s0,32(sp)
    80003fa6:	ec26                	sd	s1,24(sp)
    80003fa8:	e84a                	sd	s2,16(sp)
    80003faa:	e44e                	sd	s3,8(sp)
    80003fac:	1800                	addi	s0,sp,48
    80003fae:	892a                	mv	s2,a0
    80003fb0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fb2:	0001d497          	auipc	s1,0x1d
    80003fb6:	b9e48493          	addi	s1,s1,-1122 # 80020b50 <log>
    80003fba:	00004597          	auipc	a1,0x4
    80003fbe:	69658593          	addi	a1,a1,1686 # 80008650 <syscalls+0x1e0>
    80003fc2:	8526                	mv	a0,s1
    80003fc4:	ffffd097          	auipc	ra,0xffffd
    80003fc8:	b82080e7          	jalr	-1150(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80003fcc:	0149a583          	lw	a1,20(s3)
    80003fd0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fd2:	0109a783          	lw	a5,16(s3)
    80003fd6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003fd8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fdc:	854a                	mv	a0,s2
    80003fde:	fffff097          	auipc	ra,0xfffff
    80003fe2:	e84080e7          	jalr	-380(ra) # 80002e62 <bread>
  log.lh.n = lh->n;
    80003fe6:	4d34                	lw	a3,88(a0)
    80003fe8:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fea:	02d05663          	blez	a3,80004016 <initlog+0x76>
    80003fee:	05c50793          	addi	a5,a0,92
    80003ff2:	0001d717          	auipc	a4,0x1d
    80003ff6:	b8e70713          	addi	a4,a4,-1138 # 80020b80 <log+0x30>
    80003ffa:	36fd                	addiw	a3,a3,-1
    80003ffc:	02069613          	slli	a2,a3,0x20
    80004000:	01e65693          	srli	a3,a2,0x1e
    80004004:	06050613          	addi	a2,a0,96
    80004008:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000400a:	4390                	lw	a2,0(a5)
    8000400c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000400e:	0791                	addi	a5,a5,4
    80004010:	0711                	addi	a4,a4,4
    80004012:	fed79ce3          	bne	a5,a3,8000400a <initlog+0x6a>
  brelse(buf);
    80004016:	fffff097          	auipc	ra,0xfffff
    8000401a:	f7c080e7          	jalr	-132(ra) # 80002f92 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000401e:	4505                	li	a0,1
    80004020:	00000097          	auipc	ra,0x0
    80004024:	ebc080e7          	jalr	-324(ra) # 80003edc <install_trans>
  log.lh.n = 0;
    80004028:	0001d797          	auipc	a5,0x1d
    8000402c:	b407aa23          	sw	zero,-1196(a5) # 80020b7c <log+0x2c>
  write_head(); // clear the log
    80004030:	00000097          	auipc	ra,0x0
    80004034:	e30080e7          	jalr	-464(ra) # 80003e60 <write_head>
}
    80004038:	70a2                	ld	ra,40(sp)
    8000403a:	7402                	ld	s0,32(sp)
    8000403c:	64e2                	ld	s1,24(sp)
    8000403e:	6942                	ld	s2,16(sp)
    80004040:	69a2                	ld	s3,8(sp)
    80004042:	6145                	addi	sp,sp,48
    80004044:	8082                	ret

0000000080004046 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004046:	1101                	addi	sp,sp,-32
    80004048:	ec06                	sd	ra,24(sp)
    8000404a:	e822                	sd	s0,16(sp)
    8000404c:	e426                	sd	s1,8(sp)
    8000404e:	e04a                	sd	s2,0(sp)
    80004050:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004052:	0001d517          	auipc	a0,0x1d
    80004056:	afe50513          	addi	a0,a0,-1282 # 80020b50 <log>
    8000405a:	ffffd097          	auipc	ra,0xffffd
    8000405e:	b7c080e7          	jalr	-1156(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004062:	0001d497          	auipc	s1,0x1d
    80004066:	aee48493          	addi	s1,s1,-1298 # 80020b50 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000406a:	4979                	li	s2,30
    8000406c:	a039                	j	8000407a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000406e:	85a6                	mv	a1,s1
    80004070:	8526                	mv	a0,s1
    80004072:	ffffe097          	auipc	ra,0xffffe
    80004076:	fe2080e7          	jalr	-30(ra) # 80002054 <sleep>
    if(log.committing){
    8000407a:	50dc                	lw	a5,36(s1)
    8000407c:	fbed                	bnez	a5,8000406e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000407e:	5098                	lw	a4,32(s1)
    80004080:	2705                	addiw	a4,a4,1
    80004082:	0007069b          	sext.w	a3,a4
    80004086:	0027179b          	slliw	a5,a4,0x2
    8000408a:	9fb9                	addw	a5,a5,a4
    8000408c:	0017979b          	slliw	a5,a5,0x1
    80004090:	54d8                	lw	a4,44(s1)
    80004092:	9fb9                	addw	a5,a5,a4
    80004094:	00f95963          	bge	s2,a5,800040a6 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004098:	85a6                	mv	a1,s1
    8000409a:	8526                	mv	a0,s1
    8000409c:	ffffe097          	auipc	ra,0xffffe
    800040a0:	fb8080e7          	jalr	-72(ra) # 80002054 <sleep>
    800040a4:	bfd9                	j	8000407a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040a6:	0001d517          	auipc	a0,0x1d
    800040aa:	aaa50513          	addi	a0,a0,-1366 # 80020b50 <log>
    800040ae:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040b0:	ffffd097          	auipc	ra,0xffffd
    800040b4:	bda080e7          	jalr	-1062(ra) # 80000c8a <release>
      break;
    }
  }
}
    800040b8:	60e2                	ld	ra,24(sp)
    800040ba:	6442                	ld	s0,16(sp)
    800040bc:	64a2                	ld	s1,8(sp)
    800040be:	6902                	ld	s2,0(sp)
    800040c0:	6105                	addi	sp,sp,32
    800040c2:	8082                	ret

00000000800040c4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040c4:	7139                	addi	sp,sp,-64
    800040c6:	fc06                	sd	ra,56(sp)
    800040c8:	f822                	sd	s0,48(sp)
    800040ca:	f426                	sd	s1,40(sp)
    800040cc:	f04a                	sd	s2,32(sp)
    800040ce:	ec4e                	sd	s3,24(sp)
    800040d0:	e852                	sd	s4,16(sp)
    800040d2:	e456                	sd	s5,8(sp)
    800040d4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040d6:	0001d497          	auipc	s1,0x1d
    800040da:	a7a48493          	addi	s1,s1,-1414 # 80020b50 <log>
    800040de:	8526                	mv	a0,s1
    800040e0:	ffffd097          	auipc	ra,0xffffd
    800040e4:	af6080e7          	jalr	-1290(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800040e8:	509c                	lw	a5,32(s1)
    800040ea:	37fd                	addiw	a5,a5,-1
    800040ec:	0007891b          	sext.w	s2,a5
    800040f0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040f2:	50dc                	lw	a5,36(s1)
    800040f4:	e7b9                	bnez	a5,80004142 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040f6:	04091e63          	bnez	s2,80004152 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800040fa:	0001d497          	auipc	s1,0x1d
    800040fe:	a5648493          	addi	s1,s1,-1450 # 80020b50 <log>
    80004102:	4785                	li	a5,1
    80004104:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004106:	8526                	mv	a0,s1
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	b82080e7          	jalr	-1150(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004110:	54dc                	lw	a5,44(s1)
    80004112:	06f04763          	bgtz	a5,80004180 <end_op+0xbc>
    acquire(&log.lock);
    80004116:	0001d497          	auipc	s1,0x1d
    8000411a:	a3a48493          	addi	s1,s1,-1478 # 80020b50 <log>
    8000411e:	8526                	mv	a0,s1
    80004120:	ffffd097          	auipc	ra,0xffffd
    80004124:	ab6080e7          	jalr	-1354(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004128:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000412c:	8526                	mv	a0,s1
    8000412e:	ffffe097          	auipc	ra,0xffffe
    80004132:	f8a080e7          	jalr	-118(ra) # 800020b8 <wakeup>
    release(&log.lock);
    80004136:	8526                	mv	a0,s1
    80004138:	ffffd097          	auipc	ra,0xffffd
    8000413c:	b52080e7          	jalr	-1198(ra) # 80000c8a <release>
}
    80004140:	a03d                	j	8000416e <end_op+0xaa>
    panic("log.committing");
    80004142:	00004517          	auipc	a0,0x4
    80004146:	51650513          	addi	a0,a0,1302 # 80008658 <syscalls+0x1e8>
    8000414a:	ffffc097          	auipc	ra,0xffffc
    8000414e:	3f6080e7          	jalr	1014(ra) # 80000540 <panic>
    wakeup(&log);
    80004152:	0001d497          	auipc	s1,0x1d
    80004156:	9fe48493          	addi	s1,s1,-1538 # 80020b50 <log>
    8000415a:	8526                	mv	a0,s1
    8000415c:	ffffe097          	auipc	ra,0xffffe
    80004160:	f5c080e7          	jalr	-164(ra) # 800020b8 <wakeup>
  release(&log.lock);
    80004164:	8526                	mv	a0,s1
    80004166:	ffffd097          	auipc	ra,0xffffd
    8000416a:	b24080e7          	jalr	-1244(ra) # 80000c8a <release>
}
    8000416e:	70e2                	ld	ra,56(sp)
    80004170:	7442                	ld	s0,48(sp)
    80004172:	74a2                	ld	s1,40(sp)
    80004174:	7902                	ld	s2,32(sp)
    80004176:	69e2                	ld	s3,24(sp)
    80004178:	6a42                	ld	s4,16(sp)
    8000417a:	6aa2                	ld	s5,8(sp)
    8000417c:	6121                	addi	sp,sp,64
    8000417e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004180:	0001da97          	auipc	s5,0x1d
    80004184:	a00a8a93          	addi	s5,s5,-1536 # 80020b80 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004188:	0001da17          	auipc	s4,0x1d
    8000418c:	9c8a0a13          	addi	s4,s4,-1592 # 80020b50 <log>
    80004190:	018a2583          	lw	a1,24(s4)
    80004194:	012585bb          	addw	a1,a1,s2
    80004198:	2585                	addiw	a1,a1,1
    8000419a:	028a2503          	lw	a0,40(s4)
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	cc4080e7          	jalr	-828(ra) # 80002e62 <bread>
    800041a6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041a8:	000aa583          	lw	a1,0(s5)
    800041ac:	028a2503          	lw	a0,40(s4)
    800041b0:	fffff097          	auipc	ra,0xfffff
    800041b4:	cb2080e7          	jalr	-846(ra) # 80002e62 <bread>
    800041b8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041ba:	40000613          	li	a2,1024
    800041be:	05850593          	addi	a1,a0,88
    800041c2:	05848513          	addi	a0,s1,88
    800041c6:	ffffd097          	auipc	ra,0xffffd
    800041ca:	b68080e7          	jalr	-1176(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800041ce:	8526                	mv	a0,s1
    800041d0:	fffff097          	auipc	ra,0xfffff
    800041d4:	d84080e7          	jalr	-636(ra) # 80002f54 <bwrite>
    brelse(from);
    800041d8:	854e                	mv	a0,s3
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	db8080e7          	jalr	-584(ra) # 80002f92 <brelse>
    brelse(to);
    800041e2:	8526                	mv	a0,s1
    800041e4:	fffff097          	auipc	ra,0xfffff
    800041e8:	dae080e7          	jalr	-594(ra) # 80002f92 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ec:	2905                	addiw	s2,s2,1
    800041ee:	0a91                	addi	s5,s5,4
    800041f0:	02ca2783          	lw	a5,44(s4)
    800041f4:	f8f94ee3          	blt	s2,a5,80004190 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041f8:	00000097          	auipc	ra,0x0
    800041fc:	c68080e7          	jalr	-920(ra) # 80003e60 <write_head>
    install_trans(0); // Now install writes to home locations
    80004200:	4501                	li	a0,0
    80004202:	00000097          	auipc	ra,0x0
    80004206:	cda080e7          	jalr	-806(ra) # 80003edc <install_trans>
    log.lh.n = 0;
    8000420a:	0001d797          	auipc	a5,0x1d
    8000420e:	9607a923          	sw	zero,-1678(a5) # 80020b7c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004212:	00000097          	auipc	ra,0x0
    80004216:	c4e080e7          	jalr	-946(ra) # 80003e60 <write_head>
    8000421a:	bdf5                	j	80004116 <end_op+0x52>

000000008000421c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000421c:	1101                	addi	sp,sp,-32
    8000421e:	ec06                	sd	ra,24(sp)
    80004220:	e822                	sd	s0,16(sp)
    80004222:	e426                	sd	s1,8(sp)
    80004224:	e04a                	sd	s2,0(sp)
    80004226:	1000                	addi	s0,sp,32
    80004228:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000422a:	0001d917          	auipc	s2,0x1d
    8000422e:	92690913          	addi	s2,s2,-1754 # 80020b50 <log>
    80004232:	854a                	mv	a0,s2
    80004234:	ffffd097          	auipc	ra,0xffffd
    80004238:	9a2080e7          	jalr	-1630(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000423c:	02c92603          	lw	a2,44(s2)
    80004240:	47f5                	li	a5,29
    80004242:	06c7c563          	blt	a5,a2,800042ac <log_write+0x90>
    80004246:	0001d797          	auipc	a5,0x1d
    8000424a:	9267a783          	lw	a5,-1754(a5) # 80020b6c <log+0x1c>
    8000424e:	37fd                	addiw	a5,a5,-1
    80004250:	04f65e63          	bge	a2,a5,800042ac <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004254:	0001d797          	auipc	a5,0x1d
    80004258:	91c7a783          	lw	a5,-1764(a5) # 80020b70 <log+0x20>
    8000425c:	06f05063          	blez	a5,800042bc <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004260:	4781                	li	a5,0
    80004262:	06c05563          	blez	a2,800042cc <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004266:	44cc                	lw	a1,12(s1)
    80004268:	0001d717          	auipc	a4,0x1d
    8000426c:	91870713          	addi	a4,a4,-1768 # 80020b80 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004270:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004272:	4314                	lw	a3,0(a4)
    80004274:	04b68c63          	beq	a3,a1,800042cc <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004278:	2785                	addiw	a5,a5,1
    8000427a:	0711                	addi	a4,a4,4
    8000427c:	fef61be3          	bne	a2,a5,80004272 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004280:	0621                	addi	a2,a2,8
    80004282:	060a                	slli	a2,a2,0x2
    80004284:	0001d797          	auipc	a5,0x1d
    80004288:	8cc78793          	addi	a5,a5,-1844 # 80020b50 <log>
    8000428c:	97b2                	add	a5,a5,a2
    8000428e:	44d8                	lw	a4,12(s1)
    80004290:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004292:	8526                	mv	a0,s1
    80004294:	fffff097          	auipc	ra,0xfffff
    80004298:	d9c080e7          	jalr	-612(ra) # 80003030 <bpin>
    log.lh.n++;
    8000429c:	0001d717          	auipc	a4,0x1d
    800042a0:	8b470713          	addi	a4,a4,-1868 # 80020b50 <log>
    800042a4:	575c                	lw	a5,44(a4)
    800042a6:	2785                	addiw	a5,a5,1
    800042a8:	d75c                	sw	a5,44(a4)
    800042aa:	a82d                	j	800042e4 <log_write+0xc8>
    panic("too big a transaction");
    800042ac:	00004517          	auipc	a0,0x4
    800042b0:	3bc50513          	addi	a0,a0,956 # 80008668 <syscalls+0x1f8>
    800042b4:	ffffc097          	auipc	ra,0xffffc
    800042b8:	28c080e7          	jalr	652(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800042bc:	00004517          	auipc	a0,0x4
    800042c0:	3c450513          	addi	a0,a0,964 # 80008680 <syscalls+0x210>
    800042c4:	ffffc097          	auipc	ra,0xffffc
    800042c8:	27c080e7          	jalr	636(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800042cc:	00878693          	addi	a3,a5,8
    800042d0:	068a                	slli	a3,a3,0x2
    800042d2:	0001d717          	auipc	a4,0x1d
    800042d6:	87e70713          	addi	a4,a4,-1922 # 80020b50 <log>
    800042da:	9736                	add	a4,a4,a3
    800042dc:	44d4                	lw	a3,12(s1)
    800042de:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042e0:	faf609e3          	beq	a2,a5,80004292 <log_write+0x76>
  }
  release(&log.lock);
    800042e4:	0001d517          	auipc	a0,0x1d
    800042e8:	86c50513          	addi	a0,a0,-1940 # 80020b50 <log>
    800042ec:	ffffd097          	auipc	ra,0xffffd
    800042f0:	99e080e7          	jalr	-1634(ra) # 80000c8a <release>
}
    800042f4:	60e2                	ld	ra,24(sp)
    800042f6:	6442                	ld	s0,16(sp)
    800042f8:	64a2                	ld	s1,8(sp)
    800042fa:	6902                	ld	s2,0(sp)
    800042fc:	6105                	addi	sp,sp,32
    800042fe:	8082                	ret

0000000080004300 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004300:	1101                	addi	sp,sp,-32
    80004302:	ec06                	sd	ra,24(sp)
    80004304:	e822                	sd	s0,16(sp)
    80004306:	e426                	sd	s1,8(sp)
    80004308:	e04a                	sd	s2,0(sp)
    8000430a:	1000                	addi	s0,sp,32
    8000430c:	84aa                	mv	s1,a0
    8000430e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004310:	00004597          	auipc	a1,0x4
    80004314:	39058593          	addi	a1,a1,912 # 800086a0 <syscalls+0x230>
    80004318:	0521                	addi	a0,a0,8
    8000431a:	ffffd097          	auipc	ra,0xffffd
    8000431e:	82c080e7          	jalr	-2004(ra) # 80000b46 <initlock>
  lk->name = name;
    80004322:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004326:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000432a:	0204a423          	sw	zero,40(s1)
}
    8000432e:	60e2                	ld	ra,24(sp)
    80004330:	6442                	ld	s0,16(sp)
    80004332:	64a2                	ld	s1,8(sp)
    80004334:	6902                	ld	s2,0(sp)
    80004336:	6105                	addi	sp,sp,32
    80004338:	8082                	ret

000000008000433a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000433a:	1101                	addi	sp,sp,-32
    8000433c:	ec06                	sd	ra,24(sp)
    8000433e:	e822                	sd	s0,16(sp)
    80004340:	e426                	sd	s1,8(sp)
    80004342:	e04a                	sd	s2,0(sp)
    80004344:	1000                	addi	s0,sp,32
    80004346:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004348:	00850913          	addi	s2,a0,8
    8000434c:	854a                	mv	a0,s2
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	888080e7          	jalr	-1912(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004356:	409c                	lw	a5,0(s1)
    80004358:	cb89                	beqz	a5,8000436a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000435a:	85ca                	mv	a1,s2
    8000435c:	8526                	mv	a0,s1
    8000435e:	ffffe097          	auipc	ra,0xffffe
    80004362:	cf6080e7          	jalr	-778(ra) # 80002054 <sleep>
  while (lk->locked) {
    80004366:	409c                	lw	a5,0(s1)
    80004368:	fbed                	bnez	a5,8000435a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000436a:	4785                	li	a5,1
    8000436c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000436e:	ffffd097          	auipc	ra,0xffffd
    80004372:	63e080e7          	jalr	1598(ra) # 800019ac <myproc>
    80004376:	591c                	lw	a5,48(a0)
    80004378:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000437a:	854a                	mv	a0,s2
    8000437c:	ffffd097          	auipc	ra,0xffffd
    80004380:	90e080e7          	jalr	-1778(ra) # 80000c8a <release>
}
    80004384:	60e2                	ld	ra,24(sp)
    80004386:	6442                	ld	s0,16(sp)
    80004388:	64a2                	ld	s1,8(sp)
    8000438a:	6902                	ld	s2,0(sp)
    8000438c:	6105                	addi	sp,sp,32
    8000438e:	8082                	ret

0000000080004390 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004390:	1101                	addi	sp,sp,-32
    80004392:	ec06                	sd	ra,24(sp)
    80004394:	e822                	sd	s0,16(sp)
    80004396:	e426                	sd	s1,8(sp)
    80004398:	e04a                	sd	s2,0(sp)
    8000439a:	1000                	addi	s0,sp,32
    8000439c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000439e:	00850913          	addi	s2,a0,8
    800043a2:	854a                	mv	a0,s2
    800043a4:	ffffd097          	auipc	ra,0xffffd
    800043a8:	832080e7          	jalr	-1998(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800043ac:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043b0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043b4:	8526                	mv	a0,s1
    800043b6:	ffffe097          	auipc	ra,0xffffe
    800043ba:	d02080e7          	jalr	-766(ra) # 800020b8 <wakeup>
  release(&lk->lk);
    800043be:	854a                	mv	a0,s2
    800043c0:	ffffd097          	auipc	ra,0xffffd
    800043c4:	8ca080e7          	jalr	-1846(ra) # 80000c8a <release>
}
    800043c8:	60e2                	ld	ra,24(sp)
    800043ca:	6442                	ld	s0,16(sp)
    800043cc:	64a2                	ld	s1,8(sp)
    800043ce:	6902                	ld	s2,0(sp)
    800043d0:	6105                	addi	sp,sp,32
    800043d2:	8082                	ret

00000000800043d4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043d4:	7179                	addi	sp,sp,-48
    800043d6:	f406                	sd	ra,40(sp)
    800043d8:	f022                	sd	s0,32(sp)
    800043da:	ec26                	sd	s1,24(sp)
    800043dc:	e84a                	sd	s2,16(sp)
    800043de:	e44e                	sd	s3,8(sp)
    800043e0:	1800                	addi	s0,sp,48
    800043e2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043e4:	00850913          	addi	s2,a0,8
    800043e8:	854a                	mv	a0,s2
    800043ea:	ffffc097          	auipc	ra,0xffffc
    800043ee:	7ec080e7          	jalr	2028(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043f2:	409c                	lw	a5,0(s1)
    800043f4:	ef99                	bnez	a5,80004412 <holdingsleep+0x3e>
    800043f6:	4481                	li	s1,0
  release(&lk->lk);
    800043f8:	854a                	mv	a0,s2
    800043fa:	ffffd097          	auipc	ra,0xffffd
    800043fe:	890080e7          	jalr	-1904(ra) # 80000c8a <release>
  return r;
}
    80004402:	8526                	mv	a0,s1
    80004404:	70a2                	ld	ra,40(sp)
    80004406:	7402                	ld	s0,32(sp)
    80004408:	64e2                	ld	s1,24(sp)
    8000440a:	6942                	ld	s2,16(sp)
    8000440c:	69a2                	ld	s3,8(sp)
    8000440e:	6145                	addi	sp,sp,48
    80004410:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004412:	0284a983          	lw	s3,40(s1)
    80004416:	ffffd097          	auipc	ra,0xffffd
    8000441a:	596080e7          	jalr	1430(ra) # 800019ac <myproc>
    8000441e:	5904                	lw	s1,48(a0)
    80004420:	413484b3          	sub	s1,s1,s3
    80004424:	0014b493          	seqz	s1,s1
    80004428:	bfc1                	j	800043f8 <holdingsleep+0x24>

000000008000442a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000442a:	1141                	addi	sp,sp,-16
    8000442c:	e406                	sd	ra,8(sp)
    8000442e:	e022                	sd	s0,0(sp)
    80004430:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004432:	00004597          	auipc	a1,0x4
    80004436:	27e58593          	addi	a1,a1,638 # 800086b0 <syscalls+0x240>
    8000443a:	0001d517          	auipc	a0,0x1d
    8000443e:	85e50513          	addi	a0,a0,-1954 # 80020c98 <ftable>
    80004442:	ffffc097          	auipc	ra,0xffffc
    80004446:	704080e7          	jalr	1796(ra) # 80000b46 <initlock>
}
    8000444a:	60a2                	ld	ra,8(sp)
    8000444c:	6402                	ld	s0,0(sp)
    8000444e:	0141                	addi	sp,sp,16
    80004450:	8082                	ret

0000000080004452 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004452:	1101                	addi	sp,sp,-32
    80004454:	ec06                	sd	ra,24(sp)
    80004456:	e822                	sd	s0,16(sp)
    80004458:	e426                	sd	s1,8(sp)
    8000445a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000445c:	0001d517          	auipc	a0,0x1d
    80004460:	83c50513          	addi	a0,a0,-1988 # 80020c98 <ftable>
    80004464:	ffffc097          	auipc	ra,0xffffc
    80004468:	772080e7          	jalr	1906(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000446c:	0001d497          	auipc	s1,0x1d
    80004470:	84448493          	addi	s1,s1,-1980 # 80020cb0 <ftable+0x18>
    80004474:	0001d717          	auipc	a4,0x1d
    80004478:	7dc70713          	addi	a4,a4,2012 # 80021c50 <disk>
    if(f->ref == 0){
    8000447c:	40dc                	lw	a5,4(s1)
    8000447e:	cf99                	beqz	a5,8000449c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004480:	02848493          	addi	s1,s1,40
    80004484:	fee49ce3          	bne	s1,a4,8000447c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004488:	0001d517          	auipc	a0,0x1d
    8000448c:	81050513          	addi	a0,a0,-2032 # 80020c98 <ftable>
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	7fa080e7          	jalr	2042(ra) # 80000c8a <release>
  return 0;
    80004498:	4481                	li	s1,0
    8000449a:	a819                	j	800044b0 <filealloc+0x5e>
      f->ref = 1;
    8000449c:	4785                	li	a5,1
    8000449e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044a0:	0001c517          	auipc	a0,0x1c
    800044a4:	7f850513          	addi	a0,a0,2040 # 80020c98 <ftable>
    800044a8:	ffffc097          	auipc	ra,0xffffc
    800044ac:	7e2080e7          	jalr	2018(ra) # 80000c8a <release>
}
    800044b0:	8526                	mv	a0,s1
    800044b2:	60e2                	ld	ra,24(sp)
    800044b4:	6442                	ld	s0,16(sp)
    800044b6:	64a2                	ld	s1,8(sp)
    800044b8:	6105                	addi	sp,sp,32
    800044ba:	8082                	ret

00000000800044bc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044bc:	1101                	addi	sp,sp,-32
    800044be:	ec06                	sd	ra,24(sp)
    800044c0:	e822                	sd	s0,16(sp)
    800044c2:	e426                	sd	s1,8(sp)
    800044c4:	1000                	addi	s0,sp,32
    800044c6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044c8:	0001c517          	auipc	a0,0x1c
    800044cc:	7d050513          	addi	a0,a0,2000 # 80020c98 <ftable>
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	706080e7          	jalr	1798(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800044d8:	40dc                	lw	a5,4(s1)
    800044da:	02f05263          	blez	a5,800044fe <filedup+0x42>
    panic("filedup");
  f->ref++;
    800044de:	2785                	addiw	a5,a5,1
    800044e0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800044e2:	0001c517          	auipc	a0,0x1c
    800044e6:	7b650513          	addi	a0,a0,1974 # 80020c98 <ftable>
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	7a0080e7          	jalr	1952(ra) # 80000c8a <release>
  return f;
}
    800044f2:	8526                	mv	a0,s1
    800044f4:	60e2                	ld	ra,24(sp)
    800044f6:	6442                	ld	s0,16(sp)
    800044f8:	64a2                	ld	s1,8(sp)
    800044fa:	6105                	addi	sp,sp,32
    800044fc:	8082                	ret
    panic("filedup");
    800044fe:	00004517          	auipc	a0,0x4
    80004502:	1ba50513          	addi	a0,a0,442 # 800086b8 <syscalls+0x248>
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	03a080e7          	jalr	58(ra) # 80000540 <panic>

000000008000450e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000450e:	7139                	addi	sp,sp,-64
    80004510:	fc06                	sd	ra,56(sp)
    80004512:	f822                	sd	s0,48(sp)
    80004514:	f426                	sd	s1,40(sp)
    80004516:	f04a                	sd	s2,32(sp)
    80004518:	ec4e                	sd	s3,24(sp)
    8000451a:	e852                	sd	s4,16(sp)
    8000451c:	e456                	sd	s5,8(sp)
    8000451e:	0080                	addi	s0,sp,64
    80004520:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004522:	0001c517          	auipc	a0,0x1c
    80004526:	77650513          	addi	a0,a0,1910 # 80020c98 <ftable>
    8000452a:	ffffc097          	auipc	ra,0xffffc
    8000452e:	6ac080e7          	jalr	1708(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004532:	40dc                	lw	a5,4(s1)
    80004534:	06f05163          	blez	a5,80004596 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004538:	37fd                	addiw	a5,a5,-1
    8000453a:	0007871b          	sext.w	a4,a5
    8000453e:	c0dc                	sw	a5,4(s1)
    80004540:	06e04363          	bgtz	a4,800045a6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004544:	0004a903          	lw	s2,0(s1)
    80004548:	0094ca83          	lbu	s5,9(s1)
    8000454c:	0104ba03          	ld	s4,16(s1)
    80004550:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004554:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004558:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000455c:	0001c517          	auipc	a0,0x1c
    80004560:	73c50513          	addi	a0,a0,1852 # 80020c98 <ftable>
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	726080e7          	jalr	1830(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    8000456c:	4785                	li	a5,1
    8000456e:	04f90d63          	beq	s2,a5,800045c8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004572:	3979                	addiw	s2,s2,-2
    80004574:	4785                	li	a5,1
    80004576:	0527e063          	bltu	a5,s2,800045b6 <fileclose+0xa8>
    begin_op();
    8000457a:	00000097          	auipc	ra,0x0
    8000457e:	acc080e7          	jalr	-1332(ra) # 80004046 <begin_op>
    iput(ff.ip);
    80004582:	854e                	mv	a0,s3
    80004584:	fffff097          	auipc	ra,0xfffff
    80004588:	2b0080e7          	jalr	688(ra) # 80003834 <iput>
    end_op();
    8000458c:	00000097          	auipc	ra,0x0
    80004590:	b38080e7          	jalr	-1224(ra) # 800040c4 <end_op>
    80004594:	a00d                	j	800045b6 <fileclose+0xa8>
    panic("fileclose");
    80004596:	00004517          	auipc	a0,0x4
    8000459a:	12a50513          	addi	a0,a0,298 # 800086c0 <syscalls+0x250>
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	fa2080e7          	jalr	-94(ra) # 80000540 <panic>
    release(&ftable.lock);
    800045a6:	0001c517          	auipc	a0,0x1c
    800045aa:	6f250513          	addi	a0,a0,1778 # 80020c98 <ftable>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	6dc080e7          	jalr	1756(ra) # 80000c8a <release>
  }
}
    800045b6:	70e2                	ld	ra,56(sp)
    800045b8:	7442                	ld	s0,48(sp)
    800045ba:	74a2                	ld	s1,40(sp)
    800045bc:	7902                	ld	s2,32(sp)
    800045be:	69e2                	ld	s3,24(sp)
    800045c0:	6a42                	ld	s4,16(sp)
    800045c2:	6aa2                	ld	s5,8(sp)
    800045c4:	6121                	addi	sp,sp,64
    800045c6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045c8:	85d6                	mv	a1,s5
    800045ca:	8552                	mv	a0,s4
    800045cc:	00000097          	auipc	ra,0x0
    800045d0:	34c080e7          	jalr	844(ra) # 80004918 <pipeclose>
    800045d4:	b7cd                	j	800045b6 <fileclose+0xa8>

00000000800045d6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045d6:	715d                	addi	sp,sp,-80
    800045d8:	e486                	sd	ra,72(sp)
    800045da:	e0a2                	sd	s0,64(sp)
    800045dc:	fc26                	sd	s1,56(sp)
    800045de:	f84a                	sd	s2,48(sp)
    800045e0:	f44e                	sd	s3,40(sp)
    800045e2:	0880                	addi	s0,sp,80
    800045e4:	84aa                	mv	s1,a0
    800045e6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045e8:	ffffd097          	auipc	ra,0xffffd
    800045ec:	3c4080e7          	jalr	964(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045f0:	409c                	lw	a5,0(s1)
    800045f2:	37f9                	addiw	a5,a5,-2
    800045f4:	4705                	li	a4,1
    800045f6:	04f76763          	bltu	a4,a5,80004644 <filestat+0x6e>
    800045fa:	892a                	mv	s2,a0
    ilock(f->ip);
    800045fc:	6c88                	ld	a0,24(s1)
    800045fe:	fffff097          	auipc	ra,0xfffff
    80004602:	07c080e7          	jalr	124(ra) # 8000367a <ilock>
    stati(f->ip, &st);
    80004606:	fb840593          	addi	a1,s0,-72
    8000460a:	6c88                	ld	a0,24(s1)
    8000460c:	fffff097          	auipc	ra,0xfffff
    80004610:	2f8080e7          	jalr	760(ra) # 80003904 <stati>
    iunlock(f->ip);
    80004614:	6c88                	ld	a0,24(s1)
    80004616:	fffff097          	auipc	ra,0xfffff
    8000461a:	126080e7          	jalr	294(ra) # 8000373c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000461e:	46e1                	li	a3,24
    80004620:	fb840613          	addi	a2,s0,-72
    80004624:	85ce                	mv	a1,s3
    80004626:	05093503          	ld	a0,80(s2)
    8000462a:	ffffd097          	auipc	ra,0xffffd
    8000462e:	042080e7          	jalr	66(ra) # 8000166c <copyout>
    80004632:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004636:	60a6                	ld	ra,72(sp)
    80004638:	6406                	ld	s0,64(sp)
    8000463a:	74e2                	ld	s1,56(sp)
    8000463c:	7942                	ld	s2,48(sp)
    8000463e:	79a2                	ld	s3,40(sp)
    80004640:	6161                	addi	sp,sp,80
    80004642:	8082                	ret
  return -1;
    80004644:	557d                	li	a0,-1
    80004646:	bfc5                	j	80004636 <filestat+0x60>

0000000080004648 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004648:	7179                	addi	sp,sp,-48
    8000464a:	f406                	sd	ra,40(sp)
    8000464c:	f022                	sd	s0,32(sp)
    8000464e:	ec26                	sd	s1,24(sp)
    80004650:	e84a                	sd	s2,16(sp)
    80004652:	e44e                	sd	s3,8(sp)
    80004654:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004656:	00854783          	lbu	a5,8(a0)
    8000465a:	c3d5                	beqz	a5,800046fe <fileread+0xb6>
    8000465c:	84aa                	mv	s1,a0
    8000465e:	89ae                	mv	s3,a1
    80004660:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004662:	411c                	lw	a5,0(a0)
    80004664:	4705                	li	a4,1
    80004666:	04e78963          	beq	a5,a4,800046b8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000466a:	470d                	li	a4,3
    8000466c:	04e78d63          	beq	a5,a4,800046c6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004670:	4709                	li	a4,2
    80004672:	06e79e63          	bne	a5,a4,800046ee <fileread+0xa6>
    ilock(f->ip);
    80004676:	6d08                	ld	a0,24(a0)
    80004678:	fffff097          	auipc	ra,0xfffff
    8000467c:	002080e7          	jalr	2(ra) # 8000367a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004680:	874a                	mv	a4,s2
    80004682:	5094                	lw	a3,32(s1)
    80004684:	864e                	mv	a2,s3
    80004686:	4585                	li	a1,1
    80004688:	6c88                	ld	a0,24(s1)
    8000468a:	fffff097          	auipc	ra,0xfffff
    8000468e:	2a4080e7          	jalr	676(ra) # 8000392e <readi>
    80004692:	892a                	mv	s2,a0
    80004694:	00a05563          	blez	a0,8000469e <fileread+0x56>
      f->off += r;
    80004698:	509c                	lw	a5,32(s1)
    8000469a:	9fa9                	addw	a5,a5,a0
    8000469c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000469e:	6c88                	ld	a0,24(s1)
    800046a0:	fffff097          	auipc	ra,0xfffff
    800046a4:	09c080e7          	jalr	156(ra) # 8000373c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046a8:	854a                	mv	a0,s2
    800046aa:	70a2                	ld	ra,40(sp)
    800046ac:	7402                	ld	s0,32(sp)
    800046ae:	64e2                	ld	s1,24(sp)
    800046b0:	6942                	ld	s2,16(sp)
    800046b2:	69a2                	ld	s3,8(sp)
    800046b4:	6145                	addi	sp,sp,48
    800046b6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046b8:	6908                	ld	a0,16(a0)
    800046ba:	00000097          	auipc	ra,0x0
    800046be:	3c6080e7          	jalr	966(ra) # 80004a80 <piperead>
    800046c2:	892a                	mv	s2,a0
    800046c4:	b7d5                	j	800046a8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046c6:	02451783          	lh	a5,36(a0)
    800046ca:	03079693          	slli	a3,a5,0x30
    800046ce:	92c1                	srli	a3,a3,0x30
    800046d0:	4725                	li	a4,9
    800046d2:	02d76863          	bltu	a4,a3,80004702 <fileread+0xba>
    800046d6:	0792                	slli	a5,a5,0x4
    800046d8:	0001c717          	auipc	a4,0x1c
    800046dc:	52070713          	addi	a4,a4,1312 # 80020bf8 <devsw>
    800046e0:	97ba                	add	a5,a5,a4
    800046e2:	639c                	ld	a5,0(a5)
    800046e4:	c38d                	beqz	a5,80004706 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046e6:	4505                	li	a0,1
    800046e8:	9782                	jalr	a5
    800046ea:	892a                	mv	s2,a0
    800046ec:	bf75                	j	800046a8 <fileread+0x60>
    panic("fileread");
    800046ee:	00004517          	auipc	a0,0x4
    800046f2:	fe250513          	addi	a0,a0,-30 # 800086d0 <syscalls+0x260>
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	e4a080e7          	jalr	-438(ra) # 80000540 <panic>
    return -1;
    800046fe:	597d                	li	s2,-1
    80004700:	b765                	j	800046a8 <fileread+0x60>
      return -1;
    80004702:	597d                	li	s2,-1
    80004704:	b755                	j	800046a8 <fileread+0x60>
    80004706:	597d                	li	s2,-1
    80004708:	b745                	j	800046a8 <fileread+0x60>

000000008000470a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000470a:	715d                	addi	sp,sp,-80
    8000470c:	e486                	sd	ra,72(sp)
    8000470e:	e0a2                	sd	s0,64(sp)
    80004710:	fc26                	sd	s1,56(sp)
    80004712:	f84a                	sd	s2,48(sp)
    80004714:	f44e                	sd	s3,40(sp)
    80004716:	f052                	sd	s4,32(sp)
    80004718:	ec56                	sd	s5,24(sp)
    8000471a:	e85a                	sd	s6,16(sp)
    8000471c:	e45e                	sd	s7,8(sp)
    8000471e:	e062                	sd	s8,0(sp)
    80004720:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004722:	00954783          	lbu	a5,9(a0)
    80004726:	10078663          	beqz	a5,80004832 <filewrite+0x128>
    8000472a:	892a                	mv	s2,a0
    8000472c:	8b2e                	mv	s6,a1
    8000472e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004730:	411c                	lw	a5,0(a0)
    80004732:	4705                	li	a4,1
    80004734:	02e78263          	beq	a5,a4,80004758 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004738:	470d                	li	a4,3
    8000473a:	02e78663          	beq	a5,a4,80004766 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000473e:	4709                	li	a4,2
    80004740:	0ee79163          	bne	a5,a4,80004822 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004744:	0ac05d63          	blez	a2,800047fe <filewrite+0xf4>
    int i = 0;
    80004748:	4981                	li	s3,0
    8000474a:	6b85                	lui	s7,0x1
    8000474c:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004750:	6c05                	lui	s8,0x1
    80004752:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004756:	a861                	j	800047ee <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004758:	6908                	ld	a0,16(a0)
    8000475a:	00000097          	auipc	ra,0x0
    8000475e:	22e080e7          	jalr	558(ra) # 80004988 <pipewrite>
    80004762:	8a2a                	mv	s4,a0
    80004764:	a045                	j	80004804 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004766:	02451783          	lh	a5,36(a0)
    8000476a:	03079693          	slli	a3,a5,0x30
    8000476e:	92c1                	srli	a3,a3,0x30
    80004770:	4725                	li	a4,9
    80004772:	0cd76263          	bltu	a4,a3,80004836 <filewrite+0x12c>
    80004776:	0792                	slli	a5,a5,0x4
    80004778:	0001c717          	auipc	a4,0x1c
    8000477c:	48070713          	addi	a4,a4,1152 # 80020bf8 <devsw>
    80004780:	97ba                	add	a5,a5,a4
    80004782:	679c                	ld	a5,8(a5)
    80004784:	cbdd                	beqz	a5,8000483a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004786:	4505                	li	a0,1
    80004788:	9782                	jalr	a5
    8000478a:	8a2a                	mv	s4,a0
    8000478c:	a8a5                	j	80004804 <filewrite+0xfa>
    8000478e:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004792:	00000097          	auipc	ra,0x0
    80004796:	8b4080e7          	jalr	-1868(ra) # 80004046 <begin_op>
      ilock(f->ip);
    8000479a:	01893503          	ld	a0,24(s2)
    8000479e:	fffff097          	auipc	ra,0xfffff
    800047a2:	edc080e7          	jalr	-292(ra) # 8000367a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047a6:	8756                	mv	a4,s5
    800047a8:	02092683          	lw	a3,32(s2)
    800047ac:	01698633          	add	a2,s3,s6
    800047b0:	4585                	li	a1,1
    800047b2:	01893503          	ld	a0,24(s2)
    800047b6:	fffff097          	auipc	ra,0xfffff
    800047ba:	270080e7          	jalr	624(ra) # 80003a26 <writei>
    800047be:	84aa                	mv	s1,a0
    800047c0:	00a05763          	blez	a0,800047ce <filewrite+0xc4>
        f->off += r;
    800047c4:	02092783          	lw	a5,32(s2)
    800047c8:	9fa9                	addw	a5,a5,a0
    800047ca:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047ce:	01893503          	ld	a0,24(s2)
    800047d2:	fffff097          	auipc	ra,0xfffff
    800047d6:	f6a080e7          	jalr	-150(ra) # 8000373c <iunlock>
      end_op();
    800047da:	00000097          	auipc	ra,0x0
    800047de:	8ea080e7          	jalr	-1814(ra) # 800040c4 <end_op>

      if(r != n1){
    800047e2:	009a9f63          	bne	s5,s1,80004800 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800047e6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047ea:	0149db63          	bge	s3,s4,80004800 <filewrite+0xf6>
      int n1 = n - i;
    800047ee:	413a04bb          	subw	s1,s4,s3
    800047f2:	0004879b          	sext.w	a5,s1
    800047f6:	f8fbdce3          	bge	s7,a5,8000478e <filewrite+0x84>
    800047fa:	84e2                	mv	s1,s8
    800047fc:	bf49                	j	8000478e <filewrite+0x84>
    int i = 0;
    800047fe:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004800:	013a1f63          	bne	s4,s3,8000481e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004804:	8552                	mv	a0,s4
    80004806:	60a6                	ld	ra,72(sp)
    80004808:	6406                	ld	s0,64(sp)
    8000480a:	74e2                	ld	s1,56(sp)
    8000480c:	7942                	ld	s2,48(sp)
    8000480e:	79a2                	ld	s3,40(sp)
    80004810:	7a02                	ld	s4,32(sp)
    80004812:	6ae2                	ld	s5,24(sp)
    80004814:	6b42                	ld	s6,16(sp)
    80004816:	6ba2                	ld	s7,8(sp)
    80004818:	6c02                	ld	s8,0(sp)
    8000481a:	6161                	addi	sp,sp,80
    8000481c:	8082                	ret
    ret = (i == n ? n : -1);
    8000481e:	5a7d                	li	s4,-1
    80004820:	b7d5                	j	80004804 <filewrite+0xfa>
    panic("filewrite");
    80004822:	00004517          	auipc	a0,0x4
    80004826:	ebe50513          	addi	a0,a0,-322 # 800086e0 <syscalls+0x270>
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	d16080e7          	jalr	-746(ra) # 80000540 <panic>
    return -1;
    80004832:	5a7d                	li	s4,-1
    80004834:	bfc1                	j	80004804 <filewrite+0xfa>
      return -1;
    80004836:	5a7d                	li	s4,-1
    80004838:	b7f1                	j	80004804 <filewrite+0xfa>
    8000483a:	5a7d                	li	s4,-1
    8000483c:	b7e1                	j	80004804 <filewrite+0xfa>

000000008000483e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000483e:	7179                	addi	sp,sp,-48
    80004840:	f406                	sd	ra,40(sp)
    80004842:	f022                	sd	s0,32(sp)
    80004844:	ec26                	sd	s1,24(sp)
    80004846:	e84a                	sd	s2,16(sp)
    80004848:	e44e                	sd	s3,8(sp)
    8000484a:	e052                	sd	s4,0(sp)
    8000484c:	1800                	addi	s0,sp,48
    8000484e:	84aa                	mv	s1,a0
    80004850:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004852:	0005b023          	sd	zero,0(a1)
    80004856:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000485a:	00000097          	auipc	ra,0x0
    8000485e:	bf8080e7          	jalr	-1032(ra) # 80004452 <filealloc>
    80004862:	e088                	sd	a0,0(s1)
    80004864:	c551                	beqz	a0,800048f0 <pipealloc+0xb2>
    80004866:	00000097          	auipc	ra,0x0
    8000486a:	bec080e7          	jalr	-1044(ra) # 80004452 <filealloc>
    8000486e:	00aa3023          	sd	a0,0(s4)
    80004872:	c92d                	beqz	a0,800048e4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	272080e7          	jalr	626(ra) # 80000ae6 <kalloc>
    8000487c:	892a                	mv	s2,a0
    8000487e:	c125                	beqz	a0,800048de <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004880:	4985                	li	s3,1
    80004882:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004886:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000488a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000488e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004892:	00004597          	auipc	a1,0x4
    80004896:	e5e58593          	addi	a1,a1,-418 # 800086f0 <syscalls+0x280>
    8000489a:	ffffc097          	auipc	ra,0xffffc
    8000489e:	2ac080e7          	jalr	684(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800048a2:	609c                	ld	a5,0(s1)
    800048a4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048a8:	609c                	ld	a5,0(s1)
    800048aa:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048ae:	609c                	ld	a5,0(s1)
    800048b0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048b4:	609c                	ld	a5,0(s1)
    800048b6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048ba:	000a3783          	ld	a5,0(s4)
    800048be:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048c2:	000a3783          	ld	a5,0(s4)
    800048c6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048ca:	000a3783          	ld	a5,0(s4)
    800048ce:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048d2:	000a3783          	ld	a5,0(s4)
    800048d6:	0127b823          	sd	s2,16(a5)
  return 0;
    800048da:	4501                	li	a0,0
    800048dc:	a025                	j	80004904 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800048de:	6088                	ld	a0,0(s1)
    800048e0:	e501                	bnez	a0,800048e8 <pipealloc+0xaa>
    800048e2:	a039                	j	800048f0 <pipealloc+0xb2>
    800048e4:	6088                	ld	a0,0(s1)
    800048e6:	c51d                	beqz	a0,80004914 <pipealloc+0xd6>
    fileclose(*f0);
    800048e8:	00000097          	auipc	ra,0x0
    800048ec:	c26080e7          	jalr	-986(ra) # 8000450e <fileclose>
  if(*f1)
    800048f0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800048f4:	557d                	li	a0,-1
  if(*f1)
    800048f6:	c799                	beqz	a5,80004904 <pipealloc+0xc6>
    fileclose(*f1);
    800048f8:	853e                	mv	a0,a5
    800048fa:	00000097          	auipc	ra,0x0
    800048fe:	c14080e7          	jalr	-1004(ra) # 8000450e <fileclose>
  return -1;
    80004902:	557d                	li	a0,-1
}
    80004904:	70a2                	ld	ra,40(sp)
    80004906:	7402                	ld	s0,32(sp)
    80004908:	64e2                	ld	s1,24(sp)
    8000490a:	6942                	ld	s2,16(sp)
    8000490c:	69a2                	ld	s3,8(sp)
    8000490e:	6a02                	ld	s4,0(sp)
    80004910:	6145                	addi	sp,sp,48
    80004912:	8082                	ret
  return -1;
    80004914:	557d                	li	a0,-1
    80004916:	b7fd                	j	80004904 <pipealloc+0xc6>

0000000080004918 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004918:	1101                	addi	sp,sp,-32
    8000491a:	ec06                	sd	ra,24(sp)
    8000491c:	e822                	sd	s0,16(sp)
    8000491e:	e426                	sd	s1,8(sp)
    80004920:	e04a                	sd	s2,0(sp)
    80004922:	1000                	addi	s0,sp,32
    80004924:	84aa                	mv	s1,a0
    80004926:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004928:	ffffc097          	auipc	ra,0xffffc
    8000492c:	2ae080e7          	jalr	686(ra) # 80000bd6 <acquire>
  if(writable){
    80004930:	02090d63          	beqz	s2,8000496a <pipeclose+0x52>
    pi->writeopen = 0;
    80004934:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004938:	21848513          	addi	a0,s1,536
    8000493c:	ffffd097          	auipc	ra,0xffffd
    80004940:	77c080e7          	jalr	1916(ra) # 800020b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004944:	2204b783          	ld	a5,544(s1)
    80004948:	eb95                	bnez	a5,8000497c <pipeclose+0x64>
    release(&pi->lock);
    8000494a:	8526                	mv	a0,s1
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	33e080e7          	jalr	830(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004954:	8526                	mv	a0,s1
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	092080e7          	jalr	146(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    8000495e:	60e2                	ld	ra,24(sp)
    80004960:	6442                	ld	s0,16(sp)
    80004962:	64a2                	ld	s1,8(sp)
    80004964:	6902                	ld	s2,0(sp)
    80004966:	6105                	addi	sp,sp,32
    80004968:	8082                	ret
    pi->readopen = 0;
    8000496a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000496e:	21c48513          	addi	a0,s1,540
    80004972:	ffffd097          	auipc	ra,0xffffd
    80004976:	746080e7          	jalr	1862(ra) # 800020b8 <wakeup>
    8000497a:	b7e9                	j	80004944 <pipeclose+0x2c>
    release(&pi->lock);
    8000497c:	8526                	mv	a0,s1
    8000497e:	ffffc097          	auipc	ra,0xffffc
    80004982:	30c080e7          	jalr	780(ra) # 80000c8a <release>
}
    80004986:	bfe1                	j	8000495e <pipeclose+0x46>

0000000080004988 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004988:	711d                	addi	sp,sp,-96
    8000498a:	ec86                	sd	ra,88(sp)
    8000498c:	e8a2                	sd	s0,80(sp)
    8000498e:	e4a6                	sd	s1,72(sp)
    80004990:	e0ca                	sd	s2,64(sp)
    80004992:	fc4e                	sd	s3,56(sp)
    80004994:	f852                	sd	s4,48(sp)
    80004996:	f456                	sd	s5,40(sp)
    80004998:	f05a                	sd	s6,32(sp)
    8000499a:	ec5e                	sd	s7,24(sp)
    8000499c:	e862                	sd	s8,16(sp)
    8000499e:	1080                	addi	s0,sp,96
    800049a0:	84aa                	mv	s1,a0
    800049a2:	8aae                	mv	s5,a1
    800049a4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800049a6:	ffffd097          	auipc	ra,0xffffd
    800049aa:	006080e7          	jalr	6(ra) # 800019ac <myproc>
    800049ae:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800049b0:	8526                	mv	a0,s1
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	224080e7          	jalr	548(ra) # 80000bd6 <acquire>
  while(i < n){
    800049ba:	0b405663          	blez	s4,80004a66 <pipewrite+0xde>
  int i = 0;
    800049be:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049c0:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049c2:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049c6:	21c48b93          	addi	s7,s1,540
    800049ca:	a089                	j	80004a0c <pipewrite+0x84>
      release(&pi->lock);
    800049cc:	8526                	mv	a0,s1
    800049ce:	ffffc097          	auipc	ra,0xffffc
    800049d2:	2bc080e7          	jalr	700(ra) # 80000c8a <release>
      return -1;
    800049d6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800049d8:	854a                	mv	a0,s2
    800049da:	60e6                	ld	ra,88(sp)
    800049dc:	6446                	ld	s0,80(sp)
    800049de:	64a6                	ld	s1,72(sp)
    800049e0:	6906                	ld	s2,64(sp)
    800049e2:	79e2                	ld	s3,56(sp)
    800049e4:	7a42                	ld	s4,48(sp)
    800049e6:	7aa2                	ld	s5,40(sp)
    800049e8:	7b02                	ld	s6,32(sp)
    800049ea:	6be2                	ld	s7,24(sp)
    800049ec:	6c42                	ld	s8,16(sp)
    800049ee:	6125                	addi	sp,sp,96
    800049f0:	8082                	ret
      wakeup(&pi->nread);
    800049f2:	8562                	mv	a0,s8
    800049f4:	ffffd097          	auipc	ra,0xffffd
    800049f8:	6c4080e7          	jalr	1732(ra) # 800020b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049fc:	85a6                	mv	a1,s1
    800049fe:	855e                	mv	a0,s7
    80004a00:	ffffd097          	auipc	ra,0xffffd
    80004a04:	654080e7          	jalr	1620(ra) # 80002054 <sleep>
  while(i < n){
    80004a08:	07495063          	bge	s2,s4,80004a68 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004a0c:	2204a783          	lw	a5,544(s1)
    80004a10:	dfd5                	beqz	a5,800049cc <pipewrite+0x44>
    80004a12:	854e                	mv	a0,s3
    80004a14:	ffffe097          	auipc	ra,0xffffe
    80004a18:	8e8080e7          	jalr	-1816(ra) # 800022fc <killed>
    80004a1c:	f945                	bnez	a0,800049cc <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a1e:	2184a783          	lw	a5,536(s1)
    80004a22:	21c4a703          	lw	a4,540(s1)
    80004a26:	2007879b          	addiw	a5,a5,512
    80004a2a:	fcf704e3          	beq	a4,a5,800049f2 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a2e:	4685                	li	a3,1
    80004a30:	01590633          	add	a2,s2,s5
    80004a34:	faf40593          	addi	a1,s0,-81
    80004a38:	0509b503          	ld	a0,80(s3)
    80004a3c:	ffffd097          	auipc	ra,0xffffd
    80004a40:	cbc080e7          	jalr	-836(ra) # 800016f8 <copyin>
    80004a44:	03650263          	beq	a0,s6,80004a68 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a48:	21c4a783          	lw	a5,540(s1)
    80004a4c:	0017871b          	addiw	a4,a5,1
    80004a50:	20e4ae23          	sw	a4,540(s1)
    80004a54:	1ff7f793          	andi	a5,a5,511
    80004a58:	97a6                	add	a5,a5,s1
    80004a5a:	faf44703          	lbu	a4,-81(s0)
    80004a5e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a62:	2905                	addiw	s2,s2,1
    80004a64:	b755                	j	80004a08 <pipewrite+0x80>
  int i = 0;
    80004a66:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004a68:	21848513          	addi	a0,s1,536
    80004a6c:	ffffd097          	auipc	ra,0xffffd
    80004a70:	64c080e7          	jalr	1612(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004a74:	8526                	mv	a0,s1
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	214080e7          	jalr	532(ra) # 80000c8a <release>
  return i;
    80004a7e:	bfa9                	j	800049d8 <pipewrite+0x50>

0000000080004a80 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a80:	715d                	addi	sp,sp,-80
    80004a82:	e486                	sd	ra,72(sp)
    80004a84:	e0a2                	sd	s0,64(sp)
    80004a86:	fc26                	sd	s1,56(sp)
    80004a88:	f84a                	sd	s2,48(sp)
    80004a8a:	f44e                	sd	s3,40(sp)
    80004a8c:	f052                	sd	s4,32(sp)
    80004a8e:	ec56                	sd	s5,24(sp)
    80004a90:	e85a                	sd	s6,16(sp)
    80004a92:	0880                	addi	s0,sp,80
    80004a94:	84aa                	mv	s1,a0
    80004a96:	892e                	mv	s2,a1
    80004a98:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a9a:	ffffd097          	auipc	ra,0xffffd
    80004a9e:	f12080e7          	jalr	-238(ra) # 800019ac <myproc>
    80004aa2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004aa4:	8526                	mv	a0,s1
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	130080e7          	jalr	304(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004aae:	2184a703          	lw	a4,536(s1)
    80004ab2:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ab6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004aba:	02f71763          	bne	a4,a5,80004ae8 <piperead+0x68>
    80004abe:	2244a783          	lw	a5,548(s1)
    80004ac2:	c39d                	beqz	a5,80004ae8 <piperead+0x68>
    if(killed(pr)){
    80004ac4:	8552                	mv	a0,s4
    80004ac6:	ffffe097          	auipc	ra,0xffffe
    80004aca:	836080e7          	jalr	-1994(ra) # 800022fc <killed>
    80004ace:	e949                	bnez	a0,80004b60 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ad0:	85a6                	mv	a1,s1
    80004ad2:	854e                	mv	a0,s3
    80004ad4:	ffffd097          	auipc	ra,0xffffd
    80004ad8:	580080e7          	jalr	1408(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004adc:	2184a703          	lw	a4,536(s1)
    80004ae0:	21c4a783          	lw	a5,540(s1)
    80004ae4:	fcf70de3          	beq	a4,a5,80004abe <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ae8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004aea:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aec:	05505463          	blez	s5,80004b34 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004af0:	2184a783          	lw	a5,536(s1)
    80004af4:	21c4a703          	lw	a4,540(s1)
    80004af8:	02f70e63          	beq	a4,a5,80004b34 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004afc:	0017871b          	addiw	a4,a5,1
    80004b00:	20e4ac23          	sw	a4,536(s1)
    80004b04:	1ff7f793          	andi	a5,a5,511
    80004b08:	97a6                	add	a5,a5,s1
    80004b0a:	0187c783          	lbu	a5,24(a5)
    80004b0e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b12:	4685                	li	a3,1
    80004b14:	fbf40613          	addi	a2,s0,-65
    80004b18:	85ca                	mv	a1,s2
    80004b1a:	050a3503          	ld	a0,80(s4)
    80004b1e:	ffffd097          	auipc	ra,0xffffd
    80004b22:	b4e080e7          	jalr	-1202(ra) # 8000166c <copyout>
    80004b26:	01650763          	beq	a0,s6,80004b34 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b2a:	2985                	addiw	s3,s3,1
    80004b2c:	0905                	addi	s2,s2,1
    80004b2e:	fd3a91e3          	bne	s5,s3,80004af0 <piperead+0x70>
    80004b32:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b34:	21c48513          	addi	a0,s1,540
    80004b38:	ffffd097          	auipc	ra,0xffffd
    80004b3c:	580080e7          	jalr	1408(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004b40:	8526                	mv	a0,s1
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	148080e7          	jalr	328(ra) # 80000c8a <release>
  return i;
}
    80004b4a:	854e                	mv	a0,s3
    80004b4c:	60a6                	ld	ra,72(sp)
    80004b4e:	6406                	ld	s0,64(sp)
    80004b50:	74e2                	ld	s1,56(sp)
    80004b52:	7942                	ld	s2,48(sp)
    80004b54:	79a2                	ld	s3,40(sp)
    80004b56:	7a02                	ld	s4,32(sp)
    80004b58:	6ae2                	ld	s5,24(sp)
    80004b5a:	6b42                	ld	s6,16(sp)
    80004b5c:	6161                	addi	sp,sp,80
    80004b5e:	8082                	ret
      release(&pi->lock);
    80004b60:	8526                	mv	a0,s1
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	128080e7          	jalr	296(ra) # 80000c8a <release>
      return -1;
    80004b6a:	59fd                	li	s3,-1
    80004b6c:	bff9                	j	80004b4a <piperead+0xca>

0000000080004b6e <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004b6e:	1141                	addi	sp,sp,-16
    80004b70:	e422                	sd	s0,8(sp)
    80004b72:	0800                	addi	s0,sp,16
    80004b74:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004b76:	8905                	andi	a0,a0,1
    80004b78:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004b7a:	8b89                	andi	a5,a5,2
    80004b7c:	c399                	beqz	a5,80004b82 <flags2perm+0x14>
      perm |= PTE_W;
    80004b7e:	00456513          	ori	a0,a0,4
    return perm;
}
    80004b82:	6422                	ld	s0,8(sp)
    80004b84:	0141                	addi	sp,sp,16
    80004b86:	8082                	ret

0000000080004b88 <exec>:

int
exec(char *path, char **argv)
{
    80004b88:	de010113          	addi	sp,sp,-544
    80004b8c:	20113c23          	sd	ra,536(sp)
    80004b90:	20813823          	sd	s0,528(sp)
    80004b94:	20913423          	sd	s1,520(sp)
    80004b98:	21213023          	sd	s2,512(sp)
    80004b9c:	ffce                	sd	s3,504(sp)
    80004b9e:	fbd2                	sd	s4,496(sp)
    80004ba0:	f7d6                	sd	s5,488(sp)
    80004ba2:	f3da                	sd	s6,480(sp)
    80004ba4:	efde                	sd	s7,472(sp)
    80004ba6:	ebe2                	sd	s8,464(sp)
    80004ba8:	e7e6                	sd	s9,456(sp)
    80004baa:	e3ea                	sd	s10,448(sp)
    80004bac:	ff6e                	sd	s11,440(sp)
    80004bae:	1400                	addi	s0,sp,544
    80004bb0:	892a                	mv	s2,a0
    80004bb2:	dea43423          	sd	a0,-536(s0)
    80004bb6:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004bba:	ffffd097          	auipc	ra,0xffffd
    80004bbe:	df2080e7          	jalr	-526(ra) # 800019ac <myproc>
    80004bc2:	84aa                	mv	s1,a0

  begin_op();
    80004bc4:	fffff097          	auipc	ra,0xfffff
    80004bc8:	482080e7          	jalr	1154(ra) # 80004046 <begin_op>

  if((ip = namei(path)) == 0){
    80004bcc:	854a                	mv	a0,s2
    80004bce:	fffff097          	auipc	ra,0xfffff
    80004bd2:	258080e7          	jalr	600(ra) # 80003e26 <namei>
    80004bd6:	c93d                	beqz	a0,80004c4c <exec+0xc4>
    80004bd8:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004bda:	fffff097          	auipc	ra,0xfffff
    80004bde:	aa0080e7          	jalr	-1376(ra) # 8000367a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004be2:	04000713          	li	a4,64
    80004be6:	4681                	li	a3,0
    80004be8:	e5040613          	addi	a2,s0,-432
    80004bec:	4581                	li	a1,0
    80004bee:	8556                	mv	a0,s5
    80004bf0:	fffff097          	auipc	ra,0xfffff
    80004bf4:	d3e080e7          	jalr	-706(ra) # 8000392e <readi>
    80004bf8:	04000793          	li	a5,64
    80004bfc:	00f51a63          	bne	a0,a5,80004c10 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c00:	e5042703          	lw	a4,-432(s0)
    80004c04:	464c47b7          	lui	a5,0x464c4
    80004c08:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c0c:	04f70663          	beq	a4,a5,80004c58 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c10:	8556                	mv	a0,s5
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	cca080e7          	jalr	-822(ra) # 800038dc <iunlockput>
    end_op();
    80004c1a:	fffff097          	auipc	ra,0xfffff
    80004c1e:	4aa080e7          	jalr	1194(ra) # 800040c4 <end_op>
  }
  return -1;
    80004c22:	557d                	li	a0,-1
}
    80004c24:	21813083          	ld	ra,536(sp)
    80004c28:	21013403          	ld	s0,528(sp)
    80004c2c:	20813483          	ld	s1,520(sp)
    80004c30:	20013903          	ld	s2,512(sp)
    80004c34:	79fe                	ld	s3,504(sp)
    80004c36:	7a5e                	ld	s4,496(sp)
    80004c38:	7abe                	ld	s5,488(sp)
    80004c3a:	7b1e                	ld	s6,480(sp)
    80004c3c:	6bfe                	ld	s7,472(sp)
    80004c3e:	6c5e                	ld	s8,464(sp)
    80004c40:	6cbe                	ld	s9,456(sp)
    80004c42:	6d1e                	ld	s10,448(sp)
    80004c44:	7dfa                	ld	s11,440(sp)
    80004c46:	22010113          	addi	sp,sp,544
    80004c4a:	8082                	ret
    end_op();
    80004c4c:	fffff097          	auipc	ra,0xfffff
    80004c50:	478080e7          	jalr	1144(ra) # 800040c4 <end_op>
    return -1;
    80004c54:	557d                	li	a0,-1
    80004c56:	b7f9                	j	80004c24 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c58:	8526                	mv	a0,s1
    80004c5a:	ffffd097          	auipc	ra,0xffffd
    80004c5e:	e16080e7          	jalr	-490(ra) # 80001a70 <proc_pagetable>
    80004c62:	8b2a                	mv	s6,a0
    80004c64:	d555                	beqz	a0,80004c10 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c66:	e7042783          	lw	a5,-400(s0)
    80004c6a:	e8845703          	lhu	a4,-376(s0)
    80004c6e:	c735                	beqz	a4,80004cda <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c70:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c72:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004c76:	6a05                	lui	s4,0x1
    80004c78:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004c7c:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004c80:	6d85                	lui	s11,0x1
    80004c82:	7d7d                	lui	s10,0xfffff
    80004c84:	ac3d                	j	80004ec2 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004c86:	00004517          	auipc	a0,0x4
    80004c8a:	a7250513          	addi	a0,a0,-1422 # 800086f8 <syscalls+0x288>
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	8b2080e7          	jalr	-1870(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c96:	874a                	mv	a4,s2
    80004c98:	009c86bb          	addw	a3,s9,s1
    80004c9c:	4581                	li	a1,0
    80004c9e:	8556                	mv	a0,s5
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	c8e080e7          	jalr	-882(ra) # 8000392e <readi>
    80004ca8:	2501                	sext.w	a0,a0
    80004caa:	1aa91963          	bne	s2,a0,80004e5c <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004cae:	009d84bb          	addw	s1,s11,s1
    80004cb2:	013d09bb          	addw	s3,s10,s3
    80004cb6:	1f74f663          	bgeu	s1,s7,80004ea2 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004cba:	02049593          	slli	a1,s1,0x20
    80004cbe:	9181                	srli	a1,a1,0x20
    80004cc0:	95e2                	add	a1,a1,s8
    80004cc2:	855a                	mv	a0,s6
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	398080e7          	jalr	920(ra) # 8000105c <walkaddr>
    80004ccc:	862a                	mv	a2,a0
    if(pa == 0)
    80004cce:	dd45                	beqz	a0,80004c86 <exec+0xfe>
      n = PGSIZE;
    80004cd0:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004cd2:	fd49f2e3          	bgeu	s3,s4,80004c96 <exec+0x10e>
      n = sz - i;
    80004cd6:	894e                	mv	s2,s3
    80004cd8:	bf7d                	j	80004c96 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cda:	4901                	li	s2,0
  iunlockput(ip);
    80004cdc:	8556                	mv	a0,s5
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	bfe080e7          	jalr	-1026(ra) # 800038dc <iunlockput>
  end_op();
    80004ce6:	fffff097          	auipc	ra,0xfffff
    80004cea:	3de080e7          	jalr	990(ra) # 800040c4 <end_op>
  p = myproc();
    80004cee:	ffffd097          	auipc	ra,0xffffd
    80004cf2:	cbe080e7          	jalr	-834(ra) # 800019ac <myproc>
    80004cf6:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004cf8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004cfc:	6785                	lui	a5,0x1
    80004cfe:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004d00:	97ca                	add	a5,a5,s2
    80004d02:	777d                	lui	a4,0xfffff
    80004d04:	8ff9                	and	a5,a5,a4
    80004d06:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d0a:	4691                	li	a3,4
    80004d0c:	6609                	lui	a2,0x2
    80004d0e:	963e                	add	a2,a2,a5
    80004d10:	85be                	mv	a1,a5
    80004d12:	855a                	mv	a0,s6
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	6fc080e7          	jalr	1788(ra) # 80001410 <uvmalloc>
    80004d1c:	8c2a                	mv	s8,a0
  ip = 0;
    80004d1e:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d20:	12050e63          	beqz	a0,80004e5c <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d24:	75f9                	lui	a1,0xffffe
    80004d26:	95aa                	add	a1,a1,a0
    80004d28:	855a                	mv	a0,s6
    80004d2a:	ffffd097          	auipc	ra,0xffffd
    80004d2e:	910080e7          	jalr	-1776(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004d32:	7afd                	lui	s5,0xfffff
    80004d34:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d36:	df043783          	ld	a5,-528(s0)
    80004d3a:	6388                	ld	a0,0(a5)
    80004d3c:	c925                	beqz	a0,80004dac <exec+0x224>
    80004d3e:	e9040993          	addi	s3,s0,-368
    80004d42:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d46:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d48:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	104080e7          	jalr	260(ra) # 80000e4e <strlen>
    80004d52:	0015079b          	addiw	a5,a0,1
    80004d56:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d5a:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004d5e:	13596663          	bltu	s2,s5,80004e8a <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d62:	df043d83          	ld	s11,-528(s0)
    80004d66:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004d6a:	8552                	mv	a0,s4
    80004d6c:	ffffc097          	auipc	ra,0xffffc
    80004d70:	0e2080e7          	jalr	226(ra) # 80000e4e <strlen>
    80004d74:	0015069b          	addiw	a3,a0,1
    80004d78:	8652                	mv	a2,s4
    80004d7a:	85ca                	mv	a1,s2
    80004d7c:	855a                	mv	a0,s6
    80004d7e:	ffffd097          	auipc	ra,0xffffd
    80004d82:	8ee080e7          	jalr	-1810(ra) # 8000166c <copyout>
    80004d86:	10054663          	bltz	a0,80004e92 <exec+0x30a>
    ustack[argc] = sp;
    80004d8a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d8e:	0485                	addi	s1,s1,1
    80004d90:	008d8793          	addi	a5,s11,8
    80004d94:	def43823          	sd	a5,-528(s0)
    80004d98:	008db503          	ld	a0,8(s11)
    80004d9c:	c911                	beqz	a0,80004db0 <exec+0x228>
    if(argc >= MAXARG)
    80004d9e:	09a1                	addi	s3,s3,8
    80004da0:	fb3c95e3          	bne	s9,s3,80004d4a <exec+0x1c2>
  sz = sz1;
    80004da4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004da8:	4a81                	li	s5,0
    80004daa:	a84d                	j	80004e5c <exec+0x2d4>
  sp = sz;
    80004dac:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dae:	4481                	li	s1,0
  ustack[argc] = 0;
    80004db0:	00349793          	slli	a5,s1,0x3
    80004db4:	f9078793          	addi	a5,a5,-112
    80004db8:	97a2                	add	a5,a5,s0
    80004dba:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004dbe:	00148693          	addi	a3,s1,1
    80004dc2:	068e                	slli	a3,a3,0x3
    80004dc4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004dc8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004dcc:	01597663          	bgeu	s2,s5,80004dd8 <exec+0x250>
  sz = sz1;
    80004dd0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dd4:	4a81                	li	s5,0
    80004dd6:	a059                	j	80004e5c <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004dd8:	e9040613          	addi	a2,s0,-368
    80004ddc:	85ca                	mv	a1,s2
    80004dde:	855a                	mv	a0,s6
    80004de0:	ffffd097          	auipc	ra,0xffffd
    80004de4:	88c080e7          	jalr	-1908(ra) # 8000166c <copyout>
    80004de8:	0a054963          	bltz	a0,80004e9a <exec+0x312>
  p->trapframe->a1 = sp;
    80004dec:	058bb783          	ld	a5,88(s7)
    80004df0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004df4:	de843783          	ld	a5,-536(s0)
    80004df8:	0007c703          	lbu	a4,0(a5)
    80004dfc:	cf11                	beqz	a4,80004e18 <exec+0x290>
    80004dfe:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e00:	02f00693          	li	a3,47
    80004e04:	a039                	j	80004e12 <exec+0x28a>
      last = s+1;
    80004e06:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e0a:	0785                	addi	a5,a5,1
    80004e0c:	fff7c703          	lbu	a4,-1(a5)
    80004e10:	c701                	beqz	a4,80004e18 <exec+0x290>
    if(*s == '/')
    80004e12:	fed71ce3          	bne	a4,a3,80004e0a <exec+0x282>
    80004e16:	bfc5                	j	80004e06 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e18:	4641                	li	a2,16
    80004e1a:	de843583          	ld	a1,-536(s0)
    80004e1e:	158b8513          	addi	a0,s7,344
    80004e22:	ffffc097          	auipc	ra,0xffffc
    80004e26:	ffa080e7          	jalr	-6(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004e2a:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e2e:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e32:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e36:	058bb783          	ld	a5,88(s7)
    80004e3a:	e6843703          	ld	a4,-408(s0)
    80004e3e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e40:	058bb783          	ld	a5,88(s7)
    80004e44:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e48:	85ea                	mv	a1,s10
    80004e4a:	ffffd097          	auipc	ra,0xffffd
    80004e4e:	cc2080e7          	jalr	-830(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e52:	0004851b          	sext.w	a0,s1
    80004e56:	b3f9                	j	80004c24 <exec+0x9c>
    80004e58:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004e5c:	df843583          	ld	a1,-520(s0)
    80004e60:	855a                	mv	a0,s6
    80004e62:	ffffd097          	auipc	ra,0xffffd
    80004e66:	caa080e7          	jalr	-854(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004e6a:	da0a93e3          	bnez	s5,80004c10 <exec+0x88>
  return -1;
    80004e6e:	557d                	li	a0,-1
    80004e70:	bb55                	j	80004c24 <exec+0x9c>
    80004e72:	df243c23          	sd	s2,-520(s0)
    80004e76:	b7dd                	j	80004e5c <exec+0x2d4>
    80004e78:	df243c23          	sd	s2,-520(s0)
    80004e7c:	b7c5                	j	80004e5c <exec+0x2d4>
    80004e7e:	df243c23          	sd	s2,-520(s0)
    80004e82:	bfe9                	j	80004e5c <exec+0x2d4>
    80004e84:	df243c23          	sd	s2,-520(s0)
    80004e88:	bfd1                	j	80004e5c <exec+0x2d4>
  sz = sz1;
    80004e8a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e8e:	4a81                	li	s5,0
    80004e90:	b7f1                	j	80004e5c <exec+0x2d4>
  sz = sz1;
    80004e92:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e96:	4a81                	li	s5,0
    80004e98:	b7d1                	j	80004e5c <exec+0x2d4>
  sz = sz1;
    80004e9a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e9e:	4a81                	li	s5,0
    80004ea0:	bf75                	j	80004e5c <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ea2:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ea6:	e0843783          	ld	a5,-504(s0)
    80004eaa:	0017869b          	addiw	a3,a5,1
    80004eae:	e0d43423          	sd	a3,-504(s0)
    80004eb2:	e0043783          	ld	a5,-512(s0)
    80004eb6:	0387879b          	addiw	a5,a5,56
    80004eba:	e8845703          	lhu	a4,-376(s0)
    80004ebe:	e0e6dfe3          	bge	a3,a4,80004cdc <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ec2:	2781                	sext.w	a5,a5
    80004ec4:	e0f43023          	sd	a5,-512(s0)
    80004ec8:	03800713          	li	a4,56
    80004ecc:	86be                	mv	a3,a5
    80004ece:	e1840613          	addi	a2,s0,-488
    80004ed2:	4581                	li	a1,0
    80004ed4:	8556                	mv	a0,s5
    80004ed6:	fffff097          	auipc	ra,0xfffff
    80004eda:	a58080e7          	jalr	-1448(ra) # 8000392e <readi>
    80004ede:	03800793          	li	a5,56
    80004ee2:	f6f51be3          	bne	a0,a5,80004e58 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80004ee6:	e1842783          	lw	a5,-488(s0)
    80004eea:	4705                	li	a4,1
    80004eec:	fae79de3          	bne	a5,a4,80004ea6 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80004ef0:	e4043483          	ld	s1,-448(s0)
    80004ef4:	e3843783          	ld	a5,-456(s0)
    80004ef8:	f6f4ede3          	bltu	s1,a5,80004e72 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004efc:	e2843783          	ld	a5,-472(s0)
    80004f00:	94be                	add	s1,s1,a5
    80004f02:	f6f4ebe3          	bltu	s1,a5,80004e78 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80004f06:	de043703          	ld	a4,-544(s0)
    80004f0a:	8ff9                	and	a5,a5,a4
    80004f0c:	fbad                	bnez	a5,80004e7e <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f0e:	e1c42503          	lw	a0,-484(s0)
    80004f12:	00000097          	auipc	ra,0x0
    80004f16:	c5c080e7          	jalr	-932(ra) # 80004b6e <flags2perm>
    80004f1a:	86aa                	mv	a3,a0
    80004f1c:	8626                	mv	a2,s1
    80004f1e:	85ca                	mv	a1,s2
    80004f20:	855a                	mv	a0,s6
    80004f22:	ffffc097          	auipc	ra,0xffffc
    80004f26:	4ee080e7          	jalr	1262(ra) # 80001410 <uvmalloc>
    80004f2a:	dea43c23          	sd	a0,-520(s0)
    80004f2e:	d939                	beqz	a0,80004e84 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f30:	e2843c03          	ld	s8,-472(s0)
    80004f34:	e2042c83          	lw	s9,-480(s0)
    80004f38:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f3c:	f60b83e3          	beqz	s7,80004ea2 <exec+0x31a>
    80004f40:	89de                	mv	s3,s7
    80004f42:	4481                	li	s1,0
    80004f44:	bb9d                	j	80004cba <exec+0x132>

0000000080004f46 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f46:	7179                	addi	sp,sp,-48
    80004f48:	f406                	sd	ra,40(sp)
    80004f4a:	f022                	sd	s0,32(sp)
    80004f4c:	ec26                	sd	s1,24(sp)
    80004f4e:	e84a                	sd	s2,16(sp)
    80004f50:	1800                	addi	s0,sp,48
    80004f52:	892e                	mv	s2,a1
    80004f54:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004f56:	fdc40593          	addi	a1,s0,-36
    80004f5a:	ffffe097          	auipc	ra,0xffffe
    80004f5e:	b8a080e7          	jalr	-1142(ra) # 80002ae4 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f62:	fdc42703          	lw	a4,-36(s0)
    80004f66:	47bd                	li	a5,15
    80004f68:	02e7eb63          	bltu	a5,a4,80004f9e <argfd+0x58>
    80004f6c:	ffffd097          	auipc	ra,0xffffd
    80004f70:	a40080e7          	jalr	-1472(ra) # 800019ac <myproc>
    80004f74:	fdc42703          	lw	a4,-36(s0)
    80004f78:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd28a>
    80004f7c:	078e                	slli	a5,a5,0x3
    80004f7e:	953e                	add	a0,a0,a5
    80004f80:	611c                	ld	a5,0(a0)
    80004f82:	c385                	beqz	a5,80004fa2 <argfd+0x5c>
    return -1;
  if(pfd)
    80004f84:	00090463          	beqz	s2,80004f8c <argfd+0x46>
    *pfd = fd;
    80004f88:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f8c:	4501                	li	a0,0
  if(pf)
    80004f8e:	c091                	beqz	s1,80004f92 <argfd+0x4c>
    *pf = f;
    80004f90:	e09c                	sd	a5,0(s1)
}
    80004f92:	70a2                	ld	ra,40(sp)
    80004f94:	7402                	ld	s0,32(sp)
    80004f96:	64e2                	ld	s1,24(sp)
    80004f98:	6942                	ld	s2,16(sp)
    80004f9a:	6145                	addi	sp,sp,48
    80004f9c:	8082                	ret
    return -1;
    80004f9e:	557d                	li	a0,-1
    80004fa0:	bfcd                	j	80004f92 <argfd+0x4c>
    80004fa2:	557d                	li	a0,-1
    80004fa4:	b7fd                	j	80004f92 <argfd+0x4c>

0000000080004fa6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fa6:	1101                	addi	sp,sp,-32
    80004fa8:	ec06                	sd	ra,24(sp)
    80004faa:	e822                	sd	s0,16(sp)
    80004fac:	e426                	sd	s1,8(sp)
    80004fae:	1000                	addi	s0,sp,32
    80004fb0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fb2:	ffffd097          	auipc	ra,0xffffd
    80004fb6:	9fa080e7          	jalr	-1542(ra) # 800019ac <myproc>
    80004fba:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004fbc:	0d050793          	addi	a5,a0,208
    80004fc0:	4501                	li	a0,0
    80004fc2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004fc4:	6398                	ld	a4,0(a5)
    80004fc6:	cb19                	beqz	a4,80004fdc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004fc8:	2505                	addiw	a0,a0,1
    80004fca:	07a1                	addi	a5,a5,8
    80004fcc:	fed51ce3          	bne	a0,a3,80004fc4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004fd0:	557d                	li	a0,-1
}
    80004fd2:	60e2                	ld	ra,24(sp)
    80004fd4:	6442                	ld	s0,16(sp)
    80004fd6:	64a2                	ld	s1,8(sp)
    80004fd8:	6105                	addi	sp,sp,32
    80004fda:	8082                	ret
      p->ofile[fd] = f;
    80004fdc:	01a50793          	addi	a5,a0,26
    80004fe0:	078e                	slli	a5,a5,0x3
    80004fe2:	963e                	add	a2,a2,a5
    80004fe4:	e204                	sd	s1,0(a2)
      return fd;
    80004fe6:	b7f5                	j	80004fd2 <fdalloc+0x2c>

0000000080004fe8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004fe8:	715d                	addi	sp,sp,-80
    80004fea:	e486                	sd	ra,72(sp)
    80004fec:	e0a2                	sd	s0,64(sp)
    80004fee:	fc26                	sd	s1,56(sp)
    80004ff0:	f84a                	sd	s2,48(sp)
    80004ff2:	f44e                	sd	s3,40(sp)
    80004ff4:	f052                	sd	s4,32(sp)
    80004ff6:	ec56                	sd	s5,24(sp)
    80004ff8:	e85a                	sd	s6,16(sp)
    80004ffa:	0880                	addi	s0,sp,80
    80004ffc:	8b2e                	mv	s6,a1
    80004ffe:	89b2                	mv	s3,a2
    80005000:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005002:	fb040593          	addi	a1,s0,-80
    80005006:	fffff097          	auipc	ra,0xfffff
    8000500a:	e3e080e7          	jalr	-450(ra) # 80003e44 <nameiparent>
    8000500e:	84aa                	mv	s1,a0
    80005010:	14050f63          	beqz	a0,8000516e <create+0x186>
    return 0;

  ilock(dp);
    80005014:	ffffe097          	auipc	ra,0xffffe
    80005018:	666080e7          	jalr	1638(ra) # 8000367a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000501c:	4601                	li	a2,0
    8000501e:	fb040593          	addi	a1,s0,-80
    80005022:	8526                	mv	a0,s1
    80005024:	fffff097          	auipc	ra,0xfffff
    80005028:	b3a080e7          	jalr	-1222(ra) # 80003b5e <dirlookup>
    8000502c:	8aaa                	mv	s5,a0
    8000502e:	c931                	beqz	a0,80005082 <create+0x9a>
    iunlockput(dp);
    80005030:	8526                	mv	a0,s1
    80005032:	fffff097          	auipc	ra,0xfffff
    80005036:	8aa080e7          	jalr	-1878(ra) # 800038dc <iunlockput>
    ilock(ip);
    8000503a:	8556                	mv	a0,s5
    8000503c:	ffffe097          	auipc	ra,0xffffe
    80005040:	63e080e7          	jalr	1598(ra) # 8000367a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005044:	000b059b          	sext.w	a1,s6
    80005048:	4789                	li	a5,2
    8000504a:	02f59563          	bne	a1,a5,80005074 <create+0x8c>
    8000504e:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd2b4>
    80005052:	37f9                	addiw	a5,a5,-2
    80005054:	17c2                	slli	a5,a5,0x30
    80005056:	93c1                	srli	a5,a5,0x30
    80005058:	4705                	li	a4,1
    8000505a:	00f76d63          	bltu	a4,a5,80005074 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000505e:	8556                	mv	a0,s5
    80005060:	60a6                	ld	ra,72(sp)
    80005062:	6406                	ld	s0,64(sp)
    80005064:	74e2                	ld	s1,56(sp)
    80005066:	7942                	ld	s2,48(sp)
    80005068:	79a2                	ld	s3,40(sp)
    8000506a:	7a02                	ld	s4,32(sp)
    8000506c:	6ae2                	ld	s5,24(sp)
    8000506e:	6b42                	ld	s6,16(sp)
    80005070:	6161                	addi	sp,sp,80
    80005072:	8082                	ret
    iunlockput(ip);
    80005074:	8556                	mv	a0,s5
    80005076:	fffff097          	auipc	ra,0xfffff
    8000507a:	866080e7          	jalr	-1946(ra) # 800038dc <iunlockput>
    return 0;
    8000507e:	4a81                	li	s5,0
    80005080:	bff9                	j	8000505e <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005082:	85da                	mv	a1,s6
    80005084:	4088                	lw	a0,0(s1)
    80005086:	ffffe097          	auipc	ra,0xffffe
    8000508a:	456080e7          	jalr	1110(ra) # 800034dc <ialloc>
    8000508e:	8a2a                	mv	s4,a0
    80005090:	c539                	beqz	a0,800050de <create+0xf6>
  ilock(ip);
    80005092:	ffffe097          	auipc	ra,0xffffe
    80005096:	5e8080e7          	jalr	1512(ra) # 8000367a <ilock>
  ip->major = major;
    8000509a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000509e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800050a2:	4905                	li	s2,1
    800050a4:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800050a8:	8552                	mv	a0,s4
    800050aa:	ffffe097          	auipc	ra,0xffffe
    800050ae:	504080e7          	jalr	1284(ra) # 800035ae <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050b2:	000b059b          	sext.w	a1,s6
    800050b6:	03258b63          	beq	a1,s2,800050ec <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800050ba:	004a2603          	lw	a2,4(s4)
    800050be:	fb040593          	addi	a1,s0,-80
    800050c2:	8526                	mv	a0,s1
    800050c4:	fffff097          	auipc	ra,0xfffff
    800050c8:	cb0080e7          	jalr	-848(ra) # 80003d74 <dirlink>
    800050cc:	06054f63          	bltz	a0,8000514a <create+0x162>
  iunlockput(dp);
    800050d0:	8526                	mv	a0,s1
    800050d2:	fffff097          	auipc	ra,0xfffff
    800050d6:	80a080e7          	jalr	-2038(ra) # 800038dc <iunlockput>
  return ip;
    800050da:	8ad2                	mv	s5,s4
    800050dc:	b749                	j	8000505e <create+0x76>
    iunlockput(dp);
    800050de:	8526                	mv	a0,s1
    800050e0:	ffffe097          	auipc	ra,0xffffe
    800050e4:	7fc080e7          	jalr	2044(ra) # 800038dc <iunlockput>
    return 0;
    800050e8:	8ad2                	mv	s5,s4
    800050ea:	bf95                	j	8000505e <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050ec:	004a2603          	lw	a2,4(s4)
    800050f0:	00003597          	auipc	a1,0x3
    800050f4:	62858593          	addi	a1,a1,1576 # 80008718 <syscalls+0x2a8>
    800050f8:	8552                	mv	a0,s4
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	c7a080e7          	jalr	-902(ra) # 80003d74 <dirlink>
    80005102:	04054463          	bltz	a0,8000514a <create+0x162>
    80005106:	40d0                	lw	a2,4(s1)
    80005108:	00003597          	auipc	a1,0x3
    8000510c:	61858593          	addi	a1,a1,1560 # 80008720 <syscalls+0x2b0>
    80005110:	8552                	mv	a0,s4
    80005112:	fffff097          	auipc	ra,0xfffff
    80005116:	c62080e7          	jalr	-926(ra) # 80003d74 <dirlink>
    8000511a:	02054863          	bltz	a0,8000514a <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000511e:	004a2603          	lw	a2,4(s4)
    80005122:	fb040593          	addi	a1,s0,-80
    80005126:	8526                	mv	a0,s1
    80005128:	fffff097          	auipc	ra,0xfffff
    8000512c:	c4c080e7          	jalr	-948(ra) # 80003d74 <dirlink>
    80005130:	00054d63          	bltz	a0,8000514a <create+0x162>
    dp->nlink++;  // for ".."
    80005134:	04a4d783          	lhu	a5,74(s1)
    80005138:	2785                	addiw	a5,a5,1
    8000513a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000513e:	8526                	mv	a0,s1
    80005140:	ffffe097          	auipc	ra,0xffffe
    80005144:	46e080e7          	jalr	1134(ra) # 800035ae <iupdate>
    80005148:	b761                	j	800050d0 <create+0xe8>
  ip->nlink = 0;
    8000514a:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000514e:	8552                	mv	a0,s4
    80005150:	ffffe097          	auipc	ra,0xffffe
    80005154:	45e080e7          	jalr	1118(ra) # 800035ae <iupdate>
  iunlockput(ip);
    80005158:	8552                	mv	a0,s4
    8000515a:	ffffe097          	auipc	ra,0xffffe
    8000515e:	782080e7          	jalr	1922(ra) # 800038dc <iunlockput>
  iunlockput(dp);
    80005162:	8526                	mv	a0,s1
    80005164:	ffffe097          	auipc	ra,0xffffe
    80005168:	778080e7          	jalr	1912(ra) # 800038dc <iunlockput>
  return 0;
    8000516c:	bdcd                	j	8000505e <create+0x76>
    return 0;
    8000516e:	8aaa                	mv	s5,a0
    80005170:	b5fd                	j	8000505e <create+0x76>

0000000080005172 <sys_dup>:
{
    80005172:	7179                	addi	sp,sp,-48
    80005174:	f406                	sd	ra,40(sp)
    80005176:	f022                	sd	s0,32(sp)
    80005178:	ec26                	sd	s1,24(sp)
    8000517a:	e84a                	sd	s2,16(sp)
    8000517c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000517e:	fd840613          	addi	a2,s0,-40
    80005182:	4581                	li	a1,0
    80005184:	4501                	li	a0,0
    80005186:	00000097          	auipc	ra,0x0
    8000518a:	dc0080e7          	jalr	-576(ra) # 80004f46 <argfd>
    return -1;
    8000518e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005190:	02054363          	bltz	a0,800051b6 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005194:	fd843903          	ld	s2,-40(s0)
    80005198:	854a                	mv	a0,s2
    8000519a:	00000097          	auipc	ra,0x0
    8000519e:	e0c080e7          	jalr	-500(ra) # 80004fa6 <fdalloc>
    800051a2:	84aa                	mv	s1,a0
    return -1;
    800051a4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051a6:	00054863          	bltz	a0,800051b6 <sys_dup+0x44>
  filedup(f);
    800051aa:	854a                	mv	a0,s2
    800051ac:	fffff097          	auipc	ra,0xfffff
    800051b0:	310080e7          	jalr	784(ra) # 800044bc <filedup>
  return fd;
    800051b4:	87a6                	mv	a5,s1
}
    800051b6:	853e                	mv	a0,a5
    800051b8:	70a2                	ld	ra,40(sp)
    800051ba:	7402                	ld	s0,32(sp)
    800051bc:	64e2                	ld	s1,24(sp)
    800051be:	6942                	ld	s2,16(sp)
    800051c0:	6145                	addi	sp,sp,48
    800051c2:	8082                	ret

00000000800051c4 <sys_read>:
{
    800051c4:	7179                	addi	sp,sp,-48
    800051c6:	f406                	sd	ra,40(sp)
    800051c8:	f022                	sd	s0,32(sp)
    800051ca:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800051cc:	fd840593          	addi	a1,s0,-40
    800051d0:	4505                	li	a0,1
    800051d2:	ffffe097          	auipc	ra,0xffffe
    800051d6:	932080e7          	jalr	-1742(ra) # 80002b04 <argaddr>
  argint(2, &n);
    800051da:	fe440593          	addi	a1,s0,-28
    800051de:	4509                	li	a0,2
    800051e0:	ffffe097          	auipc	ra,0xffffe
    800051e4:	904080e7          	jalr	-1788(ra) # 80002ae4 <argint>
  if(argfd(0, 0, &f) < 0)
    800051e8:	fe840613          	addi	a2,s0,-24
    800051ec:	4581                	li	a1,0
    800051ee:	4501                	li	a0,0
    800051f0:	00000097          	auipc	ra,0x0
    800051f4:	d56080e7          	jalr	-682(ra) # 80004f46 <argfd>
    800051f8:	87aa                	mv	a5,a0
    return -1;
    800051fa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800051fc:	0007cc63          	bltz	a5,80005214 <sys_read+0x50>
  return fileread(f, p, n);
    80005200:	fe442603          	lw	a2,-28(s0)
    80005204:	fd843583          	ld	a1,-40(s0)
    80005208:	fe843503          	ld	a0,-24(s0)
    8000520c:	fffff097          	auipc	ra,0xfffff
    80005210:	43c080e7          	jalr	1084(ra) # 80004648 <fileread>
}
    80005214:	70a2                	ld	ra,40(sp)
    80005216:	7402                	ld	s0,32(sp)
    80005218:	6145                	addi	sp,sp,48
    8000521a:	8082                	ret

000000008000521c <sys_write>:
{
    8000521c:	7179                	addi	sp,sp,-48
    8000521e:	f406                	sd	ra,40(sp)
    80005220:	f022                	sd	s0,32(sp)
    80005222:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005224:	fd840593          	addi	a1,s0,-40
    80005228:	4505                	li	a0,1
    8000522a:	ffffe097          	auipc	ra,0xffffe
    8000522e:	8da080e7          	jalr	-1830(ra) # 80002b04 <argaddr>
  argint(2, &n);
    80005232:	fe440593          	addi	a1,s0,-28
    80005236:	4509                	li	a0,2
    80005238:	ffffe097          	auipc	ra,0xffffe
    8000523c:	8ac080e7          	jalr	-1876(ra) # 80002ae4 <argint>
  if(argfd(0, 0, &f) < 0)
    80005240:	fe840613          	addi	a2,s0,-24
    80005244:	4581                	li	a1,0
    80005246:	4501                	li	a0,0
    80005248:	00000097          	auipc	ra,0x0
    8000524c:	cfe080e7          	jalr	-770(ra) # 80004f46 <argfd>
    80005250:	87aa                	mv	a5,a0
    return -1;
    80005252:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005254:	0007cc63          	bltz	a5,8000526c <sys_write+0x50>
  return filewrite(f, p, n);
    80005258:	fe442603          	lw	a2,-28(s0)
    8000525c:	fd843583          	ld	a1,-40(s0)
    80005260:	fe843503          	ld	a0,-24(s0)
    80005264:	fffff097          	auipc	ra,0xfffff
    80005268:	4a6080e7          	jalr	1190(ra) # 8000470a <filewrite>
}
    8000526c:	70a2                	ld	ra,40(sp)
    8000526e:	7402                	ld	s0,32(sp)
    80005270:	6145                	addi	sp,sp,48
    80005272:	8082                	ret

0000000080005274 <sys_close>:
{
    80005274:	1101                	addi	sp,sp,-32
    80005276:	ec06                	sd	ra,24(sp)
    80005278:	e822                	sd	s0,16(sp)
    8000527a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000527c:	fe040613          	addi	a2,s0,-32
    80005280:	fec40593          	addi	a1,s0,-20
    80005284:	4501                	li	a0,0
    80005286:	00000097          	auipc	ra,0x0
    8000528a:	cc0080e7          	jalr	-832(ra) # 80004f46 <argfd>
    return -1;
    8000528e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005290:	02054463          	bltz	a0,800052b8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005294:	ffffc097          	auipc	ra,0xffffc
    80005298:	718080e7          	jalr	1816(ra) # 800019ac <myproc>
    8000529c:	fec42783          	lw	a5,-20(s0)
    800052a0:	07e9                	addi	a5,a5,26
    800052a2:	078e                	slli	a5,a5,0x3
    800052a4:	953e                	add	a0,a0,a5
    800052a6:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800052aa:	fe043503          	ld	a0,-32(s0)
    800052ae:	fffff097          	auipc	ra,0xfffff
    800052b2:	260080e7          	jalr	608(ra) # 8000450e <fileclose>
  return 0;
    800052b6:	4781                	li	a5,0
}
    800052b8:	853e                	mv	a0,a5
    800052ba:	60e2                	ld	ra,24(sp)
    800052bc:	6442                	ld	s0,16(sp)
    800052be:	6105                	addi	sp,sp,32
    800052c0:	8082                	ret

00000000800052c2 <sys_fstat>:
{
    800052c2:	1101                	addi	sp,sp,-32
    800052c4:	ec06                	sd	ra,24(sp)
    800052c6:	e822                	sd	s0,16(sp)
    800052c8:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800052ca:	fe040593          	addi	a1,s0,-32
    800052ce:	4505                	li	a0,1
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	834080e7          	jalr	-1996(ra) # 80002b04 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800052d8:	fe840613          	addi	a2,s0,-24
    800052dc:	4581                	li	a1,0
    800052de:	4501                	li	a0,0
    800052e0:	00000097          	auipc	ra,0x0
    800052e4:	c66080e7          	jalr	-922(ra) # 80004f46 <argfd>
    800052e8:	87aa                	mv	a5,a0
    return -1;
    800052ea:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052ec:	0007ca63          	bltz	a5,80005300 <sys_fstat+0x3e>
  return filestat(f, st);
    800052f0:	fe043583          	ld	a1,-32(s0)
    800052f4:	fe843503          	ld	a0,-24(s0)
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	2de080e7          	jalr	734(ra) # 800045d6 <filestat>
}
    80005300:	60e2                	ld	ra,24(sp)
    80005302:	6442                	ld	s0,16(sp)
    80005304:	6105                	addi	sp,sp,32
    80005306:	8082                	ret

0000000080005308 <sys_link>:
{
    80005308:	7169                	addi	sp,sp,-304
    8000530a:	f606                	sd	ra,296(sp)
    8000530c:	f222                	sd	s0,288(sp)
    8000530e:	ee26                	sd	s1,280(sp)
    80005310:	ea4a                	sd	s2,272(sp)
    80005312:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005314:	08000613          	li	a2,128
    80005318:	ed040593          	addi	a1,s0,-304
    8000531c:	4501                	li	a0,0
    8000531e:	ffffe097          	auipc	ra,0xffffe
    80005322:	806080e7          	jalr	-2042(ra) # 80002b24 <argstr>
    return -1;
    80005326:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005328:	10054e63          	bltz	a0,80005444 <sys_link+0x13c>
    8000532c:	08000613          	li	a2,128
    80005330:	f5040593          	addi	a1,s0,-176
    80005334:	4505                	li	a0,1
    80005336:	ffffd097          	auipc	ra,0xffffd
    8000533a:	7ee080e7          	jalr	2030(ra) # 80002b24 <argstr>
    return -1;
    8000533e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005340:	10054263          	bltz	a0,80005444 <sys_link+0x13c>
  begin_op();
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	d02080e7          	jalr	-766(ra) # 80004046 <begin_op>
  if((ip = namei(old)) == 0){
    8000534c:	ed040513          	addi	a0,s0,-304
    80005350:	fffff097          	auipc	ra,0xfffff
    80005354:	ad6080e7          	jalr	-1322(ra) # 80003e26 <namei>
    80005358:	84aa                	mv	s1,a0
    8000535a:	c551                	beqz	a0,800053e6 <sys_link+0xde>
  ilock(ip);
    8000535c:	ffffe097          	auipc	ra,0xffffe
    80005360:	31e080e7          	jalr	798(ra) # 8000367a <ilock>
  if(ip->type == T_DIR){
    80005364:	04449703          	lh	a4,68(s1)
    80005368:	4785                	li	a5,1
    8000536a:	08f70463          	beq	a4,a5,800053f2 <sys_link+0xea>
  ip->nlink++;
    8000536e:	04a4d783          	lhu	a5,74(s1)
    80005372:	2785                	addiw	a5,a5,1
    80005374:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005378:	8526                	mv	a0,s1
    8000537a:	ffffe097          	auipc	ra,0xffffe
    8000537e:	234080e7          	jalr	564(ra) # 800035ae <iupdate>
  iunlock(ip);
    80005382:	8526                	mv	a0,s1
    80005384:	ffffe097          	auipc	ra,0xffffe
    80005388:	3b8080e7          	jalr	952(ra) # 8000373c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000538c:	fd040593          	addi	a1,s0,-48
    80005390:	f5040513          	addi	a0,s0,-176
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	ab0080e7          	jalr	-1360(ra) # 80003e44 <nameiparent>
    8000539c:	892a                	mv	s2,a0
    8000539e:	c935                	beqz	a0,80005412 <sys_link+0x10a>
  ilock(dp);
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	2da080e7          	jalr	730(ra) # 8000367a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053a8:	00092703          	lw	a4,0(s2)
    800053ac:	409c                	lw	a5,0(s1)
    800053ae:	04f71d63          	bne	a4,a5,80005408 <sys_link+0x100>
    800053b2:	40d0                	lw	a2,4(s1)
    800053b4:	fd040593          	addi	a1,s0,-48
    800053b8:	854a                	mv	a0,s2
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	9ba080e7          	jalr	-1606(ra) # 80003d74 <dirlink>
    800053c2:	04054363          	bltz	a0,80005408 <sys_link+0x100>
  iunlockput(dp);
    800053c6:	854a                	mv	a0,s2
    800053c8:	ffffe097          	auipc	ra,0xffffe
    800053cc:	514080e7          	jalr	1300(ra) # 800038dc <iunlockput>
  iput(ip);
    800053d0:	8526                	mv	a0,s1
    800053d2:	ffffe097          	auipc	ra,0xffffe
    800053d6:	462080e7          	jalr	1122(ra) # 80003834 <iput>
  end_op();
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	cea080e7          	jalr	-790(ra) # 800040c4 <end_op>
  return 0;
    800053e2:	4781                	li	a5,0
    800053e4:	a085                	j	80005444 <sys_link+0x13c>
    end_op();
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	cde080e7          	jalr	-802(ra) # 800040c4 <end_op>
    return -1;
    800053ee:	57fd                	li	a5,-1
    800053f0:	a891                	j	80005444 <sys_link+0x13c>
    iunlockput(ip);
    800053f2:	8526                	mv	a0,s1
    800053f4:	ffffe097          	auipc	ra,0xffffe
    800053f8:	4e8080e7          	jalr	1256(ra) # 800038dc <iunlockput>
    end_op();
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	cc8080e7          	jalr	-824(ra) # 800040c4 <end_op>
    return -1;
    80005404:	57fd                	li	a5,-1
    80005406:	a83d                	j	80005444 <sys_link+0x13c>
    iunlockput(dp);
    80005408:	854a                	mv	a0,s2
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	4d2080e7          	jalr	1234(ra) # 800038dc <iunlockput>
  ilock(ip);
    80005412:	8526                	mv	a0,s1
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	266080e7          	jalr	614(ra) # 8000367a <ilock>
  ip->nlink--;
    8000541c:	04a4d783          	lhu	a5,74(s1)
    80005420:	37fd                	addiw	a5,a5,-1
    80005422:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005426:	8526                	mv	a0,s1
    80005428:	ffffe097          	auipc	ra,0xffffe
    8000542c:	186080e7          	jalr	390(ra) # 800035ae <iupdate>
  iunlockput(ip);
    80005430:	8526                	mv	a0,s1
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	4aa080e7          	jalr	1194(ra) # 800038dc <iunlockput>
  end_op();
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	c8a080e7          	jalr	-886(ra) # 800040c4 <end_op>
  return -1;
    80005442:	57fd                	li	a5,-1
}
    80005444:	853e                	mv	a0,a5
    80005446:	70b2                	ld	ra,296(sp)
    80005448:	7412                	ld	s0,288(sp)
    8000544a:	64f2                	ld	s1,280(sp)
    8000544c:	6952                	ld	s2,272(sp)
    8000544e:	6155                	addi	sp,sp,304
    80005450:	8082                	ret

0000000080005452 <sys_unlink>:
{
    80005452:	7151                	addi	sp,sp,-240
    80005454:	f586                	sd	ra,232(sp)
    80005456:	f1a2                	sd	s0,224(sp)
    80005458:	eda6                	sd	s1,216(sp)
    8000545a:	e9ca                	sd	s2,208(sp)
    8000545c:	e5ce                	sd	s3,200(sp)
    8000545e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005460:	08000613          	li	a2,128
    80005464:	f3040593          	addi	a1,s0,-208
    80005468:	4501                	li	a0,0
    8000546a:	ffffd097          	auipc	ra,0xffffd
    8000546e:	6ba080e7          	jalr	1722(ra) # 80002b24 <argstr>
    80005472:	18054163          	bltz	a0,800055f4 <sys_unlink+0x1a2>
  begin_op();
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	bd0080e7          	jalr	-1072(ra) # 80004046 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000547e:	fb040593          	addi	a1,s0,-80
    80005482:	f3040513          	addi	a0,s0,-208
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	9be080e7          	jalr	-1602(ra) # 80003e44 <nameiparent>
    8000548e:	84aa                	mv	s1,a0
    80005490:	c979                	beqz	a0,80005566 <sys_unlink+0x114>
  ilock(dp);
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	1e8080e7          	jalr	488(ra) # 8000367a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000549a:	00003597          	auipc	a1,0x3
    8000549e:	27e58593          	addi	a1,a1,638 # 80008718 <syscalls+0x2a8>
    800054a2:	fb040513          	addi	a0,s0,-80
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	69e080e7          	jalr	1694(ra) # 80003b44 <namecmp>
    800054ae:	14050a63          	beqz	a0,80005602 <sys_unlink+0x1b0>
    800054b2:	00003597          	auipc	a1,0x3
    800054b6:	26e58593          	addi	a1,a1,622 # 80008720 <syscalls+0x2b0>
    800054ba:	fb040513          	addi	a0,s0,-80
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	686080e7          	jalr	1670(ra) # 80003b44 <namecmp>
    800054c6:	12050e63          	beqz	a0,80005602 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054ca:	f2c40613          	addi	a2,s0,-212
    800054ce:	fb040593          	addi	a1,s0,-80
    800054d2:	8526                	mv	a0,s1
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	68a080e7          	jalr	1674(ra) # 80003b5e <dirlookup>
    800054dc:	892a                	mv	s2,a0
    800054de:	12050263          	beqz	a0,80005602 <sys_unlink+0x1b0>
  ilock(ip);
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	198080e7          	jalr	408(ra) # 8000367a <ilock>
  if(ip->nlink < 1)
    800054ea:	04a91783          	lh	a5,74(s2)
    800054ee:	08f05263          	blez	a5,80005572 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800054f2:	04491703          	lh	a4,68(s2)
    800054f6:	4785                	li	a5,1
    800054f8:	08f70563          	beq	a4,a5,80005582 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800054fc:	4641                	li	a2,16
    800054fe:	4581                	li	a1,0
    80005500:	fc040513          	addi	a0,s0,-64
    80005504:	ffffb097          	auipc	ra,0xffffb
    80005508:	7ce080e7          	jalr	1998(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000550c:	4741                	li	a4,16
    8000550e:	f2c42683          	lw	a3,-212(s0)
    80005512:	fc040613          	addi	a2,s0,-64
    80005516:	4581                	li	a1,0
    80005518:	8526                	mv	a0,s1
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	50c080e7          	jalr	1292(ra) # 80003a26 <writei>
    80005522:	47c1                	li	a5,16
    80005524:	0af51563          	bne	a0,a5,800055ce <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005528:	04491703          	lh	a4,68(s2)
    8000552c:	4785                	li	a5,1
    8000552e:	0af70863          	beq	a4,a5,800055de <sys_unlink+0x18c>
  iunlockput(dp);
    80005532:	8526                	mv	a0,s1
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	3a8080e7          	jalr	936(ra) # 800038dc <iunlockput>
  ip->nlink--;
    8000553c:	04a95783          	lhu	a5,74(s2)
    80005540:	37fd                	addiw	a5,a5,-1
    80005542:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005546:	854a                	mv	a0,s2
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	066080e7          	jalr	102(ra) # 800035ae <iupdate>
  iunlockput(ip);
    80005550:	854a                	mv	a0,s2
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	38a080e7          	jalr	906(ra) # 800038dc <iunlockput>
  end_op();
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	b6a080e7          	jalr	-1174(ra) # 800040c4 <end_op>
  return 0;
    80005562:	4501                	li	a0,0
    80005564:	a84d                	j	80005616 <sys_unlink+0x1c4>
    end_op();
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	b5e080e7          	jalr	-1186(ra) # 800040c4 <end_op>
    return -1;
    8000556e:	557d                	li	a0,-1
    80005570:	a05d                	j	80005616 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005572:	00003517          	auipc	a0,0x3
    80005576:	1b650513          	addi	a0,a0,438 # 80008728 <syscalls+0x2b8>
    8000557a:	ffffb097          	auipc	ra,0xffffb
    8000557e:	fc6080e7          	jalr	-58(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005582:	04c92703          	lw	a4,76(s2)
    80005586:	02000793          	li	a5,32
    8000558a:	f6e7f9e3          	bgeu	a5,a4,800054fc <sys_unlink+0xaa>
    8000558e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005592:	4741                	li	a4,16
    80005594:	86ce                	mv	a3,s3
    80005596:	f1840613          	addi	a2,s0,-232
    8000559a:	4581                	li	a1,0
    8000559c:	854a                	mv	a0,s2
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	390080e7          	jalr	912(ra) # 8000392e <readi>
    800055a6:	47c1                	li	a5,16
    800055a8:	00f51b63          	bne	a0,a5,800055be <sys_unlink+0x16c>
    if(de.inum != 0)
    800055ac:	f1845783          	lhu	a5,-232(s0)
    800055b0:	e7a1                	bnez	a5,800055f8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055b2:	29c1                	addiw	s3,s3,16
    800055b4:	04c92783          	lw	a5,76(s2)
    800055b8:	fcf9ede3          	bltu	s3,a5,80005592 <sys_unlink+0x140>
    800055bc:	b781                	j	800054fc <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055be:	00003517          	auipc	a0,0x3
    800055c2:	18250513          	addi	a0,a0,386 # 80008740 <syscalls+0x2d0>
    800055c6:	ffffb097          	auipc	ra,0xffffb
    800055ca:	f7a080e7          	jalr	-134(ra) # 80000540 <panic>
    panic("unlink: writei");
    800055ce:	00003517          	auipc	a0,0x3
    800055d2:	18a50513          	addi	a0,a0,394 # 80008758 <syscalls+0x2e8>
    800055d6:	ffffb097          	auipc	ra,0xffffb
    800055da:	f6a080e7          	jalr	-150(ra) # 80000540 <panic>
    dp->nlink--;
    800055de:	04a4d783          	lhu	a5,74(s1)
    800055e2:	37fd                	addiw	a5,a5,-1
    800055e4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	fc4080e7          	jalr	-60(ra) # 800035ae <iupdate>
    800055f2:	b781                	j	80005532 <sys_unlink+0xe0>
    return -1;
    800055f4:	557d                	li	a0,-1
    800055f6:	a005                	j	80005616 <sys_unlink+0x1c4>
    iunlockput(ip);
    800055f8:	854a                	mv	a0,s2
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	2e2080e7          	jalr	738(ra) # 800038dc <iunlockput>
  iunlockput(dp);
    80005602:	8526                	mv	a0,s1
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	2d8080e7          	jalr	728(ra) # 800038dc <iunlockput>
  end_op();
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	ab8080e7          	jalr	-1352(ra) # 800040c4 <end_op>
  return -1;
    80005614:	557d                	li	a0,-1
}
    80005616:	70ae                	ld	ra,232(sp)
    80005618:	740e                	ld	s0,224(sp)
    8000561a:	64ee                	ld	s1,216(sp)
    8000561c:	694e                	ld	s2,208(sp)
    8000561e:	69ae                	ld	s3,200(sp)
    80005620:	616d                	addi	sp,sp,240
    80005622:	8082                	ret

0000000080005624 <sys_open>:

uint64
sys_open(void)
{
    80005624:	7131                	addi	sp,sp,-192
    80005626:	fd06                	sd	ra,184(sp)
    80005628:	f922                	sd	s0,176(sp)
    8000562a:	f526                	sd	s1,168(sp)
    8000562c:	f14a                	sd	s2,160(sp)
    8000562e:	ed4e                	sd	s3,152(sp)
    80005630:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005632:	f4c40593          	addi	a1,s0,-180
    80005636:	4505                	li	a0,1
    80005638:	ffffd097          	auipc	ra,0xffffd
    8000563c:	4ac080e7          	jalr	1196(ra) # 80002ae4 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005640:	08000613          	li	a2,128
    80005644:	f5040593          	addi	a1,s0,-176
    80005648:	4501                	li	a0,0
    8000564a:	ffffd097          	auipc	ra,0xffffd
    8000564e:	4da080e7          	jalr	1242(ra) # 80002b24 <argstr>
    80005652:	87aa                	mv	a5,a0
    return -1;
    80005654:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005656:	0a07c963          	bltz	a5,80005708 <sys_open+0xe4>

  begin_op();
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	9ec080e7          	jalr	-1556(ra) # 80004046 <begin_op>

  if(omode & O_CREATE){
    80005662:	f4c42783          	lw	a5,-180(s0)
    80005666:	2007f793          	andi	a5,a5,512
    8000566a:	cfc5                	beqz	a5,80005722 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000566c:	4681                	li	a3,0
    8000566e:	4601                	li	a2,0
    80005670:	4589                	li	a1,2
    80005672:	f5040513          	addi	a0,s0,-176
    80005676:	00000097          	auipc	ra,0x0
    8000567a:	972080e7          	jalr	-1678(ra) # 80004fe8 <create>
    8000567e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005680:	c959                	beqz	a0,80005716 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005682:	04449703          	lh	a4,68(s1)
    80005686:	478d                	li	a5,3
    80005688:	00f71763          	bne	a4,a5,80005696 <sys_open+0x72>
    8000568c:	0464d703          	lhu	a4,70(s1)
    80005690:	47a5                	li	a5,9
    80005692:	0ce7ed63          	bltu	a5,a4,8000576c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	dbc080e7          	jalr	-580(ra) # 80004452 <filealloc>
    8000569e:	89aa                	mv	s3,a0
    800056a0:	10050363          	beqz	a0,800057a6 <sys_open+0x182>
    800056a4:	00000097          	auipc	ra,0x0
    800056a8:	902080e7          	jalr	-1790(ra) # 80004fa6 <fdalloc>
    800056ac:	892a                	mv	s2,a0
    800056ae:	0e054763          	bltz	a0,8000579c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056b2:	04449703          	lh	a4,68(s1)
    800056b6:	478d                	li	a5,3
    800056b8:	0cf70563          	beq	a4,a5,80005782 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056bc:	4789                	li	a5,2
    800056be:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056c2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056c6:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056ca:	f4c42783          	lw	a5,-180(s0)
    800056ce:	0017c713          	xori	a4,a5,1
    800056d2:	8b05                	andi	a4,a4,1
    800056d4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056d8:	0037f713          	andi	a4,a5,3
    800056dc:	00e03733          	snez	a4,a4
    800056e0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800056e4:	4007f793          	andi	a5,a5,1024
    800056e8:	c791                	beqz	a5,800056f4 <sys_open+0xd0>
    800056ea:	04449703          	lh	a4,68(s1)
    800056ee:	4789                	li	a5,2
    800056f0:	0af70063          	beq	a4,a5,80005790 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800056f4:	8526                	mv	a0,s1
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	046080e7          	jalr	70(ra) # 8000373c <iunlock>
  end_op();
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	9c6080e7          	jalr	-1594(ra) # 800040c4 <end_op>

  return fd;
    80005706:	854a                	mv	a0,s2
}
    80005708:	70ea                	ld	ra,184(sp)
    8000570a:	744a                	ld	s0,176(sp)
    8000570c:	74aa                	ld	s1,168(sp)
    8000570e:	790a                	ld	s2,160(sp)
    80005710:	69ea                	ld	s3,152(sp)
    80005712:	6129                	addi	sp,sp,192
    80005714:	8082                	ret
      end_op();
    80005716:	fffff097          	auipc	ra,0xfffff
    8000571a:	9ae080e7          	jalr	-1618(ra) # 800040c4 <end_op>
      return -1;
    8000571e:	557d                	li	a0,-1
    80005720:	b7e5                	j	80005708 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005722:	f5040513          	addi	a0,s0,-176
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	700080e7          	jalr	1792(ra) # 80003e26 <namei>
    8000572e:	84aa                	mv	s1,a0
    80005730:	c905                	beqz	a0,80005760 <sys_open+0x13c>
    ilock(ip);
    80005732:	ffffe097          	auipc	ra,0xffffe
    80005736:	f48080e7          	jalr	-184(ra) # 8000367a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000573a:	04449703          	lh	a4,68(s1)
    8000573e:	4785                	li	a5,1
    80005740:	f4f711e3          	bne	a4,a5,80005682 <sys_open+0x5e>
    80005744:	f4c42783          	lw	a5,-180(s0)
    80005748:	d7b9                	beqz	a5,80005696 <sys_open+0x72>
      iunlockput(ip);
    8000574a:	8526                	mv	a0,s1
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	190080e7          	jalr	400(ra) # 800038dc <iunlockput>
      end_op();
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	970080e7          	jalr	-1680(ra) # 800040c4 <end_op>
      return -1;
    8000575c:	557d                	li	a0,-1
    8000575e:	b76d                	j	80005708 <sys_open+0xe4>
      end_op();
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	964080e7          	jalr	-1692(ra) # 800040c4 <end_op>
      return -1;
    80005768:	557d                	li	a0,-1
    8000576a:	bf79                	j	80005708 <sys_open+0xe4>
    iunlockput(ip);
    8000576c:	8526                	mv	a0,s1
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	16e080e7          	jalr	366(ra) # 800038dc <iunlockput>
    end_op();
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	94e080e7          	jalr	-1714(ra) # 800040c4 <end_op>
    return -1;
    8000577e:	557d                	li	a0,-1
    80005780:	b761                	j	80005708 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005782:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005786:	04649783          	lh	a5,70(s1)
    8000578a:	02f99223          	sh	a5,36(s3)
    8000578e:	bf25                	j	800056c6 <sys_open+0xa2>
    itrunc(ip);
    80005790:	8526                	mv	a0,s1
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	ff6080e7          	jalr	-10(ra) # 80003788 <itrunc>
    8000579a:	bfa9                	j	800056f4 <sys_open+0xd0>
      fileclose(f);
    8000579c:	854e                	mv	a0,s3
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	d70080e7          	jalr	-656(ra) # 8000450e <fileclose>
    iunlockput(ip);
    800057a6:	8526                	mv	a0,s1
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	134080e7          	jalr	308(ra) # 800038dc <iunlockput>
    end_op();
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	914080e7          	jalr	-1772(ra) # 800040c4 <end_op>
    return -1;
    800057b8:	557d                	li	a0,-1
    800057ba:	b7b9                	j	80005708 <sys_open+0xe4>

00000000800057bc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057bc:	7175                	addi	sp,sp,-144
    800057be:	e506                	sd	ra,136(sp)
    800057c0:	e122                	sd	s0,128(sp)
    800057c2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	882080e7          	jalr	-1918(ra) # 80004046 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057cc:	08000613          	li	a2,128
    800057d0:	f7040593          	addi	a1,s0,-144
    800057d4:	4501                	li	a0,0
    800057d6:	ffffd097          	auipc	ra,0xffffd
    800057da:	34e080e7          	jalr	846(ra) # 80002b24 <argstr>
    800057de:	02054963          	bltz	a0,80005810 <sys_mkdir+0x54>
    800057e2:	4681                	li	a3,0
    800057e4:	4601                	li	a2,0
    800057e6:	4585                	li	a1,1
    800057e8:	f7040513          	addi	a0,s0,-144
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	7fc080e7          	jalr	2044(ra) # 80004fe8 <create>
    800057f4:	cd11                	beqz	a0,80005810 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	0e6080e7          	jalr	230(ra) # 800038dc <iunlockput>
  end_op();
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	8c6080e7          	jalr	-1850(ra) # 800040c4 <end_op>
  return 0;
    80005806:	4501                	li	a0,0
}
    80005808:	60aa                	ld	ra,136(sp)
    8000580a:	640a                	ld	s0,128(sp)
    8000580c:	6149                	addi	sp,sp,144
    8000580e:	8082                	ret
    end_op();
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	8b4080e7          	jalr	-1868(ra) # 800040c4 <end_op>
    return -1;
    80005818:	557d                	li	a0,-1
    8000581a:	b7fd                	j	80005808 <sys_mkdir+0x4c>

000000008000581c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000581c:	7135                	addi	sp,sp,-160
    8000581e:	ed06                	sd	ra,152(sp)
    80005820:	e922                	sd	s0,144(sp)
    80005822:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	822080e7          	jalr	-2014(ra) # 80004046 <begin_op>
  argint(1, &major);
    8000582c:	f6c40593          	addi	a1,s0,-148
    80005830:	4505                	li	a0,1
    80005832:	ffffd097          	auipc	ra,0xffffd
    80005836:	2b2080e7          	jalr	690(ra) # 80002ae4 <argint>
  argint(2, &minor);
    8000583a:	f6840593          	addi	a1,s0,-152
    8000583e:	4509                	li	a0,2
    80005840:	ffffd097          	auipc	ra,0xffffd
    80005844:	2a4080e7          	jalr	676(ra) # 80002ae4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005848:	08000613          	li	a2,128
    8000584c:	f7040593          	addi	a1,s0,-144
    80005850:	4501                	li	a0,0
    80005852:	ffffd097          	auipc	ra,0xffffd
    80005856:	2d2080e7          	jalr	722(ra) # 80002b24 <argstr>
    8000585a:	02054b63          	bltz	a0,80005890 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000585e:	f6841683          	lh	a3,-152(s0)
    80005862:	f6c41603          	lh	a2,-148(s0)
    80005866:	458d                	li	a1,3
    80005868:	f7040513          	addi	a0,s0,-144
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	77c080e7          	jalr	1916(ra) # 80004fe8 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005874:	cd11                	beqz	a0,80005890 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005876:	ffffe097          	auipc	ra,0xffffe
    8000587a:	066080e7          	jalr	102(ra) # 800038dc <iunlockput>
  end_op();
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	846080e7          	jalr	-1978(ra) # 800040c4 <end_op>
  return 0;
    80005886:	4501                	li	a0,0
}
    80005888:	60ea                	ld	ra,152(sp)
    8000588a:	644a                	ld	s0,144(sp)
    8000588c:	610d                	addi	sp,sp,160
    8000588e:	8082                	ret
    end_op();
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	834080e7          	jalr	-1996(ra) # 800040c4 <end_op>
    return -1;
    80005898:	557d                	li	a0,-1
    8000589a:	b7fd                	j	80005888 <sys_mknod+0x6c>

000000008000589c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000589c:	7135                	addi	sp,sp,-160
    8000589e:	ed06                	sd	ra,152(sp)
    800058a0:	e922                	sd	s0,144(sp)
    800058a2:	e526                	sd	s1,136(sp)
    800058a4:	e14a                	sd	s2,128(sp)
    800058a6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058a8:	ffffc097          	auipc	ra,0xffffc
    800058ac:	104080e7          	jalr	260(ra) # 800019ac <myproc>
    800058b0:	892a                	mv	s2,a0
  
  begin_op();
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	794080e7          	jalr	1940(ra) # 80004046 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058ba:	08000613          	li	a2,128
    800058be:	f6040593          	addi	a1,s0,-160
    800058c2:	4501                	li	a0,0
    800058c4:	ffffd097          	auipc	ra,0xffffd
    800058c8:	260080e7          	jalr	608(ra) # 80002b24 <argstr>
    800058cc:	04054b63          	bltz	a0,80005922 <sys_chdir+0x86>
    800058d0:	f6040513          	addi	a0,s0,-160
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	552080e7          	jalr	1362(ra) # 80003e26 <namei>
    800058dc:	84aa                	mv	s1,a0
    800058de:	c131                	beqz	a0,80005922 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	d9a080e7          	jalr	-614(ra) # 8000367a <ilock>
  if(ip->type != T_DIR){
    800058e8:	04449703          	lh	a4,68(s1)
    800058ec:	4785                	li	a5,1
    800058ee:	04f71063          	bne	a4,a5,8000592e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800058f2:	8526                	mv	a0,s1
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	e48080e7          	jalr	-440(ra) # 8000373c <iunlock>
  iput(p->cwd);
    800058fc:	15093503          	ld	a0,336(s2)
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	f34080e7          	jalr	-204(ra) # 80003834 <iput>
  end_op();
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	7bc080e7          	jalr	1980(ra) # 800040c4 <end_op>
  p->cwd = ip;
    80005910:	14993823          	sd	s1,336(s2)
  return 0;
    80005914:	4501                	li	a0,0
}
    80005916:	60ea                	ld	ra,152(sp)
    80005918:	644a                	ld	s0,144(sp)
    8000591a:	64aa                	ld	s1,136(sp)
    8000591c:	690a                	ld	s2,128(sp)
    8000591e:	610d                	addi	sp,sp,160
    80005920:	8082                	ret
    end_op();
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	7a2080e7          	jalr	1954(ra) # 800040c4 <end_op>
    return -1;
    8000592a:	557d                	li	a0,-1
    8000592c:	b7ed                	j	80005916 <sys_chdir+0x7a>
    iunlockput(ip);
    8000592e:	8526                	mv	a0,s1
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	fac080e7          	jalr	-84(ra) # 800038dc <iunlockput>
    end_op();
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	78c080e7          	jalr	1932(ra) # 800040c4 <end_op>
    return -1;
    80005940:	557d                	li	a0,-1
    80005942:	bfd1                	j	80005916 <sys_chdir+0x7a>

0000000080005944 <sys_exec>:

uint64
sys_exec(void)
{
    80005944:	7145                	addi	sp,sp,-464
    80005946:	e786                	sd	ra,456(sp)
    80005948:	e3a2                	sd	s0,448(sp)
    8000594a:	ff26                	sd	s1,440(sp)
    8000594c:	fb4a                	sd	s2,432(sp)
    8000594e:	f74e                	sd	s3,424(sp)
    80005950:	f352                	sd	s4,416(sp)
    80005952:	ef56                	sd	s5,408(sp)
    80005954:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005956:	e3840593          	addi	a1,s0,-456
    8000595a:	4505                	li	a0,1
    8000595c:	ffffd097          	auipc	ra,0xffffd
    80005960:	1a8080e7          	jalr	424(ra) # 80002b04 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005964:	08000613          	li	a2,128
    80005968:	f4040593          	addi	a1,s0,-192
    8000596c:	4501                	li	a0,0
    8000596e:	ffffd097          	auipc	ra,0xffffd
    80005972:	1b6080e7          	jalr	438(ra) # 80002b24 <argstr>
    80005976:	87aa                	mv	a5,a0
    return -1;
    80005978:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000597a:	0c07c363          	bltz	a5,80005a40 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    8000597e:	10000613          	li	a2,256
    80005982:	4581                	li	a1,0
    80005984:	e4040513          	addi	a0,s0,-448
    80005988:	ffffb097          	auipc	ra,0xffffb
    8000598c:	34a080e7          	jalr	842(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005990:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005994:	89a6                	mv	s3,s1
    80005996:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005998:	02000a13          	li	s4,32
    8000599c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059a0:	00391513          	slli	a0,s2,0x3
    800059a4:	e3040593          	addi	a1,s0,-464
    800059a8:	e3843783          	ld	a5,-456(s0)
    800059ac:	953e                	add	a0,a0,a5
    800059ae:	ffffd097          	auipc	ra,0xffffd
    800059b2:	098080e7          	jalr	152(ra) # 80002a46 <fetchaddr>
    800059b6:	02054a63          	bltz	a0,800059ea <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800059ba:	e3043783          	ld	a5,-464(s0)
    800059be:	c3b9                	beqz	a5,80005a04 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059c0:	ffffb097          	auipc	ra,0xffffb
    800059c4:	126080e7          	jalr	294(ra) # 80000ae6 <kalloc>
    800059c8:	85aa                	mv	a1,a0
    800059ca:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059ce:	cd11                	beqz	a0,800059ea <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059d0:	6605                	lui	a2,0x1
    800059d2:	e3043503          	ld	a0,-464(s0)
    800059d6:	ffffd097          	auipc	ra,0xffffd
    800059da:	0c2080e7          	jalr	194(ra) # 80002a98 <fetchstr>
    800059de:	00054663          	bltz	a0,800059ea <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800059e2:	0905                	addi	s2,s2,1
    800059e4:	09a1                	addi	s3,s3,8
    800059e6:	fb491be3          	bne	s2,s4,8000599c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059ea:	f4040913          	addi	s2,s0,-192
    800059ee:	6088                	ld	a0,0(s1)
    800059f0:	c539                	beqz	a0,80005a3e <sys_exec+0xfa>
    kfree(argv[i]);
    800059f2:	ffffb097          	auipc	ra,0xffffb
    800059f6:	ff6080e7          	jalr	-10(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059fa:	04a1                	addi	s1,s1,8
    800059fc:	ff2499e3          	bne	s1,s2,800059ee <sys_exec+0xaa>
  return -1;
    80005a00:	557d                	li	a0,-1
    80005a02:	a83d                	j	80005a40 <sys_exec+0xfc>
      argv[i] = 0;
    80005a04:	0a8e                	slli	s5,s5,0x3
    80005a06:	fc0a8793          	addi	a5,s5,-64
    80005a0a:	00878ab3          	add	s5,a5,s0
    80005a0e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a12:	e4040593          	addi	a1,s0,-448
    80005a16:	f4040513          	addi	a0,s0,-192
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	16e080e7          	jalr	366(ra) # 80004b88 <exec>
    80005a22:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a24:	f4040993          	addi	s3,s0,-192
    80005a28:	6088                	ld	a0,0(s1)
    80005a2a:	c901                	beqz	a0,80005a3a <sys_exec+0xf6>
    kfree(argv[i]);
    80005a2c:	ffffb097          	auipc	ra,0xffffb
    80005a30:	fbc080e7          	jalr	-68(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a34:	04a1                	addi	s1,s1,8
    80005a36:	ff3499e3          	bne	s1,s3,80005a28 <sys_exec+0xe4>
  return ret;
    80005a3a:	854a                	mv	a0,s2
    80005a3c:	a011                	j	80005a40 <sys_exec+0xfc>
  return -1;
    80005a3e:	557d                	li	a0,-1
}
    80005a40:	60be                	ld	ra,456(sp)
    80005a42:	641e                	ld	s0,448(sp)
    80005a44:	74fa                	ld	s1,440(sp)
    80005a46:	795a                	ld	s2,432(sp)
    80005a48:	79ba                	ld	s3,424(sp)
    80005a4a:	7a1a                	ld	s4,416(sp)
    80005a4c:	6afa                	ld	s5,408(sp)
    80005a4e:	6179                	addi	sp,sp,464
    80005a50:	8082                	ret

0000000080005a52 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a52:	7139                	addi	sp,sp,-64
    80005a54:	fc06                	sd	ra,56(sp)
    80005a56:	f822                	sd	s0,48(sp)
    80005a58:	f426                	sd	s1,40(sp)
    80005a5a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a5c:	ffffc097          	auipc	ra,0xffffc
    80005a60:	f50080e7          	jalr	-176(ra) # 800019ac <myproc>
    80005a64:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005a66:	fd840593          	addi	a1,s0,-40
    80005a6a:	4501                	li	a0,0
    80005a6c:	ffffd097          	auipc	ra,0xffffd
    80005a70:	098080e7          	jalr	152(ra) # 80002b04 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005a74:	fc840593          	addi	a1,s0,-56
    80005a78:	fd040513          	addi	a0,s0,-48
    80005a7c:	fffff097          	auipc	ra,0xfffff
    80005a80:	dc2080e7          	jalr	-574(ra) # 8000483e <pipealloc>
    return -1;
    80005a84:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a86:	0c054463          	bltz	a0,80005b4e <sys_pipe+0xfc>
  fd0 = -1;
    80005a8a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a8e:	fd043503          	ld	a0,-48(s0)
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	514080e7          	jalr	1300(ra) # 80004fa6 <fdalloc>
    80005a9a:	fca42223          	sw	a0,-60(s0)
    80005a9e:	08054b63          	bltz	a0,80005b34 <sys_pipe+0xe2>
    80005aa2:	fc843503          	ld	a0,-56(s0)
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	500080e7          	jalr	1280(ra) # 80004fa6 <fdalloc>
    80005aae:	fca42023          	sw	a0,-64(s0)
    80005ab2:	06054863          	bltz	a0,80005b22 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ab6:	4691                	li	a3,4
    80005ab8:	fc440613          	addi	a2,s0,-60
    80005abc:	fd843583          	ld	a1,-40(s0)
    80005ac0:	68a8                	ld	a0,80(s1)
    80005ac2:	ffffc097          	auipc	ra,0xffffc
    80005ac6:	baa080e7          	jalr	-1110(ra) # 8000166c <copyout>
    80005aca:	02054063          	bltz	a0,80005aea <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ace:	4691                	li	a3,4
    80005ad0:	fc040613          	addi	a2,s0,-64
    80005ad4:	fd843583          	ld	a1,-40(s0)
    80005ad8:	0591                	addi	a1,a1,4
    80005ada:	68a8                	ld	a0,80(s1)
    80005adc:	ffffc097          	auipc	ra,0xffffc
    80005ae0:	b90080e7          	jalr	-1136(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ae4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ae6:	06055463          	bgez	a0,80005b4e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005aea:	fc442783          	lw	a5,-60(s0)
    80005aee:	07e9                	addi	a5,a5,26
    80005af0:	078e                	slli	a5,a5,0x3
    80005af2:	97a6                	add	a5,a5,s1
    80005af4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005af8:	fc042783          	lw	a5,-64(s0)
    80005afc:	07e9                	addi	a5,a5,26
    80005afe:	078e                	slli	a5,a5,0x3
    80005b00:	94be                	add	s1,s1,a5
    80005b02:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005b06:	fd043503          	ld	a0,-48(s0)
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	a04080e7          	jalr	-1532(ra) # 8000450e <fileclose>
    fileclose(wf);
    80005b12:	fc843503          	ld	a0,-56(s0)
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	9f8080e7          	jalr	-1544(ra) # 8000450e <fileclose>
    return -1;
    80005b1e:	57fd                	li	a5,-1
    80005b20:	a03d                	j	80005b4e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005b22:	fc442783          	lw	a5,-60(s0)
    80005b26:	0007c763          	bltz	a5,80005b34 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005b2a:	07e9                	addi	a5,a5,26
    80005b2c:	078e                	slli	a5,a5,0x3
    80005b2e:	97a6                	add	a5,a5,s1
    80005b30:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005b34:	fd043503          	ld	a0,-48(s0)
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	9d6080e7          	jalr	-1578(ra) # 8000450e <fileclose>
    fileclose(wf);
    80005b40:	fc843503          	ld	a0,-56(s0)
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	9ca080e7          	jalr	-1590(ra) # 8000450e <fileclose>
    return -1;
    80005b4c:	57fd                	li	a5,-1
}
    80005b4e:	853e                	mv	a0,a5
    80005b50:	70e2                	ld	ra,56(sp)
    80005b52:	7442                	ld	s0,48(sp)
    80005b54:	74a2                	ld	s1,40(sp)
    80005b56:	6121                	addi	sp,sp,64
    80005b58:	8082                	ret
    80005b5a:	0000                	unimp
    80005b5c:	0000                	unimp
	...

0000000080005b60 <kernelvec>:
    80005b60:	7111                	addi	sp,sp,-256
    80005b62:	e006                	sd	ra,0(sp)
    80005b64:	e40a                	sd	sp,8(sp)
    80005b66:	e80e                	sd	gp,16(sp)
    80005b68:	ec12                	sd	tp,24(sp)
    80005b6a:	f016                	sd	t0,32(sp)
    80005b6c:	f41a                	sd	t1,40(sp)
    80005b6e:	f81e                	sd	t2,48(sp)
    80005b70:	fc22                	sd	s0,56(sp)
    80005b72:	e0a6                	sd	s1,64(sp)
    80005b74:	e4aa                	sd	a0,72(sp)
    80005b76:	e8ae                	sd	a1,80(sp)
    80005b78:	ecb2                	sd	a2,88(sp)
    80005b7a:	f0b6                	sd	a3,96(sp)
    80005b7c:	f4ba                	sd	a4,104(sp)
    80005b7e:	f8be                	sd	a5,112(sp)
    80005b80:	fcc2                	sd	a6,120(sp)
    80005b82:	e146                	sd	a7,128(sp)
    80005b84:	e54a                	sd	s2,136(sp)
    80005b86:	e94e                	sd	s3,144(sp)
    80005b88:	ed52                	sd	s4,152(sp)
    80005b8a:	f156                	sd	s5,160(sp)
    80005b8c:	f55a                	sd	s6,168(sp)
    80005b8e:	f95e                	sd	s7,176(sp)
    80005b90:	fd62                	sd	s8,184(sp)
    80005b92:	e1e6                	sd	s9,192(sp)
    80005b94:	e5ea                	sd	s10,200(sp)
    80005b96:	e9ee                	sd	s11,208(sp)
    80005b98:	edf2                	sd	t3,216(sp)
    80005b9a:	f1f6                	sd	t4,224(sp)
    80005b9c:	f5fa                	sd	t5,232(sp)
    80005b9e:	f9fe                	sd	t6,240(sp)
    80005ba0:	d73fc0ef          	jal	ra,80002912 <kerneltrap>
    80005ba4:	6082                	ld	ra,0(sp)
    80005ba6:	6122                	ld	sp,8(sp)
    80005ba8:	61c2                	ld	gp,16(sp)
    80005baa:	7282                	ld	t0,32(sp)
    80005bac:	7322                	ld	t1,40(sp)
    80005bae:	73c2                	ld	t2,48(sp)
    80005bb0:	7462                	ld	s0,56(sp)
    80005bb2:	6486                	ld	s1,64(sp)
    80005bb4:	6526                	ld	a0,72(sp)
    80005bb6:	65c6                	ld	a1,80(sp)
    80005bb8:	6666                	ld	a2,88(sp)
    80005bba:	7686                	ld	a3,96(sp)
    80005bbc:	7726                	ld	a4,104(sp)
    80005bbe:	77c6                	ld	a5,112(sp)
    80005bc0:	7866                	ld	a6,120(sp)
    80005bc2:	688a                	ld	a7,128(sp)
    80005bc4:	692a                	ld	s2,136(sp)
    80005bc6:	69ca                	ld	s3,144(sp)
    80005bc8:	6a6a                	ld	s4,152(sp)
    80005bca:	7a8a                	ld	s5,160(sp)
    80005bcc:	7b2a                	ld	s6,168(sp)
    80005bce:	7bca                	ld	s7,176(sp)
    80005bd0:	7c6a                	ld	s8,184(sp)
    80005bd2:	6c8e                	ld	s9,192(sp)
    80005bd4:	6d2e                	ld	s10,200(sp)
    80005bd6:	6dce                	ld	s11,208(sp)
    80005bd8:	6e6e                	ld	t3,216(sp)
    80005bda:	7e8e                	ld	t4,224(sp)
    80005bdc:	7f2e                	ld	t5,232(sp)
    80005bde:	7fce                	ld	t6,240(sp)
    80005be0:	6111                	addi	sp,sp,256
    80005be2:	10200073          	sret
    80005be6:	00000013          	nop
    80005bea:	00000013          	nop
    80005bee:	0001                	nop

0000000080005bf0 <timervec>:
    80005bf0:	34051573          	csrrw	a0,mscratch,a0
    80005bf4:	e10c                	sd	a1,0(a0)
    80005bf6:	e510                	sd	a2,8(a0)
    80005bf8:	e914                	sd	a3,16(a0)
    80005bfa:	6d0c                	ld	a1,24(a0)
    80005bfc:	7110                	ld	a2,32(a0)
    80005bfe:	6194                	ld	a3,0(a1)
    80005c00:	96b2                	add	a3,a3,a2
    80005c02:	e194                	sd	a3,0(a1)
    80005c04:	4589                	li	a1,2
    80005c06:	14459073          	csrw	sip,a1
    80005c0a:	6914                	ld	a3,16(a0)
    80005c0c:	6510                	ld	a2,8(a0)
    80005c0e:	610c                	ld	a1,0(a0)
    80005c10:	34051573          	csrrw	a0,mscratch,a0
    80005c14:	30200073          	mret
	...

0000000080005c1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c1a:	1141                	addi	sp,sp,-16
    80005c1c:	e422                	sd	s0,8(sp)
    80005c1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c20:	0c0007b7          	lui	a5,0xc000
    80005c24:	4705                	li	a4,1
    80005c26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c28:	c3d8                	sw	a4,4(a5)
}
    80005c2a:	6422                	ld	s0,8(sp)
    80005c2c:	0141                	addi	sp,sp,16
    80005c2e:	8082                	ret

0000000080005c30 <plicinithart>:

void
plicinithart(void)
{
    80005c30:	1141                	addi	sp,sp,-16
    80005c32:	e406                	sd	ra,8(sp)
    80005c34:	e022                	sd	s0,0(sp)
    80005c36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c38:	ffffc097          	auipc	ra,0xffffc
    80005c3c:	d48080e7          	jalr	-696(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c40:	0085171b          	slliw	a4,a0,0x8
    80005c44:	0c0027b7          	lui	a5,0xc002
    80005c48:	97ba                	add	a5,a5,a4
    80005c4a:	40200713          	li	a4,1026
    80005c4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c52:	00d5151b          	slliw	a0,a0,0xd
    80005c56:	0c2017b7          	lui	a5,0xc201
    80005c5a:	97aa                	add	a5,a5,a0
    80005c5c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005c60:	60a2                	ld	ra,8(sp)
    80005c62:	6402                	ld	s0,0(sp)
    80005c64:	0141                	addi	sp,sp,16
    80005c66:	8082                	ret

0000000080005c68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c68:	1141                	addi	sp,sp,-16
    80005c6a:	e406                	sd	ra,8(sp)
    80005c6c:	e022                	sd	s0,0(sp)
    80005c6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c70:	ffffc097          	auipc	ra,0xffffc
    80005c74:	d10080e7          	jalr	-752(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c78:	00d5151b          	slliw	a0,a0,0xd
    80005c7c:	0c2017b7          	lui	a5,0xc201
    80005c80:	97aa                	add	a5,a5,a0
  return irq;
}
    80005c82:	43c8                	lw	a0,4(a5)
    80005c84:	60a2                	ld	ra,8(sp)
    80005c86:	6402                	ld	s0,0(sp)
    80005c88:	0141                	addi	sp,sp,16
    80005c8a:	8082                	ret

0000000080005c8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c8c:	1101                	addi	sp,sp,-32
    80005c8e:	ec06                	sd	ra,24(sp)
    80005c90:	e822                	sd	s0,16(sp)
    80005c92:	e426                	sd	s1,8(sp)
    80005c94:	1000                	addi	s0,sp,32
    80005c96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c98:	ffffc097          	auipc	ra,0xffffc
    80005c9c:	ce8080e7          	jalr	-792(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ca0:	00d5151b          	slliw	a0,a0,0xd
    80005ca4:	0c2017b7          	lui	a5,0xc201
    80005ca8:	97aa                	add	a5,a5,a0
    80005caa:	c3c4                	sw	s1,4(a5)
}
    80005cac:	60e2                	ld	ra,24(sp)
    80005cae:	6442                	ld	s0,16(sp)
    80005cb0:	64a2                	ld	s1,8(sp)
    80005cb2:	6105                	addi	sp,sp,32
    80005cb4:	8082                	ret

0000000080005cb6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005cb6:	1141                	addi	sp,sp,-16
    80005cb8:	e406                	sd	ra,8(sp)
    80005cba:	e022                	sd	s0,0(sp)
    80005cbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cbe:	479d                	li	a5,7
    80005cc0:	04a7cc63          	blt	a5,a0,80005d18 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005cc4:	0001c797          	auipc	a5,0x1c
    80005cc8:	f8c78793          	addi	a5,a5,-116 # 80021c50 <disk>
    80005ccc:	97aa                	add	a5,a5,a0
    80005cce:	0187c783          	lbu	a5,24(a5)
    80005cd2:	ebb9                	bnez	a5,80005d28 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005cd4:	00451693          	slli	a3,a0,0x4
    80005cd8:	0001c797          	auipc	a5,0x1c
    80005cdc:	f7878793          	addi	a5,a5,-136 # 80021c50 <disk>
    80005ce0:	6398                	ld	a4,0(a5)
    80005ce2:	9736                	add	a4,a4,a3
    80005ce4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005ce8:	6398                	ld	a4,0(a5)
    80005cea:	9736                	add	a4,a4,a3
    80005cec:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005cf0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005cf4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005cf8:	97aa                	add	a5,a5,a0
    80005cfa:	4705                	li	a4,1
    80005cfc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005d00:	0001c517          	auipc	a0,0x1c
    80005d04:	f6850513          	addi	a0,a0,-152 # 80021c68 <disk+0x18>
    80005d08:	ffffc097          	auipc	ra,0xffffc
    80005d0c:	3b0080e7          	jalr	944(ra) # 800020b8 <wakeup>
}
    80005d10:	60a2                	ld	ra,8(sp)
    80005d12:	6402                	ld	s0,0(sp)
    80005d14:	0141                	addi	sp,sp,16
    80005d16:	8082                	ret
    panic("free_desc 1");
    80005d18:	00003517          	auipc	a0,0x3
    80005d1c:	a5050513          	addi	a0,a0,-1456 # 80008768 <syscalls+0x2f8>
    80005d20:	ffffb097          	auipc	ra,0xffffb
    80005d24:	820080e7          	jalr	-2016(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005d28:	00003517          	auipc	a0,0x3
    80005d2c:	a5050513          	addi	a0,a0,-1456 # 80008778 <syscalls+0x308>
    80005d30:	ffffb097          	auipc	ra,0xffffb
    80005d34:	810080e7          	jalr	-2032(ra) # 80000540 <panic>

0000000080005d38 <virtio_disk_init>:
{
    80005d38:	1101                	addi	sp,sp,-32
    80005d3a:	ec06                	sd	ra,24(sp)
    80005d3c:	e822                	sd	s0,16(sp)
    80005d3e:	e426                	sd	s1,8(sp)
    80005d40:	e04a                	sd	s2,0(sp)
    80005d42:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d44:	00003597          	auipc	a1,0x3
    80005d48:	a4458593          	addi	a1,a1,-1468 # 80008788 <syscalls+0x318>
    80005d4c:	0001c517          	auipc	a0,0x1c
    80005d50:	02c50513          	addi	a0,a0,44 # 80021d78 <disk+0x128>
    80005d54:	ffffb097          	auipc	ra,0xffffb
    80005d58:	df2080e7          	jalr	-526(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d5c:	100017b7          	lui	a5,0x10001
    80005d60:	4398                	lw	a4,0(a5)
    80005d62:	2701                	sext.w	a4,a4
    80005d64:	747277b7          	lui	a5,0x74727
    80005d68:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d6c:	14f71b63          	bne	a4,a5,80005ec2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005d70:	100017b7          	lui	a5,0x10001
    80005d74:	43dc                	lw	a5,4(a5)
    80005d76:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d78:	4709                	li	a4,2
    80005d7a:	14e79463          	bne	a5,a4,80005ec2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d7e:	100017b7          	lui	a5,0x10001
    80005d82:	479c                	lw	a5,8(a5)
    80005d84:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005d86:	12e79e63          	bne	a5,a4,80005ec2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d8a:	100017b7          	lui	a5,0x10001
    80005d8e:	47d8                	lw	a4,12(a5)
    80005d90:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d92:	554d47b7          	lui	a5,0x554d4
    80005d96:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d9a:	12f71463          	bne	a4,a5,80005ec2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d9e:	100017b7          	lui	a5,0x10001
    80005da2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005da6:	4705                	li	a4,1
    80005da8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005daa:	470d                	li	a4,3
    80005dac:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005dae:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005db0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005db4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc9cf>
    80005db8:	8f75                	and	a4,a4,a3
    80005dba:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dbc:	472d                	li	a4,11
    80005dbe:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005dc0:	5bbc                	lw	a5,112(a5)
    80005dc2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005dc6:	8ba1                	andi	a5,a5,8
    80005dc8:	10078563          	beqz	a5,80005ed2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005dcc:	100017b7          	lui	a5,0x10001
    80005dd0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005dd4:	43fc                	lw	a5,68(a5)
    80005dd6:	2781                	sext.w	a5,a5
    80005dd8:	10079563          	bnez	a5,80005ee2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ddc:	100017b7          	lui	a5,0x10001
    80005de0:	5bdc                	lw	a5,52(a5)
    80005de2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005de4:	10078763          	beqz	a5,80005ef2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005de8:	471d                	li	a4,7
    80005dea:	10f77c63          	bgeu	a4,a5,80005f02 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005dee:	ffffb097          	auipc	ra,0xffffb
    80005df2:	cf8080e7          	jalr	-776(ra) # 80000ae6 <kalloc>
    80005df6:	0001c497          	auipc	s1,0x1c
    80005dfa:	e5a48493          	addi	s1,s1,-422 # 80021c50 <disk>
    80005dfe:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005e00:	ffffb097          	auipc	ra,0xffffb
    80005e04:	ce6080e7          	jalr	-794(ra) # 80000ae6 <kalloc>
    80005e08:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005e0a:	ffffb097          	auipc	ra,0xffffb
    80005e0e:	cdc080e7          	jalr	-804(ra) # 80000ae6 <kalloc>
    80005e12:	87aa                	mv	a5,a0
    80005e14:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005e16:	6088                	ld	a0,0(s1)
    80005e18:	cd6d                	beqz	a0,80005f12 <virtio_disk_init+0x1da>
    80005e1a:	0001c717          	auipc	a4,0x1c
    80005e1e:	e3e73703          	ld	a4,-450(a4) # 80021c58 <disk+0x8>
    80005e22:	cb65                	beqz	a4,80005f12 <virtio_disk_init+0x1da>
    80005e24:	c7fd                	beqz	a5,80005f12 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005e26:	6605                	lui	a2,0x1
    80005e28:	4581                	li	a1,0
    80005e2a:	ffffb097          	auipc	ra,0xffffb
    80005e2e:	ea8080e7          	jalr	-344(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005e32:	0001c497          	auipc	s1,0x1c
    80005e36:	e1e48493          	addi	s1,s1,-482 # 80021c50 <disk>
    80005e3a:	6605                	lui	a2,0x1
    80005e3c:	4581                	li	a1,0
    80005e3e:	6488                	ld	a0,8(s1)
    80005e40:	ffffb097          	auipc	ra,0xffffb
    80005e44:	e92080e7          	jalr	-366(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005e48:	6605                	lui	a2,0x1
    80005e4a:	4581                	li	a1,0
    80005e4c:	6888                	ld	a0,16(s1)
    80005e4e:	ffffb097          	auipc	ra,0xffffb
    80005e52:	e84080e7          	jalr	-380(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e56:	100017b7          	lui	a5,0x10001
    80005e5a:	4721                	li	a4,8
    80005e5c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005e5e:	4098                	lw	a4,0(s1)
    80005e60:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005e64:	40d8                	lw	a4,4(s1)
    80005e66:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005e6a:	6498                	ld	a4,8(s1)
    80005e6c:	0007069b          	sext.w	a3,a4
    80005e70:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005e74:	9701                	srai	a4,a4,0x20
    80005e76:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005e7a:	6898                	ld	a4,16(s1)
    80005e7c:	0007069b          	sext.w	a3,a4
    80005e80:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005e84:	9701                	srai	a4,a4,0x20
    80005e86:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005e8a:	4705                	li	a4,1
    80005e8c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005e8e:	00e48c23          	sb	a4,24(s1)
    80005e92:	00e48ca3          	sb	a4,25(s1)
    80005e96:	00e48d23          	sb	a4,26(s1)
    80005e9a:	00e48da3          	sb	a4,27(s1)
    80005e9e:	00e48e23          	sb	a4,28(s1)
    80005ea2:	00e48ea3          	sb	a4,29(s1)
    80005ea6:	00e48f23          	sb	a4,30(s1)
    80005eaa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005eae:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eb2:	0727a823          	sw	s2,112(a5)
}
    80005eb6:	60e2                	ld	ra,24(sp)
    80005eb8:	6442                	ld	s0,16(sp)
    80005eba:	64a2                	ld	s1,8(sp)
    80005ebc:	6902                	ld	s2,0(sp)
    80005ebe:	6105                	addi	sp,sp,32
    80005ec0:	8082                	ret
    panic("could not find virtio disk");
    80005ec2:	00003517          	auipc	a0,0x3
    80005ec6:	8d650513          	addi	a0,a0,-1834 # 80008798 <syscalls+0x328>
    80005eca:	ffffa097          	auipc	ra,0xffffa
    80005ece:	676080e7          	jalr	1654(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005ed2:	00003517          	auipc	a0,0x3
    80005ed6:	8e650513          	addi	a0,a0,-1818 # 800087b8 <syscalls+0x348>
    80005eda:	ffffa097          	auipc	ra,0xffffa
    80005ede:	666080e7          	jalr	1638(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005ee2:	00003517          	auipc	a0,0x3
    80005ee6:	8f650513          	addi	a0,a0,-1802 # 800087d8 <syscalls+0x368>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	656080e7          	jalr	1622(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005ef2:	00003517          	auipc	a0,0x3
    80005ef6:	90650513          	addi	a0,a0,-1786 # 800087f8 <syscalls+0x388>
    80005efa:	ffffa097          	auipc	ra,0xffffa
    80005efe:	646080e7          	jalr	1606(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80005f02:	00003517          	auipc	a0,0x3
    80005f06:	91650513          	addi	a0,a0,-1770 # 80008818 <syscalls+0x3a8>
    80005f0a:	ffffa097          	auipc	ra,0xffffa
    80005f0e:	636080e7          	jalr	1590(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80005f12:	00003517          	auipc	a0,0x3
    80005f16:	92650513          	addi	a0,a0,-1754 # 80008838 <syscalls+0x3c8>
    80005f1a:	ffffa097          	auipc	ra,0xffffa
    80005f1e:	626080e7          	jalr	1574(ra) # 80000540 <panic>

0000000080005f22 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f22:	7119                	addi	sp,sp,-128
    80005f24:	fc86                	sd	ra,120(sp)
    80005f26:	f8a2                	sd	s0,112(sp)
    80005f28:	f4a6                	sd	s1,104(sp)
    80005f2a:	f0ca                	sd	s2,96(sp)
    80005f2c:	ecce                	sd	s3,88(sp)
    80005f2e:	e8d2                	sd	s4,80(sp)
    80005f30:	e4d6                	sd	s5,72(sp)
    80005f32:	e0da                	sd	s6,64(sp)
    80005f34:	fc5e                	sd	s7,56(sp)
    80005f36:	f862                	sd	s8,48(sp)
    80005f38:	f466                	sd	s9,40(sp)
    80005f3a:	f06a                	sd	s10,32(sp)
    80005f3c:	ec6e                	sd	s11,24(sp)
    80005f3e:	0100                	addi	s0,sp,128
    80005f40:	8aaa                	mv	s5,a0
    80005f42:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f44:	00c52d03          	lw	s10,12(a0)
    80005f48:	001d1d1b          	slliw	s10,s10,0x1
    80005f4c:	1d02                	slli	s10,s10,0x20
    80005f4e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80005f52:	0001c517          	auipc	a0,0x1c
    80005f56:	e2650513          	addi	a0,a0,-474 # 80021d78 <disk+0x128>
    80005f5a:	ffffb097          	auipc	ra,0xffffb
    80005f5e:	c7c080e7          	jalr	-900(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80005f62:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f64:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f66:	0001cb97          	auipc	s7,0x1c
    80005f6a:	ceab8b93          	addi	s7,s7,-790 # 80021c50 <disk>
  for(int i = 0; i < 3; i++){
    80005f6e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f70:	0001cc97          	auipc	s9,0x1c
    80005f74:	e08c8c93          	addi	s9,s9,-504 # 80021d78 <disk+0x128>
    80005f78:	a08d                	j	80005fda <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80005f7a:	00fb8733          	add	a4,s7,a5
    80005f7e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f82:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f84:	0207c563          	bltz	a5,80005fae <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80005f88:	2905                	addiw	s2,s2,1
    80005f8a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005f8c:	05690c63          	beq	s2,s6,80005fe4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80005f90:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f92:	0001c717          	auipc	a4,0x1c
    80005f96:	cbe70713          	addi	a4,a4,-834 # 80021c50 <disk>
    80005f9a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f9c:	01874683          	lbu	a3,24(a4)
    80005fa0:	fee9                	bnez	a3,80005f7a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80005fa2:	2785                	addiw	a5,a5,1
    80005fa4:	0705                	addi	a4,a4,1
    80005fa6:	fe979be3          	bne	a5,s1,80005f9c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80005faa:	57fd                	li	a5,-1
    80005fac:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005fae:	01205d63          	blez	s2,80005fc8 <virtio_disk_rw+0xa6>
    80005fb2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005fb4:	000a2503          	lw	a0,0(s4)
    80005fb8:	00000097          	auipc	ra,0x0
    80005fbc:	cfe080e7          	jalr	-770(ra) # 80005cb6 <free_desc>
      for(int j = 0; j < i; j++)
    80005fc0:	2d85                	addiw	s11,s11,1
    80005fc2:	0a11                	addi	s4,s4,4
    80005fc4:	ff2d98e3          	bne	s11,s2,80005fb4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fc8:	85e6                	mv	a1,s9
    80005fca:	0001c517          	auipc	a0,0x1c
    80005fce:	c9e50513          	addi	a0,a0,-866 # 80021c68 <disk+0x18>
    80005fd2:	ffffc097          	auipc	ra,0xffffc
    80005fd6:	082080e7          	jalr	130(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    80005fda:	f8040a13          	addi	s4,s0,-128
{
    80005fde:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005fe0:	894e                	mv	s2,s3
    80005fe2:	b77d                	j	80005f90 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005fe4:	f8042503          	lw	a0,-128(s0)
    80005fe8:	00a50713          	addi	a4,a0,10
    80005fec:	0712                	slli	a4,a4,0x4

  if(write)
    80005fee:	0001c797          	auipc	a5,0x1c
    80005ff2:	c6278793          	addi	a5,a5,-926 # 80021c50 <disk>
    80005ff6:	00e786b3          	add	a3,a5,a4
    80005ffa:	01803633          	snez	a2,s8
    80005ffe:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006000:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006004:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006008:	f6070613          	addi	a2,a4,-160
    8000600c:	6394                	ld	a3,0(a5)
    8000600e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006010:	00870593          	addi	a1,a4,8
    80006014:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006016:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006018:	0007b803          	ld	a6,0(a5)
    8000601c:	9642                	add	a2,a2,a6
    8000601e:	46c1                	li	a3,16
    80006020:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006022:	4585                	li	a1,1
    80006024:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006028:	f8442683          	lw	a3,-124(s0)
    8000602c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006030:	0692                	slli	a3,a3,0x4
    80006032:	9836                	add	a6,a6,a3
    80006034:	058a8613          	addi	a2,s5,88
    80006038:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000603c:	0007b803          	ld	a6,0(a5)
    80006040:	96c2                	add	a3,a3,a6
    80006042:	40000613          	li	a2,1024
    80006046:	c690                	sw	a2,8(a3)
  if(write)
    80006048:	001c3613          	seqz	a2,s8
    8000604c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006050:	00166613          	ori	a2,a2,1
    80006054:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006058:	f8842603          	lw	a2,-120(s0)
    8000605c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006060:	00250693          	addi	a3,a0,2
    80006064:	0692                	slli	a3,a3,0x4
    80006066:	96be                	add	a3,a3,a5
    80006068:	58fd                	li	a7,-1
    8000606a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000606e:	0612                	slli	a2,a2,0x4
    80006070:	9832                	add	a6,a6,a2
    80006072:	f9070713          	addi	a4,a4,-112
    80006076:	973e                	add	a4,a4,a5
    80006078:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000607c:	6398                	ld	a4,0(a5)
    8000607e:	9732                	add	a4,a4,a2
    80006080:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006082:	4609                	li	a2,2
    80006084:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006088:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000608c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006090:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006094:	6794                	ld	a3,8(a5)
    80006096:	0026d703          	lhu	a4,2(a3)
    8000609a:	8b1d                	andi	a4,a4,7
    8000609c:	0706                	slli	a4,a4,0x1
    8000609e:	96ba                	add	a3,a3,a4
    800060a0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800060a4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060a8:	6798                	ld	a4,8(a5)
    800060aa:	00275783          	lhu	a5,2(a4)
    800060ae:	2785                	addiw	a5,a5,1
    800060b0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060b4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060b8:	100017b7          	lui	a5,0x10001
    800060bc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060c0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800060c4:	0001c917          	auipc	s2,0x1c
    800060c8:	cb490913          	addi	s2,s2,-844 # 80021d78 <disk+0x128>
  while(b->disk == 1) {
    800060cc:	4485                	li	s1,1
    800060ce:	00b79c63          	bne	a5,a1,800060e6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800060d2:	85ca                	mv	a1,s2
    800060d4:	8556                	mv	a0,s5
    800060d6:	ffffc097          	auipc	ra,0xffffc
    800060da:	f7e080e7          	jalr	-130(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    800060de:	004aa783          	lw	a5,4(s5)
    800060e2:	fe9788e3          	beq	a5,s1,800060d2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800060e6:	f8042903          	lw	s2,-128(s0)
    800060ea:	00290713          	addi	a4,s2,2
    800060ee:	0712                	slli	a4,a4,0x4
    800060f0:	0001c797          	auipc	a5,0x1c
    800060f4:	b6078793          	addi	a5,a5,-1184 # 80021c50 <disk>
    800060f8:	97ba                	add	a5,a5,a4
    800060fa:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800060fe:	0001c997          	auipc	s3,0x1c
    80006102:	b5298993          	addi	s3,s3,-1198 # 80021c50 <disk>
    80006106:	00491713          	slli	a4,s2,0x4
    8000610a:	0009b783          	ld	a5,0(s3)
    8000610e:	97ba                	add	a5,a5,a4
    80006110:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006114:	854a                	mv	a0,s2
    80006116:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000611a:	00000097          	auipc	ra,0x0
    8000611e:	b9c080e7          	jalr	-1124(ra) # 80005cb6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006122:	8885                	andi	s1,s1,1
    80006124:	f0ed                	bnez	s1,80006106 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006126:	0001c517          	auipc	a0,0x1c
    8000612a:	c5250513          	addi	a0,a0,-942 # 80021d78 <disk+0x128>
    8000612e:	ffffb097          	auipc	ra,0xffffb
    80006132:	b5c080e7          	jalr	-1188(ra) # 80000c8a <release>
}
    80006136:	70e6                	ld	ra,120(sp)
    80006138:	7446                	ld	s0,112(sp)
    8000613a:	74a6                	ld	s1,104(sp)
    8000613c:	7906                	ld	s2,96(sp)
    8000613e:	69e6                	ld	s3,88(sp)
    80006140:	6a46                	ld	s4,80(sp)
    80006142:	6aa6                	ld	s5,72(sp)
    80006144:	6b06                	ld	s6,64(sp)
    80006146:	7be2                	ld	s7,56(sp)
    80006148:	7c42                	ld	s8,48(sp)
    8000614a:	7ca2                	ld	s9,40(sp)
    8000614c:	7d02                	ld	s10,32(sp)
    8000614e:	6de2                	ld	s11,24(sp)
    80006150:	6109                	addi	sp,sp,128
    80006152:	8082                	ret

0000000080006154 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006154:	1101                	addi	sp,sp,-32
    80006156:	ec06                	sd	ra,24(sp)
    80006158:	e822                	sd	s0,16(sp)
    8000615a:	e426                	sd	s1,8(sp)
    8000615c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000615e:	0001c497          	auipc	s1,0x1c
    80006162:	af248493          	addi	s1,s1,-1294 # 80021c50 <disk>
    80006166:	0001c517          	auipc	a0,0x1c
    8000616a:	c1250513          	addi	a0,a0,-1006 # 80021d78 <disk+0x128>
    8000616e:	ffffb097          	auipc	ra,0xffffb
    80006172:	a68080e7          	jalr	-1432(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006176:	10001737          	lui	a4,0x10001
    8000617a:	533c                	lw	a5,96(a4)
    8000617c:	8b8d                	andi	a5,a5,3
    8000617e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006180:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006184:	689c                	ld	a5,16(s1)
    80006186:	0204d703          	lhu	a4,32(s1)
    8000618a:	0027d783          	lhu	a5,2(a5)
    8000618e:	04f70863          	beq	a4,a5,800061de <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006192:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006196:	6898                	ld	a4,16(s1)
    80006198:	0204d783          	lhu	a5,32(s1)
    8000619c:	8b9d                	andi	a5,a5,7
    8000619e:	078e                	slli	a5,a5,0x3
    800061a0:	97ba                	add	a5,a5,a4
    800061a2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800061a4:	00278713          	addi	a4,a5,2
    800061a8:	0712                	slli	a4,a4,0x4
    800061aa:	9726                	add	a4,a4,s1
    800061ac:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800061b0:	e721                	bnez	a4,800061f8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800061b2:	0789                	addi	a5,a5,2
    800061b4:	0792                	slli	a5,a5,0x4
    800061b6:	97a6                	add	a5,a5,s1
    800061b8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800061ba:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800061be:	ffffc097          	auipc	ra,0xffffc
    800061c2:	efa080e7          	jalr	-262(ra) # 800020b8 <wakeup>

    disk.used_idx += 1;
    800061c6:	0204d783          	lhu	a5,32(s1)
    800061ca:	2785                	addiw	a5,a5,1
    800061cc:	17c2                	slli	a5,a5,0x30
    800061ce:	93c1                	srli	a5,a5,0x30
    800061d0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061d4:	6898                	ld	a4,16(s1)
    800061d6:	00275703          	lhu	a4,2(a4)
    800061da:	faf71ce3          	bne	a4,a5,80006192 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800061de:	0001c517          	auipc	a0,0x1c
    800061e2:	b9a50513          	addi	a0,a0,-1126 # 80021d78 <disk+0x128>
    800061e6:	ffffb097          	auipc	ra,0xffffb
    800061ea:	aa4080e7          	jalr	-1372(ra) # 80000c8a <release>
}
    800061ee:	60e2                	ld	ra,24(sp)
    800061f0:	6442                	ld	s0,16(sp)
    800061f2:	64a2                	ld	s1,8(sp)
    800061f4:	6105                	addi	sp,sp,32
    800061f6:	8082                	ret
      panic("virtio_disk_intr status");
    800061f8:	00002517          	auipc	a0,0x2
    800061fc:	65850513          	addi	a0,a0,1624 # 80008850 <syscalls+0x3e0>
    80006200:	ffffa097          	auipc	ra,0xffffa
    80006204:	340080e7          	jalr	832(ra) # 80000540 <panic>
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
