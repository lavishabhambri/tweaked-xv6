
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	86013103          	ld	sp,-1952(sp) # 80008860 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	bdc78793          	addi	a5,a5,-1060 # 80005c40 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3fc080e7          	jalr	1020(ra) # 80002528 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f4c080e7          	jalr	-180(ra) # 80002120 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	2c2080e7          	jalr	706(ra) # 800024d2 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

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
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
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
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

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
    800002f6:	28c080e7          	jalr	652(ra) # 8000257e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
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
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e66080e7          	jalr	-410(ra) # 800022ac <wakeup>
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
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	2a078793          	addi	a5,a5,672 # 80021718 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
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
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
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
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	a0c080e7          	jalr	-1524(ra) # 800022ac <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	7f4080e7          	jalr	2036(ra) # 80002120 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	848080e7          	jalr	-1976(ra) # 8000271c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	da4080e7          	jalr	-604(ra) # 80005c80 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	fea080e7          	jalr	-22(ra) # 80001ece <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	7a8080e7          	jalr	1960(ra) # 800026f4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	7c8080e7          	jalr	1992(ra) # 8000271c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	d0e080e7          	jalr	-754(ra) # 80005c6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	d1c080e7          	jalr	-740(ra) # 80005c80 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	f00080e7          	jalr	-256(ra) # 80002e6c <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	590080e7          	jalr	1424(ra) # 80003504 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	53a080e7          	jalr	1338(ra) # 800044b6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	e1e080e7          	jalr	-482(ra) # 80005da2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d10080e7          	jalr	-752(ra) # 80001c9c <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	c62a0a13          	addi	s4,s4,-926 # 800174d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	17848493          	addi	s1,s1,376
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00016997          	auipc	s3,0x16
    8000193e:	b9698993          	addi	s3,s3,-1130 # 800174d0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	17848493          	addi	s1,s1,376
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e107a783          	lw	a5,-496(a5) # 80008810 <first.1686>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	d2a080e7          	jalr	-726(ra) # 80002734 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	de07ab23          	sw	zero,-522(a5) # 80008810 <first.1686>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	a60080e7          	jalr	-1440(ra) # 80003484 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	dc878793          	addi	a5,a5,-568 # 80008814 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	05893683          	ld	a3,88(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6e:	6d28                	ld	a0,88(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7e:	68a8                	ld	a0,80(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	64ac                	ld	a1,72(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	b0a48493          	addi	s1,s1,-1270 # 800116d0 <proc>
    80001bce:	00016917          	auipc	s2,0x16
    80001bd2:	90290913          	addi	s2,s2,-1790 # 800174d0 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	17848493          	addi	s1,s1,376
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a09d                	j	80001c5e <allocproc+0xa4>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  p->startTime = ticks;
    80001c08:	00007797          	auipc	a5,0x7
    80001c0c:	4287a783          	lw	a5,1064(a5) # 80009030 <ticks>
    80001c10:	16f4a423          	sw	a5,360(s1)
  p->runTime = 0;
    80001c14:	1604a823          	sw	zero,368(s1)
  p->endTime = 0;
    80001c18:	1604a623          	sw	zero,364(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	ed8080e7          	jalr	-296(ra) # 80000af4 <kalloc>
    80001c24:	892a                	mv	s2,a0
    80001c26:	eca8                	sd	a0,88(s1)
    80001c28:	c131                	beqz	a0,80001c6c <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	e48080e7          	jalr	-440(ra) # 80001a74 <proc_pagetable>
    80001c34:	892a                	mv	s2,a0
    80001c36:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c38:	c531                	beqz	a0,80001c84 <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001c3a:	07000613          	li	a2,112
    80001c3e:	4581                	li	a1,0
    80001c40:	06048513          	addi	a0,s1,96
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	09c080e7          	jalr	156(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c4c:	00000797          	auipc	a5,0x0
    80001c50:	d9c78793          	addi	a5,a5,-612 # 800019e8 <forkret>
    80001c54:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c56:	60bc                	ld	a5,64(s1)
    80001c58:	6705                	lui	a4,0x1
    80001c5a:	97ba                	add	a5,a5,a4
    80001c5c:	f4bc                	sd	a5,104(s1)
}
    80001c5e:	8526                	mv	a0,s1
    80001c60:	60e2                	ld	ra,24(sp)
    80001c62:	6442                	ld	s0,16(sp)
    80001c64:	64a2                	ld	s1,8(sp)
    80001c66:	6902                	ld	s2,0(sp)
    80001c68:	6105                	addi	sp,sp,32
    80001c6a:	8082                	ret
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef4080e7          	jalr	-268(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	020080e7          	jalr	32(ra) # 80000c98 <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	bff1                	j	80001c5e <allocproc+0xa4>
    freeproc(p);
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	edc080e7          	jalr	-292(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	008080e7          	jalr	8(ra) # 80000c98 <release>
    return 0;
    80001c98:	84ca                	mv	s1,s2
    80001c9a:	b7d1                	j	80001c5e <allocproc+0xa4>

0000000080001c9c <userinit>:
{
    80001c9c:	1101                	addi	sp,sp,-32
    80001c9e:	ec06                	sd	ra,24(sp)
    80001ca0:	e822                	sd	s0,16(sp)
    80001ca2:	e426                	sd	s1,8(sp)
    80001ca4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	f14080e7          	jalr	-236(ra) # 80001bba <allocproc>
    80001cae:	84aa                	mv	s1,a0
  initproc = p;
    80001cb0:	00007797          	auipc	a5,0x7
    80001cb4:	36a7bc23          	sd	a0,888(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb8:	03400613          	li	a2,52
    80001cbc:	00007597          	auipc	a1,0x7
    80001cc0:	b6458593          	addi	a1,a1,-1180 # 80008820 <initcode>
    80001cc4:	6928                	ld	a0,80(a0)
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	6a2080e7          	jalr	1698(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cce:	6785                	lui	a5,0x1
    80001cd0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cd2:	6cb8                	ld	a4,88(s1)
    80001cd4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd8:	6cb8                	ld	a4,88(s1)
    80001cda:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cdc:	4641                	li	a2,16
    80001cde:	00006597          	auipc	a1,0x6
    80001ce2:	52258593          	addi	a1,a1,1314 # 80008200 <digits+0x1c0>
    80001ce6:	15848513          	addi	a0,s1,344
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	148080e7          	jalr	328(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cf2:	00006517          	auipc	a0,0x6
    80001cf6:	51e50513          	addi	a0,a0,1310 # 80008210 <digits+0x1d0>
    80001cfa:	00002097          	auipc	ra,0x2
    80001cfe:	1b8080e7          	jalr	440(ra) # 80003eb2 <namei>
    80001d02:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d06:	478d                	li	a5,3
    80001d08:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	f8c080e7          	jalr	-116(ra) # 80000c98 <release>
}
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6105                	addi	sp,sp,32
    80001d1c:	8082                	ret

0000000080001d1e <growproc>:
{
    80001d1e:	1101                	addi	sp,sp,-32
    80001d20:	ec06                	sd	ra,24(sp)
    80001d22:	e822                	sd	s0,16(sp)
    80001d24:	e426                	sd	s1,8(sp)
    80001d26:	e04a                	sd	s2,0(sp)
    80001d28:	1000                	addi	s0,sp,32
    80001d2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d2c:	00000097          	auipc	ra,0x0
    80001d30:	c84080e7          	jalr	-892(ra) # 800019b0 <myproc>
    80001d34:	892a                	mv	s2,a0
  sz = p->sz;
    80001d36:	652c                	ld	a1,72(a0)
    80001d38:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d3c:	00904f63          	bgtz	s1,80001d5a <growproc+0x3c>
  } else if(n < 0){
    80001d40:	0204cc63          	bltz	s1,80001d78 <growproc+0x5a>
  p->sz = sz;
    80001d44:	1602                	slli	a2,a2,0x20
    80001d46:	9201                	srli	a2,a2,0x20
    80001d48:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d4c:	4501                	li	a0,0
}
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6902                	ld	s2,0(sp)
    80001d56:	6105                	addi	sp,sp,32
    80001d58:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d5a:	9e25                	addw	a2,a2,s1
    80001d5c:	1602                	slli	a2,a2,0x20
    80001d5e:	9201                	srli	a2,a2,0x20
    80001d60:	1582                	slli	a1,a1,0x20
    80001d62:	9181                	srli	a1,a1,0x20
    80001d64:	6928                	ld	a0,80(a0)
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	6bc080e7          	jalr	1724(ra) # 80001422 <uvmalloc>
    80001d6e:	0005061b          	sext.w	a2,a0
    80001d72:	fa69                	bnez	a2,80001d44 <growproc+0x26>
      return -1;
    80001d74:	557d                	li	a0,-1
    80001d76:	bfe1                	j	80001d4e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d78:	9e25                	addw	a2,a2,s1
    80001d7a:	1602                	slli	a2,a2,0x20
    80001d7c:	9201                	srli	a2,a2,0x20
    80001d7e:	1582                	slli	a1,a1,0x20
    80001d80:	9181                	srli	a1,a1,0x20
    80001d82:	6928                	ld	a0,80(a0)
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	656080e7          	jalr	1622(ra) # 800013da <uvmdealloc>
    80001d8c:	0005061b          	sext.w	a2,a0
    80001d90:	bf55                	j	80001d44 <growproc+0x26>

0000000080001d92 <fork>:
{
    80001d92:	7179                	addi	sp,sp,-48
    80001d94:	f406                	sd	ra,40(sp)
    80001d96:	f022                	sd	s0,32(sp)
    80001d98:	ec26                	sd	s1,24(sp)
    80001d9a:	e84a                	sd	s2,16(sp)
    80001d9c:	e44e                	sd	s3,8(sp)
    80001d9e:	e052                	sd	s4,0(sp)
    80001da0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	c0e080e7          	jalr	-1010(ra) # 800019b0 <myproc>
    80001daa:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	e0e080e7          	jalr	-498(ra) # 80001bba <allocproc>
    80001db4:	10050b63          	beqz	a0,80001eca <fork+0x138>
    80001db8:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dba:	04893603          	ld	a2,72(s2)
    80001dbe:	692c                	ld	a1,80(a0)
    80001dc0:	05093503          	ld	a0,80(s2)
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	7aa080e7          	jalr	1962(ra) # 8000156e <uvmcopy>
    80001dcc:	04054663          	bltz	a0,80001e18 <fork+0x86>
  np->sz = p->sz;
    80001dd0:	04893783          	ld	a5,72(s2)
    80001dd4:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dd8:	05893683          	ld	a3,88(s2)
    80001ddc:	87b6                	mv	a5,a3
    80001dde:	0589b703          	ld	a4,88(s3)
    80001de2:	12068693          	addi	a3,a3,288
    80001de6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dea:	6788                	ld	a0,8(a5)
    80001dec:	6b8c                	ld	a1,16(a5)
    80001dee:	6f90                	ld	a2,24(a5)
    80001df0:	01073023          	sd	a6,0(a4)
    80001df4:	e708                	sd	a0,8(a4)
    80001df6:	eb0c                	sd	a1,16(a4)
    80001df8:	ef10                	sd	a2,24(a4)
    80001dfa:	02078793          	addi	a5,a5,32
    80001dfe:	02070713          	addi	a4,a4,32
    80001e02:	fed792e3          	bne	a5,a3,80001de6 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e06:	0589b783          	ld	a5,88(s3)
    80001e0a:	0607b823          	sd	zero,112(a5)
    80001e0e:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e12:	15000a13          	li	s4,336
    80001e16:	a03d                	j	80001e44 <fork+0xb2>
    freeproc(np);
    80001e18:	854e                	mv	a0,s3
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	d48080e7          	jalr	-696(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e22:	854e                	mv	a0,s3
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	e74080e7          	jalr	-396(ra) # 80000c98 <release>
    return -1;
    80001e2c:	5a7d                	li	s4,-1
    80001e2e:	a069                	j	80001eb8 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e30:	00002097          	auipc	ra,0x2
    80001e34:	718080e7          	jalr	1816(ra) # 80004548 <filedup>
    80001e38:	009987b3          	add	a5,s3,s1
    80001e3c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e3e:	04a1                	addi	s1,s1,8
    80001e40:	01448763          	beq	s1,s4,80001e4e <fork+0xbc>
    if(p->ofile[i])
    80001e44:	009907b3          	add	a5,s2,s1
    80001e48:	6388                	ld	a0,0(a5)
    80001e4a:	f17d                	bnez	a0,80001e30 <fork+0x9e>
    80001e4c:	bfcd                	j	80001e3e <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e4e:	15093503          	ld	a0,336(s2)
    80001e52:	00002097          	auipc	ra,0x2
    80001e56:	86c080e7          	jalr	-1940(ra) # 800036be <idup>
    80001e5a:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e5e:	4641                	li	a2,16
    80001e60:	15890593          	addi	a1,s2,344
    80001e64:	15898513          	addi	a0,s3,344
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	fca080e7          	jalr	-54(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e70:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e74:	854e                	mv	a0,s3
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	e22080e7          	jalr	-478(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e7e:	0000f497          	auipc	s1,0xf
    80001e82:	43a48493          	addi	s1,s1,1082 # 800112b8 <wait_lock>
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	d5c080e7          	jalr	-676(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e90:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e94:	8526                	mv	a0,s1
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	e02080e7          	jalr	-510(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e9e:	854e                	mv	a0,s3
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	d44080e7          	jalr	-700(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ea8:	478d                	li	a5,3
    80001eaa:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eae:	854e                	mv	a0,s3
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	de8080e7          	jalr	-536(ra) # 80000c98 <release>
}
    80001eb8:	8552                	mv	a0,s4
    80001eba:	70a2                	ld	ra,40(sp)
    80001ebc:	7402                	ld	s0,32(sp)
    80001ebe:	64e2                	ld	s1,24(sp)
    80001ec0:	6942                	ld	s2,16(sp)
    80001ec2:	69a2                	ld	s3,8(sp)
    80001ec4:	6a02                	ld	s4,0(sp)
    80001ec6:	6145                	addi	sp,sp,48
    80001ec8:	8082                	ret
    return -1;
    80001eca:	5a7d                	li	s4,-1
    80001ecc:	b7f5                	j	80001eb8 <fork+0x126>

0000000080001ece <scheduler>:
{
    80001ece:	7139                	addi	sp,sp,-64
    80001ed0:	fc06                	sd	ra,56(sp)
    80001ed2:	f822                	sd	s0,48(sp)
    80001ed4:	f426                	sd	s1,40(sp)
    80001ed6:	f04a                	sd	s2,32(sp)
    80001ed8:	ec4e                	sd	s3,24(sp)
    80001eda:	e852                	sd	s4,16(sp)
    80001edc:	e456                	sd	s5,8(sp)
    80001ede:	e05a                	sd	s6,0(sp)
    80001ee0:	0080                	addi	s0,sp,64
    80001ee2:	8792                	mv	a5,tp
  int id = r_tp();
    80001ee4:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ee6:	00779a93          	slli	s5,a5,0x7
    80001eea:	0000f717          	auipc	a4,0xf
    80001eee:	3b670713          	addi	a4,a4,950 # 800112a0 <pid_lock>
    80001ef2:	9756                	add	a4,a4,s5
    80001ef4:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ef8:	0000f717          	auipc	a4,0xf
    80001efc:	3e070713          	addi	a4,a4,992 # 800112d8 <cpus+0x8>
    80001f00:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f02:	498d                	li	s3,3
        p->state = RUNNING;
    80001f04:	4b11                	li	s6,4
        c->proc = p;
    80001f06:	079e                	slli	a5,a5,0x7
    80001f08:	0000fa17          	auipc	s4,0xf
    80001f0c:	398a0a13          	addi	s4,s4,920 # 800112a0 <pid_lock>
    80001f10:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f12:	00015917          	auipc	s2,0x15
    80001f16:	5be90913          	addi	s2,s2,1470 # 800174d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f1e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f22:	10079073          	csrw	sstatus,a5
    80001f26:	0000f497          	auipc	s1,0xf
    80001f2a:	7aa48493          	addi	s1,s1,1962 # 800116d0 <proc>
    80001f2e:	a03d                	j	80001f5c <scheduler+0x8e>
        p->state = RUNNING;
    80001f30:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f34:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f38:	06048593          	addi	a1,s1,96
    80001f3c:	8556                	mv	a0,s5
    80001f3e:	00000097          	auipc	ra,0x0
    80001f42:	74c080e7          	jalr	1868(ra) # 8000268a <swtch>
        c->proc = 0;
    80001f46:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f4a:	8526                	mv	a0,s1
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	d4c080e7          	jalr	-692(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f54:	17848493          	addi	s1,s1,376
    80001f58:	fd2481e3          	beq	s1,s2,80001f1a <scheduler+0x4c>
      acquire(&p->lock);
    80001f5c:	8526                	mv	a0,s1
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	c86080e7          	jalr	-890(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001f66:	4c9c                	lw	a5,24(s1)
    80001f68:	ff3791e3          	bne	a5,s3,80001f4a <scheduler+0x7c>
    80001f6c:	b7d1                	j	80001f30 <scheduler+0x62>

0000000080001f6e <scheduler_multiple>:
{
    80001f6e:	7139                	addi	sp,sp,-64
    80001f70:	fc06                	sd	ra,56(sp)
    80001f72:	f822                	sd	s0,48(sp)
    80001f74:	f426                	sd	s1,40(sp)
    80001f76:	f04a                	sd	s2,32(sp)
    80001f78:	ec4e                	sd	s3,24(sp)
    80001f7a:	e852                	sd	s4,16(sp)
    80001f7c:	e456                	sd	s5,8(sp)
    80001f7e:	e05a                	sd	s6,0(sp)
    80001f80:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f82:	8792                	mv	a5,tp
  int id = r_tp();
    80001f84:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f86:	00779a93          	slli	s5,a5,0x7
    80001f8a:	0000f717          	auipc	a4,0xf
    80001f8e:	31670713          	addi	a4,a4,790 # 800112a0 <pid_lock>
    80001f92:	9756                	add	a4,a4,s5
    80001f94:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f98:	0000f717          	auipc	a4,0xf
    80001f9c:	34070713          	addi	a4,a4,832 # 800112d8 <cpus+0x8>
    80001fa0:	9aba                	add	s5,s5,a4
        if(p->state == RUNNABLE) {
    80001fa2:	498d                	li	s3,3
          p->state = RUNNING;
    80001fa4:	4b11                	li	s6,4
          c->proc = p;
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000fa17          	auipc	s4,0xf
    80001fac:	2f8a0a13          	addi	s4,s4,760 # 800112a0 <pid_lock>
    80001fb0:	9a3e                	add	s4,s4,a5
      for(p = proc; p < &proc[NPROC]; p++) {
    80001fb2:	00015917          	auipc	s2,0x15
    80001fb6:	51e90913          	addi	s2,s2,1310 # 800174d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fbe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fc2:	10079073          	csrw	sstatus,a5
    80001fc6:	0000f497          	auipc	s1,0xf
    80001fca:	70a48493          	addi	s1,s1,1802 # 800116d0 <proc>
    80001fce:	a03d                	j	80001ffc <scheduler_multiple+0x8e>
          p->state = RUNNING;
    80001fd0:	0164ac23          	sw	s6,24(s1)
          c->proc = p;
    80001fd4:	029a3823          	sd	s1,48(s4)
          swtch(&c->context, &p->context);
    80001fd8:	06048593          	addi	a1,s1,96
    80001fdc:	8556                	mv	a0,s5
    80001fde:	00000097          	auipc	ra,0x0
    80001fe2:	6ac080e7          	jalr	1708(ra) # 8000268a <swtch>
          c->proc = 0;
    80001fe6:	020a3823          	sd	zero,48(s4)
        release(&p->lock);
    80001fea:	8526                	mv	a0,s1
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	cac080e7          	jalr	-852(ra) # 80000c98 <release>
      for(p = proc; p < &proc[NPROC]; p++) {
    80001ff4:	17848493          	addi	s1,s1,376
    80001ff8:	fd2481e3          	beq	s1,s2,80001fba <scheduler_multiple+0x4c>
        acquire(&p->lock);
    80001ffc:	8526                	mv	a0,s1
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	be6080e7          	jalr	-1050(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80002006:	4c9c                	lw	a5,24(s1)
    80002008:	ff3791e3          	bne	a5,s3,80001fea <scheduler_multiple+0x7c>
    8000200c:	b7d1                	j	80001fd0 <scheduler_multiple+0x62>

000000008000200e <sched>:
{
    8000200e:	7179                	addi	sp,sp,-48
    80002010:	f406                	sd	ra,40(sp)
    80002012:	f022                	sd	s0,32(sp)
    80002014:	ec26                	sd	s1,24(sp)
    80002016:	e84a                	sd	s2,16(sp)
    80002018:	e44e                	sd	s3,8(sp)
    8000201a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000201c:	00000097          	auipc	ra,0x0
    80002020:	994080e7          	jalr	-1644(ra) # 800019b0 <myproc>
    80002024:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	b44080e7          	jalr	-1212(ra) # 80000b6a <holding>
    8000202e:	c93d                	beqz	a0,800020a4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002030:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002032:	2781                	sext.w	a5,a5
    80002034:	079e                	slli	a5,a5,0x7
    80002036:	0000f717          	auipc	a4,0xf
    8000203a:	26a70713          	addi	a4,a4,618 # 800112a0 <pid_lock>
    8000203e:	97ba                	add	a5,a5,a4
    80002040:	0a87a703          	lw	a4,168(a5)
    80002044:	4785                	li	a5,1
    80002046:	06f71763          	bne	a4,a5,800020b4 <sched+0xa6>
  if(p->state == RUNNING)
    8000204a:	4c98                	lw	a4,24(s1)
    8000204c:	4791                	li	a5,4
    8000204e:	06f70b63          	beq	a4,a5,800020c4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002052:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002056:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002058:	efb5                	bnez	a5,800020d4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000205a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000205c:	0000f917          	auipc	s2,0xf
    80002060:	24490913          	addi	s2,s2,580 # 800112a0 <pid_lock>
    80002064:	2781                	sext.w	a5,a5
    80002066:	079e                	slli	a5,a5,0x7
    80002068:	97ca                	add	a5,a5,s2
    8000206a:	0ac7a983          	lw	s3,172(a5)
    8000206e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002070:	2781                	sext.w	a5,a5
    80002072:	079e                	slli	a5,a5,0x7
    80002074:	0000f597          	auipc	a1,0xf
    80002078:	26458593          	addi	a1,a1,612 # 800112d8 <cpus+0x8>
    8000207c:	95be                	add	a1,a1,a5
    8000207e:	06048513          	addi	a0,s1,96
    80002082:	00000097          	auipc	ra,0x0
    80002086:	608080e7          	jalr	1544(ra) # 8000268a <swtch>
    8000208a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000208c:	2781                	sext.w	a5,a5
    8000208e:	079e                	slli	a5,a5,0x7
    80002090:	97ca                	add	a5,a5,s2
    80002092:	0b37a623          	sw	s3,172(a5)
}
    80002096:	70a2                	ld	ra,40(sp)
    80002098:	7402                	ld	s0,32(sp)
    8000209a:	64e2                	ld	s1,24(sp)
    8000209c:	6942                	ld	s2,16(sp)
    8000209e:	69a2                	ld	s3,8(sp)
    800020a0:	6145                	addi	sp,sp,48
    800020a2:	8082                	ret
    panic("sched p->lock");
    800020a4:	00006517          	auipc	a0,0x6
    800020a8:	17450513          	addi	a0,a0,372 # 80008218 <digits+0x1d8>
    800020ac:	ffffe097          	auipc	ra,0xffffe
    800020b0:	492080e7          	jalr	1170(ra) # 8000053e <panic>
    panic("sched locks");
    800020b4:	00006517          	auipc	a0,0x6
    800020b8:	17450513          	addi	a0,a0,372 # 80008228 <digits+0x1e8>
    800020bc:	ffffe097          	auipc	ra,0xffffe
    800020c0:	482080e7          	jalr	1154(ra) # 8000053e <panic>
    panic("sched running");
    800020c4:	00006517          	auipc	a0,0x6
    800020c8:	17450513          	addi	a0,a0,372 # 80008238 <digits+0x1f8>
    800020cc:	ffffe097          	auipc	ra,0xffffe
    800020d0:	472080e7          	jalr	1138(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020d4:	00006517          	auipc	a0,0x6
    800020d8:	17450513          	addi	a0,a0,372 # 80008248 <digits+0x208>
    800020dc:	ffffe097          	auipc	ra,0xffffe
    800020e0:	462080e7          	jalr	1122(ra) # 8000053e <panic>

00000000800020e4 <yield>:
{
    800020e4:	1101                	addi	sp,sp,-32
    800020e6:	ec06                	sd	ra,24(sp)
    800020e8:	e822                	sd	s0,16(sp)
    800020ea:	e426                	sd	s1,8(sp)
    800020ec:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020ee:	00000097          	auipc	ra,0x0
    800020f2:	8c2080e7          	jalr	-1854(ra) # 800019b0 <myproc>
    800020f6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	aec080e7          	jalr	-1300(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002100:	478d                	li	a5,3
    80002102:	cc9c                	sw	a5,24(s1)
  sched();
    80002104:	00000097          	auipc	ra,0x0
    80002108:	f0a080e7          	jalr	-246(ra) # 8000200e <sched>
  release(&p->lock);
    8000210c:	8526                	mv	a0,s1
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	b8a080e7          	jalr	-1142(ra) # 80000c98 <release>
}
    80002116:	60e2                	ld	ra,24(sp)
    80002118:	6442                	ld	s0,16(sp)
    8000211a:	64a2                	ld	s1,8(sp)
    8000211c:	6105                	addi	sp,sp,32
    8000211e:	8082                	ret

0000000080002120 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002120:	7179                	addi	sp,sp,-48
    80002122:	f406                	sd	ra,40(sp)
    80002124:	f022                	sd	s0,32(sp)
    80002126:	ec26                	sd	s1,24(sp)
    80002128:	e84a                	sd	s2,16(sp)
    8000212a:	e44e                	sd	s3,8(sp)
    8000212c:	1800                	addi	s0,sp,48
    8000212e:	89aa                	mv	s3,a0
    80002130:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002132:	00000097          	auipc	ra,0x0
    80002136:	87e080e7          	jalr	-1922(ra) # 800019b0 <myproc>
    8000213a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	aa8080e7          	jalr	-1368(ra) # 80000be4 <acquire>
  release(lk);
    80002144:	854a                	mv	a0,s2
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	b52080e7          	jalr	-1198(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000214e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002152:	4789                	li	a5,2
    80002154:	cc9c                	sw	a5,24(s1)

  sched();
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	eb8080e7          	jalr	-328(ra) # 8000200e <sched>

  // Tidy up.
  p->chan = 0;
    8000215e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002162:	8526                	mv	a0,s1
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	b34080e7          	jalr	-1228(ra) # 80000c98 <release>
  acquire(lk);
    8000216c:	854a                	mv	a0,s2
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	a76080e7          	jalr	-1418(ra) # 80000be4 <acquire>
}
    80002176:	70a2                	ld	ra,40(sp)
    80002178:	7402                	ld	s0,32(sp)
    8000217a:	64e2                	ld	s1,24(sp)
    8000217c:	6942                	ld	s2,16(sp)
    8000217e:	69a2                	ld	s3,8(sp)
    80002180:	6145                	addi	sp,sp,48
    80002182:	8082                	ret

0000000080002184 <wait>:
{
    80002184:	715d                	addi	sp,sp,-80
    80002186:	e486                	sd	ra,72(sp)
    80002188:	e0a2                	sd	s0,64(sp)
    8000218a:	fc26                	sd	s1,56(sp)
    8000218c:	f84a                	sd	s2,48(sp)
    8000218e:	f44e                	sd	s3,40(sp)
    80002190:	f052                	sd	s4,32(sp)
    80002192:	ec56                	sd	s5,24(sp)
    80002194:	e85a                	sd	s6,16(sp)
    80002196:	e45e                	sd	s7,8(sp)
    80002198:	e062                	sd	s8,0(sp)
    8000219a:	0880                	addi	s0,sp,80
    8000219c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	812080e7          	jalr	-2030(ra) # 800019b0 <myproc>
    800021a6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021a8:	0000f517          	auipc	a0,0xf
    800021ac:	11050513          	addi	a0,a0,272 # 800112b8 <wait_lock>
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	a34080e7          	jalr	-1484(ra) # 80000be4 <acquire>
    havekids = 0;
    800021b8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800021ba:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800021bc:	00015997          	auipc	s3,0x15
    800021c0:	31498993          	addi	s3,s3,788 # 800174d0 <tickslock>
        havekids = 1;
    800021c4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021c6:	0000fc17          	auipc	s8,0xf
    800021ca:	0f2c0c13          	addi	s8,s8,242 # 800112b8 <wait_lock>
    havekids = 0;
    800021ce:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800021d0:	0000f497          	auipc	s1,0xf
    800021d4:	50048493          	addi	s1,s1,1280 # 800116d0 <proc>
    800021d8:	a0bd                	j	80002246 <wait+0xc2>
          pid = np->pid;
    800021da:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021de:	000b0e63          	beqz	s6,800021fa <wait+0x76>
    800021e2:	4691                	li	a3,4
    800021e4:	02c48613          	addi	a2,s1,44
    800021e8:	85da                	mv	a1,s6
    800021ea:	05093503          	ld	a0,80(s2)
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	484080e7          	jalr	1156(ra) # 80001672 <copyout>
    800021f6:	02054563          	bltz	a0,80002220 <wait+0x9c>
          freeproc(np);
    800021fa:	8526                	mv	a0,s1
    800021fc:	00000097          	auipc	ra,0x0
    80002200:	966080e7          	jalr	-1690(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002204:	8526                	mv	a0,s1
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	a92080e7          	jalr	-1390(ra) # 80000c98 <release>
          release(&wait_lock);
    8000220e:	0000f517          	auipc	a0,0xf
    80002212:	0aa50513          	addi	a0,a0,170 # 800112b8 <wait_lock>
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	a82080e7          	jalr	-1406(ra) # 80000c98 <release>
          return pid;
    8000221e:	a09d                	j	80002284 <wait+0x100>
            release(&np->lock);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	a76080e7          	jalr	-1418(ra) # 80000c98 <release>
            release(&wait_lock);
    8000222a:	0000f517          	auipc	a0,0xf
    8000222e:	08e50513          	addi	a0,a0,142 # 800112b8 <wait_lock>
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	a66080e7          	jalr	-1434(ra) # 80000c98 <release>
            return -1;
    8000223a:	59fd                	li	s3,-1
    8000223c:	a0a1                	j	80002284 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000223e:	17848493          	addi	s1,s1,376
    80002242:	03348463          	beq	s1,s3,8000226a <wait+0xe6>
      if(np->parent == p){
    80002246:	7c9c                	ld	a5,56(s1)
    80002248:	ff279be3          	bne	a5,s2,8000223e <wait+0xba>
        acquire(&np->lock);
    8000224c:	8526                	mv	a0,s1
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	996080e7          	jalr	-1642(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002256:	4c9c                	lw	a5,24(s1)
    80002258:	f94781e3          	beq	a5,s4,800021da <wait+0x56>
        release(&np->lock);
    8000225c:	8526                	mv	a0,s1
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	a3a080e7          	jalr	-1478(ra) # 80000c98 <release>
        havekids = 1;
    80002266:	8756                	mv	a4,s5
    80002268:	bfd9                	j	8000223e <wait+0xba>
    if(!havekids || p->killed){
    8000226a:	c701                	beqz	a4,80002272 <wait+0xee>
    8000226c:	02892783          	lw	a5,40(s2)
    80002270:	c79d                	beqz	a5,8000229e <wait+0x11a>
      release(&wait_lock);
    80002272:	0000f517          	auipc	a0,0xf
    80002276:	04650513          	addi	a0,a0,70 # 800112b8 <wait_lock>
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	a1e080e7          	jalr	-1506(ra) # 80000c98 <release>
      return -1;
    80002282:	59fd                	li	s3,-1
}
    80002284:	854e                	mv	a0,s3
    80002286:	60a6                	ld	ra,72(sp)
    80002288:	6406                	ld	s0,64(sp)
    8000228a:	74e2                	ld	s1,56(sp)
    8000228c:	7942                	ld	s2,48(sp)
    8000228e:	79a2                	ld	s3,40(sp)
    80002290:	7a02                	ld	s4,32(sp)
    80002292:	6ae2                	ld	s5,24(sp)
    80002294:	6b42                	ld	s6,16(sp)
    80002296:	6ba2                	ld	s7,8(sp)
    80002298:	6c02                	ld	s8,0(sp)
    8000229a:	6161                	addi	sp,sp,80
    8000229c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000229e:	85e2                	mv	a1,s8
    800022a0:	854a                	mv	a0,s2
    800022a2:	00000097          	auipc	ra,0x0
    800022a6:	e7e080e7          	jalr	-386(ra) # 80002120 <sleep>
    havekids = 0;
    800022aa:	b715                	j	800021ce <wait+0x4a>

00000000800022ac <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800022ac:	7139                	addi	sp,sp,-64
    800022ae:	fc06                	sd	ra,56(sp)
    800022b0:	f822                	sd	s0,48(sp)
    800022b2:	f426                	sd	s1,40(sp)
    800022b4:	f04a                	sd	s2,32(sp)
    800022b6:	ec4e                	sd	s3,24(sp)
    800022b8:	e852                	sd	s4,16(sp)
    800022ba:	e456                	sd	s5,8(sp)
    800022bc:	0080                	addi	s0,sp,64
    800022be:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800022c0:	0000f497          	auipc	s1,0xf
    800022c4:	41048493          	addi	s1,s1,1040 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800022c8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800022ca:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800022cc:	00015917          	auipc	s2,0x15
    800022d0:	20490913          	addi	s2,s2,516 # 800174d0 <tickslock>
    800022d4:	a821                	j	800022ec <wakeup+0x40>
        p->state = RUNNABLE;
    800022d6:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800022da:	8526                	mv	a0,s1
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	9bc080e7          	jalr	-1604(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022e4:	17848493          	addi	s1,s1,376
    800022e8:	03248463          	beq	s1,s2,80002310 <wakeup+0x64>
    if(p != myproc()){
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	6c4080e7          	jalr	1732(ra) # 800019b0 <myproc>
    800022f4:	fea488e3          	beq	s1,a0,800022e4 <wakeup+0x38>
      acquire(&p->lock);
    800022f8:	8526                	mv	a0,s1
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	8ea080e7          	jalr	-1814(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002302:	4c9c                	lw	a5,24(s1)
    80002304:	fd379be3          	bne	a5,s3,800022da <wakeup+0x2e>
    80002308:	709c                	ld	a5,32(s1)
    8000230a:	fd4798e3          	bne	a5,s4,800022da <wakeup+0x2e>
    8000230e:	b7e1                	j	800022d6 <wakeup+0x2a>
    }
  }
}
    80002310:	70e2                	ld	ra,56(sp)
    80002312:	7442                	ld	s0,48(sp)
    80002314:	74a2                	ld	s1,40(sp)
    80002316:	7902                	ld	s2,32(sp)
    80002318:	69e2                	ld	s3,24(sp)
    8000231a:	6a42                	ld	s4,16(sp)
    8000231c:	6aa2                	ld	s5,8(sp)
    8000231e:	6121                	addi	sp,sp,64
    80002320:	8082                	ret

0000000080002322 <reparent>:
{
    80002322:	7179                	addi	sp,sp,-48
    80002324:	f406                	sd	ra,40(sp)
    80002326:	f022                	sd	s0,32(sp)
    80002328:	ec26                	sd	s1,24(sp)
    8000232a:	e84a                	sd	s2,16(sp)
    8000232c:	e44e                	sd	s3,8(sp)
    8000232e:	e052                	sd	s4,0(sp)
    80002330:	1800                	addi	s0,sp,48
    80002332:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002334:	0000f497          	auipc	s1,0xf
    80002338:	39c48493          	addi	s1,s1,924 # 800116d0 <proc>
      pp->parent = initproc;
    8000233c:	00007a17          	auipc	s4,0x7
    80002340:	ceca0a13          	addi	s4,s4,-788 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002344:	00015997          	auipc	s3,0x15
    80002348:	18c98993          	addi	s3,s3,396 # 800174d0 <tickslock>
    8000234c:	a029                	j	80002356 <reparent+0x34>
    8000234e:	17848493          	addi	s1,s1,376
    80002352:	01348d63          	beq	s1,s3,8000236c <reparent+0x4a>
    if(pp->parent == p){
    80002356:	7c9c                	ld	a5,56(s1)
    80002358:	ff279be3          	bne	a5,s2,8000234e <reparent+0x2c>
      pp->parent = initproc;
    8000235c:	000a3503          	ld	a0,0(s4)
    80002360:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002362:	00000097          	auipc	ra,0x0
    80002366:	f4a080e7          	jalr	-182(ra) # 800022ac <wakeup>
    8000236a:	b7d5                	j	8000234e <reparent+0x2c>
}
    8000236c:	70a2                	ld	ra,40(sp)
    8000236e:	7402                	ld	s0,32(sp)
    80002370:	64e2                	ld	s1,24(sp)
    80002372:	6942                	ld	s2,16(sp)
    80002374:	69a2                	ld	s3,8(sp)
    80002376:	6a02                	ld	s4,0(sp)
    80002378:	6145                	addi	sp,sp,48
    8000237a:	8082                	ret

000000008000237c <exit>:
{
    8000237c:	7179                	addi	sp,sp,-48
    8000237e:	f406                	sd	ra,40(sp)
    80002380:	f022                	sd	s0,32(sp)
    80002382:	ec26                	sd	s1,24(sp)
    80002384:	e84a                	sd	s2,16(sp)
    80002386:	e44e                	sd	s3,8(sp)
    80002388:	e052                	sd	s4,0(sp)
    8000238a:	1800                	addi	s0,sp,48
    8000238c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	622080e7          	jalr	1570(ra) # 800019b0 <myproc>
  if(p == initproc)
    80002396:	00007797          	auipc	a5,0x7
    8000239a:	c927b783          	ld	a5,-878(a5) # 80009028 <initproc>
    8000239e:	00a78e63          	beq	a5,a0,800023ba <exit+0x3e>
    800023a2:	89aa                	mv	s3,a0
  p->endTime = ticks;
    800023a4:	00007797          	auipc	a5,0x7
    800023a8:	c8c7a783          	lw	a5,-884(a5) # 80009030 <ticks>
    800023ac:	16f52623          	sw	a5,364(a0)
  for(int fd = 0; fd < NOFILE; fd++){
    800023b0:	0d050493          	addi	s1,a0,208
    800023b4:	15050913          	addi	s2,a0,336
    800023b8:	a015                	j	800023dc <exit+0x60>
    panic("init exiting");
    800023ba:	00006517          	auipc	a0,0x6
    800023be:	ea650513          	addi	a0,a0,-346 # 80008260 <digits+0x220>
    800023c2:	ffffe097          	auipc	ra,0xffffe
    800023c6:	17c080e7          	jalr	380(ra) # 8000053e <panic>
      fileclose(f);
    800023ca:	00002097          	auipc	ra,0x2
    800023ce:	1d0080e7          	jalr	464(ra) # 8000459a <fileclose>
      p->ofile[fd] = 0;
    800023d2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800023d6:	04a1                	addi	s1,s1,8
    800023d8:	01248563          	beq	s1,s2,800023e2 <exit+0x66>
    if(p->ofile[fd]){
    800023dc:	6088                	ld	a0,0(s1)
    800023de:	f575                	bnez	a0,800023ca <exit+0x4e>
    800023e0:	bfdd                	j	800023d6 <exit+0x5a>
  begin_op();
    800023e2:	00002097          	auipc	ra,0x2
    800023e6:	cec080e7          	jalr	-788(ra) # 800040ce <begin_op>
  iput(p->cwd);
    800023ea:	1509b503          	ld	a0,336(s3)
    800023ee:	00001097          	auipc	ra,0x1
    800023f2:	4c8080e7          	jalr	1224(ra) # 800038b6 <iput>
  end_op();
    800023f6:	00002097          	auipc	ra,0x2
    800023fa:	d58080e7          	jalr	-680(ra) # 8000414e <end_op>
  p->cwd = 0;
    800023fe:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002402:	0000f497          	auipc	s1,0xf
    80002406:	eb648493          	addi	s1,s1,-330 # 800112b8 <wait_lock>
    8000240a:	8526                	mv	a0,s1
    8000240c:	ffffe097          	auipc	ra,0xffffe
    80002410:	7d8080e7          	jalr	2008(ra) # 80000be4 <acquire>
  reparent(p);
    80002414:	854e                	mv	a0,s3
    80002416:	00000097          	auipc	ra,0x0
    8000241a:	f0c080e7          	jalr	-244(ra) # 80002322 <reparent>
  wakeup(p->parent);
    8000241e:	0389b503          	ld	a0,56(s3)
    80002422:	00000097          	auipc	ra,0x0
    80002426:	e8a080e7          	jalr	-374(ra) # 800022ac <wakeup>
  acquire(&p->lock);
    8000242a:	854e                	mv	a0,s3
    8000242c:	ffffe097          	auipc	ra,0xffffe
    80002430:	7b8080e7          	jalr	1976(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002434:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002438:	4795                	li	a5,5
    8000243a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000243e:	8526                	mv	a0,s1
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	858080e7          	jalr	-1960(ra) # 80000c98 <release>
  sched();
    80002448:	00000097          	auipc	ra,0x0
    8000244c:	bc6080e7          	jalr	-1082(ra) # 8000200e <sched>
  panic("zombie exit");
    80002450:	00006517          	auipc	a0,0x6
    80002454:	e2050513          	addi	a0,a0,-480 # 80008270 <digits+0x230>
    80002458:	ffffe097          	auipc	ra,0xffffe
    8000245c:	0e6080e7          	jalr	230(ra) # 8000053e <panic>

0000000080002460 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002460:	7179                	addi	sp,sp,-48
    80002462:	f406                	sd	ra,40(sp)
    80002464:	f022                	sd	s0,32(sp)
    80002466:	ec26                	sd	s1,24(sp)
    80002468:	e84a                	sd	s2,16(sp)
    8000246a:	e44e                	sd	s3,8(sp)
    8000246c:	1800                	addi	s0,sp,48
    8000246e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002470:	0000f497          	auipc	s1,0xf
    80002474:	26048493          	addi	s1,s1,608 # 800116d0 <proc>
    80002478:	00015997          	auipc	s3,0x15
    8000247c:	05898993          	addi	s3,s3,88 # 800174d0 <tickslock>
    acquire(&p->lock);
    80002480:	8526                	mv	a0,s1
    80002482:	ffffe097          	auipc	ra,0xffffe
    80002486:	762080e7          	jalr	1890(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000248a:	589c                	lw	a5,48(s1)
    8000248c:	01278d63          	beq	a5,s2,800024a6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002490:	8526                	mv	a0,s1
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	806080e7          	jalr	-2042(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000249a:	17848493          	addi	s1,s1,376
    8000249e:	ff3491e3          	bne	s1,s3,80002480 <kill+0x20>
  }
  return -1;
    800024a2:	557d                	li	a0,-1
    800024a4:	a829                	j	800024be <kill+0x5e>
      p->killed = 1;
    800024a6:	4785                	li	a5,1
    800024a8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024aa:	4c98                	lw	a4,24(s1)
    800024ac:	4789                	li	a5,2
    800024ae:	00f70f63          	beq	a4,a5,800024cc <kill+0x6c>
      release(&p->lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	7e4080e7          	jalr	2020(ra) # 80000c98 <release>
      return 0;
    800024bc:	4501                	li	a0,0
}
    800024be:	70a2                	ld	ra,40(sp)
    800024c0:	7402                	ld	s0,32(sp)
    800024c2:	64e2                	ld	s1,24(sp)
    800024c4:	6942                	ld	s2,16(sp)
    800024c6:	69a2                	ld	s3,8(sp)
    800024c8:	6145                	addi	sp,sp,48
    800024ca:	8082                	ret
        p->state = RUNNABLE;
    800024cc:	478d                	li	a5,3
    800024ce:	cc9c                	sw	a5,24(s1)
    800024d0:	b7cd                	j	800024b2 <kill+0x52>

00000000800024d2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024d2:	7179                	addi	sp,sp,-48
    800024d4:	f406                	sd	ra,40(sp)
    800024d6:	f022                	sd	s0,32(sp)
    800024d8:	ec26                	sd	s1,24(sp)
    800024da:	e84a                	sd	s2,16(sp)
    800024dc:	e44e                	sd	s3,8(sp)
    800024de:	e052                	sd	s4,0(sp)
    800024e0:	1800                	addi	s0,sp,48
    800024e2:	84aa                	mv	s1,a0
    800024e4:	892e                	mv	s2,a1
    800024e6:	89b2                	mv	s3,a2
    800024e8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	4c6080e7          	jalr	1222(ra) # 800019b0 <myproc>
  if(user_dst){
    800024f2:	c08d                	beqz	s1,80002514 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024f4:	86d2                	mv	a3,s4
    800024f6:	864e                	mv	a2,s3
    800024f8:	85ca                	mv	a1,s2
    800024fa:	6928                	ld	a0,80(a0)
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	176080e7          	jalr	374(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002504:	70a2                	ld	ra,40(sp)
    80002506:	7402                	ld	s0,32(sp)
    80002508:	64e2                	ld	s1,24(sp)
    8000250a:	6942                	ld	s2,16(sp)
    8000250c:	69a2                	ld	s3,8(sp)
    8000250e:	6a02                	ld	s4,0(sp)
    80002510:	6145                	addi	sp,sp,48
    80002512:	8082                	ret
    memmove((char *)dst, src, len);
    80002514:	000a061b          	sext.w	a2,s4
    80002518:	85ce                	mv	a1,s3
    8000251a:	854a                	mv	a0,s2
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	824080e7          	jalr	-2012(ra) # 80000d40 <memmove>
    return 0;
    80002524:	8526                	mv	a0,s1
    80002526:	bff9                	j	80002504 <either_copyout+0x32>

0000000080002528 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002528:	7179                	addi	sp,sp,-48
    8000252a:	f406                	sd	ra,40(sp)
    8000252c:	f022                	sd	s0,32(sp)
    8000252e:	ec26                	sd	s1,24(sp)
    80002530:	e84a                	sd	s2,16(sp)
    80002532:	e44e                	sd	s3,8(sp)
    80002534:	e052                	sd	s4,0(sp)
    80002536:	1800                	addi	s0,sp,48
    80002538:	892a                	mv	s2,a0
    8000253a:	84ae                	mv	s1,a1
    8000253c:	89b2                	mv	s3,a2
    8000253e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002540:	fffff097          	auipc	ra,0xfffff
    80002544:	470080e7          	jalr	1136(ra) # 800019b0 <myproc>
  if(user_src){
    80002548:	c08d                	beqz	s1,8000256a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000254a:	86d2                	mv	a3,s4
    8000254c:	864e                	mv	a2,s3
    8000254e:	85ca                	mv	a1,s2
    80002550:	6928                	ld	a0,80(a0)
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	1ac080e7          	jalr	428(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000255a:	70a2                	ld	ra,40(sp)
    8000255c:	7402                	ld	s0,32(sp)
    8000255e:	64e2                	ld	s1,24(sp)
    80002560:	6942                	ld	s2,16(sp)
    80002562:	69a2                	ld	s3,8(sp)
    80002564:	6a02                	ld	s4,0(sp)
    80002566:	6145                	addi	sp,sp,48
    80002568:	8082                	ret
    memmove(dst, (char*)src, len);
    8000256a:	000a061b          	sext.w	a2,s4
    8000256e:	85ce                	mv	a1,s3
    80002570:	854a                	mv	a0,s2
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	7ce080e7          	jalr	1998(ra) # 80000d40 <memmove>
    return 0;
    8000257a:	8526                	mv	a0,s1
    8000257c:	bff9                	j	8000255a <either_copyin+0x32>

000000008000257e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000257e:	715d                	addi	sp,sp,-80
    80002580:	e486                	sd	ra,72(sp)
    80002582:	e0a2                	sd	s0,64(sp)
    80002584:	fc26                	sd	s1,56(sp)
    80002586:	f84a                	sd	s2,48(sp)
    80002588:	f44e                	sd	s3,40(sp)
    8000258a:	f052                	sd	s4,32(sp)
    8000258c:	ec56                	sd	s5,24(sp)
    8000258e:	e85a                	sd	s6,16(sp)
    80002590:	e45e                	sd	s7,8(sp)
    80002592:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002594:	00006517          	auipc	a0,0x6
    80002598:	b3450513          	addi	a0,a0,-1228 # 800080c8 <digits+0x88>
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	fec080e7          	jalr	-20(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025a4:	0000f497          	auipc	s1,0xf
    800025a8:	28448493          	addi	s1,s1,644 # 80011828 <proc+0x158>
    800025ac:	00015917          	auipc	s2,0x15
    800025b0:	07c90913          	addi	s2,s2,124 # 80017628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025b6:	00006997          	auipc	s3,0x6
    800025ba:	cca98993          	addi	s3,s3,-822 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025be:	00006a97          	auipc	s5,0x6
    800025c2:	ccaa8a93          	addi	s5,s5,-822 # 80008288 <digits+0x248>
    printf("\n");
    800025c6:	00006a17          	auipc	s4,0x6
    800025ca:	b02a0a13          	addi	s4,s4,-1278 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ce:	00006b97          	auipc	s7,0x6
    800025d2:	cf2b8b93          	addi	s7,s7,-782 # 800082c0 <states.1723>
    800025d6:	a00d                	j	800025f8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025d8:	ed86a583          	lw	a1,-296(a3)
    800025dc:	8556                	mv	a0,s5
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	faa080e7          	jalr	-86(ra) # 80000588 <printf>
    printf("\n");
    800025e6:	8552                	mv	a0,s4
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	fa0080e7          	jalr	-96(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f0:	17848493          	addi	s1,s1,376
    800025f4:	03248163          	beq	s1,s2,80002616 <procdump+0x98>
    if(p->state == UNUSED)
    800025f8:	86a6                	mv	a3,s1
    800025fa:	ec04a783          	lw	a5,-320(s1)
    800025fe:	dbed                	beqz	a5,800025f0 <procdump+0x72>
      state = "???";
    80002600:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002602:	fcfb6be3          	bltu	s6,a5,800025d8 <procdump+0x5a>
    80002606:	1782                	slli	a5,a5,0x20
    80002608:	9381                	srli	a5,a5,0x20
    8000260a:	078e                	slli	a5,a5,0x3
    8000260c:	97de                	add	a5,a5,s7
    8000260e:	6390                	ld	a2,0(a5)
    80002610:	f661                	bnez	a2,800025d8 <procdump+0x5a>
      state = "???";
    80002612:	864e                	mv	a2,s3
    80002614:	b7d1                	j	800025d8 <procdump+0x5a>
  }
}
    80002616:	60a6                	ld	ra,72(sp)
    80002618:	6406                	ld	s0,64(sp)
    8000261a:	74e2                	ld	s1,56(sp)
    8000261c:	7942                	ld	s2,48(sp)
    8000261e:	79a2                	ld	s3,40(sp)
    80002620:	7a02                	ld	s4,32(sp)
    80002622:	6ae2                	ld	s5,24(sp)
    80002624:	6b42                	ld	s6,16(sp)
    80002626:	6ba2                	ld	s7,8(sp)
    80002628:	6161                	addi	sp,sp,80
    8000262a:	8082                	ret

000000008000262c <increaseRuntime>:

// This function is executed after every CPU cycle with every ticks
// Iterates through each process & increases the run time of every running process.
void increaseRuntime() {
    8000262c:	7179                	addi	sp,sp,-48
    8000262e:	f406                	sd	ra,40(sp)
    80002630:	f022                	sd	s0,32(sp)
    80002632:	ec26                	sd	s1,24(sp)
    80002634:	e84a                	sd	s2,16(sp)
    80002636:	e44e                	sd	s3,8(sp)
    80002638:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p<&proc[NPROC]; p++) {
    8000263a:	0000f497          	auipc	s1,0xf
    8000263e:	09648493          	addi	s1,s1,150 # 800116d0 <proc>
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002642:	4991                	li	s3,4
  for (p = proc; p<&proc[NPROC]; p++) {
    80002644:	00015917          	auipc	s2,0x15
    80002648:	e8c90913          	addi	s2,s2,-372 # 800174d0 <tickslock>
    8000264c:	a811                	j	80002660 <increaseRuntime+0x34>
      p->runTime++;
    
    release(&p->lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	648080e7          	jalr	1608(ra) # 80000c98 <release>
  for (p = proc; p<&proc[NPROC]; p++) {
    80002658:	17848493          	addi	s1,s1,376
    8000265c:	03248063          	beq	s1,s2,8000267c <increaseRuntime+0x50>
    acquire(&p->lock);
    80002660:	8526                	mv	a0,s1
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	582080e7          	jalr	1410(ra) # 80000be4 <acquire>
    if (p->state == RUNNING)
    8000266a:	4c9c                	lw	a5,24(s1)
    8000266c:	ff3791e3          	bne	a5,s3,8000264e <increaseRuntime+0x22>
      p->runTime++;
    80002670:	1704a783          	lw	a5,368(s1)
    80002674:	2785                	addiw	a5,a5,1
    80002676:	16f4a823          	sw	a5,368(s1)
    8000267a:	bfd1                	j	8000264e <increaseRuntime+0x22>
  }
}
    8000267c:	70a2                	ld	ra,40(sp)
    8000267e:	7402                	ld	s0,32(sp)
    80002680:	64e2                	ld	s1,24(sp)
    80002682:	6942                	ld	s2,16(sp)
    80002684:	69a2                	ld	s3,8(sp)
    80002686:	6145                	addi	sp,sp,48
    80002688:	8082                	ret

000000008000268a <swtch>:
    8000268a:	00153023          	sd	ra,0(a0)
    8000268e:	00253423          	sd	sp,8(a0)
    80002692:	e900                	sd	s0,16(a0)
    80002694:	ed04                	sd	s1,24(a0)
    80002696:	03253023          	sd	s2,32(a0)
    8000269a:	03353423          	sd	s3,40(a0)
    8000269e:	03453823          	sd	s4,48(a0)
    800026a2:	03553c23          	sd	s5,56(a0)
    800026a6:	05653023          	sd	s6,64(a0)
    800026aa:	05753423          	sd	s7,72(a0)
    800026ae:	05853823          	sd	s8,80(a0)
    800026b2:	05953c23          	sd	s9,88(a0)
    800026b6:	07a53023          	sd	s10,96(a0)
    800026ba:	07b53423          	sd	s11,104(a0)
    800026be:	0005b083          	ld	ra,0(a1)
    800026c2:	0085b103          	ld	sp,8(a1)
    800026c6:	6980                	ld	s0,16(a1)
    800026c8:	6d84                	ld	s1,24(a1)
    800026ca:	0205b903          	ld	s2,32(a1)
    800026ce:	0285b983          	ld	s3,40(a1)
    800026d2:	0305ba03          	ld	s4,48(a1)
    800026d6:	0385ba83          	ld	s5,56(a1)
    800026da:	0405bb03          	ld	s6,64(a1)
    800026de:	0485bb83          	ld	s7,72(a1)
    800026e2:	0505bc03          	ld	s8,80(a1)
    800026e6:	0585bc83          	ld	s9,88(a1)
    800026ea:	0605bd03          	ld	s10,96(a1)
    800026ee:	0685bd83          	ld	s11,104(a1)
    800026f2:	8082                	ret

00000000800026f4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026f4:	1141                	addi	sp,sp,-16
    800026f6:	e406                	sd	ra,8(sp)
    800026f8:	e022                	sd	s0,0(sp)
    800026fa:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026fc:	00006597          	auipc	a1,0x6
    80002700:	bf458593          	addi	a1,a1,-1036 # 800082f0 <states.1723+0x30>
    80002704:	00015517          	auipc	a0,0x15
    80002708:	dcc50513          	addi	a0,a0,-564 # 800174d0 <tickslock>
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	448080e7          	jalr	1096(ra) # 80000b54 <initlock>
}
    80002714:	60a2                	ld	ra,8(sp)
    80002716:	6402                	ld	s0,0(sp)
    80002718:	0141                	addi	sp,sp,16
    8000271a:	8082                	ret

000000008000271c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000271c:	1141                	addi	sp,sp,-16
    8000271e:	e422                	sd	s0,8(sp)
    80002720:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002722:	00003797          	auipc	a5,0x3
    80002726:	48e78793          	addi	a5,a5,1166 # 80005bb0 <kernelvec>
    8000272a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000272e:	6422                	ld	s0,8(sp)
    80002730:	0141                	addi	sp,sp,16
    80002732:	8082                	ret

0000000080002734 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002734:	1141                	addi	sp,sp,-16
    80002736:	e406                	sd	ra,8(sp)
    80002738:	e022                	sd	s0,0(sp)
    8000273a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000273c:	fffff097          	auipc	ra,0xfffff
    80002740:	274080e7          	jalr	628(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002744:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002748:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000274a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000274e:	00005617          	auipc	a2,0x5
    80002752:	8b260613          	addi	a2,a2,-1870 # 80007000 <_trampoline>
    80002756:	00005697          	auipc	a3,0x5
    8000275a:	8aa68693          	addi	a3,a3,-1878 # 80007000 <_trampoline>
    8000275e:	8e91                	sub	a3,a3,a2
    80002760:	040007b7          	lui	a5,0x4000
    80002764:	17fd                	addi	a5,a5,-1
    80002766:	07b2                	slli	a5,a5,0xc
    80002768:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000276a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000276e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002770:	180026f3          	csrr	a3,satp
    80002774:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002776:	6d38                	ld	a4,88(a0)
    80002778:	6134                	ld	a3,64(a0)
    8000277a:	6585                	lui	a1,0x1
    8000277c:	96ae                	add	a3,a3,a1
    8000277e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002780:	6d38                	ld	a4,88(a0)
    80002782:	00000697          	auipc	a3,0x0
    80002786:	14668693          	addi	a3,a3,326 # 800028c8 <usertrap>
    8000278a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000278c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000278e:	8692                	mv	a3,tp
    80002790:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002792:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002796:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000279a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000279e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027a2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027a4:	6f18                	ld	a4,24(a4)
    800027a6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027aa:	692c                	ld	a1,80(a0)
    800027ac:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027ae:	00005717          	auipc	a4,0x5
    800027b2:	8e270713          	addi	a4,a4,-1822 # 80007090 <userret>
    800027b6:	8f11                	sub	a4,a4,a2
    800027b8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027ba:	577d                	li	a4,-1
    800027bc:	177e                	slli	a4,a4,0x3f
    800027be:	8dd9                	or	a1,a1,a4
    800027c0:	02000537          	lui	a0,0x2000
    800027c4:	157d                	addi	a0,a0,-1
    800027c6:	0536                	slli	a0,a0,0xd
    800027c8:	9782                	jalr	a5
}
    800027ca:	60a2                	ld	ra,8(sp)
    800027cc:	6402                	ld	s0,0(sp)
    800027ce:	0141                	addi	sp,sp,16
    800027d0:	8082                	ret

00000000800027d2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027d2:	1101                	addi	sp,sp,-32
    800027d4:	ec06                	sd	ra,24(sp)
    800027d6:	e822                	sd	s0,16(sp)
    800027d8:	e426                	sd	s1,8(sp)
    800027da:	e04a                	sd	s2,0(sp)
    800027dc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027de:	00015917          	auipc	s2,0x15
    800027e2:	cf290913          	addi	s2,s2,-782 # 800174d0 <tickslock>
    800027e6:	854a                	mv	a0,s2
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	3fc080e7          	jalr	1020(ra) # 80000be4 <acquire>
  ticks++;
    800027f0:	00007497          	auipc	s1,0x7
    800027f4:	84048493          	addi	s1,s1,-1984 # 80009030 <ticks>
    800027f8:	409c                	lw	a5,0(s1)
    800027fa:	2785                	addiw	a5,a5,1
    800027fc:	c09c                	sw	a5,0(s1)
  increaseRuntime();
    800027fe:	00000097          	auipc	ra,0x0
    80002802:	e2e080e7          	jalr	-466(ra) # 8000262c <increaseRuntime>
  wakeup(&ticks);
    80002806:	8526                	mv	a0,s1
    80002808:	00000097          	auipc	ra,0x0
    8000280c:	aa4080e7          	jalr	-1372(ra) # 800022ac <wakeup>
  release(&tickslock);
    80002810:	854a                	mv	a0,s2
    80002812:	ffffe097          	auipc	ra,0xffffe
    80002816:	486080e7          	jalr	1158(ra) # 80000c98 <release>
}
    8000281a:	60e2                	ld	ra,24(sp)
    8000281c:	6442                	ld	s0,16(sp)
    8000281e:	64a2                	ld	s1,8(sp)
    80002820:	6902                	ld	s2,0(sp)
    80002822:	6105                	addi	sp,sp,32
    80002824:	8082                	ret

0000000080002826 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002826:	1101                	addi	sp,sp,-32
    80002828:	ec06                	sd	ra,24(sp)
    8000282a:	e822                	sd	s0,16(sp)
    8000282c:	e426                	sd	s1,8(sp)
    8000282e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002830:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002834:	00074d63          	bltz	a4,8000284e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002838:	57fd                	li	a5,-1
    8000283a:	17fe                	slli	a5,a5,0x3f
    8000283c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000283e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002840:	06f70363          	beq	a4,a5,800028a6 <devintr+0x80>
  }
}
    80002844:	60e2                	ld	ra,24(sp)
    80002846:	6442                	ld	s0,16(sp)
    80002848:	64a2                	ld	s1,8(sp)
    8000284a:	6105                	addi	sp,sp,32
    8000284c:	8082                	ret
     (scause & 0xff) == 9){
    8000284e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002852:	46a5                	li	a3,9
    80002854:	fed792e3          	bne	a5,a3,80002838 <devintr+0x12>
    int irq = plic_claim();
    80002858:	00003097          	auipc	ra,0x3
    8000285c:	460080e7          	jalr	1120(ra) # 80005cb8 <plic_claim>
    80002860:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002862:	47a9                	li	a5,10
    80002864:	02f50763          	beq	a0,a5,80002892 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002868:	4785                	li	a5,1
    8000286a:	02f50963          	beq	a0,a5,8000289c <devintr+0x76>
    return 1;
    8000286e:	4505                	li	a0,1
    } else if(irq){
    80002870:	d8f1                	beqz	s1,80002844 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002872:	85a6                	mv	a1,s1
    80002874:	00006517          	auipc	a0,0x6
    80002878:	a8450513          	addi	a0,a0,-1404 # 800082f8 <states.1723+0x38>
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	d0c080e7          	jalr	-756(ra) # 80000588 <printf>
      plic_complete(irq);
    80002884:	8526                	mv	a0,s1
    80002886:	00003097          	auipc	ra,0x3
    8000288a:	456080e7          	jalr	1110(ra) # 80005cdc <plic_complete>
    return 1;
    8000288e:	4505                	li	a0,1
    80002890:	bf55                	j	80002844 <devintr+0x1e>
      uartintr();
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	116080e7          	jalr	278(ra) # 800009a8 <uartintr>
    8000289a:	b7ed                	j	80002884 <devintr+0x5e>
      virtio_disk_intr();
    8000289c:	00004097          	auipc	ra,0x4
    800028a0:	920080e7          	jalr	-1760(ra) # 800061bc <virtio_disk_intr>
    800028a4:	b7c5                	j	80002884 <devintr+0x5e>
    if(cpuid() == 0){
    800028a6:	fffff097          	auipc	ra,0xfffff
    800028aa:	0de080e7          	jalr	222(ra) # 80001984 <cpuid>
    800028ae:	c901                	beqz	a0,800028be <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028b0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028b4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028b6:	14479073          	csrw	sip,a5
    return 2;
    800028ba:	4509                	li	a0,2
    800028bc:	b761                	j	80002844 <devintr+0x1e>
      clockintr();
    800028be:	00000097          	auipc	ra,0x0
    800028c2:	f14080e7          	jalr	-236(ra) # 800027d2 <clockintr>
    800028c6:	b7ed                	j	800028b0 <devintr+0x8a>

00000000800028c8 <usertrap>:
{
    800028c8:	1101                	addi	sp,sp,-32
    800028ca:	ec06                	sd	ra,24(sp)
    800028cc:	e822                	sd	s0,16(sp)
    800028ce:	e426                	sd	s1,8(sp)
    800028d0:	e04a                	sd	s2,0(sp)
    800028d2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028d8:	1007f793          	andi	a5,a5,256
    800028dc:	e3ad                	bnez	a5,8000293e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028de:	00003797          	auipc	a5,0x3
    800028e2:	2d278793          	addi	a5,a5,722 # 80005bb0 <kernelvec>
    800028e6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028ea:	fffff097          	auipc	ra,0xfffff
    800028ee:	0c6080e7          	jalr	198(ra) # 800019b0 <myproc>
    800028f2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028f4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028f6:	14102773          	csrr	a4,sepc
    800028fa:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028fc:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002900:	47a1                	li	a5,8
    80002902:	04f71c63          	bne	a4,a5,8000295a <usertrap+0x92>
    if(p->killed)
    80002906:	551c                	lw	a5,40(a0)
    80002908:	e3b9                	bnez	a5,8000294e <usertrap+0x86>
    p->trapframe->epc += 4;
    8000290a:	6cb8                	ld	a4,88(s1)
    8000290c:	6f1c                	ld	a5,24(a4)
    8000290e:	0791                	addi	a5,a5,4
    80002910:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002912:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002916:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000291a:	10079073          	csrw	sstatus,a5
    syscall();
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	2e0080e7          	jalr	736(ra) # 80002bfe <syscall>
  if(p->killed)
    80002926:	549c                	lw	a5,40(s1)
    80002928:	ebc1                	bnez	a5,800029b8 <usertrap+0xf0>
  usertrapret();
    8000292a:	00000097          	auipc	ra,0x0
    8000292e:	e0a080e7          	jalr	-502(ra) # 80002734 <usertrapret>
}
    80002932:	60e2                	ld	ra,24(sp)
    80002934:	6442                	ld	s0,16(sp)
    80002936:	64a2                	ld	s1,8(sp)
    80002938:	6902                	ld	s2,0(sp)
    8000293a:	6105                	addi	sp,sp,32
    8000293c:	8082                	ret
    panic("usertrap: not from user mode");
    8000293e:	00006517          	auipc	a0,0x6
    80002942:	9da50513          	addi	a0,a0,-1574 # 80008318 <states.1723+0x58>
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	bf8080e7          	jalr	-1032(ra) # 8000053e <panic>
      exit(-1);
    8000294e:	557d                	li	a0,-1
    80002950:	00000097          	auipc	ra,0x0
    80002954:	a2c080e7          	jalr	-1492(ra) # 8000237c <exit>
    80002958:	bf4d                	j	8000290a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000295a:	00000097          	auipc	ra,0x0
    8000295e:	ecc080e7          	jalr	-308(ra) # 80002826 <devintr>
    80002962:	892a                	mv	s2,a0
    80002964:	c501                	beqz	a0,8000296c <usertrap+0xa4>
  if(p->killed)
    80002966:	549c                	lw	a5,40(s1)
    80002968:	c3a1                	beqz	a5,800029a8 <usertrap+0xe0>
    8000296a:	a815                	j	8000299e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000296c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002970:	5890                	lw	a2,48(s1)
    80002972:	00006517          	auipc	a0,0x6
    80002976:	9c650513          	addi	a0,a0,-1594 # 80008338 <states.1723+0x78>
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	c0e080e7          	jalr	-1010(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002982:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002986:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000298a:	00006517          	auipc	a0,0x6
    8000298e:	9de50513          	addi	a0,a0,-1570 # 80008368 <states.1723+0xa8>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	bf6080e7          	jalr	-1034(ra) # 80000588 <printf>
    p->killed = 1;
    8000299a:	4785                	li	a5,1
    8000299c:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000299e:	557d                	li	a0,-1
    800029a0:	00000097          	auipc	ra,0x0
    800029a4:	9dc080e7          	jalr	-1572(ra) # 8000237c <exit>
  if(which_dev == 2)
    800029a8:	4789                	li	a5,2
    800029aa:	f8f910e3          	bne	s2,a5,8000292a <usertrap+0x62>
    yield();
    800029ae:	fffff097          	auipc	ra,0xfffff
    800029b2:	736080e7          	jalr	1846(ra) # 800020e4 <yield>
    800029b6:	bf95                	j	8000292a <usertrap+0x62>
  int which_dev = 0;
    800029b8:	4901                	li	s2,0
    800029ba:	b7d5                	j	8000299e <usertrap+0xd6>

00000000800029bc <kerneltrap>:
{
    800029bc:	7179                	addi	sp,sp,-48
    800029be:	f406                	sd	ra,40(sp)
    800029c0:	f022                	sd	s0,32(sp)
    800029c2:	ec26                	sd	s1,24(sp)
    800029c4:	e84a                	sd	s2,16(sp)
    800029c6:	e44e                	sd	s3,8(sp)
    800029c8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ca:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ce:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029d2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029d6:	1004f793          	andi	a5,s1,256
    800029da:	cb85                	beqz	a5,80002a0a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029dc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029e0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029e2:	ef85                	bnez	a5,80002a1a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029e4:	00000097          	auipc	ra,0x0
    800029e8:	e42080e7          	jalr	-446(ra) # 80002826 <devintr>
    800029ec:	cd1d                	beqz	a0,80002a2a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029ee:	4789                	li	a5,2
    800029f0:	06f50a63          	beq	a0,a5,80002a64 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029f4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029f8:	10049073          	csrw	sstatus,s1
}
    800029fc:	70a2                	ld	ra,40(sp)
    800029fe:	7402                	ld	s0,32(sp)
    80002a00:	64e2                	ld	s1,24(sp)
    80002a02:	6942                	ld	s2,16(sp)
    80002a04:	69a2                	ld	s3,8(sp)
    80002a06:	6145                	addi	sp,sp,48
    80002a08:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a0a:	00006517          	auipc	a0,0x6
    80002a0e:	97e50513          	addi	a0,a0,-1666 # 80008388 <states.1723+0xc8>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	b2c080e7          	jalr	-1236(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a1a:	00006517          	auipc	a0,0x6
    80002a1e:	99650513          	addi	a0,a0,-1642 # 800083b0 <states.1723+0xf0>
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	b1c080e7          	jalr	-1252(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a2a:	85ce                	mv	a1,s3
    80002a2c:	00006517          	auipc	a0,0x6
    80002a30:	9a450513          	addi	a0,a0,-1628 # 800083d0 <states.1723+0x110>
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	b54080e7          	jalr	-1196(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a3c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a40:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a44:	00006517          	auipc	a0,0x6
    80002a48:	99c50513          	addi	a0,a0,-1636 # 800083e0 <states.1723+0x120>
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	b3c080e7          	jalr	-1220(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a54:	00006517          	auipc	a0,0x6
    80002a58:	9a450513          	addi	a0,a0,-1628 # 800083f8 <states.1723+0x138>
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	ae2080e7          	jalr	-1310(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a64:	fffff097          	auipc	ra,0xfffff
    80002a68:	f4c080e7          	jalr	-180(ra) # 800019b0 <myproc>
    80002a6c:	d541                	beqz	a0,800029f4 <kerneltrap+0x38>
    80002a6e:	fffff097          	auipc	ra,0xfffff
    80002a72:	f42080e7          	jalr	-190(ra) # 800019b0 <myproc>
    80002a76:	4d18                	lw	a4,24(a0)
    80002a78:	4791                	li	a5,4
    80002a7a:	f6f71de3          	bne	a4,a5,800029f4 <kerneltrap+0x38>
    yield();
    80002a7e:	fffff097          	auipc	ra,0xfffff
    80002a82:	666080e7          	jalr	1638(ra) # 800020e4 <yield>
    80002a86:	b7bd                	j	800029f4 <kerneltrap+0x38>

0000000080002a88 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a88:	1101                	addi	sp,sp,-32
    80002a8a:	ec06                	sd	ra,24(sp)
    80002a8c:	e822                	sd	s0,16(sp)
    80002a8e:	e426                	sd	s1,8(sp)
    80002a90:	1000                	addi	s0,sp,32
    80002a92:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a94:	fffff097          	auipc	ra,0xfffff
    80002a98:	f1c080e7          	jalr	-228(ra) # 800019b0 <myproc>
  switch (n) {
    80002a9c:	4795                	li	a5,5
    80002a9e:	0497e163          	bltu	a5,s1,80002ae0 <argraw+0x58>
    80002aa2:	048a                	slli	s1,s1,0x2
    80002aa4:	00006717          	auipc	a4,0x6
    80002aa8:	98c70713          	addi	a4,a4,-1652 # 80008430 <states.1723+0x170>
    80002aac:	94ba                	add	s1,s1,a4
    80002aae:	409c                	lw	a5,0(s1)
    80002ab0:	97ba                	add	a5,a5,a4
    80002ab2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ab4:	6d3c                	ld	a5,88(a0)
    80002ab6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ab8:	60e2                	ld	ra,24(sp)
    80002aba:	6442                	ld	s0,16(sp)
    80002abc:	64a2                	ld	s1,8(sp)
    80002abe:	6105                	addi	sp,sp,32
    80002ac0:	8082                	ret
    return p->trapframe->a1;
    80002ac2:	6d3c                	ld	a5,88(a0)
    80002ac4:	7fa8                	ld	a0,120(a5)
    80002ac6:	bfcd                	j	80002ab8 <argraw+0x30>
    return p->trapframe->a2;
    80002ac8:	6d3c                	ld	a5,88(a0)
    80002aca:	63c8                	ld	a0,128(a5)
    80002acc:	b7f5                	j	80002ab8 <argraw+0x30>
    return p->trapframe->a3;
    80002ace:	6d3c                	ld	a5,88(a0)
    80002ad0:	67c8                	ld	a0,136(a5)
    80002ad2:	b7dd                	j	80002ab8 <argraw+0x30>
    return p->trapframe->a4;
    80002ad4:	6d3c                	ld	a5,88(a0)
    80002ad6:	6bc8                	ld	a0,144(a5)
    80002ad8:	b7c5                	j	80002ab8 <argraw+0x30>
    return p->trapframe->a5;
    80002ada:	6d3c                	ld	a5,88(a0)
    80002adc:	6fc8                	ld	a0,152(a5)
    80002ade:	bfe9                	j	80002ab8 <argraw+0x30>
  panic("argraw");
    80002ae0:	00006517          	auipc	a0,0x6
    80002ae4:	92850513          	addi	a0,a0,-1752 # 80008408 <states.1723+0x148>
    80002ae8:	ffffe097          	auipc	ra,0xffffe
    80002aec:	a56080e7          	jalr	-1450(ra) # 8000053e <panic>

0000000080002af0 <fetchaddr>:
{
    80002af0:	1101                	addi	sp,sp,-32
    80002af2:	ec06                	sd	ra,24(sp)
    80002af4:	e822                	sd	s0,16(sp)
    80002af6:	e426                	sd	s1,8(sp)
    80002af8:	e04a                	sd	s2,0(sp)
    80002afa:	1000                	addi	s0,sp,32
    80002afc:	84aa                	mv	s1,a0
    80002afe:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b00:	fffff097          	auipc	ra,0xfffff
    80002b04:	eb0080e7          	jalr	-336(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b08:	653c                	ld	a5,72(a0)
    80002b0a:	02f4f863          	bgeu	s1,a5,80002b3a <fetchaddr+0x4a>
    80002b0e:	00848713          	addi	a4,s1,8
    80002b12:	02e7e663          	bltu	a5,a4,80002b3e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b16:	46a1                	li	a3,8
    80002b18:	8626                	mv	a2,s1
    80002b1a:	85ca                	mv	a1,s2
    80002b1c:	6928                	ld	a0,80(a0)
    80002b1e:	fffff097          	auipc	ra,0xfffff
    80002b22:	be0080e7          	jalr	-1056(ra) # 800016fe <copyin>
    80002b26:	00a03533          	snez	a0,a0
    80002b2a:	40a00533          	neg	a0,a0
}
    80002b2e:	60e2                	ld	ra,24(sp)
    80002b30:	6442                	ld	s0,16(sp)
    80002b32:	64a2                	ld	s1,8(sp)
    80002b34:	6902                	ld	s2,0(sp)
    80002b36:	6105                	addi	sp,sp,32
    80002b38:	8082                	ret
    return -1;
    80002b3a:	557d                	li	a0,-1
    80002b3c:	bfcd                	j	80002b2e <fetchaddr+0x3e>
    80002b3e:	557d                	li	a0,-1
    80002b40:	b7fd                	j	80002b2e <fetchaddr+0x3e>

0000000080002b42 <fetchstr>:
{
    80002b42:	7179                	addi	sp,sp,-48
    80002b44:	f406                	sd	ra,40(sp)
    80002b46:	f022                	sd	s0,32(sp)
    80002b48:	ec26                	sd	s1,24(sp)
    80002b4a:	e84a                	sd	s2,16(sp)
    80002b4c:	e44e                	sd	s3,8(sp)
    80002b4e:	1800                	addi	s0,sp,48
    80002b50:	892a                	mv	s2,a0
    80002b52:	84ae                	mv	s1,a1
    80002b54:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	e5a080e7          	jalr	-422(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b5e:	86ce                	mv	a3,s3
    80002b60:	864a                	mv	a2,s2
    80002b62:	85a6                	mv	a1,s1
    80002b64:	6928                	ld	a0,80(a0)
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	c24080e7          	jalr	-988(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002b6e:	00054763          	bltz	a0,80002b7c <fetchstr+0x3a>
  return strlen(buf);
    80002b72:	8526                	mv	a0,s1
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	2f0080e7          	jalr	752(ra) # 80000e64 <strlen>
}
    80002b7c:	70a2                	ld	ra,40(sp)
    80002b7e:	7402                	ld	s0,32(sp)
    80002b80:	64e2                	ld	s1,24(sp)
    80002b82:	6942                	ld	s2,16(sp)
    80002b84:	69a2                	ld	s3,8(sp)
    80002b86:	6145                	addi	sp,sp,48
    80002b88:	8082                	ret

0000000080002b8a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b8a:	1101                	addi	sp,sp,-32
    80002b8c:	ec06                	sd	ra,24(sp)
    80002b8e:	e822                	sd	s0,16(sp)
    80002b90:	e426                	sd	s1,8(sp)
    80002b92:	1000                	addi	s0,sp,32
    80002b94:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b96:	00000097          	auipc	ra,0x0
    80002b9a:	ef2080e7          	jalr	-270(ra) # 80002a88 <argraw>
    80002b9e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ba0:	4501                	li	a0,0
    80002ba2:	60e2                	ld	ra,24(sp)
    80002ba4:	6442                	ld	s0,16(sp)
    80002ba6:	64a2                	ld	s1,8(sp)
    80002ba8:	6105                	addi	sp,sp,32
    80002baa:	8082                	ret

0000000080002bac <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bac:	1101                	addi	sp,sp,-32
    80002bae:	ec06                	sd	ra,24(sp)
    80002bb0:	e822                	sd	s0,16(sp)
    80002bb2:	e426                	sd	s1,8(sp)
    80002bb4:	1000                	addi	s0,sp,32
    80002bb6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bb8:	00000097          	auipc	ra,0x0
    80002bbc:	ed0080e7          	jalr	-304(ra) # 80002a88 <argraw>
    80002bc0:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bc2:	4501                	li	a0,0
    80002bc4:	60e2                	ld	ra,24(sp)
    80002bc6:	6442                	ld	s0,16(sp)
    80002bc8:	64a2                	ld	s1,8(sp)
    80002bca:	6105                	addi	sp,sp,32
    80002bcc:	8082                	ret

0000000080002bce <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bce:	1101                	addi	sp,sp,-32
    80002bd0:	ec06                	sd	ra,24(sp)
    80002bd2:	e822                	sd	s0,16(sp)
    80002bd4:	e426                	sd	s1,8(sp)
    80002bd6:	e04a                	sd	s2,0(sp)
    80002bd8:	1000                	addi	s0,sp,32
    80002bda:	84ae                	mv	s1,a1
    80002bdc:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bde:	00000097          	auipc	ra,0x0
    80002be2:	eaa080e7          	jalr	-342(ra) # 80002a88 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002be6:	864a                	mv	a2,s2
    80002be8:	85a6                	mv	a1,s1
    80002bea:	00000097          	auipc	ra,0x0
    80002bee:	f58080e7          	jalr	-168(ra) # 80002b42 <fetchstr>
}
    80002bf2:	60e2                	ld	ra,24(sp)
    80002bf4:	6442                	ld	s0,16(sp)
    80002bf6:	64a2                	ld	s1,8(sp)
    80002bf8:	6902                	ld	s2,0(sp)
    80002bfa:	6105                	addi	sp,sp,32
    80002bfc:	8082                	ret

0000000080002bfe <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002bfe:	1101                	addi	sp,sp,-32
    80002c00:	ec06                	sd	ra,24(sp)
    80002c02:	e822                	sd	s0,16(sp)
    80002c04:	e426                	sd	s1,8(sp)
    80002c06:	e04a                	sd	s2,0(sp)
    80002c08:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c0a:	fffff097          	auipc	ra,0xfffff
    80002c0e:	da6080e7          	jalr	-602(ra) # 800019b0 <myproc>
    80002c12:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c14:	05853903          	ld	s2,88(a0)
    80002c18:	0a893783          	ld	a5,168(s2)
    80002c1c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c20:	37fd                	addiw	a5,a5,-1
    80002c22:	4751                	li	a4,20
    80002c24:	00f76f63          	bltu	a4,a5,80002c42 <syscall+0x44>
    80002c28:	00369713          	slli	a4,a3,0x3
    80002c2c:	00006797          	auipc	a5,0x6
    80002c30:	81c78793          	addi	a5,a5,-2020 # 80008448 <syscalls>
    80002c34:	97ba                	add	a5,a5,a4
    80002c36:	639c                	ld	a5,0(a5)
    80002c38:	c789                	beqz	a5,80002c42 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c3a:	9782                	jalr	a5
    80002c3c:	06a93823          	sd	a0,112(s2)
    80002c40:	a839                	j	80002c5e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c42:	15848613          	addi	a2,s1,344
    80002c46:	588c                	lw	a1,48(s1)
    80002c48:	00005517          	auipc	a0,0x5
    80002c4c:	7c850513          	addi	a0,a0,1992 # 80008410 <states.1723+0x150>
    80002c50:	ffffe097          	auipc	ra,0xffffe
    80002c54:	938080e7          	jalr	-1736(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c58:	6cbc                	ld	a5,88(s1)
    80002c5a:	577d                	li	a4,-1
    80002c5c:	fbb8                	sd	a4,112(a5)
  }
}
    80002c5e:	60e2                	ld	ra,24(sp)
    80002c60:	6442                	ld	s0,16(sp)
    80002c62:	64a2                	ld	s1,8(sp)
    80002c64:	6902                	ld	s2,0(sp)
    80002c66:	6105                	addi	sp,sp,32
    80002c68:	8082                	ret

0000000080002c6a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c6a:	1101                	addi	sp,sp,-32
    80002c6c:	ec06                	sd	ra,24(sp)
    80002c6e:	e822                	sd	s0,16(sp)
    80002c70:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c72:	fec40593          	addi	a1,s0,-20
    80002c76:	4501                	li	a0,0
    80002c78:	00000097          	auipc	ra,0x0
    80002c7c:	f12080e7          	jalr	-238(ra) # 80002b8a <argint>
    return -1;
    80002c80:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c82:	00054963          	bltz	a0,80002c94 <sys_exit+0x2a>
  exit(n);
    80002c86:	fec42503          	lw	a0,-20(s0)
    80002c8a:	fffff097          	auipc	ra,0xfffff
    80002c8e:	6f2080e7          	jalr	1778(ra) # 8000237c <exit>
  return 0;  // not reached
    80002c92:	4781                	li	a5,0
}
    80002c94:	853e                	mv	a0,a5
    80002c96:	60e2                	ld	ra,24(sp)
    80002c98:	6442                	ld	s0,16(sp)
    80002c9a:	6105                	addi	sp,sp,32
    80002c9c:	8082                	ret

0000000080002c9e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c9e:	1141                	addi	sp,sp,-16
    80002ca0:	e406                	sd	ra,8(sp)
    80002ca2:	e022                	sd	s0,0(sp)
    80002ca4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	d0a080e7          	jalr	-758(ra) # 800019b0 <myproc>
}
    80002cae:	5908                	lw	a0,48(a0)
    80002cb0:	60a2                	ld	ra,8(sp)
    80002cb2:	6402                	ld	s0,0(sp)
    80002cb4:	0141                	addi	sp,sp,16
    80002cb6:	8082                	ret

0000000080002cb8 <sys_fork>:

uint64
sys_fork(void)
{
    80002cb8:	1141                	addi	sp,sp,-16
    80002cba:	e406                	sd	ra,8(sp)
    80002cbc:	e022                	sd	s0,0(sp)
    80002cbe:	0800                	addi	s0,sp,16
  return fork();
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	0d2080e7          	jalr	210(ra) # 80001d92 <fork>
}
    80002cc8:	60a2                	ld	ra,8(sp)
    80002cca:	6402                	ld	s0,0(sp)
    80002ccc:	0141                	addi	sp,sp,16
    80002cce:	8082                	ret

0000000080002cd0 <sys_wait>:

uint64
sys_wait(void)
{
    80002cd0:	1101                	addi	sp,sp,-32
    80002cd2:	ec06                	sd	ra,24(sp)
    80002cd4:	e822                	sd	s0,16(sp)
    80002cd6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cd8:	fe840593          	addi	a1,s0,-24
    80002cdc:	4501                	li	a0,0
    80002cde:	00000097          	auipc	ra,0x0
    80002ce2:	ece080e7          	jalr	-306(ra) # 80002bac <argaddr>
    80002ce6:	87aa                	mv	a5,a0
    return -1;
    80002ce8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cea:	0007c863          	bltz	a5,80002cfa <sys_wait+0x2a>
  return wait(p);
    80002cee:	fe843503          	ld	a0,-24(s0)
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	492080e7          	jalr	1170(ra) # 80002184 <wait>
}
    80002cfa:	60e2                	ld	ra,24(sp)
    80002cfc:	6442                	ld	s0,16(sp)
    80002cfe:	6105                	addi	sp,sp,32
    80002d00:	8082                	ret

0000000080002d02 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d02:	7179                	addi	sp,sp,-48
    80002d04:	f406                	sd	ra,40(sp)
    80002d06:	f022                	sd	s0,32(sp)
    80002d08:	ec26                	sd	s1,24(sp)
    80002d0a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d0c:	fdc40593          	addi	a1,s0,-36
    80002d10:	4501                	li	a0,0
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	e78080e7          	jalr	-392(ra) # 80002b8a <argint>
    80002d1a:	87aa                	mv	a5,a0
    return -1;
    80002d1c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d1e:	0207c063          	bltz	a5,80002d3e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	c8e080e7          	jalr	-882(ra) # 800019b0 <myproc>
    80002d2a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d2c:	fdc42503          	lw	a0,-36(s0)
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	fee080e7          	jalr	-18(ra) # 80001d1e <growproc>
    80002d38:	00054863          	bltz	a0,80002d48 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d3c:	8526                	mv	a0,s1
}
    80002d3e:	70a2                	ld	ra,40(sp)
    80002d40:	7402                	ld	s0,32(sp)
    80002d42:	64e2                	ld	s1,24(sp)
    80002d44:	6145                	addi	sp,sp,48
    80002d46:	8082                	ret
    return -1;
    80002d48:	557d                	li	a0,-1
    80002d4a:	bfd5                	j	80002d3e <sys_sbrk+0x3c>

0000000080002d4c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d4c:	7139                	addi	sp,sp,-64
    80002d4e:	fc06                	sd	ra,56(sp)
    80002d50:	f822                	sd	s0,48(sp)
    80002d52:	f426                	sd	s1,40(sp)
    80002d54:	f04a                	sd	s2,32(sp)
    80002d56:	ec4e                	sd	s3,24(sp)
    80002d58:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d5a:	fcc40593          	addi	a1,s0,-52
    80002d5e:	4501                	li	a0,0
    80002d60:	00000097          	auipc	ra,0x0
    80002d64:	e2a080e7          	jalr	-470(ra) # 80002b8a <argint>
    return -1;
    80002d68:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d6a:	06054563          	bltz	a0,80002dd4 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d6e:	00014517          	auipc	a0,0x14
    80002d72:	76250513          	addi	a0,a0,1890 # 800174d0 <tickslock>
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	e6e080e7          	jalr	-402(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002d7e:	00006917          	auipc	s2,0x6
    80002d82:	2b292903          	lw	s2,690(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002d86:	fcc42783          	lw	a5,-52(s0)
    80002d8a:	cf85                	beqz	a5,80002dc2 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d8c:	00014997          	auipc	s3,0x14
    80002d90:	74498993          	addi	s3,s3,1860 # 800174d0 <tickslock>
    80002d94:	00006497          	auipc	s1,0x6
    80002d98:	29c48493          	addi	s1,s1,668 # 80009030 <ticks>
    if(myproc()->killed){
    80002d9c:	fffff097          	auipc	ra,0xfffff
    80002da0:	c14080e7          	jalr	-1004(ra) # 800019b0 <myproc>
    80002da4:	551c                	lw	a5,40(a0)
    80002da6:	ef9d                	bnez	a5,80002de4 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002da8:	85ce                	mv	a1,s3
    80002daa:	8526                	mv	a0,s1
    80002dac:	fffff097          	auipc	ra,0xfffff
    80002db0:	374080e7          	jalr	884(ra) # 80002120 <sleep>
  while(ticks - ticks0 < n){
    80002db4:	409c                	lw	a5,0(s1)
    80002db6:	412787bb          	subw	a5,a5,s2
    80002dba:	fcc42703          	lw	a4,-52(s0)
    80002dbe:	fce7efe3          	bltu	a5,a4,80002d9c <sys_sleep+0x50>
  }
  release(&tickslock);
    80002dc2:	00014517          	auipc	a0,0x14
    80002dc6:	70e50513          	addi	a0,a0,1806 # 800174d0 <tickslock>
    80002dca:	ffffe097          	auipc	ra,0xffffe
    80002dce:	ece080e7          	jalr	-306(ra) # 80000c98 <release>
  return 0;
    80002dd2:	4781                	li	a5,0
}
    80002dd4:	853e                	mv	a0,a5
    80002dd6:	70e2                	ld	ra,56(sp)
    80002dd8:	7442                	ld	s0,48(sp)
    80002dda:	74a2                	ld	s1,40(sp)
    80002ddc:	7902                	ld	s2,32(sp)
    80002dde:	69e2                	ld	s3,24(sp)
    80002de0:	6121                	addi	sp,sp,64
    80002de2:	8082                	ret
      release(&tickslock);
    80002de4:	00014517          	auipc	a0,0x14
    80002de8:	6ec50513          	addi	a0,a0,1772 # 800174d0 <tickslock>
    80002dec:	ffffe097          	auipc	ra,0xffffe
    80002df0:	eac080e7          	jalr	-340(ra) # 80000c98 <release>
      return -1;
    80002df4:	57fd                	li	a5,-1
    80002df6:	bff9                	j	80002dd4 <sys_sleep+0x88>

0000000080002df8 <sys_kill>:

uint64
sys_kill(void)
{
    80002df8:	1101                	addi	sp,sp,-32
    80002dfa:	ec06                	sd	ra,24(sp)
    80002dfc:	e822                	sd	s0,16(sp)
    80002dfe:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e00:	fec40593          	addi	a1,s0,-20
    80002e04:	4501                	li	a0,0
    80002e06:	00000097          	auipc	ra,0x0
    80002e0a:	d84080e7          	jalr	-636(ra) # 80002b8a <argint>
    80002e0e:	87aa                	mv	a5,a0
    return -1;
    80002e10:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e12:	0007c863          	bltz	a5,80002e22 <sys_kill+0x2a>
  return kill(pid);
    80002e16:	fec42503          	lw	a0,-20(s0)
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	646080e7          	jalr	1606(ra) # 80002460 <kill>
}
    80002e22:	60e2                	ld	ra,24(sp)
    80002e24:	6442                	ld	s0,16(sp)
    80002e26:	6105                	addi	sp,sp,32
    80002e28:	8082                	ret

0000000080002e2a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e2a:	1101                	addi	sp,sp,-32
    80002e2c:	ec06                	sd	ra,24(sp)
    80002e2e:	e822                	sd	s0,16(sp)
    80002e30:	e426                	sd	s1,8(sp)
    80002e32:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e34:	00014517          	auipc	a0,0x14
    80002e38:	69c50513          	addi	a0,a0,1692 # 800174d0 <tickslock>
    80002e3c:	ffffe097          	auipc	ra,0xffffe
    80002e40:	da8080e7          	jalr	-600(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002e44:	00006497          	auipc	s1,0x6
    80002e48:	1ec4a483          	lw	s1,492(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e4c:	00014517          	auipc	a0,0x14
    80002e50:	68450513          	addi	a0,a0,1668 # 800174d0 <tickslock>
    80002e54:	ffffe097          	auipc	ra,0xffffe
    80002e58:	e44080e7          	jalr	-444(ra) # 80000c98 <release>
  return xticks;
}
    80002e5c:	02049513          	slli	a0,s1,0x20
    80002e60:	9101                	srli	a0,a0,0x20
    80002e62:	60e2                	ld	ra,24(sp)
    80002e64:	6442                	ld	s0,16(sp)
    80002e66:	64a2                	ld	s1,8(sp)
    80002e68:	6105                	addi	sp,sp,32
    80002e6a:	8082                	ret

0000000080002e6c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e6c:	7179                	addi	sp,sp,-48
    80002e6e:	f406                	sd	ra,40(sp)
    80002e70:	f022                	sd	s0,32(sp)
    80002e72:	ec26                	sd	s1,24(sp)
    80002e74:	e84a                	sd	s2,16(sp)
    80002e76:	e44e                	sd	s3,8(sp)
    80002e78:	e052                	sd	s4,0(sp)
    80002e7a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e7c:	00005597          	auipc	a1,0x5
    80002e80:	67c58593          	addi	a1,a1,1660 # 800084f8 <syscalls+0xb0>
    80002e84:	00014517          	auipc	a0,0x14
    80002e88:	66450513          	addi	a0,a0,1636 # 800174e8 <bcache>
    80002e8c:	ffffe097          	auipc	ra,0xffffe
    80002e90:	cc8080e7          	jalr	-824(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e94:	0001c797          	auipc	a5,0x1c
    80002e98:	65478793          	addi	a5,a5,1620 # 8001f4e8 <bcache+0x8000>
    80002e9c:	0001d717          	auipc	a4,0x1d
    80002ea0:	8b470713          	addi	a4,a4,-1868 # 8001f750 <bcache+0x8268>
    80002ea4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ea8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eac:	00014497          	auipc	s1,0x14
    80002eb0:	65448493          	addi	s1,s1,1620 # 80017500 <bcache+0x18>
    b->next = bcache.head.next;
    80002eb4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002eb6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002eb8:	00005a17          	auipc	s4,0x5
    80002ebc:	648a0a13          	addi	s4,s4,1608 # 80008500 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002ec0:	2b893783          	ld	a5,696(s2)
    80002ec4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ec6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002eca:	85d2                	mv	a1,s4
    80002ecc:	01048513          	addi	a0,s1,16
    80002ed0:	00001097          	auipc	ra,0x1
    80002ed4:	4bc080e7          	jalr	1212(ra) # 8000438c <initsleeplock>
    bcache.head.next->prev = b;
    80002ed8:	2b893783          	ld	a5,696(s2)
    80002edc:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ede:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ee2:	45848493          	addi	s1,s1,1112
    80002ee6:	fd349de3          	bne	s1,s3,80002ec0 <binit+0x54>
  }
}
    80002eea:	70a2                	ld	ra,40(sp)
    80002eec:	7402                	ld	s0,32(sp)
    80002eee:	64e2                	ld	s1,24(sp)
    80002ef0:	6942                	ld	s2,16(sp)
    80002ef2:	69a2                	ld	s3,8(sp)
    80002ef4:	6a02                	ld	s4,0(sp)
    80002ef6:	6145                	addi	sp,sp,48
    80002ef8:	8082                	ret

0000000080002efa <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002efa:	7179                	addi	sp,sp,-48
    80002efc:	f406                	sd	ra,40(sp)
    80002efe:	f022                	sd	s0,32(sp)
    80002f00:	ec26                	sd	s1,24(sp)
    80002f02:	e84a                	sd	s2,16(sp)
    80002f04:	e44e                	sd	s3,8(sp)
    80002f06:	1800                	addi	s0,sp,48
    80002f08:	89aa                	mv	s3,a0
    80002f0a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f0c:	00014517          	auipc	a0,0x14
    80002f10:	5dc50513          	addi	a0,a0,1500 # 800174e8 <bcache>
    80002f14:	ffffe097          	auipc	ra,0xffffe
    80002f18:	cd0080e7          	jalr	-816(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f1c:	0001d497          	auipc	s1,0x1d
    80002f20:	8844b483          	ld	s1,-1916(s1) # 8001f7a0 <bcache+0x82b8>
    80002f24:	0001d797          	auipc	a5,0x1d
    80002f28:	82c78793          	addi	a5,a5,-2004 # 8001f750 <bcache+0x8268>
    80002f2c:	02f48f63          	beq	s1,a5,80002f6a <bread+0x70>
    80002f30:	873e                	mv	a4,a5
    80002f32:	a021                	j	80002f3a <bread+0x40>
    80002f34:	68a4                	ld	s1,80(s1)
    80002f36:	02e48a63          	beq	s1,a4,80002f6a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f3a:	449c                	lw	a5,8(s1)
    80002f3c:	ff379ce3          	bne	a5,s3,80002f34 <bread+0x3a>
    80002f40:	44dc                	lw	a5,12(s1)
    80002f42:	ff2799e3          	bne	a5,s2,80002f34 <bread+0x3a>
      b->refcnt++;
    80002f46:	40bc                	lw	a5,64(s1)
    80002f48:	2785                	addiw	a5,a5,1
    80002f4a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f4c:	00014517          	auipc	a0,0x14
    80002f50:	59c50513          	addi	a0,a0,1436 # 800174e8 <bcache>
    80002f54:	ffffe097          	auipc	ra,0xffffe
    80002f58:	d44080e7          	jalr	-700(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002f5c:	01048513          	addi	a0,s1,16
    80002f60:	00001097          	auipc	ra,0x1
    80002f64:	466080e7          	jalr	1126(ra) # 800043c6 <acquiresleep>
      return b;
    80002f68:	a8b9                	j	80002fc6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f6a:	0001d497          	auipc	s1,0x1d
    80002f6e:	82e4b483          	ld	s1,-2002(s1) # 8001f798 <bcache+0x82b0>
    80002f72:	0001c797          	auipc	a5,0x1c
    80002f76:	7de78793          	addi	a5,a5,2014 # 8001f750 <bcache+0x8268>
    80002f7a:	00f48863          	beq	s1,a5,80002f8a <bread+0x90>
    80002f7e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f80:	40bc                	lw	a5,64(s1)
    80002f82:	cf81                	beqz	a5,80002f9a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f84:	64a4                	ld	s1,72(s1)
    80002f86:	fee49de3          	bne	s1,a4,80002f80 <bread+0x86>
  panic("bget: no buffers");
    80002f8a:	00005517          	auipc	a0,0x5
    80002f8e:	57e50513          	addi	a0,a0,1406 # 80008508 <syscalls+0xc0>
    80002f92:	ffffd097          	auipc	ra,0xffffd
    80002f96:	5ac080e7          	jalr	1452(ra) # 8000053e <panic>
      b->dev = dev;
    80002f9a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002f9e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fa2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fa6:	4785                	li	a5,1
    80002fa8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002faa:	00014517          	auipc	a0,0x14
    80002fae:	53e50513          	addi	a0,a0,1342 # 800174e8 <bcache>
    80002fb2:	ffffe097          	auipc	ra,0xffffe
    80002fb6:	ce6080e7          	jalr	-794(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002fba:	01048513          	addi	a0,s1,16
    80002fbe:	00001097          	auipc	ra,0x1
    80002fc2:	408080e7          	jalr	1032(ra) # 800043c6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fc6:	409c                	lw	a5,0(s1)
    80002fc8:	cb89                	beqz	a5,80002fda <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fca:	8526                	mv	a0,s1
    80002fcc:	70a2                	ld	ra,40(sp)
    80002fce:	7402                	ld	s0,32(sp)
    80002fd0:	64e2                	ld	s1,24(sp)
    80002fd2:	6942                	ld	s2,16(sp)
    80002fd4:	69a2                	ld	s3,8(sp)
    80002fd6:	6145                	addi	sp,sp,48
    80002fd8:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fda:	4581                	li	a1,0
    80002fdc:	8526                	mv	a0,s1
    80002fde:	00003097          	auipc	ra,0x3
    80002fe2:	f08080e7          	jalr	-248(ra) # 80005ee6 <virtio_disk_rw>
    b->valid = 1;
    80002fe6:	4785                	li	a5,1
    80002fe8:	c09c                	sw	a5,0(s1)
  return b;
    80002fea:	b7c5                	j	80002fca <bread+0xd0>

0000000080002fec <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fec:	1101                	addi	sp,sp,-32
    80002fee:	ec06                	sd	ra,24(sp)
    80002ff0:	e822                	sd	s0,16(sp)
    80002ff2:	e426                	sd	s1,8(sp)
    80002ff4:	1000                	addi	s0,sp,32
    80002ff6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ff8:	0541                	addi	a0,a0,16
    80002ffa:	00001097          	auipc	ra,0x1
    80002ffe:	466080e7          	jalr	1126(ra) # 80004460 <holdingsleep>
    80003002:	cd01                	beqz	a0,8000301a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003004:	4585                	li	a1,1
    80003006:	8526                	mv	a0,s1
    80003008:	00003097          	auipc	ra,0x3
    8000300c:	ede080e7          	jalr	-290(ra) # 80005ee6 <virtio_disk_rw>
}
    80003010:	60e2                	ld	ra,24(sp)
    80003012:	6442                	ld	s0,16(sp)
    80003014:	64a2                	ld	s1,8(sp)
    80003016:	6105                	addi	sp,sp,32
    80003018:	8082                	ret
    panic("bwrite");
    8000301a:	00005517          	auipc	a0,0x5
    8000301e:	50650513          	addi	a0,a0,1286 # 80008520 <syscalls+0xd8>
    80003022:	ffffd097          	auipc	ra,0xffffd
    80003026:	51c080e7          	jalr	1308(ra) # 8000053e <panic>

000000008000302a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000302a:	1101                	addi	sp,sp,-32
    8000302c:	ec06                	sd	ra,24(sp)
    8000302e:	e822                	sd	s0,16(sp)
    80003030:	e426                	sd	s1,8(sp)
    80003032:	e04a                	sd	s2,0(sp)
    80003034:	1000                	addi	s0,sp,32
    80003036:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003038:	01050913          	addi	s2,a0,16
    8000303c:	854a                	mv	a0,s2
    8000303e:	00001097          	auipc	ra,0x1
    80003042:	422080e7          	jalr	1058(ra) # 80004460 <holdingsleep>
    80003046:	c92d                	beqz	a0,800030b8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003048:	854a                	mv	a0,s2
    8000304a:	00001097          	auipc	ra,0x1
    8000304e:	3d2080e7          	jalr	978(ra) # 8000441c <releasesleep>

  acquire(&bcache.lock);
    80003052:	00014517          	auipc	a0,0x14
    80003056:	49650513          	addi	a0,a0,1174 # 800174e8 <bcache>
    8000305a:	ffffe097          	auipc	ra,0xffffe
    8000305e:	b8a080e7          	jalr	-1142(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003062:	40bc                	lw	a5,64(s1)
    80003064:	37fd                	addiw	a5,a5,-1
    80003066:	0007871b          	sext.w	a4,a5
    8000306a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000306c:	eb05                	bnez	a4,8000309c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000306e:	68bc                	ld	a5,80(s1)
    80003070:	64b8                	ld	a4,72(s1)
    80003072:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003074:	64bc                	ld	a5,72(s1)
    80003076:	68b8                	ld	a4,80(s1)
    80003078:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000307a:	0001c797          	auipc	a5,0x1c
    8000307e:	46e78793          	addi	a5,a5,1134 # 8001f4e8 <bcache+0x8000>
    80003082:	2b87b703          	ld	a4,696(a5)
    80003086:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003088:	0001c717          	auipc	a4,0x1c
    8000308c:	6c870713          	addi	a4,a4,1736 # 8001f750 <bcache+0x8268>
    80003090:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003092:	2b87b703          	ld	a4,696(a5)
    80003096:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003098:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000309c:	00014517          	auipc	a0,0x14
    800030a0:	44c50513          	addi	a0,a0,1100 # 800174e8 <bcache>
    800030a4:	ffffe097          	auipc	ra,0xffffe
    800030a8:	bf4080e7          	jalr	-1036(ra) # 80000c98 <release>
}
    800030ac:	60e2                	ld	ra,24(sp)
    800030ae:	6442                	ld	s0,16(sp)
    800030b0:	64a2                	ld	s1,8(sp)
    800030b2:	6902                	ld	s2,0(sp)
    800030b4:	6105                	addi	sp,sp,32
    800030b6:	8082                	ret
    panic("brelse");
    800030b8:	00005517          	auipc	a0,0x5
    800030bc:	47050513          	addi	a0,a0,1136 # 80008528 <syscalls+0xe0>
    800030c0:	ffffd097          	auipc	ra,0xffffd
    800030c4:	47e080e7          	jalr	1150(ra) # 8000053e <panic>

00000000800030c8 <bpin>:

void
bpin(struct buf *b) {
    800030c8:	1101                	addi	sp,sp,-32
    800030ca:	ec06                	sd	ra,24(sp)
    800030cc:	e822                	sd	s0,16(sp)
    800030ce:	e426                	sd	s1,8(sp)
    800030d0:	1000                	addi	s0,sp,32
    800030d2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030d4:	00014517          	auipc	a0,0x14
    800030d8:	41450513          	addi	a0,a0,1044 # 800174e8 <bcache>
    800030dc:	ffffe097          	auipc	ra,0xffffe
    800030e0:	b08080e7          	jalr	-1272(ra) # 80000be4 <acquire>
  b->refcnt++;
    800030e4:	40bc                	lw	a5,64(s1)
    800030e6:	2785                	addiw	a5,a5,1
    800030e8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030ea:	00014517          	auipc	a0,0x14
    800030ee:	3fe50513          	addi	a0,a0,1022 # 800174e8 <bcache>
    800030f2:	ffffe097          	auipc	ra,0xffffe
    800030f6:	ba6080e7          	jalr	-1114(ra) # 80000c98 <release>
}
    800030fa:	60e2                	ld	ra,24(sp)
    800030fc:	6442                	ld	s0,16(sp)
    800030fe:	64a2                	ld	s1,8(sp)
    80003100:	6105                	addi	sp,sp,32
    80003102:	8082                	ret

0000000080003104 <bunpin>:

void
bunpin(struct buf *b) {
    80003104:	1101                	addi	sp,sp,-32
    80003106:	ec06                	sd	ra,24(sp)
    80003108:	e822                	sd	s0,16(sp)
    8000310a:	e426                	sd	s1,8(sp)
    8000310c:	1000                	addi	s0,sp,32
    8000310e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003110:	00014517          	auipc	a0,0x14
    80003114:	3d850513          	addi	a0,a0,984 # 800174e8 <bcache>
    80003118:	ffffe097          	auipc	ra,0xffffe
    8000311c:	acc080e7          	jalr	-1332(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003120:	40bc                	lw	a5,64(s1)
    80003122:	37fd                	addiw	a5,a5,-1
    80003124:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003126:	00014517          	auipc	a0,0x14
    8000312a:	3c250513          	addi	a0,a0,962 # 800174e8 <bcache>
    8000312e:	ffffe097          	auipc	ra,0xffffe
    80003132:	b6a080e7          	jalr	-1174(ra) # 80000c98 <release>
}
    80003136:	60e2                	ld	ra,24(sp)
    80003138:	6442                	ld	s0,16(sp)
    8000313a:	64a2                	ld	s1,8(sp)
    8000313c:	6105                	addi	sp,sp,32
    8000313e:	8082                	ret

0000000080003140 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003140:	1101                	addi	sp,sp,-32
    80003142:	ec06                	sd	ra,24(sp)
    80003144:	e822                	sd	s0,16(sp)
    80003146:	e426                	sd	s1,8(sp)
    80003148:	e04a                	sd	s2,0(sp)
    8000314a:	1000                	addi	s0,sp,32
    8000314c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000314e:	00d5d59b          	srliw	a1,a1,0xd
    80003152:	0001d797          	auipc	a5,0x1d
    80003156:	a727a783          	lw	a5,-1422(a5) # 8001fbc4 <sb+0x1c>
    8000315a:	9dbd                	addw	a1,a1,a5
    8000315c:	00000097          	auipc	ra,0x0
    80003160:	d9e080e7          	jalr	-610(ra) # 80002efa <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003164:	0074f713          	andi	a4,s1,7
    80003168:	4785                	li	a5,1
    8000316a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000316e:	14ce                	slli	s1,s1,0x33
    80003170:	90d9                	srli	s1,s1,0x36
    80003172:	00950733          	add	a4,a0,s1
    80003176:	05874703          	lbu	a4,88(a4)
    8000317a:	00e7f6b3          	and	a3,a5,a4
    8000317e:	c69d                	beqz	a3,800031ac <bfree+0x6c>
    80003180:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003182:	94aa                	add	s1,s1,a0
    80003184:	fff7c793          	not	a5,a5
    80003188:	8ff9                	and	a5,a5,a4
    8000318a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000318e:	00001097          	auipc	ra,0x1
    80003192:	118080e7          	jalr	280(ra) # 800042a6 <log_write>
  brelse(bp);
    80003196:	854a                	mv	a0,s2
    80003198:	00000097          	auipc	ra,0x0
    8000319c:	e92080e7          	jalr	-366(ra) # 8000302a <brelse>
}
    800031a0:	60e2                	ld	ra,24(sp)
    800031a2:	6442                	ld	s0,16(sp)
    800031a4:	64a2                	ld	s1,8(sp)
    800031a6:	6902                	ld	s2,0(sp)
    800031a8:	6105                	addi	sp,sp,32
    800031aa:	8082                	ret
    panic("freeing free block");
    800031ac:	00005517          	auipc	a0,0x5
    800031b0:	38450513          	addi	a0,a0,900 # 80008530 <syscalls+0xe8>
    800031b4:	ffffd097          	auipc	ra,0xffffd
    800031b8:	38a080e7          	jalr	906(ra) # 8000053e <panic>

00000000800031bc <balloc>:
{
    800031bc:	711d                	addi	sp,sp,-96
    800031be:	ec86                	sd	ra,88(sp)
    800031c0:	e8a2                	sd	s0,80(sp)
    800031c2:	e4a6                	sd	s1,72(sp)
    800031c4:	e0ca                	sd	s2,64(sp)
    800031c6:	fc4e                	sd	s3,56(sp)
    800031c8:	f852                	sd	s4,48(sp)
    800031ca:	f456                	sd	s5,40(sp)
    800031cc:	f05a                	sd	s6,32(sp)
    800031ce:	ec5e                	sd	s7,24(sp)
    800031d0:	e862                	sd	s8,16(sp)
    800031d2:	e466                	sd	s9,8(sp)
    800031d4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031d6:	0001d797          	auipc	a5,0x1d
    800031da:	9d67a783          	lw	a5,-1578(a5) # 8001fbac <sb+0x4>
    800031de:	cbd1                	beqz	a5,80003272 <balloc+0xb6>
    800031e0:	8baa                	mv	s7,a0
    800031e2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031e4:	0001db17          	auipc	s6,0x1d
    800031e8:	9c4b0b13          	addi	s6,s6,-1596 # 8001fba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031ec:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031ee:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031f0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031f2:	6c89                	lui	s9,0x2
    800031f4:	a831                	j	80003210 <balloc+0x54>
    brelse(bp);
    800031f6:	854a                	mv	a0,s2
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	e32080e7          	jalr	-462(ra) # 8000302a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003200:	015c87bb          	addw	a5,s9,s5
    80003204:	00078a9b          	sext.w	s5,a5
    80003208:	004b2703          	lw	a4,4(s6)
    8000320c:	06eaf363          	bgeu	s5,a4,80003272 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003210:	41fad79b          	sraiw	a5,s5,0x1f
    80003214:	0137d79b          	srliw	a5,a5,0x13
    80003218:	015787bb          	addw	a5,a5,s5
    8000321c:	40d7d79b          	sraiw	a5,a5,0xd
    80003220:	01cb2583          	lw	a1,28(s6)
    80003224:	9dbd                	addw	a1,a1,a5
    80003226:	855e                	mv	a0,s7
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	cd2080e7          	jalr	-814(ra) # 80002efa <bread>
    80003230:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003232:	004b2503          	lw	a0,4(s6)
    80003236:	000a849b          	sext.w	s1,s5
    8000323a:	8662                	mv	a2,s8
    8000323c:	faa4fde3          	bgeu	s1,a0,800031f6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003240:	41f6579b          	sraiw	a5,a2,0x1f
    80003244:	01d7d69b          	srliw	a3,a5,0x1d
    80003248:	00c6873b          	addw	a4,a3,a2
    8000324c:	00777793          	andi	a5,a4,7
    80003250:	9f95                	subw	a5,a5,a3
    80003252:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003256:	4037571b          	sraiw	a4,a4,0x3
    8000325a:	00e906b3          	add	a3,s2,a4
    8000325e:	0586c683          	lbu	a3,88(a3)
    80003262:	00d7f5b3          	and	a1,a5,a3
    80003266:	cd91                	beqz	a1,80003282 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003268:	2605                	addiw	a2,a2,1
    8000326a:	2485                	addiw	s1,s1,1
    8000326c:	fd4618e3          	bne	a2,s4,8000323c <balloc+0x80>
    80003270:	b759                	j	800031f6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003272:	00005517          	auipc	a0,0x5
    80003276:	2d650513          	addi	a0,a0,726 # 80008548 <syscalls+0x100>
    8000327a:	ffffd097          	auipc	ra,0xffffd
    8000327e:	2c4080e7          	jalr	708(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003282:	974a                	add	a4,a4,s2
    80003284:	8fd5                	or	a5,a5,a3
    80003286:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000328a:	854a                	mv	a0,s2
    8000328c:	00001097          	auipc	ra,0x1
    80003290:	01a080e7          	jalr	26(ra) # 800042a6 <log_write>
        brelse(bp);
    80003294:	854a                	mv	a0,s2
    80003296:	00000097          	auipc	ra,0x0
    8000329a:	d94080e7          	jalr	-620(ra) # 8000302a <brelse>
  bp = bread(dev, bno);
    8000329e:	85a6                	mv	a1,s1
    800032a0:	855e                	mv	a0,s7
    800032a2:	00000097          	auipc	ra,0x0
    800032a6:	c58080e7          	jalr	-936(ra) # 80002efa <bread>
    800032aa:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032ac:	40000613          	li	a2,1024
    800032b0:	4581                	li	a1,0
    800032b2:	05850513          	addi	a0,a0,88
    800032b6:	ffffe097          	auipc	ra,0xffffe
    800032ba:	a2a080e7          	jalr	-1494(ra) # 80000ce0 <memset>
  log_write(bp);
    800032be:	854a                	mv	a0,s2
    800032c0:	00001097          	auipc	ra,0x1
    800032c4:	fe6080e7          	jalr	-26(ra) # 800042a6 <log_write>
  brelse(bp);
    800032c8:	854a                	mv	a0,s2
    800032ca:	00000097          	auipc	ra,0x0
    800032ce:	d60080e7          	jalr	-672(ra) # 8000302a <brelse>
}
    800032d2:	8526                	mv	a0,s1
    800032d4:	60e6                	ld	ra,88(sp)
    800032d6:	6446                	ld	s0,80(sp)
    800032d8:	64a6                	ld	s1,72(sp)
    800032da:	6906                	ld	s2,64(sp)
    800032dc:	79e2                	ld	s3,56(sp)
    800032de:	7a42                	ld	s4,48(sp)
    800032e0:	7aa2                	ld	s5,40(sp)
    800032e2:	7b02                	ld	s6,32(sp)
    800032e4:	6be2                	ld	s7,24(sp)
    800032e6:	6c42                	ld	s8,16(sp)
    800032e8:	6ca2                	ld	s9,8(sp)
    800032ea:	6125                	addi	sp,sp,96
    800032ec:	8082                	ret

00000000800032ee <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032ee:	7179                	addi	sp,sp,-48
    800032f0:	f406                	sd	ra,40(sp)
    800032f2:	f022                	sd	s0,32(sp)
    800032f4:	ec26                	sd	s1,24(sp)
    800032f6:	e84a                	sd	s2,16(sp)
    800032f8:	e44e                	sd	s3,8(sp)
    800032fa:	e052                	sd	s4,0(sp)
    800032fc:	1800                	addi	s0,sp,48
    800032fe:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003300:	47ad                	li	a5,11
    80003302:	04b7fe63          	bgeu	a5,a1,8000335e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003306:	ff45849b          	addiw	s1,a1,-12
    8000330a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000330e:	0ff00793          	li	a5,255
    80003312:	0ae7e363          	bltu	a5,a4,800033b8 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003316:	08052583          	lw	a1,128(a0)
    8000331a:	c5ad                	beqz	a1,80003384 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000331c:	00092503          	lw	a0,0(s2)
    80003320:	00000097          	auipc	ra,0x0
    80003324:	bda080e7          	jalr	-1062(ra) # 80002efa <bread>
    80003328:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000332a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000332e:	02049593          	slli	a1,s1,0x20
    80003332:	9181                	srli	a1,a1,0x20
    80003334:	058a                	slli	a1,a1,0x2
    80003336:	00b784b3          	add	s1,a5,a1
    8000333a:	0004a983          	lw	s3,0(s1)
    8000333e:	04098d63          	beqz	s3,80003398 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003342:	8552                	mv	a0,s4
    80003344:	00000097          	auipc	ra,0x0
    80003348:	ce6080e7          	jalr	-794(ra) # 8000302a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000334c:	854e                	mv	a0,s3
    8000334e:	70a2                	ld	ra,40(sp)
    80003350:	7402                	ld	s0,32(sp)
    80003352:	64e2                	ld	s1,24(sp)
    80003354:	6942                	ld	s2,16(sp)
    80003356:	69a2                	ld	s3,8(sp)
    80003358:	6a02                	ld	s4,0(sp)
    8000335a:	6145                	addi	sp,sp,48
    8000335c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000335e:	02059493          	slli	s1,a1,0x20
    80003362:	9081                	srli	s1,s1,0x20
    80003364:	048a                	slli	s1,s1,0x2
    80003366:	94aa                	add	s1,s1,a0
    80003368:	0504a983          	lw	s3,80(s1)
    8000336c:	fe0990e3          	bnez	s3,8000334c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003370:	4108                	lw	a0,0(a0)
    80003372:	00000097          	auipc	ra,0x0
    80003376:	e4a080e7          	jalr	-438(ra) # 800031bc <balloc>
    8000337a:	0005099b          	sext.w	s3,a0
    8000337e:	0534a823          	sw	s3,80(s1)
    80003382:	b7e9                	j	8000334c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003384:	4108                	lw	a0,0(a0)
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	e36080e7          	jalr	-458(ra) # 800031bc <balloc>
    8000338e:	0005059b          	sext.w	a1,a0
    80003392:	08b92023          	sw	a1,128(s2)
    80003396:	b759                	j	8000331c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003398:	00092503          	lw	a0,0(s2)
    8000339c:	00000097          	auipc	ra,0x0
    800033a0:	e20080e7          	jalr	-480(ra) # 800031bc <balloc>
    800033a4:	0005099b          	sext.w	s3,a0
    800033a8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033ac:	8552                	mv	a0,s4
    800033ae:	00001097          	auipc	ra,0x1
    800033b2:	ef8080e7          	jalr	-264(ra) # 800042a6 <log_write>
    800033b6:	b771                	j	80003342 <bmap+0x54>
  panic("bmap: out of range");
    800033b8:	00005517          	auipc	a0,0x5
    800033bc:	1a850513          	addi	a0,a0,424 # 80008560 <syscalls+0x118>
    800033c0:	ffffd097          	auipc	ra,0xffffd
    800033c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800033c8 <iget>:
{
    800033c8:	7179                	addi	sp,sp,-48
    800033ca:	f406                	sd	ra,40(sp)
    800033cc:	f022                	sd	s0,32(sp)
    800033ce:	ec26                	sd	s1,24(sp)
    800033d0:	e84a                	sd	s2,16(sp)
    800033d2:	e44e                	sd	s3,8(sp)
    800033d4:	e052                	sd	s4,0(sp)
    800033d6:	1800                	addi	s0,sp,48
    800033d8:	89aa                	mv	s3,a0
    800033da:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033dc:	0001c517          	auipc	a0,0x1c
    800033e0:	7ec50513          	addi	a0,a0,2028 # 8001fbc8 <itable>
    800033e4:	ffffe097          	auipc	ra,0xffffe
    800033e8:	800080e7          	jalr	-2048(ra) # 80000be4 <acquire>
  empty = 0;
    800033ec:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033ee:	0001c497          	auipc	s1,0x1c
    800033f2:	7f248493          	addi	s1,s1,2034 # 8001fbe0 <itable+0x18>
    800033f6:	0001e697          	auipc	a3,0x1e
    800033fa:	27a68693          	addi	a3,a3,634 # 80021670 <log>
    800033fe:	a039                	j	8000340c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003400:	02090b63          	beqz	s2,80003436 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003404:	08848493          	addi	s1,s1,136
    80003408:	02d48a63          	beq	s1,a3,8000343c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000340c:	449c                	lw	a5,8(s1)
    8000340e:	fef059e3          	blez	a5,80003400 <iget+0x38>
    80003412:	4098                	lw	a4,0(s1)
    80003414:	ff3716e3          	bne	a4,s3,80003400 <iget+0x38>
    80003418:	40d8                	lw	a4,4(s1)
    8000341a:	ff4713e3          	bne	a4,s4,80003400 <iget+0x38>
      ip->ref++;
    8000341e:	2785                	addiw	a5,a5,1
    80003420:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003422:	0001c517          	auipc	a0,0x1c
    80003426:	7a650513          	addi	a0,a0,1958 # 8001fbc8 <itable>
    8000342a:	ffffe097          	auipc	ra,0xffffe
    8000342e:	86e080e7          	jalr	-1938(ra) # 80000c98 <release>
      return ip;
    80003432:	8926                	mv	s2,s1
    80003434:	a03d                	j	80003462 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003436:	f7f9                	bnez	a5,80003404 <iget+0x3c>
    80003438:	8926                	mv	s2,s1
    8000343a:	b7e9                	j	80003404 <iget+0x3c>
  if(empty == 0)
    8000343c:	02090c63          	beqz	s2,80003474 <iget+0xac>
  ip->dev = dev;
    80003440:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003444:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003448:	4785                	li	a5,1
    8000344a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000344e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003452:	0001c517          	auipc	a0,0x1c
    80003456:	77650513          	addi	a0,a0,1910 # 8001fbc8 <itable>
    8000345a:	ffffe097          	auipc	ra,0xffffe
    8000345e:	83e080e7          	jalr	-1986(ra) # 80000c98 <release>
}
    80003462:	854a                	mv	a0,s2
    80003464:	70a2                	ld	ra,40(sp)
    80003466:	7402                	ld	s0,32(sp)
    80003468:	64e2                	ld	s1,24(sp)
    8000346a:	6942                	ld	s2,16(sp)
    8000346c:	69a2                	ld	s3,8(sp)
    8000346e:	6a02                	ld	s4,0(sp)
    80003470:	6145                	addi	sp,sp,48
    80003472:	8082                	ret
    panic("iget: no inodes");
    80003474:	00005517          	auipc	a0,0x5
    80003478:	10450513          	addi	a0,a0,260 # 80008578 <syscalls+0x130>
    8000347c:	ffffd097          	auipc	ra,0xffffd
    80003480:	0c2080e7          	jalr	194(ra) # 8000053e <panic>

0000000080003484 <fsinit>:
fsinit(int dev) {
    80003484:	7179                	addi	sp,sp,-48
    80003486:	f406                	sd	ra,40(sp)
    80003488:	f022                	sd	s0,32(sp)
    8000348a:	ec26                	sd	s1,24(sp)
    8000348c:	e84a                	sd	s2,16(sp)
    8000348e:	e44e                	sd	s3,8(sp)
    80003490:	1800                	addi	s0,sp,48
    80003492:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003494:	4585                	li	a1,1
    80003496:	00000097          	auipc	ra,0x0
    8000349a:	a64080e7          	jalr	-1436(ra) # 80002efa <bread>
    8000349e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034a0:	0001c997          	auipc	s3,0x1c
    800034a4:	70898993          	addi	s3,s3,1800 # 8001fba8 <sb>
    800034a8:	02000613          	li	a2,32
    800034ac:	05850593          	addi	a1,a0,88
    800034b0:	854e                	mv	a0,s3
    800034b2:	ffffe097          	auipc	ra,0xffffe
    800034b6:	88e080e7          	jalr	-1906(ra) # 80000d40 <memmove>
  brelse(bp);
    800034ba:	8526                	mv	a0,s1
    800034bc:	00000097          	auipc	ra,0x0
    800034c0:	b6e080e7          	jalr	-1170(ra) # 8000302a <brelse>
  if(sb.magic != FSMAGIC)
    800034c4:	0009a703          	lw	a4,0(s3)
    800034c8:	102037b7          	lui	a5,0x10203
    800034cc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034d0:	02f71263          	bne	a4,a5,800034f4 <fsinit+0x70>
  initlog(dev, &sb);
    800034d4:	0001c597          	auipc	a1,0x1c
    800034d8:	6d458593          	addi	a1,a1,1748 # 8001fba8 <sb>
    800034dc:	854a                	mv	a0,s2
    800034de:	00001097          	auipc	ra,0x1
    800034e2:	b4c080e7          	jalr	-1204(ra) # 8000402a <initlog>
}
    800034e6:	70a2                	ld	ra,40(sp)
    800034e8:	7402                	ld	s0,32(sp)
    800034ea:	64e2                	ld	s1,24(sp)
    800034ec:	6942                	ld	s2,16(sp)
    800034ee:	69a2                	ld	s3,8(sp)
    800034f0:	6145                	addi	sp,sp,48
    800034f2:	8082                	ret
    panic("invalid file system");
    800034f4:	00005517          	auipc	a0,0x5
    800034f8:	09450513          	addi	a0,a0,148 # 80008588 <syscalls+0x140>
    800034fc:	ffffd097          	auipc	ra,0xffffd
    80003500:	042080e7          	jalr	66(ra) # 8000053e <panic>

0000000080003504 <iinit>:
{
    80003504:	7179                	addi	sp,sp,-48
    80003506:	f406                	sd	ra,40(sp)
    80003508:	f022                	sd	s0,32(sp)
    8000350a:	ec26                	sd	s1,24(sp)
    8000350c:	e84a                	sd	s2,16(sp)
    8000350e:	e44e                	sd	s3,8(sp)
    80003510:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003512:	00005597          	auipc	a1,0x5
    80003516:	08e58593          	addi	a1,a1,142 # 800085a0 <syscalls+0x158>
    8000351a:	0001c517          	auipc	a0,0x1c
    8000351e:	6ae50513          	addi	a0,a0,1710 # 8001fbc8 <itable>
    80003522:	ffffd097          	auipc	ra,0xffffd
    80003526:	632080e7          	jalr	1586(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000352a:	0001c497          	auipc	s1,0x1c
    8000352e:	6c648493          	addi	s1,s1,1734 # 8001fbf0 <itable+0x28>
    80003532:	0001e997          	auipc	s3,0x1e
    80003536:	14e98993          	addi	s3,s3,334 # 80021680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000353a:	00005917          	auipc	s2,0x5
    8000353e:	06e90913          	addi	s2,s2,110 # 800085a8 <syscalls+0x160>
    80003542:	85ca                	mv	a1,s2
    80003544:	8526                	mv	a0,s1
    80003546:	00001097          	auipc	ra,0x1
    8000354a:	e46080e7          	jalr	-442(ra) # 8000438c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000354e:	08848493          	addi	s1,s1,136
    80003552:	ff3498e3          	bne	s1,s3,80003542 <iinit+0x3e>
}
    80003556:	70a2                	ld	ra,40(sp)
    80003558:	7402                	ld	s0,32(sp)
    8000355a:	64e2                	ld	s1,24(sp)
    8000355c:	6942                	ld	s2,16(sp)
    8000355e:	69a2                	ld	s3,8(sp)
    80003560:	6145                	addi	sp,sp,48
    80003562:	8082                	ret

0000000080003564 <ialloc>:
{
    80003564:	715d                	addi	sp,sp,-80
    80003566:	e486                	sd	ra,72(sp)
    80003568:	e0a2                	sd	s0,64(sp)
    8000356a:	fc26                	sd	s1,56(sp)
    8000356c:	f84a                	sd	s2,48(sp)
    8000356e:	f44e                	sd	s3,40(sp)
    80003570:	f052                	sd	s4,32(sp)
    80003572:	ec56                	sd	s5,24(sp)
    80003574:	e85a                	sd	s6,16(sp)
    80003576:	e45e                	sd	s7,8(sp)
    80003578:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000357a:	0001c717          	auipc	a4,0x1c
    8000357e:	63a72703          	lw	a4,1594(a4) # 8001fbb4 <sb+0xc>
    80003582:	4785                	li	a5,1
    80003584:	04e7fa63          	bgeu	a5,a4,800035d8 <ialloc+0x74>
    80003588:	8aaa                	mv	s5,a0
    8000358a:	8bae                	mv	s7,a1
    8000358c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000358e:	0001ca17          	auipc	s4,0x1c
    80003592:	61aa0a13          	addi	s4,s4,1562 # 8001fba8 <sb>
    80003596:	00048b1b          	sext.w	s6,s1
    8000359a:	0044d593          	srli	a1,s1,0x4
    8000359e:	018a2783          	lw	a5,24(s4)
    800035a2:	9dbd                	addw	a1,a1,a5
    800035a4:	8556                	mv	a0,s5
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	954080e7          	jalr	-1708(ra) # 80002efa <bread>
    800035ae:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035b0:	05850993          	addi	s3,a0,88
    800035b4:	00f4f793          	andi	a5,s1,15
    800035b8:	079a                	slli	a5,a5,0x6
    800035ba:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035bc:	00099783          	lh	a5,0(s3)
    800035c0:	c785                	beqz	a5,800035e8 <ialloc+0x84>
    brelse(bp);
    800035c2:	00000097          	auipc	ra,0x0
    800035c6:	a68080e7          	jalr	-1432(ra) # 8000302a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035ca:	0485                	addi	s1,s1,1
    800035cc:	00ca2703          	lw	a4,12(s4)
    800035d0:	0004879b          	sext.w	a5,s1
    800035d4:	fce7e1e3          	bltu	a5,a4,80003596 <ialloc+0x32>
  panic("ialloc: no inodes");
    800035d8:	00005517          	auipc	a0,0x5
    800035dc:	fd850513          	addi	a0,a0,-40 # 800085b0 <syscalls+0x168>
    800035e0:	ffffd097          	auipc	ra,0xffffd
    800035e4:	f5e080e7          	jalr	-162(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800035e8:	04000613          	li	a2,64
    800035ec:	4581                	li	a1,0
    800035ee:	854e                	mv	a0,s3
    800035f0:	ffffd097          	auipc	ra,0xffffd
    800035f4:	6f0080e7          	jalr	1776(ra) # 80000ce0 <memset>
      dip->type = type;
    800035f8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035fc:	854a                	mv	a0,s2
    800035fe:	00001097          	auipc	ra,0x1
    80003602:	ca8080e7          	jalr	-856(ra) # 800042a6 <log_write>
      brelse(bp);
    80003606:	854a                	mv	a0,s2
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	a22080e7          	jalr	-1502(ra) # 8000302a <brelse>
      return iget(dev, inum);
    80003610:	85da                	mv	a1,s6
    80003612:	8556                	mv	a0,s5
    80003614:	00000097          	auipc	ra,0x0
    80003618:	db4080e7          	jalr	-588(ra) # 800033c8 <iget>
}
    8000361c:	60a6                	ld	ra,72(sp)
    8000361e:	6406                	ld	s0,64(sp)
    80003620:	74e2                	ld	s1,56(sp)
    80003622:	7942                	ld	s2,48(sp)
    80003624:	79a2                	ld	s3,40(sp)
    80003626:	7a02                	ld	s4,32(sp)
    80003628:	6ae2                	ld	s5,24(sp)
    8000362a:	6b42                	ld	s6,16(sp)
    8000362c:	6ba2                	ld	s7,8(sp)
    8000362e:	6161                	addi	sp,sp,80
    80003630:	8082                	ret

0000000080003632 <iupdate>:
{
    80003632:	1101                	addi	sp,sp,-32
    80003634:	ec06                	sd	ra,24(sp)
    80003636:	e822                	sd	s0,16(sp)
    80003638:	e426                	sd	s1,8(sp)
    8000363a:	e04a                	sd	s2,0(sp)
    8000363c:	1000                	addi	s0,sp,32
    8000363e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003640:	415c                	lw	a5,4(a0)
    80003642:	0047d79b          	srliw	a5,a5,0x4
    80003646:	0001c597          	auipc	a1,0x1c
    8000364a:	57a5a583          	lw	a1,1402(a1) # 8001fbc0 <sb+0x18>
    8000364e:	9dbd                	addw	a1,a1,a5
    80003650:	4108                	lw	a0,0(a0)
    80003652:	00000097          	auipc	ra,0x0
    80003656:	8a8080e7          	jalr	-1880(ra) # 80002efa <bread>
    8000365a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000365c:	05850793          	addi	a5,a0,88
    80003660:	40c8                	lw	a0,4(s1)
    80003662:	893d                	andi	a0,a0,15
    80003664:	051a                	slli	a0,a0,0x6
    80003666:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003668:	04449703          	lh	a4,68(s1)
    8000366c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003670:	04649703          	lh	a4,70(s1)
    80003674:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003678:	04849703          	lh	a4,72(s1)
    8000367c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003680:	04a49703          	lh	a4,74(s1)
    80003684:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003688:	44f8                	lw	a4,76(s1)
    8000368a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000368c:	03400613          	li	a2,52
    80003690:	05048593          	addi	a1,s1,80
    80003694:	0531                	addi	a0,a0,12
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	6aa080e7          	jalr	1706(ra) # 80000d40 <memmove>
  log_write(bp);
    8000369e:	854a                	mv	a0,s2
    800036a0:	00001097          	auipc	ra,0x1
    800036a4:	c06080e7          	jalr	-1018(ra) # 800042a6 <log_write>
  brelse(bp);
    800036a8:	854a                	mv	a0,s2
    800036aa:	00000097          	auipc	ra,0x0
    800036ae:	980080e7          	jalr	-1664(ra) # 8000302a <brelse>
}
    800036b2:	60e2                	ld	ra,24(sp)
    800036b4:	6442                	ld	s0,16(sp)
    800036b6:	64a2                	ld	s1,8(sp)
    800036b8:	6902                	ld	s2,0(sp)
    800036ba:	6105                	addi	sp,sp,32
    800036bc:	8082                	ret

00000000800036be <idup>:
{
    800036be:	1101                	addi	sp,sp,-32
    800036c0:	ec06                	sd	ra,24(sp)
    800036c2:	e822                	sd	s0,16(sp)
    800036c4:	e426                	sd	s1,8(sp)
    800036c6:	1000                	addi	s0,sp,32
    800036c8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036ca:	0001c517          	auipc	a0,0x1c
    800036ce:	4fe50513          	addi	a0,a0,1278 # 8001fbc8 <itable>
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	512080e7          	jalr	1298(ra) # 80000be4 <acquire>
  ip->ref++;
    800036da:	449c                	lw	a5,8(s1)
    800036dc:	2785                	addiw	a5,a5,1
    800036de:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036e0:	0001c517          	auipc	a0,0x1c
    800036e4:	4e850513          	addi	a0,a0,1256 # 8001fbc8 <itable>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	5b0080e7          	jalr	1456(ra) # 80000c98 <release>
}
    800036f0:	8526                	mv	a0,s1
    800036f2:	60e2                	ld	ra,24(sp)
    800036f4:	6442                	ld	s0,16(sp)
    800036f6:	64a2                	ld	s1,8(sp)
    800036f8:	6105                	addi	sp,sp,32
    800036fa:	8082                	ret

00000000800036fc <ilock>:
{
    800036fc:	1101                	addi	sp,sp,-32
    800036fe:	ec06                	sd	ra,24(sp)
    80003700:	e822                	sd	s0,16(sp)
    80003702:	e426                	sd	s1,8(sp)
    80003704:	e04a                	sd	s2,0(sp)
    80003706:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003708:	c115                	beqz	a0,8000372c <ilock+0x30>
    8000370a:	84aa                	mv	s1,a0
    8000370c:	451c                	lw	a5,8(a0)
    8000370e:	00f05f63          	blez	a5,8000372c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003712:	0541                	addi	a0,a0,16
    80003714:	00001097          	auipc	ra,0x1
    80003718:	cb2080e7          	jalr	-846(ra) # 800043c6 <acquiresleep>
  if(ip->valid == 0){
    8000371c:	40bc                	lw	a5,64(s1)
    8000371e:	cf99                	beqz	a5,8000373c <ilock+0x40>
}
    80003720:	60e2                	ld	ra,24(sp)
    80003722:	6442                	ld	s0,16(sp)
    80003724:	64a2                	ld	s1,8(sp)
    80003726:	6902                	ld	s2,0(sp)
    80003728:	6105                	addi	sp,sp,32
    8000372a:	8082                	ret
    panic("ilock");
    8000372c:	00005517          	auipc	a0,0x5
    80003730:	e9c50513          	addi	a0,a0,-356 # 800085c8 <syscalls+0x180>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	e0a080e7          	jalr	-502(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000373c:	40dc                	lw	a5,4(s1)
    8000373e:	0047d79b          	srliw	a5,a5,0x4
    80003742:	0001c597          	auipc	a1,0x1c
    80003746:	47e5a583          	lw	a1,1150(a1) # 8001fbc0 <sb+0x18>
    8000374a:	9dbd                	addw	a1,a1,a5
    8000374c:	4088                	lw	a0,0(s1)
    8000374e:	fffff097          	auipc	ra,0xfffff
    80003752:	7ac080e7          	jalr	1964(ra) # 80002efa <bread>
    80003756:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003758:	05850593          	addi	a1,a0,88
    8000375c:	40dc                	lw	a5,4(s1)
    8000375e:	8bbd                	andi	a5,a5,15
    80003760:	079a                	slli	a5,a5,0x6
    80003762:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003764:	00059783          	lh	a5,0(a1)
    80003768:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000376c:	00259783          	lh	a5,2(a1)
    80003770:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003774:	00459783          	lh	a5,4(a1)
    80003778:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000377c:	00659783          	lh	a5,6(a1)
    80003780:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003784:	459c                	lw	a5,8(a1)
    80003786:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003788:	03400613          	li	a2,52
    8000378c:	05b1                	addi	a1,a1,12
    8000378e:	05048513          	addi	a0,s1,80
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	5ae080e7          	jalr	1454(ra) # 80000d40 <memmove>
    brelse(bp);
    8000379a:	854a                	mv	a0,s2
    8000379c:	00000097          	auipc	ra,0x0
    800037a0:	88e080e7          	jalr	-1906(ra) # 8000302a <brelse>
    ip->valid = 1;
    800037a4:	4785                	li	a5,1
    800037a6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037a8:	04449783          	lh	a5,68(s1)
    800037ac:	fbb5                	bnez	a5,80003720 <ilock+0x24>
      panic("ilock: no type");
    800037ae:	00005517          	auipc	a0,0x5
    800037b2:	e2250513          	addi	a0,a0,-478 # 800085d0 <syscalls+0x188>
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	d88080e7          	jalr	-632(ra) # 8000053e <panic>

00000000800037be <iunlock>:
{
    800037be:	1101                	addi	sp,sp,-32
    800037c0:	ec06                	sd	ra,24(sp)
    800037c2:	e822                	sd	s0,16(sp)
    800037c4:	e426                	sd	s1,8(sp)
    800037c6:	e04a                	sd	s2,0(sp)
    800037c8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037ca:	c905                	beqz	a0,800037fa <iunlock+0x3c>
    800037cc:	84aa                	mv	s1,a0
    800037ce:	01050913          	addi	s2,a0,16
    800037d2:	854a                	mv	a0,s2
    800037d4:	00001097          	auipc	ra,0x1
    800037d8:	c8c080e7          	jalr	-884(ra) # 80004460 <holdingsleep>
    800037dc:	cd19                	beqz	a0,800037fa <iunlock+0x3c>
    800037de:	449c                	lw	a5,8(s1)
    800037e0:	00f05d63          	blez	a5,800037fa <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037e4:	854a                	mv	a0,s2
    800037e6:	00001097          	auipc	ra,0x1
    800037ea:	c36080e7          	jalr	-970(ra) # 8000441c <releasesleep>
}
    800037ee:	60e2                	ld	ra,24(sp)
    800037f0:	6442                	ld	s0,16(sp)
    800037f2:	64a2                	ld	s1,8(sp)
    800037f4:	6902                	ld	s2,0(sp)
    800037f6:	6105                	addi	sp,sp,32
    800037f8:	8082                	ret
    panic("iunlock");
    800037fa:	00005517          	auipc	a0,0x5
    800037fe:	de650513          	addi	a0,a0,-538 # 800085e0 <syscalls+0x198>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	d3c080e7          	jalr	-708(ra) # 8000053e <panic>

000000008000380a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000380a:	7179                	addi	sp,sp,-48
    8000380c:	f406                	sd	ra,40(sp)
    8000380e:	f022                	sd	s0,32(sp)
    80003810:	ec26                	sd	s1,24(sp)
    80003812:	e84a                	sd	s2,16(sp)
    80003814:	e44e                	sd	s3,8(sp)
    80003816:	e052                	sd	s4,0(sp)
    80003818:	1800                	addi	s0,sp,48
    8000381a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000381c:	05050493          	addi	s1,a0,80
    80003820:	08050913          	addi	s2,a0,128
    80003824:	a021                	j	8000382c <itrunc+0x22>
    80003826:	0491                	addi	s1,s1,4
    80003828:	01248d63          	beq	s1,s2,80003842 <itrunc+0x38>
    if(ip->addrs[i]){
    8000382c:	408c                	lw	a1,0(s1)
    8000382e:	dde5                	beqz	a1,80003826 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003830:	0009a503          	lw	a0,0(s3)
    80003834:	00000097          	auipc	ra,0x0
    80003838:	90c080e7          	jalr	-1780(ra) # 80003140 <bfree>
      ip->addrs[i] = 0;
    8000383c:	0004a023          	sw	zero,0(s1)
    80003840:	b7dd                	j	80003826 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003842:	0809a583          	lw	a1,128(s3)
    80003846:	e185                	bnez	a1,80003866 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003848:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000384c:	854e                	mv	a0,s3
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	de4080e7          	jalr	-540(ra) # 80003632 <iupdate>
}
    80003856:	70a2                	ld	ra,40(sp)
    80003858:	7402                	ld	s0,32(sp)
    8000385a:	64e2                	ld	s1,24(sp)
    8000385c:	6942                	ld	s2,16(sp)
    8000385e:	69a2                	ld	s3,8(sp)
    80003860:	6a02                	ld	s4,0(sp)
    80003862:	6145                	addi	sp,sp,48
    80003864:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003866:	0009a503          	lw	a0,0(s3)
    8000386a:	fffff097          	auipc	ra,0xfffff
    8000386e:	690080e7          	jalr	1680(ra) # 80002efa <bread>
    80003872:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003874:	05850493          	addi	s1,a0,88
    80003878:	45850913          	addi	s2,a0,1112
    8000387c:	a811                	j	80003890 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000387e:	0009a503          	lw	a0,0(s3)
    80003882:	00000097          	auipc	ra,0x0
    80003886:	8be080e7          	jalr	-1858(ra) # 80003140 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000388a:	0491                	addi	s1,s1,4
    8000388c:	01248563          	beq	s1,s2,80003896 <itrunc+0x8c>
      if(a[j])
    80003890:	408c                	lw	a1,0(s1)
    80003892:	dde5                	beqz	a1,8000388a <itrunc+0x80>
    80003894:	b7ed                	j	8000387e <itrunc+0x74>
    brelse(bp);
    80003896:	8552                	mv	a0,s4
    80003898:	fffff097          	auipc	ra,0xfffff
    8000389c:	792080e7          	jalr	1938(ra) # 8000302a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038a0:	0809a583          	lw	a1,128(s3)
    800038a4:	0009a503          	lw	a0,0(s3)
    800038a8:	00000097          	auipc	ra,0x0
    800038ac:	898080e7          	jalr	-1896(ra) # 80003140 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038b0:	0809a023          	sw	zero,128(s3)
    800038b4:	bf51                	j	80003848 <itrunc+0x3e>

00000000800038b6 <iput>:
{
    800038b6:	1101                	addi	sp,sp,-32
    800038b8:	ec06                	sd	ra,24(sp)
    800038ba:	e822                	sd	s0,16(sp)
    800038bc:	e426                	sd	s1,8(sp)
    800038be:	e04a                	sd	s2,0(sp)
    800038c0:	1000                	addi	s0,sp,32
    800038c2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038c4:	0001c517          	auipc	a0,0x1c
    800038c8:	30450513          	addi	a0,a0,772 # 8001fbc8 <itable>
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	318080e7          	jalr	792(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038d4:	4498                	lw	a4,8(s1)
    800038d6:	4785                	li	a5,1
    800038d8:	02f70363          	beq	a4,a5,800038fe <iput+0x48>
  ip->ref--;
    800038dc:	449c                	lw	a5,8(s1)
    800038de:	37fd                	addiw	a5,a5,-1
    800038e0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038e2:	0001c517          	auipc	a0,0x1c
    800038e6:	2e650513          	addi	a0,a0,742 # 8001fbc8 <itable>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	3ae080e7          	jalr	942(ra) # 80000c98 <release>
}
    800038f2:	60e2                	ld	ra,24(sp)
    800038f4:	6442                	ld	s0,16(sp)
    800038f6:	64a2                	ld	s1,8(sp)
    800038f8:	6902                	ld	s2,0(sp)
    800038fa:	6105                	addi	sp,sp,32
    800038fc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038fe:	40bc                	lw	a5,64(s1)
    80003900:	dff1                	beqz	a5,800038dc <iput+0x26>
    80003902:	04a49783          	lh	a5,74(s1)
    80003906:	fbf9                	bnez	a5,800038dc <iput+0x26>
    acquiresleep(&ip->lock);
    80003908:	01048913          	addi	s2,s1,16
    8000390c:	854a                	mv	a0,s2
    8000390e:	00001097          	auipc	ra,0x1
    80003912:	ab8080e7          	jalr	-1352(ra) # 800043c6 <acquiresleep>
    release(&itable.lock);
    80003916:	0001c517          	auipc	a0,0x1c
    8000391a:	2b250513          	addi	a0,a0,690 # 8001fbc8 <itable>
    8000391e:	ffffd097          	auipc	ra,0xffffd
    80003922:	37a080e7          	jalr	890(ra) # 80000c98 <release>
    itrunc(ip);
    80003926:	8526                	mv	a0,s1
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	ee2080e7          	jalr	-286(ra) # 8000380a <itrunc>
    ip->type = 0;
    80003930:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003934:	8526                	mv	a0,s1
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	cfc080e7          	jalr	-772(ra) # 80003632 <iupdate>
    ip->valid = 0;
    8000393e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003942:	854a                	mv	a0,s2
    80003944:	00001097          	auipc	ra,0x1
    80003948:	ad8080e7          	jalr	-1320(ra) # 8000441c <releasesleep>
    acquire(&itable.lock);
    8000394c:	0001c517          	auipc	a0,0x1c
    80003950:	27c50513          	addi	a0,a0,636 # 8001fbc8 <itable>
    80003954:	ffffd097          	auipc	ra,0xffffd
    80003958:	290080e7          	jalr	656(ra) # 80000be4 <acquire>
    8000395c:	b741                	j	800038dc <iput+0x26>

000000008000395e <iunlockput>:
{
    8000395e:	1101                	addi	sp,sp,-32
    80003960:	ec06                	sd	ra,24(sp)
    80003962:	e822                	sd	s0,16(sp)
    80003964:	e426                	sd	s1,8(sp)
    80003966:	1000                	addi	s0,sp,32
    80003968:	84aa                	mv	s1,a0
  iunlock(ip);
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	e54080e7          	jalr	-428(ra) # 800037be <iunlock>
  iput(ip);
    80003972:	8526                	mv	a0,s1
    80003974:	00000097          	auipc	ra,0x0
    80003978:	f42080e7          	jalr	-190(ra) # 800038b6 <iput>
}
    8000397c:	60e2                	ld	ra,24(sp)
    8000397e:	6442                	ld	s0,16(sp)
    80003980:	64a2                	ld	s1,8(sp)
    80003982:	6105                	addi	sp,sp,32
    80003984:	8082                	ret

0000000080003986 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003986:	1141                	addi	sp,sp,-16
    80003988:	e422                	sd	s0,8(sp)
    8000398a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000398c:	411c                	lw	a5,0(a0)
    8000398e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003990:	415c                	lw	a5,4(a0)
    80003992:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003994:	04451783          	lh	a5,68(a0)
    80003998:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000399c:	04a51783          	lh	a5,74(a0)
    800039a0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039a4:	04c56783          	lwu	a5,76(a0)
    800039a8:	e99c                	sd	a5,16(a1)
}
    800039aa:	6422                	ld	s0,8(sp)
    800039ac:	0141                	addi	sp,sp,16
    800039ae:	8082                	ret

00000000800039b0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039b0:	457c                	lw	a5,76(a0)
    800039b2:	0ed7e963          	bltu	a5,a3,80003aa4 <readi+0xf4>
{
    800039b6:	7159                	addi	sp,sp,-112
    800039b8:	f486                	sd	ra,104(sp)
    800039ba:	f0a2                	sd	s0,96(sp)
    800039bc:	eca6                	sd	s1,88(sp)
    800039be:	e8ca                	sd	s2,80(sp)
    800039c0:	e4ce                	sd	s3,72(sp)
    800039c2:	e0d2                	sd	s4,64(sp)
    800039c4:	fc56                	sd	s5,56(sp)
    800039c6:	f85a                	sd	s6,48(sp)
    800039c8:	f45e                	sd	s7,40(sp)
    800039ca:	f062                	sd	s8,32(sp)
    800039cc:	ec66                	sd	s9,24(sp)
    800039ce:	e86a                	sd	s10,16(sp)
    800039d0:	e46e                	sd	s11,8(sp)
    800039d2:	1880                	addi	s0,sp,112
    800039d4:	8baa                	mv	s7,a0
    800039d6:	8c2e                	mv	s8,a1
    800039d8:	8ab2                	mv	s5,a2
    800039da:	84b6                	mv	s1,a3
    800039dc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039de:	9f35                	addw	a4,a4,a3
    return 0;
    800039e0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039e2:	0ad76063          	bltu	a4,a3,80003a82 <readi+0xd2>
  if(off + n > ip->size)
    800039e6:	00e7f463          	bgeu	a5,a4,800039ee <readi+0x3e>
    n = ip->size - off;
    800039ea:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039ee:	0a0b0963          	beqz	s6,80003aa0 <readi+0xf0>
    800039f2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039f4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039f8:	5cfd                	li	s9,-1
    800039fa:	a82d                	j	80003a34 <readi+0x84>
    800039fc:	020a1d93          	slli	s11,s4,0x20
    80003a00:	020ddd93          	srli	s11,s11,0x20
    80003a04:	05890613          	addi	a2,s2,88
    80003a08:	86ee                	mv	a3,s11
    80003a0a:	963a                	add	a2,a2,a4
    80003a0c:	85d6                	mv	a1,s5
    80003a0e:	8562                	mv	a0,s8
    80003a10:	fffff097          	auipc	ra,0xfffff
    80003a14:	ac2080e7          	jalr	-1342(ra) # 800024d2 <either_copyout>
    80003a18:	05950d63          	beq	a0,s9,80003a72 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a1c:	854a                	mv	a0,s2
    80003a1e:	fffff097          	auipc	ra,0xfffff
    80003a22:	60c080e7          	jalr	1548(ra) # 8000302a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a26:	013a09bb          	addw	s3,s4,s3
    80003a2a:	009a04bb          	addw	s1,s4,s1
    80003a2e:	9aee                	add	s5,s5,s11
    80003a30:	0569f763          	bgeu	s3,s6,80003a7e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a34:	000ba903          	lw	s2,0(s7)
    80003a38:	00a4d59b          	srliw	a1,s1,0xa
    80003a3c:	855e                	mv	a0,s7
    80003a3e:	00000097          	auipc	ra,0x0
    80003a42:	8b0080e7          	jalr	-1872(ra) # 800032ee <bmap>
    80003a46:	0005059b          	sext.w	a1,a0
    80003a4a:	854a                	mv	a0,s2
    80003a4c:	fffff097          	auipc	ra,0xfffff
    80003a50:	4ae080e7          	jalr	1198(ra) # 80002efa <bread>
    80003a54:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a56:	3ff4f713          	andi	a4,s1,1023
    80003a5a:	40ed07bb          	subw	a5,s10,a4
    80003a5e:	413b06bb          	subw	a3,s6,s3
    80003a62:	8a3e                	mv	s4,a5
    80003a64:	2781                	sext.w	a5,a5
    80003a66:	0006861b          	sext.w	a2,a3
    80003a6a:	f8f679e3          	bgeu	a2,a5,800039fc <readi+0x4c>
    80003a6e:	8a36                	mv	s4,a3
    80003a70:	b771                	j	800039fc <readi+0x4c>
      brelse(bp);
    80003a72:	854a                	mv	a0,s2
    80003a74:	fffff097          	auipc	ra,0xfffff
    80003a78:	5b6080e7          	jalr	1462(ra) # 8000302a <brelse>
      tot = -1;
    80003a7c:	59fd                	li	s3,-1
  }
  return tot;
    80003a7e:	0009851b          	sext.w	a0,s3
}
    80003a82:	70a6                	ld	ra,104(sp)
    80003a84:	7406                	ld	s0,96(sp)
    80003a86:	64e6                	ld	s1,88(sp)
    80003a88:	6946                	ld	s2,80(sp)
    80003a8a:	69a6                	ld	s3,72(sp)
    80003a8c:	6a06                	ld	s4,64(sp)
    80003a8e:	7ae2                	ld	s5,56(sp)
    80003a90:	7b42                	ld	s6,48(sp)
    80003a92:	7ba2                	ld	s7,40(sp)
    80003a94:	7c02                	ld	s8,32(sp)
    80003a96:	6ce2                	ld	s9,24(sp)
    80003a98:	6d42                	ld	s10,16(sp)
    80003a9a:	6da2                	ld	s11,8(sp)
    80003a9c:	6165                	addi	sp,sp,112
    80003a9e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa0:	89da                	mv	s3,s6
    80003aa2:	bff1                	j	80003a7e <readi+0xce>
    return 0;
    80003aa4:	4501                	li	a0,0
}
    80003aa6:	8082                	ret

0000000080003aa8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aa8:	457c                	lw	a5,76(a0)
    80003aaa:	10d7e863          	bltu	a5,a3,80003bba <writei+0x112>
{
    80003aae:	7159                	addi	sp,sp,-112
    80003ab0:	f486                	sd	ra,104(sp)
    80003ab2:	f0a2                	sd	s0,96(sp)
    80003ab4:	eca6                	sd	s1,88(sp)
    80003ab6:	e8ca                	sd	s2,80(sp)
    80003ab8:	e4ce                	sd	s3,72(sp)
    80003aba:	e0d2                	sd	s4,64(sp)
    80003abc:	fc56                	sd	s5,56(sp)
    80003abe:	f85a                	sd	s6,48(sp)
    80003ac0:	f45e                	sd	s7,40(sp)
    80003ac2:	f062                	sd	s8,32(sp)
    80003ac4:	ec66                	sd	s9,24(sp)
    80003ac6:	e86a                	sd	s10,16(sp)
    80003ac8:	e46e                	sd	s11,8(sp)
    80003aca:	1880                	addi	s0,sp,112
    80003acc:	8b2a                	mv	s6,a0
    80003ace:	8c2e                	mv	s8,a1
    80003ad0:	8ab2                	mv	s5,a2
    80003ad2:	8936                	mv	s2,a3
    80003ad4:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ad6:	00e687bb          	addw	a5,a3,a4
    80003ada:	0ed7e263          	bltu	a5,a3,80003bbe <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ade:	00043737          	lui	a4,0x43
    80003ae2:	0ef76063          	bltu	a4,a5,80003bc2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ae6:	0c0b8863          	beqz	s7,80003bb6 <writei+0x10e>
    80003aea:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aec:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003af0:	5cfd                	li	s9,-1
    80003af2:	a091                	j	80003b36 <writei+0x8e>
    80003af4:	02099d93          	slli	s11,s3,0x20
    80003af8:	020ddd93          	srli	s11,s11,0x20
    80003afc:	05848513          	addi	a0,s1,88
    80003b00:	86ee                	mv	a3,s11
    80003b02:	8656                	mv	a2,s5
    80003b04:	85e2                	mv	a1,s8
    80003b06:	953a                	add	a0,a0,a4
    80003b08:	fffff097          	auipc	ra,0xfffff
    80003b0c:	a20080e7          	jalr	-1504(ra) # 80002528 <either_copyin>
    80003b10:	07950263          	beq	a0,s9,80003b74 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b14:	8526                	mv	a0,s1
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	790080e7          	jalr	1936(ra) # 800042a6 <log_write>
    brelse(bp);
    80003b1e:	8526                	mv	a0,s1
    80003b20:	fffff097          	auipc	ra,0xfffff
    80003b24:	50a080e7          	jalr	1290(ra) # 8000302a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b28:	01498a3b          	addw	s4,s3,s4
    80003b2c:	0129893b          	addw	s2,s3,s2
    80003b30:	9aee                	add	s5,s5,s11
    80003b32:	057a7663          	bgeu	s4,s7,80003b7e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b36:	000b2483          	lw	s1,0(s6)
    80003b3a:	00a9559b          	srliw	a1,s2,0xa
    80003b3e:	855a                	mv	a0,s6
    80003b40:	fffff097          	auipc	ra,0xfffff
    80003b44:	7ae080e7          	jalr	1966(ra) # 800032ee <bmap>
    80003b48:	0005059b          	sext.w	a1,a0
    80003b4c:	8526                	mv	a0,s1
    80003b4e:	fffff097          	auipc	ra,0xfffff
    80003b52:	3ac080e7          	jalr	940(ra) # 80002efa <bread>
    80003b56:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b58:	3ff97713          	andi	a4,s2,1023
    80003b5c:	40ed07bb          	subw	a5,s10,a4
    80003b60:	414b86bb          	subw	a3,s7,s4
    80003b64:	89be                	mv	s3,a5
    80003b66:	2781                	sext.w	a5,a5
    80003b68:	0006861b          	sext.w	a2,a3
    80003b6c:	f8f674e3          	bgeu	a2,a5,80003af4 <writei+0x4c>
    80003b70:	89b6                	mv	s3,a3
    80003b72:	b749                	j	80003af4 <writei+0x4c>
      brelse(bp);
    80003b74:	8526                	mv	a0,s1
    80003b76:	fffff097          	auipc	ra,0xfffff
    80003b7a:	4b4080e7          	jalr	1204(ra) # 8000302a <brelse>
  }

  if(off > ip->size)
    80003b7e:	04cb2783          	lw	a5,76(s6)
    80003b82:	0127f463          	bgeu	a5,s2,80003b8a <writei+0xe2>
    ip->size = off;
    80003b86:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b8a:	855a                	mv	a0,s6
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	aa6080e7          	jalr	-1370(ra) # 80003632 <iupdate>

  return tot;
    80003b94:	000a051b          	sext.w	a0,s4
}
    80003b98:	70a6                	ld	ra,104(sp)
    80003b9a:	7406                	ld	s0,96(sp)
    80003b9c:	64e6                	ld	s1,88(sp)
    80003b9e:	6946                	ld	s2,80(sp)
    80003ba0:	69a6                	ld	s3,72(sp)
    80003ba2:	6a06                	ld	s4,64(sp)
    80003ba4:	7ae2                	ld	s5,56(sp)
    80003ba6:	7b42                	ld	s6,48(sp)
    80003ba8:	7ba2                	ld	s7,40(sp)
    80003baa:	7c02                	ld	s8,32(sp)
    80003bac:	6ce2                	ld	s9,24(sp)
    80003bae:	6d42                	ld	s10,16(sp)
    80003bb0:	6da2                	ld	s11,8(sp)
    80003bb2:	6165                	addi	sp,sp,112
    80003bb4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bb6:	8a5e                	mv	s4,s7
    80003bb8:	bfc9                	j	80003b8a <writei+0xe2>
    return -1;
    80003bba:	557d                	li	a0,-1
}
    80003bbc:	8082                	ret
    return -1;
    80003bbe:	557d                	li	a0,-1
    80003bc0:	bfe1                	j	80003b98 <writei+0xf0>
    return -1;
    80003bc2:	557d                	li	a0,-1
    80003bc4:	bfd1                	j	80003b98 <writei+0xf0>

0000000080003bc6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bc6:	1141                	addi	sp,sp,-16
    80003bc8:	e406                	sd	ra,8(sp)
    80003bca:	e022                	sd	s0,0(sp)
    80003bcc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bce:	4639                	li	a2,14
    80003bd0:	ffffd097          	auipc	ra,0xffffd
    80003bd4:	1e8080e7          	jalr	488(ra) # 80000db8 <strncmp>
}
    80003bd8:	60a2                	ld	ra,8(sp)
    80003bda:	6402                	ld	s0,0(sp)
    80003bdc:	0141                	addi	sp,sp,16
    80003bde:	8082                	ret

0000000080003be0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003be0:	7139                	addi	sp,sp,-64
    80003be2:	fc06                	sd	ra,56(sp)
    80003be4:	f822                	sd	s0,48(sp)
    80003be6:	f426                	sd	s1,40(sp)
    80003be8:	f04a                	sd	s2,32(sp)
    80003bea:	ec4e                	sd	s3,24(sp)
    80003bec:	e852                	sd	s4,16(sp)
    80003bee:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bf0:	04451703          	lh	a4,68(a0)
    80003bf4:	4785                	li	a5,1
    80003bf6:	00f71a63          	bne	a4,a5,80003c0a <dirlookup+0x2a>
    80003bfa:	892a                	mv	s2,a0
    80003bfc:	89ae                	mv	s3,a1
    80003bfe:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c00:	457c                	lw	a5,76(a0)
    80003c02:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c04:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c06:	e79d                	bnez	a5,80003c34 <dirlookup+0x54>
    80003c08:	a8a5                	j	80003c80 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c0a:	00005517          	auipc	a0,0x5
    80003c0e:	9de50513          	addi	a0,a0,-1570 # 800085e8 <syscalls+0x1a0>
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	92c080e7          	jalr	-1748(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c1a:	00005517          	auipc	a0,0x5
    80003c1e:	9e650513          	addi	a0,a0,-1562 # 80008600 <syscalls+0x1b8>
    80003c22:	ffffd097          	auipc	ra,0xffffd
    80003c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c2a:	24c1                	addiw	s1,s1,16
    80003c2c:	04c92783          	lw	a5,76(s2)
    80003c30:	04f4f763          	bgeu	s1,a5,80003c7e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c34:	4741                	li	a4,16
    80003c36:	86a6                	mv	a3,s1
    80003c38:	fc040613          	addi	a2,s0,-64
    80003c3c:	4581                	li	a1,0
    80003c3e:	854a                	mv	a0,s2
    80003c40:	00000097          	auipc	ra,0x0
    80003c44:	d70080e7          	jalr	-656(ra) # 800039b0 <readi>
    80003c48:	47c1                	li	a5,16
    80003c4a:	fcf518e3          	bne	a0,a5,80003c1a <dirlookup+0x3a>
    if(de.inum == 0)
    80003c4e:	fc045783          	lhu	a5,-64(s0)
    80003c52:	dfe1                	beqz	a5,80003c2a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c54:	fc240593          	addi	a1,s0,-62
    80003c58:	854e                	mv	a0,s3
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	f6c080e7          	jalr	-148(ra) # 80003bc6 <namecmp>
    80003c62:	f561                	bnez	a0,80003c2a <dirlookup+0x4a>
      if(poff)
    80003c64:	000a0463          	beqz	s4,80003c6c <dirlookup+0x8c>
        *poff = off;
    80003c68:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c6c:	fc045583          	lhu	a1,-64(s0)
    80003c70:	00092503          	lw	a0,0(s2)
    80003c74:	fffff097          	auipc	ra,0xfffff
    80003c78:	754080e7          	jalr	1876(ra) # 800033c8 <iget>
    80003c7c:	a011                	j	80003c80 <dirlookup+0xa0>
  return 0;
    80003c7e:	4501                	li	a0,0
}
    80003c80:	70e2                	ld	ra,56(sp)
    80003c82:	7442                	ld	s0,48(sp)
    80003c84:	74a2                	ld	s1,40(sp)
    80003c86:	7902                	ld	s2,32(sp)
    80003c88:	69e2                	ld	s3,24(sp)
    80003c8a:	6a42                	ld	s4,16(sp)
    80003c8c:	6121                	addi	sp,sp,64
    80003c8e:	8082                	ret

0000000080003c90 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c90:	711d                	addi	sp,sp,-96
    80003c92:	ec86                	sd	ra,88(sp)
    80003c94:	e8a2                	sd	s0,80(sp)
    80003c96:	e4a6                	sd	s1,72(sp)
    80003c98:	e0ca                	sd	s2,64(sp)
    80003c9a:	fc4e                	sd	s3,56(sp)
    80003c9c:	f852                	sd	s4,48(sp)
    80003c9e:	f456                	sd	s5,40(sp)
    80003ca0:	f05a                	sd	s6,32(sp)
    80003ca2:	ec5e                	sd	s7,24(sp)
    80003ca4:	e862                	sd	s8,16(sp)
    80003ca6:	e466                	sd	s9,8(sp)
    80003ca8:	1080                	addi	s0,sp,96
    80003caa:	84aa                	mv	s1,a0
    80003cac:	8b2e                	mv	s6,a1
    80003cae:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cb0:	00054703          	lbu	a4,0(a0)
    80003cb4:	02f00793          	li	a5,47
    80003cb8:	02f70363          	beq	a4,a5,80003cde <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cbc:	ffffe097          	auipc	ra,0xffffe
    80003cc0:	cf4080e7          	jalr	-780(ra) # 800019b0 <myproc>
    80003cc4:	15053503          	ld	a0,336(a0)
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	9f6080e7          	jalr	-1546(ra) # 800036be <idup>
    80003cd0:	89aa                	mv	s3,a0
  while(*path == '/')
    80003cd2:	02f00913          	li	s2,47
  len = path - s;
    80003cd6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003cd8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cda:	4c05                	li	s8,1
    80003cdc:	a865                	j	80003d94 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003cde:	4585                	li	a1,1
    80003ce0:	4505                	li	a0,1
    80003ce2:	fffff097          	auipc	ra,0xfffff
    80003ce6:	6e6080e7          	jalr	1766(ra) # 800033c8 <iget>
    80003cea:	89aa                	mv	s3,a0
    80003cec:	b7dd                	j	80003cd2 <namex+0x42>
      iunlockput(ip);
    80003cee:	854e                	mv	a0,s3
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	c6e080e7          	jalr	-914(ra) # 8000395e <iunlockput>
      return 0;
    80003cf8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cfa:	854e                	mv	a0,s3
    80003cfc:	60e6                	ld	ra,88(sp)
    80003cfe:	6446                	ld	s0,80(sp)
    80003d00:	64a6                	ld	s1,72(sp)
    80003d02:	6906                	ld	s2,64(sp)
    80003d04:	79e2                	ld	s3,56(sp)
    80003d06:	7a42                	ld	s4,48(sp)
    80003d08:	7aa2                	ld	s5,40(sp)
    80003d0a:	7b02                	ld	s6,32(sp)
    80003d0c:	6be2                	ld	s7,24(sp)
    80003d0e:	6c42                	ld	s8,16(sp)
    80003d10:	6ca2                	ld	s9,8(sp)
    80003d12:	6125                	addi	sp,sp,96
    80003d14:	8082                	ret
      iunlock(ip);
    80003d16:	854e                	mv	a0,s3
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	aa6080e7          	jalr	-1370(ra) # 800037be <iunlock>
      return ip;
    80003d20:	bfe9                	j	80003cfa <namex+0x6a>
      iunlockput(ip);
    80003d22:	854e                	mv	a0,s3
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	c3a080e7          	jalr	-966(ra) # 8000395e <iunlockput>
      return 0;
    80003d2c:	89d2                	mv	s3,s4
    80003d2e:	b7f1                	j	80003cfa <namex+0x6a>
  len = path - s;
    80003d30:	40b48633          	sub	a2,s1,a1
    80003d34:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d38:	094cd463          	bge	s9,s4,80003dc0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d3c:	4639                	li	a2,14
    80003d3e:	8556                	mv	a0,s5
    80003d40:	ffffd097          	auipc	ra,0xffffd
    80003d44:	000080e7          	jalr	ra # 80000d40 <memmove>
  while(*path == '/')
    80003d48:	0004c783          	lbu	a5,0(s1)
    80003d4c:	01279763          	bne	a5,s2,80003d5a <namex+0xca>
    path++;
    80003d50:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d52:	0004c783          	lbu	a5,0(s1)
    80003d56:	ff278de3          	beq	a5,s2,80003d50 <namex+0xc0>
    ilock(ip);
    80003d5a:	854e                	mv	a0,s3
    80003d5c:	00000097          	auipc	ra,0x0
    80003d60:	9a0080e7          	jalr	-1632(ra) # 800036fc <ilock>
    if(ip->type != T_DIR){
    80003d64:	04499783          	lh	a5,68(s3)
    80003d68:	f98793e3          	bne	a5,s8,80003cee <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d6c:	000b0563          	beqz	s6,80003d76 <namex+0xe6>
    80003d70:	0004c783          	lbu	a5,0(s1)
    80003d74:	d3cd                	beqz	a5,80003d16 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d76:	865e                	mv	a2,s7
    80003d78:	85d6                	mv	a1,s5
    80003d7a:	854e                	mv	a0,s3
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	e64080e7          	jalr	-412(ra) # 80003be0 <dirlookup>
    80003d84:	8a2a                	mv	s4,a0
    80003d86:	dd51                	beqz	a0,80003d22 <namex+0x92>
    iunlockput(ip);
    80003d88:	854e                	mv	a0,s3
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	bd4080e7          	jalr	-1068(ra) # 8000395e <iunlockput>
    ip = next;
    80003d92:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d94:	0004c783          	lbu	a5,0(s1)
    80003d98:	05279763          	bne	a5,s2,80003de6 <namex+0x156>
    path++;
    80003d9c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d9e:	0004c783          	lbu	a5,0(s1)
    80003da2:	ff278de3          	beq	a5,s2,80003d9c <namex+0x10c>
  if(*path == 0)
    80003da6:	c79d                	beqz	a5,80003dd4 <namex+0x144>
    path++;
    80003da8:	85a6                	mv	a1,s1
  len = path - s;
    80003daa:	8a5e                	mv	s4,s7
    80003dac:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dae:	01278963          	beq	a5,s2,80003dc0 <namex+0x130>
    80003db2:	dfbd                	beqz	a5,80003d30 <namex+0xa0>
    path++;
    80003db4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003db6:	0004c783          	lbu	a5,0(s1)
    80003dba:	ff279ce3          	bne	a5,s2,80003db2 <namex+0x122>
    80003dbe:	bf8d                	j	80003d30 <namex+0xa0>
    memmove(name, s, len);
    80003dc0:	2601                	sext.w	a2,a2
    80003dc2:	8556                	mv	a0,s5
    80003dc4:	ffffd097          	auipc	ra,0xffffd
    80003dc8:	f7c080e7          	jalr	-132(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003dcc:	9a56                	add	s4,s4,s5
    80003dce:	000a0023          	sb	zero,0(s4)
    80003dd2:	bf9d                	j	80003d48 <namex+0xb8>
  if(nameiparent){
    80003dd4:	f20b03e3          	beqz	s6,80003cfa <namex+0x6a>
    iput(ip);
    80003dd8:	854e                	mv	a0,s3
    80003dda:	00000097          	auipc	ra,0x0
    80003dde:	adc080e7          	jalr	-1316(ra) # 800038b6 <iput>
    return 0;
    80003de2:	4981                	li	s3,0
    80003de4:	bf19                	j	80003cfa <namex+0x6a>
  if(*path == 0)
    80003de6:	d7fd                	beqz	a5,80003dd4 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003de8:	0004c783          	lbu	a5,0(s1)
    80003dec:	85a6                	mv	a1,s1
    80003dee:	b7d1                	j	80003db2 <namex+0x122>

0000000080003df0 <dirlink>:
{
    80003df0:	7139                	addi	sp,sp,-64
    80003df2:	fc06                	sd	ra,56(sp)
    80003df4:	f822                	sd	s0,48(sp)
    80003df6:	f426                	sd	s1,40(sp)
    80003df8:	f04a                	sd	s2,32(sp)
    80003dfa:	ec4e                	sd	s3,24(sp)
    80003dfc:	e852                	sd	s4,16(sp)
    80003dfe:	0080                	addi	s0,sp,64
    80003e00:	892a                	mv	s2,a0
    80003e02:	8a2e                	mv	s4,a1
    80003e04:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e06:	4601                	li	a2,0
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	dd8080e7          	jalr	-552(ra) # 80003be0 <dirlookup>
    80003e10:	e93d                	bnez	a0,80003e86 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e12:	04c92483          	lw	s1,76(s2)
    80003e16:	c49d                	beqz	s1,80003e44 <dirlink+0x54>
    80003e18:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e1a:	4741                	li	a4,16
    80003e1c:	86a6                	mv	a3,s1
    80003e1e:	fc040613          	addi	a2,s0,-64
    80003e22:	4581                	li	a1,0
    80003e24:	854a                	mv	a0,s2
    80003e26:	00000097          	auipc	ra,0x0
    80003e2a:	b8a080e7          	jalr	-1142(ra) # 800039b0 <readi>
    80003e2e:	47c1                	li	a5,16
    80003e30:	06f51163          	bne	a0,a5,80003e92 <dirlink+0xa2>
    if(de.inum == 0)
    80003e34:	fc045783          	lhu	a5,-64(s0)
    80003e38:	c791                	beqz	a5,80003e44 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e3a:	24c1                	addiw	s1,s1,16
    80003e3c:	04c92783          	lw	a5,76(s2)
    80003e40:	fcf4ede3          	bltu	s1,a5,80003e1a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e44:	4639                	li	a2,14
    80003e46:	85d2                	mv	a1,s4
    80003e48:	fc240513          	addi	a0,s0,-62
    80003e4c:	ffffd097          	auipc	ra,0xffffd
    80003e50:	fa8080e7          	jalr	-88(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003e54:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e58:	4741                	li	a4,16
    80003e5a:	86a6                	mv	a3,s1
    80003e5c:	fc040613          	addi	a2,s0,-64
    80003e60:	4581                	li	a1,0
    80003e62:	854a                	mv	a0,s2
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	c44080e7          	jalr	-956(ra) # 80003aa8 <writei>
    80003e6c:	872a                	mv	a4,a0
    80003e6e:	47c1                	li	a5,16
  return 0;
    80003e70:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e72:	02f71863          	bne	a4,a5,80003ea2 <dirlink+0xb2>
}
    80003e76:	70e2                	ld	ra,56(sp)
    80003e78:	7442                	ld	s0,48(sp)
    80003e7a:	74a2                	ld	s1,40(sp)
    80003e7c:	7902                	ld	s2,32(sp)
    80003e7e:	69e2                	ld	s3,24(sp)
    80003e80:	6a42                	ld	s4,16(sp)
    80003e82:	6121                	addi	sp,sp,64
    80003e84:	8082                	ret
    iput(ip);
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	a30080e7          	jalr	-1488(ra) # 800038b6 <iput>
    return -1;
    80003e8e:	557d                	li	a0,-1
    80003e90:	b7dd                	j	80003e76 <dirlink+0x86>
      panic("dirlink read");
    80003e92:	00004517          	auipc	a0,0x4
    80003e96:	77e50513          	addi	a0,a0,1918 # 80008610 <syscalls+0x1c8>
    80003e9a:	ffffc097          	auipc	ra,0xffffc
    80003e9e:	6a4080e7          	jalr	1700(ra) # 8000053e <panic>
    panic("dirlink");
    80003ea2:	00005517          	auipc	a0,0x5
    80003ea6:	87e50513          	addi	a0,a0,-1922 # 80008720 <syscalls+0x2d8>
    80003eaa:	ffffc097          	auipc	ra,0xffffc
    80003eae:	694080e7          	jalr	1684(ra) # 8000053e <panic>

0000000080003eb2 <namei>:

struct inode*
namei(char *path)
{
    80003eb2:	1101                	addi	sp,sp,-32
    80003eb4:	ec06                	sd	ra,24(sp)
    80003eb6:	e822                	sd	s0,16(sp)
    80003eb8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003eba:	fe040613          	addi	a2,s0,-32
    80003ebe:	4581                	li	a1,0
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	dd0080e7          	jalr	-560(ra) # 80003c90 <namex>
}
    80003ec8:	60e2                	ld	ra,24(sp)
    80003eca:	6442                	ld	s0,16(sp)
    80003ecc:	6105                	addi	sp,sp,32
    80003ece:	8082                	ret

0000000080003ed0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ed0:	1141                	addi	sp,sp,-16
    80003ed2:	e406                	sd	ra,8(sp)
    80003ed4:	e022                	sd	s0,0(sp)
    80003ed6:	0800                	addi	s0,sp,16
    80003ed8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003eda:	4585                	li	a1,1
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	db4080e7          	jalr	-588(ra) # 80003c90 <namex>
}
    80003ee4:	60a2                	ld	ra,8(sp)
    80003ee6:	6402                	ld	s0,0(sp)
    80003ee8:	0141                	addi	sp,sp,16
    80003eea:	8082                	ret

0000000080003eec <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003eec:	1101                	addi	sp,sp,-32
    80003eee:	ec06                	sd	ra,24(sp)
    80003ef0:	e822                	sd	s0,16(sp)
    80003ef2:	e426                	sd	s1,8(sp)
    80003ef4:	e04a                	sd	s2,0(sp)
    80003ef6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ef8:	0001d917          	auipc	s2,0x1d
    80003efc:	77890913          	addi	s2,s2,1912 # 80021670 <log>
    80003f00:	01892583          	lw	a1,24(s2)
    80003f04:	02892503          	lw	a0,40(s2)
    80003f08:	fffff097          	auipc	ra,0xfffff
    80003f0c:	ff2080e7          	jalr	-14(ra) # 80002efa <bread>
    80003f10:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f12:	02c92683          	lw	a3,44(s2)
    80003f16:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f18:	02d05763          	blez	a3,80003f46 <write_head+0x5a>
    80003f1c:	0001d797          	auipc	a5,0x1d
    80003f20:	78478793          	addi	a5,a5,1924 # 800216a0 <log+0x30>
    80003f24:	05c50713          	addi	a4,a0,92
    80003f28:	36fd                	addiw	a3,a3,-1
    80003f2a:	1682                	slli	a3,a3,0x20
    80003f2c:	9281                	srli	a3,a3,0x20
    80003f2e:	068a                	slli	a3,a3,0x2
    80003f30:	0001d617          	auipc	a2,0x1d
    80003f34:	77460613          	addi	a2,a2,1908 # 800216a4 <log+0x34>
    80003f38:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f3a:	4390                	lw	a2,0(a5)
    80003f3c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f3e:	0791                	addi	a5,a5,4
    80003f40:	0711                	addi	a4,a4,4
    80003f42:	fed79ce3          	bne	a5,a3,80003f3a <write_head+0x4e>
  }
  bwrite(buf);
    80003f46:	8526                	mv	a0,s1
    80003f48:	fffff097          	auipc	ra,0xfffff
    80003f4c:	0a4080e7          	jalr	164(ra) # 80002fec <bwrite>
  brelse(buf);
    80003f50:	8526                	mv	a0,s1
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	0d8080e7          	jalr	216(ra) # 8000302a <brelse>
}
    80003f5a:	60e2                	ld	ra,24(sp)
    80003f5c:	6442                	ld	s0,16(sp)
    80003f5e:	64a2                	ld	s1,8(sp)
    80003f60:	6902                	ld	s2,0(sp)
    80003f62:	6105                	addi	sp,sp,32
    80003f64:	8082                	ret

0000000080003f66 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f66:	0001d797          	auipc	a5,0x1d
    80003f6a:	7367a783          	lw	a5,1846(a5) # 8002169c <log+0x2c>
    80003f6e:	0af05d63          	blez	a5,80004028 <install_trans+0xc2>
{
    80003f72:	7139                	addi	sp,sp,-64
    80003f74:	fc06                	sd	ra,56(sp)
    80003f76:	f822                	sd	s0,48(sp)
    80003f78:	f426                	sd	s1,40(sp)
    80003f7a:	f04a                	sd	s2,32(sp)
    80003f7c:	ec4e                	sd	s3,24(sp)
    80003f7e:	e852                	sd	s4,16(sp)
    80003f80:	e456                	sd	s5,8(sp)
    80003f82:	e05a                	sd	s6,0(sp)
    80003f84:	0080                	addi	s0,sp,64
    80003f86:	8b2a                	mv	s6,a0
    80003f88:	0001da97          	auipc	s5,0x1d
    80003f8c:	718a8a93          	addi	s5,s5,1816 # 800216a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f90:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f92:	0001d997          	auipc	s3,0x1d
    80003f96:	6de98993          	addi	s3,s3,1758 # 80021670 <log>
    80003f9a:	a035                	j	80003fc6 <install_trans+0x60>
      bunpin(dbuf);
    80003f9c:	8526                	mv	a0,s1
    80003f9e:	fffff097          	auipc	ra,0xfffff
    80003fa2:	166080e7          	jalr	358(ra) # 80003104 <bunpin>
    brelse(lbuf);
    80003fa6:	854a                	mv	a0,s2
    80003fa8:	fffff097          	auipc	ra,0xfffff
    80003fac:	082080e7          	jalr	130(ra) # 8000302a <brelse>
    brelse(dbuf);
    80003fb0:	8526                	mv	a0,s1
    80003fb2:	fffff097          	auipc	ra,0xfffff
    80003fb6:	078080e7          	jalr	120(ra) # 8000302a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fba:	2a05                	addiw	s4,s4,1
    80003fbc:	0a91                	addi	s5,s5,4
    80003fbe:	02c9a783          	lw	a5,44(s3)
    80003fc2:	04fa5963          	bge	s4,a5,80004014 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fc6:	0189a583          	lw	a1,24(s3)
    80003fca:	014585bb          	addw	a1,a1,s4
    80003fce:	2585                	addiw	a1,a1,1
    80003fd0:	0289a503          	lw	a0,40(s3)
    80003fd4:	fffff097          	auipc	ra,0xfffff
    80003fd8:	f26080e7          	jalr	-218(ra) # 80002efa <bread>
    80003fdc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fde:	000aa583          	lw	a1,0(s5)
    80003fe2:	0289a503          	lw	a0,40(s3)
    80003fe6:	fffff097          	auipc	ra,0xfffff
    80003fea:	f14080e7          	jalr	-236(ra) # 80002efa <bread>
    80003fee:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ff0:	40000613          	li	a2,1024
    80003ff4:	05890593          	addi	a1,s2,88
    80003ff8:	05850513          	addi	a0,a0,88
    80003ffc:	ffffd097          	auipc	ra,0xffffd
    80004000:	d44080e7          	jalr	-700(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004004:	8526                	mv	a0,s1
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	fe6080e7          	jalr	-26(ra) # 80002fec <bwrite>
    if(recovering == 0)
    8000400e:	f80b1ce3          	bnez	s6,80003fa6 <install_trans+0x40>
    80004012:	b769                	j	80003f9c <install_trans+0x36>
}
    80004014:	70e2                	ld	ra,56(sp)
    80004016:	7442                	ld	s0,48(sp)
    80004018:	74a2                	ld	s1,40(sp)
    8000401a:	7902                	ld	s2,32(sp)
    8000401c:	69e2                	ld	s3,24(sp)
    8000401e:	6a42                	ld	s4,16(sp)
    80004020:	6aa2                	ld	s5,8(sp)
    80004022:	6b02                	ld	s6,0(sp)
    80004024:	6121                	addi	sp,sp,64
    80004026:	8082                	ret
    80004028:	8082                	ret

000000008000402a <initlog>:
{
    8000402a:	7179                	addi	sp,sp,-48
    8000402c:	f406                	sd	ra,40(sp)
    8000402e:	f022                	sd	s0,32(sp)
    80004030:	ec26                	sd	s1,24(sp)
    80004032:	e84a                	sd	s2,16(sp)
    80004034:	e44e                	sd	s3,8(sp)
    80004036:	1800                	addi	s0,sp,48
    80004038:	892a                	mv	s2,a0
    8000403a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000403c:	0001d497          	auipc	s1,0x1d
    80004040:	63448493          	addi	s1,s1,1588 # 80021670 <log>
    80004044:	00004597          	auipc	a1,0x4
    80004048:	5dc58593          	addi	a1,a1,1500 # 80008620 <syscalls+0x1d8>
    8000404c:	8526                	mv	a0,s1
    8000404e:	ffffd097          	auipc	ra,0xffffd
    80004052:	b06080e7          	jalr	-1274(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004056:	0149a583          	lw	a1,20(s3)
    8000405a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000405c:	0109a783          	lw	a5,16(s3)
    80004060:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004062:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004066:	854a                	mv	a0,s2
    80004068:	fffff097          	auipc	ra,0xfffff
    8000406c:	e92080e7          	jalr	-366(ra) # 80002efa <bread>
  log.lh.n = lh->n;
    80004070:	4d3c                	lw	a5,88(a0)
    80004072:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004074:	02f05563          	blez	a5,8000409e <initlog+0x74>
    80004078:	05c50713          	addi	a4,a0,92
    8000407c:	0001d697          	auipc	a3,0x1d
    80004080:	62468693          	addi	a3,a3,1572 # 800216a0 <log+0x30>
    80004084:	37fd                	addiw	a5,a5,-1
    80004086:	1782                	slli	a5,a5,0x20
    80004088:	9381                	srli	a5,a5,0x20
    8000408a:	078a                	slli	a5,a5,0x2
    8000408c:	06050613          	addi	a2,a0,96
    80004090:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004092:	4310                	lw	a2,0(a4)
    80004094:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004096:	0711                	addi	a4,a4,4
    80004098:	0691                	addi	a3,a3,4
    8000409a:	fef71ce3          	bne	a4,a5,80004092 <initlog+0x68>
  brelse(buf);
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	f8c080e7          	jalr	-116(ra) # 8000302a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040a6:	4505                	li	a0,1
    800040a8:	00000097          	auipc	ra,0x0
    800040ac:	ebe080e7          	jalr	-322(ra) # 80003f66 <install_trans>
  log.lh.n = 0;
    800040b0:	0001d797          	auipc	a5,0x1d
    800040b4:	5e07a623          	sw	zero,1516(a5) # 8002169c <log+0x2c>
  write_head(); // clear the log
    800040b8:	00000097          	auipc	ra,0x0
    800040bc:	e34080e7          	jalr	-460(ra) # 80003eec <write_head>
}
    800040c0:	70a2                	ld	ra,40(sp)
    800040c2:	7402                	ld	s0,32(sp)
    800040c4:	64e2                	ld	s1,24(sp)
    800040c6:	6942                	ld	s2,16(sp)
    800040c8:	69a2                	ld	s3,8(sp)
    800040ca:	6145                	addi	sp,sp,48
    800040cc:	8082                	ret

00000000800040ce <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040ce:	1101                	addi	sp,sp,-32
    800040d0:	ec06                	sd	ra,24(sp)
    800040d2:	e822                	sd	s0,16(sp)
    800040d4:	e426                	sd	s1,8(sp)
    800040d6:	e04a                	sd	s2,0(sp)
    800040d8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040da:	0001d517          	auipc	a0,0x1d
    800040de:	59650513          	addi	a0,a0,1430 # 80021670 <log>
    800040e2:	ffffd097          	auipc	ra,0xffffd
    800040e6:	b02080e7          	jalr	-1278(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800040ea:	0001d497          	auipc	s1,0x1d
    800040ee:	58648493          	addi	s1,s1,1414 # 80021670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040f2:	4979                	li	s2,30
    800040f4:	a039                	j	80004102 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040f6:	85a6                	mv	a1,s1
    800040f8:	8526                	mv	a0,s1
    800040fa:	ffffe097          	auipc	ra,0xffffe
    800040fe:	026080e7          	jalr	38(ra) # 80002120 <sleep>
    if(log.committing){
    80004102:	50dc                	lw	a5,36(s1)
    80004104:	fbed                	bnez	a5,800040f6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004106:	509c                	lw	a5,32(s1)
    80004108:	0017871b          	addiw	a4,a5,1
    8000410c:	0007069b          	sext.w	a3,a4
    80004110:	0027179b          	slliw	a5,a4,0x2
    80004114:	9fb9                	addw	a5,a5,a4
    80004116:	0017979b          	slliw	a5,a5,0x1
    8000411a:	54d8                	lw	a4,44(s1)
    8000411c:	9fb9                	addw	a5,a5,a4
    8000411e:	00f95963          	bge	s2,a5,80004130 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004122:	85a6                	mv	a1,s1
    80004124:	8526                	mv	a0,s1
    80004126:	ffffe097          	auipc	ra,0xffffe
    8000412a:	ffa080e7          	jalr	-6(ra) # 80002120 <sleep>
    8000412e:	bfd1                	j	80004102 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004130:	0001d517          	auipc	a0,0x1d
    80004134:	54050513          	addi	a0,a0,1344 # 80021670 <log>
    80004138:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000413a:	ffffd097          	auipc	ra,0xffffd
    8000413e:	b5e080e7          	jalr	-1186(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004142:	60e2                	ld	ra,24(sp)
    80004144:	6442                	ld	s0,16(sp)
    80004146:	64a2                	ld	s1,8(sp)
    80004148:	6902                	ld	s2,0(sp)
    8000414a:	6105                	addi	sp,sp,32
    8000414c:	8082                	ret

000000008000414e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000414e:	7139                	addi	sp,sp,-64
    80004150:	fc06                	sd	ra,56(sp)
    80004152:	f822                	sd	s0,48(sp)
    80004154:	f426                	sd	s1,40(sp)
    80004156:	f04a                	sd	s2,32(sp)
    80004158:	ec4e                	sd	s3,24(sp)
    8000415a:	e852                	sd	s4,16(sp)
    8000415c:	e456                	sd	s5,8(sp)
    8000415e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004160:	0001d497          	auipc	s1,0x1d
    80004164:	51048493          	addi	s1,s1,1296 # 80021670 <log>
    80004168:	8526                	mv	a0,s1
    8000416a:	ffffd097          	auipc	ra,0xffffd
    8000416e:	a7a080e7          	jalr	-1414(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004172:	509c                	lw	a5,32(s1)
    80004174:	37fd                	addiw	a5,a5,-1
    80004176:	0007891b          	sext.w	s2,a5
    8000417a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000417c:	50dc                	lw	a5,36(s1)
    8000417e:	efb9                	bnez	a5,800041dc <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004180:	06091663          	bnez	s2,800041ec <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004184:	0001d497          	auipc	s1,0x1d
    80004188:	4ec48493          	addi	s1,s1,1260 # 80021670 <log>
    8000418c:	4785                	li	a5,1
    8000418e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004190:	8526                	mv	a0,s1
    80004192:	ffffd097          	auipc	ra,0xffffd
    80004196:	b06080e7          	jalr	-1274(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000419a:	54dc                	lw	a5,44(s1)
    8000419c:	06f04763          	bgtz	a5,8000420a <end_op+0xbc>
    acquire(&log.lock);
    800041a0:	0001d497          	auipc	s1,0x1d
    800041a4:	4d048493          	addi	s1,s1,1232 # 80021670 <log>
    800041a8:	8526                	mv	a0,s1
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	a3a080e7          	jalr	-1478(ra) # 80000be4 <acquire>
    log.committing = 0;
    800041b2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041b6:	8526                	mv	a0,s1
    800041b8:	ffffe097          	auipc	ra,0xffffe
    800041bc:	0f4080e7          	jalr	244(ra) # 800022ac <wakeup>
    release(&log.lock);
    800041c0:	8526                	mv	a0,s1
    800041c2:	ffffd097          	auipc	ra,0xffffd
    800041c6:	ad6080e7          	jalr	-1322(ra) # 80000c98 <release>
}
    800041ca:	70e2                	ld	ra,56(sp)
    800041cc:	7442                	ld	s0,48(sp)
    800041ce:	74a2                	ld	s1,40(sp)
    800041d0:	7902                	ld	s2,32(sp)
    800041d2:	69e2                	ld	s3,24(sp)
    800041d4:	6a42                	ld	s4,16(sp)
    800041d6:	6aa2                	ld	s5,8(sp)
    800041d8:	6121                	addi	sp,sp,64
    800041da:	8082                	ret
    panic("log.committing");
    800041dc:	00004517          	auipc	a0,0x4
    800041e0:	44c50513          	addi	a0,a0,1100 # 80008628 <syscalls+0x1e0>
    800041e4:	ffffc097          	auipc	ra,0xffffc
    800041e8:	35a080e7          	jalr	858(ra) # 8000053e <panic>
    wakeup(&log);
    800041ec:	0001d497          	auipc	s1,0x1d
    800041f0:	48448493          	addi	s1,s1,1156 # 80021670 <log>
    800041f4:	8526                	mv	a0,s1
    800041f6:	ffffe097          	auipc	ra,0xffffe
    800041fa:	0b6080e7          	jalr	182(ra) # 800022ac <wakeup>
  release(&log.lock);
    800041fe:	8526                	mv	a0,s1
    80004200:	ffffd097          	auipc	ra,0xffffd
    80004204:	a98080e7          	jalr	-1384(ra) # 80000c98 <release>
  if(do_commit){
    80004208:	b7c9                	j	800041ca <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000420a:	0001da97          	auipc	s5,0x1d
    8000420e:	496a8a93          	addi	s5,s5,1174 # 800216a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004212:	0001da17          	auipc	s4,0x1d
    80004216:	45ea0a13          	addi	s4,s4,1118 # 80021670 <log>
    8000421a:	018a2583          	lw	a1,24(s4)
    8000421e:	012585bb          	addw	a1,a1,s2
    80004222:	2585                	addiw	a1,a1,1
    80004224:	028a2503          	lw	a0,40(s4)
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	cd2080e7          	jalr	-814(ra) # 80002efa <bread>
    80004230:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004232:	000aa583          	lw	a1,0(s5)
    80004236:	028a2503          	lw	a0,40(s4)
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	cc0080e7          	jalr	-832(ra) # 80002efa <bread>
    80004242:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004244:	40000613          	li	a2,1024
    80004248:	05850593          	addi	a1,a0,88
    8000424c:	05848513          	addi	a0,s1,88
    80004250:	ffffd097          	auipc	ra,0xffffd
    80004254:	af0080e7          	jalr	-1296(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004258:	8526                	mv	a0,s1
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	d92080e7          	jalr	-622(ra) # 80002fec <bwrite>
    brelse(from);
    80004262:	854e                	mv	a0,s3
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	dc6080e7          	jalr	-570(ra) # 8000302a <brelse>
    brelse(to);
    8000426c:	8526                	mv	a0,s1
    8000426e:	fffff097          	auipc	ra,0xfffff
    80004272:	dbc080e7          	jalr	-580(ra) # 8000302a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004276:	2905                	addiw	s2,s2,1
    80004278:	0a91                	addi	s5,s5,4
    8000427a:	02ca2783          	lw	a5,44(s4)
    8000427e:	f8f94ee3          	blt	s2,a5,8000421a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004282:	00000097          	auipc	ra,0x0
    80004286:	c6a080e7          	jalr	-918(ra) # 80003eec <write_head>
    install_trans(0); // Now install writes to home locations
    8000428a:	4501                	li	a0,0
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	cda080e7          	jalr	-806(ra) # 80003f66 <install_trans>
    log.lh.n = 0;
    80004294:	0001d797          	auipc	a5,0x1d
    80004298:	4007a423          	sw	zero,1032(a5) # 8002169c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000429c:	00000097          	auipc	ra,0x0
    800042a0:	c50080e7          	jalr	-944(ra) # 80003eec <write_head>
    800042a4:	bdf5                	j	800041a0 <end_op+0x52>

00000000800042a6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042a6:	1101                	addi	sp,sp,-32
    800042a8:	ec06                	sd	ra,24(sp)
    800042aa:	e822                	sd	s0,16(sp)
    800042ac:	e426                	sd	s1,8(sp)
    800042ae:	e04a                	sd	s2,0(sp)
    800042b0:	1000                	addi	s0,sp,32
    800042b2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042b4:	0001d917          	auipc	s2,0x1d
    800042b8:	3bc90913          	addi	s2,s2,956 # 80021670 <log>
    800042bc:	854a                	mv	a0,s2
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	926080e7          	jalr	-1754(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042c6:	02c92603          	lw	a2,44(s2)
    800042ca:	47f5                	li	a5,29
    800042cc:	06c7c563          	blt	a5,a2,80004336 <log_write+0x90>
    800042d0:	0001d797          	auipc	a5,0x1d
    800042d4:	3bc7a783          	lw	a5,956(a5) # 8002168c <log+0x1c>
    800042d8:	37fd                	addiw	a5,a5,-1
    800042da:	04f65e63          	bge	a2,a5,80004336 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042de:	0001d797          	auipc	a5,0x1d
    800042e2:	3b27a783          	lw	a5,946(a5) # 80021690 <log+0x20>
    800042e6:	06f05063          	blez	a5,80004346 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042ea:	4781                	li	a5,0
    800042ec:	06c05563          	blez	a2,80004356 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042f0:	44cc                	lw	a1,12(s1)
    800042f2:	0001d717          	auipc	a4,0x1d
    800042f6:	3ae70713          	addi	a4,a4,942 # 800216a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042fa:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042fc:	4314                	lw	a3,0(a4)
    800042fe:	04b68c63          	beq	a3,a1,80004356 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004302:	2785                	addiw	a5,a5,1
    80004304:	0711                	addi	a4,a4,4
    80004306:	fef61be3          	bne	a2,a5,800042fc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000430a:	0621                	addi	a2,a2,8
    8000430c:	060a                	slli	a2,a2,0x2
    8000430e:	0001d797          	auipc	a5,0x1d
    80004312:	36278793          	addi	a5,a5,866 # 80021670 <log>
    80004316:	963e                	add	a2,a2,a5
    80004318:	44dc                	lw	a5,12(s1)
    8000431a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000431c:	8526                	mv	a0,s1
    8000431e:	fffff097          	auipc	ra,0xfffff
    80004322:	daa080e7          	jalr	-598(ra) # 800030c8 <bpin>
    log.lh.n++;
    80004326:	0001d717          	auipc	a4,0x1d
    8000432a:	34a70713          	addi	a4,a4,842 # 80021670 <log>
    8000432e:	575c                	lw	a5,44(a4)
    80004330:	2785                	addiw	a5,a5,1
    80004332:	d75c                	sw	a5,44(a4)
    80004334:	a835                	j	80004370 <log_write+0xca>
    panic("too big a transaction");
    80004336:	00004517          	auipc	a0,0x4
    8000433a:	30250513          	addi	a0,a0,770 # 80008638 <syscalls+0x1f0>
    8000433e:	ffffc097          	auipc	ra,0xffffc
    80004342:	200080e7          	jalr	512(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004346:	00004517          	auipc	a0,0x4
    8000434a:	30a50513          	addi	a0,a0,778 # 80008650 <syscalls+0x208>
    8000434e:	ffffc097          	auipc	ra,0xffffc
    80004352:	1f0080e7          	jalr	496(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004356:	00878713          	addi	a4,a5,8
    8000435a:	00271693          	slli	a3,a4,0x2
    8000435e:	0001d717          	auipc	a4,0x1d
    80004362:	31270713          	addi	a4,a4,786 # 80021670 <log>
    80004366:	9736                	add	a4,a4,a3
    80004368:	44d4                	lw	a3,12(s1)
    8000436a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000436c:	faf608e3          	beq	a2,a5,8000431c <log_write+0x76>
  }
  release(&log.lock);
    80004370:	0001d517          	auipc	a0,0x1d
    80004374:	30050513          	addi	a0,a0,768 # 80021670 <log>
    80004378:	ffffd097          	auipc	ra,0xffffd
    8000437c:	920080e7          	jalr	-1760(ra) # 80000c98 <release>
}
    80004380:	60e2                	ld	ra,24(sp)
    80004382:	6442                	ld	s0,16(sp)
    80004384:	64a2                	ld	s1,8(sp)
    80004386:	6902                	ld	s2,0(sp)
    80004388:	6105                	addi	sp,sp,32
    8000438a:	8082                	ret

000000008000438c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000438c:	1101                	addi	sp,sp,-32
    8000438e:	ec06                	sd	ra,24(sp)
    80004390:	e822                	sd	s0,16(sp)
    80004392:	e426                	sd	s1,8(sp)
    80004394:	e04a                	sd	s2,0(sp)
    80004396:	1000                	addi	s0,sp,32
    80004398:	84aa                	mv	s1,a0
    8000439a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000439c:	00004597          	auipc	a1,0x4
    800043a0:	2d458593          	addi	a1,a1,724 # 80008670 <syscalls+0x228>
    800043a4:	0521                	addi	a0,a0,8
    800043a6:	ffffc097          	auipc	ra,0xffffc
    800043aa:	7ae080e7          	jalr	1966(ra) # 80000b54 <initlock>
  lk->name = name;
    800043ae:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043b2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043b6:	0204a423          	sw	zero,40(s1)
}
    800043ba:	60e2                	ld	ra,24(sp)
    800043bc:	6442                	ld	s0,16(sp)
    800043be:	64a2                	ld	s1,8(sp)
    800043c0:	6902                	ld	s2,0(sp)
    800043c2:	6105                	addi	sp,sp,32
    800043c4:	8082                	ret

00000000800043c6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043c6:	1101                	addi	sp,sp,-32
    800043c8:	ec06                	sd	ra,24(sp)
    800043ca:	e822                	sd	s0,16(sp)
    800043cc:	e426                	sd	s1,8(sp)
    800043ce:	e04a                	sd	s2,0(sp)
    800043d0:	1000                	addi	s0,sp,32
    800043d2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043d4:	00850913          	addi	s2,a0,8
    800043d8:	854a                	mv	a0,s2
    800043da:	ffffd097          	auipc	ra,0xffffd
    800043de:	80a080e7          	jalr	-2038(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800043e2:	409c                	lw	a5,0(s1)
    800043e4:	cb89                	beqz	a5,800043f6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043e6:	85ca                	mv	a1,s2
    800043e8:	8526                	mv	a0,s1
    800043ea:	ffffe097          	auipc	ra,0xffffe
    800043ee:	d36080e7          	jalr	-714(ra) # 80002120 <sleep>
  while (lk->locked) {
    800043f2:	409c                	lw	a5,0(s1)
    800043f4:	fbed                	bnez	a5,800043e6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043f6:	4785                	li	a5,1
    800043f8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043fa:	ffffd097          	auipc	ra,0xffffd
    800043fe:	5b6080e7          	jalr	1462(ra) # 800019b0 <myproc>
    80004402:	591c                	lw	a5,48(a0)
    80004404:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004406:	854a                	mv	a0,s2
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	890080e7          	jalr	-1904(ra) # 80000c98 <release>
}
    80004410:	60e2                	ld	ra,24(sp)
    80004412:	6442                	ld	s0,16(sp)
    80004414:	64a2                	ld	s1,8(sp)
    80004416:	6902                	ld	s2,0(sp)
    80004418:	6105                	addi	sp,sp,32
    8000441a:	8082                	ret

000000008000441c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000441c:	1101                	addi	sp,sp,-32
    8000441e:	ec06                	sd	ra,24(sp)
    80004420:	e822                	sd	s0,16(sp)
    80004422:	e426                	sd	s1,8(sp)
    80004424:	e04a                	sd	s2,0(sp)
    80004426:	1000                	addi	s0,sp,32
    80004428:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000442a:	00850913          	addi	s2,a0,8
    8000442e:	854a                	mv	a0,s2
    80004430:	ffffc097          	auipc	ra,0xffffc
    80004434:	7b4080e7          	jalr	1972(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004438:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000443c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004440:	8526                	mv	a0,s1
    80004442:	ffffe097          	auipc	ra,0xffffe
    80004446:	e6a080e7          	jalr	-406(ra) # 800022ac <wakeup>
  release(&lk->lk);
    8000444a:	854a                	mv	a0,s2
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	84c080e7          	jalr	-1972(ra) # 80000c98 <release>
}
    80004454:	60e2                	ld	ra,24(sp)
    80004456:	6442                	ld	s0,16(sp)
    80004458:	64a2                	ld	s1,8(sp)
    8000445a:	6902                	ld	s2,0(sp)
    8000445c:	6105                	addi	sp,sp,32
    8000445e:	8082                	ret

0000000080004460 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004460:	7179                	addi	sp,sp,-48
    80004462:	f406                	sd	ra,40(sp)
    80004464:	f022                	sd	s0,32(sp)
    80004466:	ec26                	sd	s1,24(sp)
    80004468:	e84a                	sd	s2,16(sp)
    8000446a:	e44e                	sd	s3,8(sp)
    8000446c:	1800                	addi	s0,sp,48
    8000446e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004470:	00850913          	addi	s2,a0,8
    80004474:	854a                	mv	a0,s2
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	76e080e7          	jalr	1902(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000447e:	409c                	lw	a5,0(s1)
    80004480:	ef99                	bnez	a5,8000449e <holdingsleep+0x3e>
    80004482:	4481                	li	s1,0
  release(&lk->lk);
    80004484:	854a                	mv	a0,s2
    80004486:	ffffd097          	auipc	ra,0xffffd
    8000448a:	812080e7          	jalr	-2030(ra) # 80000c98 <release>
  return r;
}
    8000448e:	8526                	mv	a0,s1
    80004490:	70a2                	ld	ra,40(sp)
    80004492:	7402                	ld	s0,32(sp)
    80004494:	64e2                	ld	s1,24(sp)
    80004496:	6942                	ld	s2,16(sp)
    80004498:	69a2                	ld	s3,8(sp)
    8000449a:	6145                	addi	sp,sp,48
    8000449c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000449e:	0284a983          	lw	s3,40(s1)
    800044a2:	ffffd097          	auipc	ra,0xffffd
    800044a6:	50e080e7          	jalr	1294(ra) # 800019b0 <myproc>
    800044aa:	5904                	lw	s1,48(a0)
    800044ac:	413484b3          	sub	s1,s1,s3
    800044b0:	0014b493          	seqz	s1,s1
    800044b4:	bfc1                	j	80004484 <holdingsleep+0x24>

00000000800044b6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044b6:	1141                	addi	sp,sp,-16
    800044b8:	e406                	sd	ra,8(sp)
    800044ba:	e022                	sd	s0,0(sp)
    800044bc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044be:	00004597          	auipc	a1,0x4
    800044c2:	1c258593          	addi	a1,a1,450 # 80008680 <syscalls+0x238>
    800044c6:	0001d517          	auipc	a0,0x1d
    800044ca:	2f250513          	addi	a0,a0,754 # 800217b8 <ftable>
    800044ce:	ffffc097          	auipc	ra,0xffffc
    800044d2:	686080e7          	jalr	1670(ra) # 80000b54 <initlock>
}
    800044d6:	60a2                	ld	ra,8(sp)
    800044d8:	6402                	ld	s0,0(sp)
    800044da:	0141                	addi	sp,sp,16
    800044dc:	8082                	ret

00000000800044de <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044de:	1101                	addi	sp,sp,-32
    800044e0:	ec06                	sd	ra,24(sp)
    800044e2:	e822                	sd	s0,16(sp)
    800044e4:	e426                	sd	s1,8(sp)
    800044e6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044e8:	0001d517          	auipc	a0,0x1d
    800044ec:	2d050513          	addi	a0,a0,720 # 800217b8 <ftable>
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	6f4080e7          	jalr	1780(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044f8:	0001d497          	auipc	s1,0x1d
    800044fc:	2d848493          	addi	s1,s1,728 # 800217d0 <ftable+0x18>
    80004500:	0001e717          	auipc	a4,0x1e
    80004504:	27070713          	addi	a4,a4,624 # 80022770 <ftable+0xfb8>
    if(f->ref == 0){
    80004508:	40dc                	lw	a5,4(s1)
    8000450a:	cf99                	beqz	a5,80004528 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000450c:	02848493          	addi	s1,s1,40
    80004510:	fee49ce3          	bne	s1,a4,80004508 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004514:	0001d517          	auipc	a0,0x1d
    80004518:	2a450513          	addi	a0,a0,676 # 800217b8 <ftable>
    8000451c:	ffffc097          	auipc	ra,0xffffc
    80004520:	77c080e7          	jalr	1916(ra) # 80000c98 <release>
  return 0;
    80004524:	4481                	li	s1,0
    80004526:	a819                	j	8000453c <filealloc+0x5e>
      f->ref = 1;
    80004528:	4785                	li	a5,1
    8000452a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000452c:	0001d517          	auipc	a0,0x1d
    80004530:	28c50513          	addi	a0,a0,652 # 800217b8 <ftable>
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	764080e7          	jalr	1892(ra) # 80000c98 <release>
}
    8000453c:	8526                	mv	a0,s1
    8000453e:	60e2                	ld	ra,24(sp)
    80004540:	6442                	ld	s0,16(sp)
    80004542:	64a2                	ld	s1,8(sp)
    80004544:	6105                	addi	sp,sp,32
    80004546:	8082                	ret

0000000080004548 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004548:	1101                	addi	sp,sp,-32
    8000454a:	ec06                	sd	ra,24(sp)
    8000454c:	e822                	sd	s0,16(sp)
    8000454e:	e426                	sd	s1,8(sp)
    80004550:	1000                	addi	s0,sp,32
    80004552:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004554:	0001d517          	auipc	a0,0x1d
    80004558:	26450513          	addi	a0,a0,612 # 800217b8 <ftable>
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	688080e7          	jalr	1672(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004564:	40dc                	lw	a5,4(s1)
    80004566:	02f05263          	blez	a5,8000458a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000456a:	2785                	addiw	a5,a5,1
    8000456c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000456e:	0001d517          	auipc	a0,0x1d
    80004572:	24a50513          	addi	a0,a0,586 # 800217b8 <ftable>
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	722080e7          	jalr	1826(ra) # 80000c98 <release>
  return f;
}
    8000457e:	8526                	mv	a0,s1
    80004580:	60e2                	ld	ra,24(sp)
    80004582:	6442                	ld	s0,16(sp)
    80004584:	64a2                	ld	s1,8(sp)
    80004586:	6105                	addi	sp,sp,32
    80004588:	8082                	ret
    panic("filedup");
    8000458a:	00004517          	auipc	a0,0x4
    8000458e:	0fe50513          	addi	a0,a0,254 # 80008688 <syscalls+0x240>
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	fac080e7          	jalr	-84(ra) # 8000053e <panic>

000000008000459a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000459a:	7139                	addi	sp,sp,-64
    8000459c:	fc06                	sd	ra,56(sp)
    8000459e:	f822                	sd	s0,48(sp)
    800045a0:	f426                	sd	s1,40(sp)
    800045a2:	f04a                	sd	s2,32(sp)
    800045a4:	ec4e                	sd	s3,24(sp)
    800045a6:	e852                	sd	s4,16(sp)
    800045a8:	e456                	sd	s5,8(sp)
    800045aa:	0080                	addi	s0,sp,64
    800045ac:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045ae:	0001d517          	auipc	a0,0x1d
    800045b2:	20a50513          	addi	a0,a0,522 # 800217b8 <ftable>
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	62e080e7          	jalr	1582(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045be:	40dc                	lw	a5,4(s1)
    800045c0:	06f05163          	blez	a5,80004622 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045c4:	37fd                	addiw	a5,a5,-1
    800045c6:	0007871b          	sext.w	a4,a5
    800045ca:	c0dc                	sw	a5,4(s1)
    800045cc:	06e04363          	bgtz	a4,80004632 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045d0:	0004a903          	lw	s2,0(s1)
    800045d4:	0094ca83          	lbu	s5,9(s1)
    800045d8:	0104ba03          	ld	s4,16(s1)
    800045dc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045e0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045e4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045e8:	0001d517          	auipc	a0,0x1d
    800045ec:	1d050513          	addi	a0,a0,464 # 800217b8 <ftable>
    800045f0:	ffffc097          	auipc	ra,0xffffc
    800045f4:	6a8080e7          	jalr	1704(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800045f8:	4785                	li	a5,1
    800045fa:	04f90d63          	beq	s2,a5,80004654 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045fe:	3979                	addiw	s2,s2,-2
    80004600:	4785                	li	a5,1
    80004602:	0527e063          	bltu	a5,s2,80004642 <fileclose+0xa8>
    begin_op();
    80004606:	00000097          	auipc	ra,0x0
    8000460a:	ac8080e7          	jalr	-1336(ra) # 800040ce <begin_op>
    iput(ff.ip);
    8000460e:	854e                	mv	a0,s3
    80004610:	fffff097          	auipc	ra,0xfffff
    80004614:	2a6080e7          	jalr	678(ra) # 800038b6 <iput>
    end_op();
    80004618:	00000097          	auipc	ra,0x0
    8000461c:	b36080e7          	jalr	-1226(ra) # 8000414e <end_op>
    80004620:	a00d                	j	80004642 <fileclose+0xa8>
    panic("fileclose");
    80004622:	00004517          	auipc	a0,0x4
    80004626:	06e50513          	addi	a0,a0,110 # 80008690 <syscalls+0x248>
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	f14080e7          	jalr	-236(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004632:	0001d517          	auipc	a0,0x1d
    80004636:	18650513          	addi	a0,a0,390 # 800217b8 <ftable>
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	65e080e7          	jalr	1630(ra) # 80000c98 <release>
  }
}
    80004642:	70e2                	ld	ra,56(sp)
    80004644:	7442                	ld	s0,48(sp)
    80004646:	74a2                	ld	s1,40(sp)
    80004648:	7902                	ld	s2,32(sp)
    8000464a:	69e2                	ld	s3,24(sp)
    8000464c:	6a42                	ld	s4,16(sp)
    8000464e:	6aa2                	ld	s5,8(sp)
    80004650:	6121                	addi	sp,sp,64
    80004652:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004654:	85d6                	mv	a1,s5
    80004656:	8552                	mv	a0,s4
    80004658:	00000097          	auipc	ra,0x0
    8000465c:	34c080e7          	jalr	844(ra) # 800049a4 <pipeclose>
    80004660:	b7cd                	j	80004642 <fileclose+0xa8>

0000000080004662 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004662:	715d                	addi	sp,sp,-80
    80004664:	e486                	sd	ra,72(sp)
    80004666:	e0a2                	sd	s0,64(sp)
    80004668:	fc26                	sd	s1,56(sp)
    8000466a:	f84a                	sd	s2,48(sp)
    8000466c:	f44e                	sd	s3,40(sp)
    8000466e:	0880                	addi	s0,sp,80
    80004670:	84aa                	mv	s1,a0
    80004672:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004674:	ffffd097          	auipc	ra,0xffffd
    80004678:	33c080e7          	jalr	828(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000467c:	409c                	lw	a5,0(s1)
    8000467e:	37f9                	addiw	a5,a5,-2
    80004680:	4705                	li	a4,1
    80004682:	04f76763          	bltu	a4,a5,800046d0 <filestat+0x6e>
    80004686:	892a                	mv	s2,a0
    ilock(f->ip);
    80004688:	6c88                	ld	a0,24(s1)
    8000468a:	fffff097          	auipc	ra,0xfffff
    8000468e:	072080e7          	jalr	114(ra) # 800036fc <ilock>
    stati(f->ip, &st);
    80004692:	fb840593          	addi	a1,s0,-72
    80004696:	6c88                	ld	a0,24(s1)
    80004698:	fffff097          	auipc	ra,0xfffff
    8000469c:	2ee080e7          	jalr	750(ra) # 80003986 <stati>
    iunlock(f->ip);
    800046a0:	6c88                	ld	a0,24(s1)
    800046a2:	fffff097          	auipc	ra,0xfffff
    800046a6:	11c080e7          	jalr	284(ra) # 800037be <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046aa:	46e1                	li	a3,24
    800046ac:	fb840613          	addi	a2,s0,-72
    800046b0:	85ce                	mv	a1,s3
    800046b2:	05093503          	ld	a0,80(s2)
    800046b6:	ffffd097          	auipc	ra,0xffffd
    800046ba:	fbc080e7          	jalr	-68(ra) # 80001672 <copyout>
    800046be:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046c2:	60a6                	ld	ra,72(sp)
    800046c4:	6406                	ld	s0,64(sp)
    800046c6:	74e2                	ld	s1,56(sp)
    800046c8:	7942                	ld	s2,48(sp)
    800046ca:	79a2                	ld	s3,40(sp)
    800046cc:	6161                	addi	sp,sp,80
    800046ce:	8082                	ret
  return -1;
    800046d0:	557d                	li	a0,-1
    800046d2:	bfc5                	j	800046c2 <filestat+0x60>

00000000800046d4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046d4:	7179                	addi	sp,sp,-48
    800046d6:	f406                	sd	ra,40(sp)
    800046d8:	f022                	sd	s0,32(sp)
    800046da:	ec26                	sd	s1,24(sp)
    800046dc:	e84a                	sd	s2,16(sp)
    800046de:	e44e                	sd	s3,8(sp)
    800046e0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046e2:	00854783          	lbu	a5,8(a0)
    800046e6:	c3d5                	beqz	a5,8000478a <fileread+0xb6>
    800046e8:	84aa                	mv	s1,a0
    800046ea:	89ae                	mv	s3,a1
    800046ec:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046ee:	411c                	lw	a5,0(a0)
    800046f0:	4705                	li	a4,1
    800046f2:	04e78963          	beq	a5,a4,80004744 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046f6:	470d                	li	a4,3
    800046f8:	04e78d63          	beq	a5,a4,80004752 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046fc:	4709                	li	a4,2
    800046fe:	06e79e63          	bne	a5,a4,8000477a <fileread+0xa6>
    ilock(f->ip);
    80004702:	6d08                	ld	a0,24(a0)
    80004704:	fffff097          	auipc	ra,0xfffff
    80004708:	ff8080e7          	jalr	-8(ra) # 800036fc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000470c:	874a                	mv	a4,s2
    8000470e:	5094                	lw	a3,32(s1)
    80004710:	864e                	mv	a2,s3
    80004712:	4585                	li	a1,1
    80004714:	6c88                	ld	a0,24(s1)
    80004716:	fffff097          	auipc	ra,0xfffff
    8000471a:	29a080e7          	jalr	666(ra) # 800039b0 <readi>
    8000471e:	892a                	mv	s2,a0
    80004720:	00a05563          	blez	a0,8000472a <fileread+0x56>
      f->off += r;
    80004724:	509c                	lw	a5,32(s1)
    80004726:	9fa9                	addw	a5,a5,a0
    80004728:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000472a:	6c88                	ld	a0,24(s1)
    8000472c:	fffff097          	auipc	ra,0xfffff
    80004730:	092080e7          	jalr	146(ra) # 800037be <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004734:	854a                	mv	a0,s2
    80004736:	70a2                	ld	ra,40(sp)
    80004738:	7402                	ld	s0,32(sp)
    8000473a:	64e2                	ld	s1,24(sp)
    8000473c:	6942                	ld	s2,16(sp)
    8000473e:	69a2                	ld	s3,8(sp)
    80004740:	6145                	addi	sp,sp,48
    80004742:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004744:	6908                	ld	a0,16(a0)
    80004746:	00000097          	auipc	ra,0x0
    8000474a:	3c8080e7          	jalr	968(ra) # 80004b0e <piperead>
    8000474e:	892a                	mv	s2,a0
    80004750:	b7d5                	j	80004734 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004752:	02451783          	lh	a5,36(a0)
    80004756:	03079693          	slli	a3,a5,0x30
    8000475a:	92c1                	srli	a3,a3,0x30
    8000475c:	4725                	li	a4,9
    8000475e:	02d76863          	bltu	a4,a3,8000478e <fileread+0xba>
    80004762:	0792                	slli	a5,a5,0x4
    80004764:	0001d717          	auipc	a4,0x1d
    80004768:	fb470713          	addi	a4,a4,-76 # 80021718 <devsw>
    8000476c:	97ba                	add	a5,a5,a4
    8000476e:	639c                	ld	a5,0(a5)
    80004770:	c38d                	beqz	a5,80004792 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004772:	4505                	li	a0,1
    80004774:	9782                	jalr	a5
    80004776:	892a                	mv	s2,a0
    80004778:	bf75                	j	80004734 <fileread+0x60>
    panic("fileread");
    8000477a:	00004517          	auipc	a0,0x4
    8000477e:	f2650513          	addi	a0,a0,-218 # 800086a0 <syscalls+0x258>
    80004782:	ffffc097          	auipc	ra,0xffffc
    80004786:	dbc080e7          	jalr	-580(ra) # 8000053e <panic>
    return -1;
    8000478a:	597d                	li	s2,-1
    8000478c:	b765                	j	80004734 <fileread+0x60>
      return -1;
    8000478e:	597d                	li	s2,-1
    80004790:	b755                	j	80004734 <fileread+0x60>
    80004792:	597d                	li	s2,-1
    80004794:	b745                	j	80004734 <fileread+0x60>

0000000080004796 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004796:	715d                	addi	sp,sp,-80
    80004798:	e486                	sd	ra,72(sp)
    8000479a:	e0a2                	sd	s0,64(sp)
    8000479c:	fc26                	sd	s1,56(sp)
    8000479e:	f84a                	sd	s2,48(sp)
    800047a0:	f44e                	sd	s3,40(sp)
    800047a2:	f052                	sd	s4,32(sp)
    800047a4:	ec56                	sd	s5,24(sp)
    800047a6:	e85a                	sd	s6,16(sp)
    800047a8:	e45e                	sd	s7,8(sp)
    800047aa:	e062                	sd	s8,0(sp)
    800047ac:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047ae:	00954783          	lbu	a5,9(a0)
    800047b2:	10078663          	beqz	a5,800048be <filewrite+0x128>
    800047b6:	892a                	mv	s2,a0
    800047b8:	8aae                	mv	s5,a1
    800047ba:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047bc:	411c                	lw	a5,0(a0)
    800047be:	4705                	li	a4,1
    800047c0:	02e78263          	beq	a5,a4,800047e4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047c4:	470d                	li	a4,3
    800047c6:	02e78663          	beq	a5,a4,800047f2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047ca:	4709                	li	a4,2
    800047cc:	0ee79163          	bne	a5,a4,800048ae <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047d0:	0ac05d63          	blez	a2,8000488a <filewrite+0xf4>
    int i = 0;
    800047d4:	4981                	li	s3,0
    800047d6:	6b05                	lui	s6,0x1
    800047d8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047dc:	6b85                	lui	s7,0x1
    800047de:	c00b8b9b          	addiw	s7,s7,-1024
    800047e2:	a861                	j	8000487a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800047e4:	6908                	ld	a0,16(a0)
    800047e6:	00000097          	auipc	ra,0x0
    800047ea:	22e080e7          	jalr	558(ra) # 80004a14 <pipewrite>
    800047ee:	8a2a                	mv	s4,a0
    800047f0:	a045                	j	80004890 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047f2:	02451783          	lh	a5,36(a0)
    800047f6:	03079693          	slli	a3,a5,0x30
    800047fa:	92c1                	srli	a3,a3,0x30
    800047fc:	4725                	li	a4,9
    800047fe:	0cd76263          	bltu	a4,a3,800048c2 <filewrite+0x12c>
    80004802:	0792                	slli	a5,a5,0x4
    80004804:	0001d717          	auipc	a4,0x1d
    80004808:	f1470713          	addi	a4,a4,-236 # 80021718 <devsw>
    8000480c:	97ba                	add	a5,a5,a4
    8000480e:	679c                	ld	a5,8(a5)
    80004810:	cbdd                	beqz	a5,800048c6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004812:	4505                	li	a0,1
    80004814:	9782                	jalr	a5
    80004816:	8a2a                	mv	s4,a0
    80004818:	a8a5                	j	80004890 <filewrite+0xfa>
    8000481a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000481e:	00000097          	auipc	ra,0x0
    80004822:	8b0080e7          	jalr	-1872(ra) # 800040ce <begin_op>
      ilock(f->ip);
    80004826:	01893503          	ld	a0,24(s2)
    8000482a:	fffff097          	auipc	ra,0xfffff
    8000482e:	ed2080e7          	jalr	-302(ra) # 800036fc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004832:	8762                	mv	a4,s8
    80004834:	02092683          	lw	a3,32(s2)
    80004838:	01598633          	add	a2,s3,s5
    8000483c:	4585                	li	a1,1
    8000483e:	01893503          	ld	a0,24(s2)
    80004842:	fffff097          	auipc	ra,0xfffff
    80004846:	266080e7          	jalr	614(ra) # 80003aa8 <writei>
    8000484a:	84aa                	mv	s1,a0
    8000484c:	00a05763          	blez	a0,8000485a <filewrite+0xc4>
        f->off += r;
    80004850:	02092783          	lw	a5,32(s2)
    80004854:	9fa9                	addw	a5,a5,a0
    80004856:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000485a:	01893503          	ld	a0,24(s2)
    8000485e:	fffff097          	auipc	ra,0xfffff
    80004862:	f60080e7          	jalr	-160(ra) # 800037be <iunlock>
      end_op();
    80004866:	00000097          	auipc	ra,0x0
    8000486a:	8e8080e7          	jalr	-1816(ra) # 8000414e <end_op>

      if(r != n1){
    8000486e:	009c1f63          	bne	s8,s1,8000488c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004872:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004876:	0149db63          	bge	s3,s4,8000488c <filewrite+0xf6>
      int n1 = n - i;
    8000487a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000487e:	84be                	mv	s1,a5
    80004880:	2781                	sext.w	a5,a5
    80004882:	f8fb5ce3          	bge	s6,a5,8000481a <filewrite+0x84>
    80004886:	84de                	mv	s1,s7
    80004888:	bf49                	j	8000481a <filewrite+0x84>
    int i = 0;
    8000488a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000488c:	013a1f63          	bne	s4,s3,800048aa <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004890:	8552                	mv	a0,s4
    80004892:	60a6                	ld	ra,72(sp)
    80004894:	6406                	ld	s0,64(sp)
    80004896:	74e2                	ld	s1,56(sp)
    80004898:	7942                	ld	s2,48(sp)
    8000489a:	79a2                	ld	s3,40(sp)
    8000489c:	7a02                	ld	s4,32(sp)
    8000489e:	6ae2                	ld	s5,24(sp)
    800048a0:	6b42                	ld	s6,16(sp)
    800048a2:	6ba2                	ld	s7,8(sp)
    800048a4:	6c02                	ld	s8,0(sp)
    800048a6:	6161                	addi	sp,sp,80
    800048a8:	8082                	ret
    ret = (i == n ? n : -1);
    800048aa:	5a7d                	li	s4,-1
    800048ac:	b7d5                	j	80004890 <filewrite+0xfa>
    panic("filewrite");
    800048ae:	00004517          	auipc	a0,0x4
    800048b2:	e0250513          	addi	a0,a0,-510 # 800086b0 <syscalls+0x268>
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	c88080e7          	jalr	-888(ra) # 8000053e <panic>
    return -1;
    800048be:	5a7d                	li	s4,-1
    800048c0:	bfc1                	j	80004890 <filewrite+0xfa>
      return -1;
    800048c2:	5a7d                	li	s4,-1
    800048c4:	b7f1                	j	80004890 <filewrite+0xfa>
    800048c6:	5a7d                	li	s4,-1
    800048c8:	b7e1                	j	80004890 <filewrite+0xfa>

00000000800048ca <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048ca:	7179                	addi	sp,sp,-48
    800048cc:	f406                	sd	ra,40(sp)
    800048ce:	f022                	sd	s0,32(sp)
    800048d0:	ec26                	sd	s1,24(sp)
    800048d2:	e84a                	sd	s2,16(sp)
    800048d4:	e44e                	sd	s3,8(sp)
    800048d6:	e052                	sd	s4,0(sp)
    800048d8:	1800                	addi	s0,sp,48
    800048da:	84aa                	mv	s1,a0
    800048dc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048de:	0005b023          	sd	zero,0(a1)
    800048e2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048e6:	00000097          	auipc	ra,0x0
    800048ea:	bf8080e7          	jalr	-1032(ra) # 800044de <filealloc>
    800048ee:	e088                	sd	a0,0(s1)
    800048f0:	c551                	beqz	a0,8000497c <pipealloc+0xb2>
    800048f2:	00000097          	auipc	ra,0x0
    800048f6:	bec080e7          	jalr	-1044(ra) # 800044de <filealloc>
    800048fa:	00aa3023          	sd	a0,0(s4)
    800048fe:	c92d                	beqz	a0,80004970 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	1f4080e7          	jalr	500(ra) # 80000af4 <kalloc>
    80004908:	892a                	mv	s2,a0
    8000490a:	c125                	beqz	a0,8000496a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000490c:	4985                	li	s3,1
    8000490e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004912:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004916:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000491a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000491e:	00004597          	auipc	a1,0x4
    80004922:	da258593          	addi	a1,a1,-606 # 800086c0 <syscalls+0x278>
    80004926:	ffffc097          	auipc	ra,0xffffc
    8000492a:	22e080e7          	jalr	558(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000492e:	609c                	ld	a5,0(s1)
    80004930:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004934:	609c                	ld	a5,0(s1)
    80004936:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000493a:	609c                	ld	a5,0(s1)
    8000493c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004940:	609c                	ld	a5,0(s1)
    80004942:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004946:	000a3783          	ld	a5,0(s4)
    8000494a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000494e:	000a3783          	ld	a5,0(s4)
    80004952:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004956:	000a3783          	ld	a5,0(s4)
    8000495a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000495e:	000a3783          	ld	a5,0(s4)
    80004962:	0127b823          	sd	s2,16(a5)
  return 0;
    80004966:	4501                	li	a0,0
    80004968:	a025                	j	80004990 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000496a:	6088                	ld	a0,0(s1)
    8000496c:	e501                	bnez	a0,80004974 <pipealloc+0xaa>
    8000496e:	a039                	j	8000497c <pipealloc+0xb2>
    80004970:	6088                	ld	a0,0(s1)
    80004972:	c51d                	beqz	a0,800049a0 <pipealloc+0xd6>
    fileclose(*f0);
    80004974:	00000097          	auipc	ra,0x0
    80004978:	c26080e7          	jalr	-986(ra) # 8000459a <fileclose>
  if(*f1)
    8000497c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004980:	557d                	li	a0,-1
  if(*f1)
    80004982:	c799                	beqz	a5,80004990 <pipealloc+0xc6>
    fileclose(*f1);
    80004984:	853e                	mv	a0,a5
    80004986:	00000097          	auipc	ra,0x0
    8000498a:	c14080e7          	jalr	-1004(ra) # 8000459a <fileclose>
  return -1;
    8000498e:	557d                	li	a0,-1
}
    80004990:	70a2                	ld	ra,40(sp)
    80004992:	7402                	ld	s0,32(sp)
    80004994:	64e2                	ld	s1,24(sp)
    80004996:	6942                	ld	s2,16(sp)
    80004998:	69a2                	ld	s3,8(sp)
    8000499a:	6a02                	ld	s4,0(sp)
    8000499c:	6145                	addi	sp,sp,48
    8000499e:	8082                	ret
  return -1;
    800049a0:	557d                	li	a0,-1
    800049a2:	b7fd                	j	80004990 <pipealloc+0xc6>

00000000800049a4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049a4:	1101                	addi	sp,sp,-32
    800049a6:	ec06                	sd	ra,24(sp)
    800049a8:	e822                	sd	s0,16(sp)
    800049aa:	e426                	sd	s1,8(sp)
    800049ac:	e04a                	sd	s2,0(sp)
    800049ae:	1000                	addi	s0,sp,32
    800049b0:	84aa                	mv	s1,a0
    800049b2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	230080e7          	jalr	560(ra) # 80000be4 <acquire>
  if(writable){
    800049bc:	02090d63          	beqz	s2,800049f6 <pipeclose+0x52>
    pi->writeopen = 0;
    800049c0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049c4:	21848513          	addi	a0,s1,536
    800049c8:	ffffe097          	auipc	ra,0xffffe
    800049cc:	8e4080e7          	jalr	-1820(ra) # 800022ac <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049d0:	2204b783          	ld	a5,544(s1)
    800049d4:	eb95                	bnez	a5,80004a08 <pipeclose+0x64>
    release(&pi->lock);
    800049d6:	8526                	mv	a0,s1
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	2c0080e7          	jalr	704(ra) # 80000c98 <release>
    kfree((char*)pi);
    800049e0:	8526                	mv	a0,s1
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	016080e7          	jalr	22(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800049ea:	60e2                	ld	ra,24(sp)
    800049ec:	6442                	ld	s0,16(sp)
    800049ee:	64a2                	ld	s1,8(sp)
    800049f0:	6902                	ld	s2,0(sp)
    800049f2:	6105                	addi	sp,sp,32
    800049f4:	8082                	ret
    pi->readopen = 0;
    800049f6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049fa:	21c48513          	addi	a0,s1,540
    800049fe:	ffffe097          	auipc	ra,0xffffe
    80004a02:	8ae080e7          	jalr	-1874(ra) # 800022ac <wakeup>
    80004a06:	b7e9                	j	800049d0 <pipeclose+0x2c>
    release(&pi->lock);
    80004a08:	8526                	mv	a0,s1
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	28e080e7          	jalr	654(ra) # 80000c98 <release>
}
    80004a12:	bfe1                	j	800049ea <pipeclose+0x46>

0000000080004a14 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a14:	7159                	addi	sp,sp,-112
    80004a16:	f486                	sd	ra,104(sp)
    80004a18:	f0a2                	sd	s0,96(sp)
    80004a1a:	eca6                	sd	s1,88(sp)
    80004a1c:	e8ca                	sd	s2,80(sp)
    80004a1e:	e4ce                	sd	s3,72(sp)
    80004a20:	e0d2                	sd	s4,64(sp)
    80004a22:	fc56                	sd	s5,56(sp)
    80004a24:	f85a                	sd	s6,48(sp)
    80004a26:	f45e                	sd	s7,40(sp)
    80004a28:	f062                	sd	s8,32(sp)
    80004a2a:	ec66                	sd	s9,24(sp)
    80004a2c:	1880                	addi	s0,sp,112
    80004a2e:	84aa                	mv	s1,a0
    80004a30:	8aae                	mv	s5,a1
    80004a32:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a34:	ffffd097          	auipc	ra,0xffffd
    80004a38:	f7c080e7          	jalr	-132(ra) # 800019b0 <myproc>
    80004a3c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a3e:	8526                	mv	a0,s1
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	1a4080e7          	jalr	420(ra) # 80000be4 <acquire>
  while(i < n){
    80004a48:	0d405163          	blez	s4,80004b0a <pipewrite+0xf6>
    80004a4c:	8ba6                	mv	s7,s1
  int i = 0;
    80004a4e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a50:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a52:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a56:	21c48c13          	addi	s8,s1,540
    80004a5a:	a08d                	j	80004abc <pipewrite+0xa8>
      release(&pi->lock);
    80004a5c:	8526                	mv	a0,s1
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
      return -1;
    80004a66:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a68:	854a                	mv	a0,s2
    80004a6a:	70a6                	ld	ra,104(sp)
    80004a6c:	7406                	ld	s0,96(sp)
    80004a6e:	64e6                	ld	s1,88(sp)
    80004a70:	6946                	ld	s2,80(sp)
    80004a72:	69a6                	ld	s3,72(sp)
    80004a74:	6a06                	ld	s4,64(sp)
    80004a76:	7ae2                	ld	s5,56(sp)
    80004a78:	7b42                	ld	s6,48(sp)
    80004a7a:	7ba2                	ld	s7,40(sp)
    80004a7c:	7c02                	ld	s8,32(sp)
    80004a7e:	6ce2                	ld	s9,24(sp)
    80004a80:	6165                	addi	sp,sp,112
    80004a82:	8082                	ret
      wakeup(&pi->nread);
    80004a84:	8566                	mv	a0,s9
    80004a86:	ffffe097          	auipc	ra,0xffffe
    80004a8a:	826080e7          	jalr	-2010(ra) # 800022ac <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a8e:	85de                	mv	a1,s7
    80004a90:	8562                	mv	a0,s8
    80004a92:	ffffd097          	auipc	ra,0xffffd
    80004a96:	68e080e7          	jalr	1678(ra) # 80002120 <sleep>
    80004a9a:	a839                	j	80004ab8 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a9c:	21c4a783          	lw	a5,540(s1)
    80004aa0:	0017871b          	addiw	a4,a5,1
    80004aa4:	20e4ae23          	sw	a4,540(s1)
    80004aa8:	1ff7f793          	andi	a5,a5,511
    80004aac:	97a6                	add	a5,a5,s1
    80004aae:	f9f44703          	lbu	a4,-97(s0)
    80004ab2:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ab6:	2905                	addiw	s2,s2,1
  while(i < n){
    80004ab8:	03495d63          	bge	s2,s4,80004af2 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004abc:	2204a783          	lw	a5,544(s1)
    80004ac0:	dfd1                	beqz	a5,80004a5c <pipewrite+0x48>
    80004ac2:	0289a783          	lw	a5,40(s3)
    80004ac6:	fbd9                	bnez	a5,80004a5c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ac8:	2184a783          	lw	a5,536(s1)
    80004acc:	21c4a703          	lw	a4,540(s1)
    80004ad0:	2007879b          	addiw	a5,a5,512
    80004ad4:	faf708e3          	beq	a4,a5,80004a84 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ad8:	4685                	li	a3,1
    80004ada:	01590633          	add	a2,s2,s5
    80004ade:	f9f40593          	addi	a1,s0,-97
    80004ae2:	0509b503          	ld	a0,80(s3)
    80004ae6:	ffffd097          	auipc	ra,0xffffd
    80004aea:	c18080e7          	jalr	-1000(ra) # 800016fe <copyin>
    80004aee:	fb6517e3          	bne	a0,s6,80004a9c <pipewrite+0x88>
  wakeup(&pi->nread);
    80004af2:	21848513          	addi	a0,s1,536
    80004af6:	ffffd097          	auipc	ra,0xffffd
    80004afa:	7b6080e7          	jalr	1974(ra) # 800022ac <wakeup>
  release(&pi->lock);
    80004afe:	8526                	mv	a0,s1
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	198080e7          	jalr	408(ra) # 80000c98 <release>
  return i;
    80004b08:	b785                	j	80004a68 <pipewrite+0x54>
  int i = 0;
    80004b0a:	4901                	li	s2,0
    80004b0c:	b7dd                	j	80004af2 <pipewrite+0xde>

0000000080004b0e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b0e:	715d                	addi	sp,sp,-80
    80004b10:	e486                	sd	ra,72(sp)
    80004b12:	e0a2                	sd	s0,64(sp)
    80004b14:	fc26                	sd	s1,56(sp)
    80004b16:	f84a                	sd	s2,48(sp)
    80004b18:	f44e                	sd	s3,40(sp)
    80004b1a:	f052                	sd	s4,32(sp)
    80004b1c:	ec56                	sd	s5,24(sp)
    80004b1e:	e85a                	sd	s6,16(sp)
    80004b20:	0880                	addi	s0,sp,80
    80004b22:	84aa                	mv	s1,a0
    80004b24:	892e                	mv	s2,a1
    80004b26:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b28:	ffffd097          	auipc	ra,0xffffd
    80004b2c:	e88080e7          	jalr	-376(ra) # 800019b0 <myproc>
    80004b30:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b32:	8b26                	mv	s6,s1
    80004b34:	8526                	mv	a0,s1
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	0ae080e7          	jalr	174(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b3e:	2184a703          	lw	a4,536(s1)
    80004b42:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b46:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b4a:	02f71463          	bne	a4,a5,80004b72 <piperead+0x64>
    80004b4e:	2244a783          	lw	a5,548(s1)
    80004b52:	c385                	beqz	a5,80004b72 <piperead+0x64>
    if(pr->killed){
    80004b54:	028a2783          	lw	a5,40(s4)
    80004b58:	ebc1                	bnez	a5,80004be8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b5a:	85da                	mv	a1,s6
    80004b5c:	854e                	mv	a0,s3
    80004b5e:	ffffd097          	auipc	ra,0xffffd
    80004b62:	5c2080e7          	jalr	1474(ra) # 80002120 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b66:	2184a703          	lw	a4,536(s1)
    80004b6a:	21c4a783          	lw	a5,540(s1)
    80004b6e:	fef700e3          	beq	a4,a5,80004b4e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b72:	09505263          	blez	s5,80004bf6 <piperead+0xe8>
    80004b76:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b78:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b7a:	2184a783          	lw	a5,536(s1)
    80004b7e:	21c4a703          	lw	a4,540(s1)
    80004b82:	02f70d63          	beq	a4,a5,80004bbc <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b86:	0017871b          	addiw	a4,a5,1
    80004b8a:	20e4ac23          	sw	a4,536(s1)
    80004b8e:	1ff7f793          	andi	a5,a5,511
    80004b92:	97a6                	add	a5,a5,s1
    80004b94:	0187c783          	lbu	a5,24(a5)
    80004b98:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b9c:	4685                	li	a3,1
    80004b9e:	fbf40613          	addi	a2,s0,-65
    80004ba2:	85ca                	mv	a1,s2
    80004ba4:	050a3503          	ld	a0,80(s4)
    80004ba8:	ffffd097          	auipc	ra,0xffffd
    80004bac:	aca080e7          	jalr	-1334(ra) # 80001672 <copyout>
    80004bb0:	01650663          	beq	a0,s6,80004bbc <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bb4:	2985                	addiw	s3,s3,1
    80004bb6:	0905                	addi	s2,s2,1
    80004bb8:	fd3a91e3          	bne	s5,s3,80004b7a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bbc:	21c48513          	addi	a0,s1,540
    80004bc0:	ffffd097          	auipc	ra,0xffffd
    80004bc4:	6ec080e7          	jalr	1772(ra) # 800022ac <wakeup>
  release(&pi->lock);
    80004bc8:	8526                	mv	a0,s1
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	0ce080e7          	jalr	206(ra) # 80000c98 <release>
  return i;
}
    80004bd2:	854e                	mv	a0,s3
    80004bd4:	60a6                	ld	ra,72(sp)
    80004bd6:	6406                	ld	s0,64(sp)
    80004bd8:	74e2                	ld	s1,56(sp)
    80004bda:	7942                	ld	s2,48(sp)
    80004bdc:	79a2                	ld	s3,40(sp)
    80004bde:	7a02                	ld	s4,32(sp)
    80004be0:	6ae2                	ld	s5,24(sp)
    80004be2:	6b42                	ld	s6,16(sp)
    80004be4:	6161                	addi	sp,sp,80
    80004be6:	8082                	ret
      release(&pi->lock);
    80004be8:	8526                	mv	a0,s1
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	0ae080e7          	jalr	174(ra) # 80000c98 <release>
      return -1;
    80004bf2:	59fd                	li	s3,-1
    80004bf4:	bff9                	j	80004bd2 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bf6:	4981                	li	s3,0
    80004bf8:	b7d1                	j	80004bbc <piperead+0xae>

0000000080004bfa <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004bfa:	df010113          	addi	sp,sp,-528
    80004bfe:	20113423          	sd	ra,520(sp)
    80004c02:	20813023          	sd	s0,512(sp)
    80004c06:	ffa6                	sd	s1,504(sp)
    80004c08:	fbca                	sd	s2,496(sp)
    80004c0a:	f7ce                	sd	s3,488(sp)
    80004c0c:	f3d2                	sd	s4,480(sp)
    80004c0e:	efd6                	sd	s5,472(sp)
    80004c10:	ebda                	sd	s6,464(sp)
    80004c12:	e7de                	sd	s7,456(sp)
    80004c14:	e3e2                	sd	s8,448(sp)
    80004c16:	ff66                	sd	s9,440(sp)
    80004c18:	fb6a                	sd	s10,432(sp)
    80004c1a:	f76e                	sd	s11,424(sp)
    80004c1c:	0c00                	addi	s0,sp,528
    80004c1e:	84aa                	mv	s1,a0
    80004c20:	dea43c23          	sd	a0,-520(s0)
    80004c24:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c28:	ffffd097          	auipc	ra,0xffffd
    80004c2c:	d88080e7          	jalr	-632(ra) # 800019b0 <myproc>
    80004c30:	892a                	mv	s2,a0

  begin_op();
    80004c32:	fffff097          	auipc	ra,0xfffff
    80004c36:	49c080e7          	jalr	1180(ra) # 800040ce <begin_op>

  if((ip = namei(path)) == 0){
    80004c3a:	8526                	mv	a0,s1
    80004c3c:	fffff097          	auipc	ra,0xfffff
    80004c40:	276080e7          	jalr	630(ra) # 80003eb2 <namei>
    80004c44:	c92d                	beqz	a0,80004cb6 <exec+0xbc>
    80004c46:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c48:	fffff097          	auipc	ra,0xfffff
    80004c4c:	ab4080e7          	jalr	-1356(ra) # 800036fc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c50:	04000713          	li	a4,64
    80004c54:	4681                	li	a3,0
    80004c56:	e5040613          	addi	a2,s0,-432
    80004c5a:	4581                	li	a1,0
    80004c5c:	8526                	mv	a0,s1
    80004c5e:	fffff097          	auipc	ra,0xfffff
    80004c62:	d52080e7          	jalr	-686(ra) # 800039b0 <readi>
    80004c66:	04000793          	li	a5,64
    80004c6a:	00f51a63          	bne	a0,a5,80004c7e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c6e:	e5042703          	lw	a4,-432(s0)
    80004c72:	464c47b7          	lui	a5,0x464c4
    80004c76:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c7a:	04f70463          	beq	a4,a5,80004cc2 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c7e:	8526                	mv	a0,s1
    80004c80:	fffff097          	auipc	ra,0xfffff
    80004c84:	cde080e7          	jalr	-802(ra) # 8000395e <iunlockput>
    end_op();
    80004c88:	fffff097          	auipc	ra,0xfffff
    80004c8c:	4c6080e7          	jalr	1222(ra) # 8000414e <end_op>
  }
  return -1;
    80004c90:	557d                	li	a0,-1
}
    80004c92:	20813083          	ld	ra,520(sp)
    80004c96:	20013403          	ld	s0,512(sp)
    80004c9a:	74fe                	ld	s1,504(sp)
    80004c9c:	795e                	ld	s2,496(sp)
    80004c9e:	79be                	ld	s3,488(sp)
    80004ca0:	7a1e                	ld	s4,480(sp)
    80004ca2:	6afe                	ld	s5,472(sp)
    80004ca4:	6b5e                	ld	s6,464(sp)
    80004ca6:	6bbe                	ld	s7,456(sp)
    80004ca8:	6c1e                	ld	s8,448(sp)
    80004caa:	7cfa                	ld	s9,440(sp)
    80004cac:	7d5a                	ld	s10,432(sp)
    80004cae:	7dba                	ld	s11,424(sp)
    80004cb0:	21010113          	addi	sp,sp,528
    80004cb4:	8082                	ret
    end_op();
    80004cb6:	fffff097          	auipc	ra,0xfffff
    80004cba:	498080e7          	jalr	1176(ra) # 8000414e <end_op>
    return -1;
    80004cbe:	557d                	li	a0,-1
    80004cc0:	bfc9                	j	80004c92 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cc2:	854a                	mv	a0,s2
    80004cc4:	ffffd097          	auipc	ra,0xffffd
    80004cc8:	db0080e7          	jalr	-592(ra) # 80001a74 <proc_pagetable>
    80004ccc:	8baa                	mv	s7,a0
    80004cce:	d945                	beqz	a0,80004c7e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cd0:	e7042983          	lw	s3,-400(s0)
    80004cd4:	e8845783          	lhu	a5,-376(s0)
    80004cd8:	c7ad                	beqz	a5,80004d42 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cda:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cdc:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004cde:	6c85                	lui	s9,0x1
    80004ce0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ce4:	def43823          	sd	a5,-528(s0)
    80004ce8:	a42d                	j	80004f12 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cea:	00004517          	auipc	a0,0x4
    80004cee:	9de50513          	addi	a0,a0,-1570 # 800086c8 <syscalls+0x280>
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	84c080e7          	jalr	-1972(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cfa:	8756                	mv	a4,s5
    80004cfc:	012d86bb          	addw	a3,s11,s2
    80004d00:	4581                	li	a1,0
    80004d02:	8526                	mv	a0,s1
    80004d04:	fffff097          	auipc	ra,0xfffff
    80004d08:	cac080e7          	jalr	-852(ra) # 800039b0 <readi>
    80004d0c:	2501                	sext.w	a0,a0
    80004d0e:	1aaa9963          	bne	s5,a0,80004ec0 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d12:	6785                	lui	a5,0x1
    80004d14:	0127893b          	addw	s2,a5,s2
    80004d18:	77fd                	lui	a5,0xfffff
    80004d1a:	01478a3b          	addw	s4,a5,s4
    80004d1e:	1f897163          	bgeu	s2,s8,80004f00 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004d22:	02091593          	slli	a1,s2,0x20
    80004d26:	9181                	srli	a1,a1,0x20
    80004d28:	95ea                	add	a1,a1,s10
    80004d2a:	855e                	mv	a0,s7
    80004d2c:	ffffc097          	auipc	ra,0xffffc
    80004d30:	342080e7          	jalr	834(ra) # 8000106e <walkaddr>
    80004d34:	862a                	mv	a2,a0
    if(pa == 0)
    80004d36:	d955                	beqz	a0,80004cea <exec+0xf0>
      n = PGSIZE;
    80004d38:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d3a:	fd9a70e3          	bgeu	s4,s9,80004cfa <exec+0x100>
      n = sz - i;
    80004d3e:	8ad2                	mv	s5,s4
    80004d40:	bf6d                	j	80004cfa <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d42:	4901                	li	s2,0
  iunlockput(ip);
    80004d44:	8526                	mv	a0,s1
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	c18080e7          	jalr	-1000(ra) # 8000395e <iunlockput>
  end_op();
    80004d4e:	fffff097          	auipc	ra,0xfffff
    80004d52:	400080e7          	jalr	1024(ra) # 8000414e <end_op>
  p = myproc();
    80004d56:	ffffd097          	auipc	ra,0xffffd
    80004d5a:	c5a080e7          	jalr	-934(ra) # 800019b0 <myproc>
    80004d5e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d60:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d64:	6785                	lui	a5,0x1
    80004d66:	17fd                	addi	a5,a5,-1
    80004d68:	993e                	add	s2,s2,a5
    80004d6a:	757d                	lui	a0,0xfffff
    80004d6c:	00a977b3          	and	a5,s2,a0
    80004d70:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d74:	6609                	lui	a2,0x2
    80004d76:	963e                	add	a2,a2,a5
    80004d78:	85be                	mv	a1,a5
    80004d7a:	855e                	mv	a0,s7
    80004d7c:	ffffc097          	auipc	ra,0xffffc
    80004d80:	6a6080e7          	jalr	1702(ra) # 80001422 <uvmalloc>
    80004d84:	8b2a                	mv	s6,a0
  ip = 0;
    80004d86:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d88:	12050c63          	beqz	a0,80004ec0 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d8c:	75f9                	lui	a1,0xffffe
    80004d8e:	95aa                	add	a1,a1,a0
    80004d90:	855e                	mv	a0,s7
    80004d92:	ffffd097          	auipc	ra,0xffffd
    80004d96:	8ae080e7          	jalr	-1874(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d9a:	7c7d                	lui	s8,0xfffff
    80004d9c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d9e:	e0043783          	ld	a5,-512(s0)
    80004da2:	6388                	ld	a0,0(a5)
    80004da4:	c535                	beqz	a0,80004e10 <exec+0x216>
    80004da6:	e9040993          	addi	s3,s0,-368
    80004daa:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004dae:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004db0:	ffffc097          	auipc	ra,0xffffc
    80004db4:	0b4080e7          	jalr	180(ra) # 80000e64 <strlen>
    80004db8:	2505                	addiw	a0,a0,1
    80004dba:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004dbe:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004dc2:	13896363          	bltu	s2,s8,80004ee8 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004dc6:	e0043d83          	ld	s11,-512(s0)
    80004dca:	000dba03          	ld	s4,0(s11)
    80004dce:	8552                	mv	a0,s4
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	094080e7          	jalr	148(ra) # 80000e64 <strlen>
    80004dd8:	0015069b          	addiw	a3,a0,1
    80004ddc:	8652                	mv	a2,s4
    80004dde:	85ca                	mv	a1,s2
    80004de0:	855e                	mv	a0,s7
    80004de2:	ffffd097          	auipc	ra,0xffffd
    80004de6:	890080e7          	jalr	-1904(ra) # 80001672 <copyout>
    80004dea:	10054363          	bltz	a0,80004ef0 <exec+0x2f6>
    ustack[argc] = sp;
    80004dee:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004df2:	0485                	addi	s1,s1,1
    80004df4:	008d8793          	addi	a5,s11,8
    80004df8:	e0f43023          	sd	a5,-512(s0)
    80004dfc:	008db503          	ld	a0,8(s11)
    80004e00:	c911                	beqz	a0,80004e14 <exec+0x21a>
    if(argc >= MAXARG)
    80004e02:	09a1                	addi	s3,s3,8
    80004e04:	fb3c96e3          	bne	s9,s3,80004db0 <exec+0x1b6>
  sz = sz1;
    80004e08:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e0c:	4481                	li	s1,0
    80004e0e:	a84d                	j	80004ec0 <exec+0x2c6>
  sp = sz;
    80004e10:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e12:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e14:	00349793          	slli	a5,s1,0x3
    80004e18:	f9040713          	addi	a4,s0,-112
    80004e1c:	97ba                	add	a5,a5,a4
    80004e1e:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004e22:	00148693          	addi	a3,s1,1
    80004e26:	068e                	slli	a3,a3,0x3
    80004e28:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e2c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e30:	01897663          	bgeu	s2,s8,80004e3c <exec+0x242>
  sz = sz1;
    80004e34:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e38:	4481                	li	s1,0
    80004e3a:	a059                	j	80004ec0 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e3c:	e9040613          	addi	a2,s0,-368
    80004e40:	85ca                	mv	a1,s2
    80004e42:	855e                	mv	a0,s7
    80004e44:	ffffd097          	auipc	ra,0xffffd
    80004e48:	82e080e7          	jalr	-2002(ra) # 80001672 <copyout>
    80004e4c:	0a054663          	bltz	a0,80004ef8 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004e50:	058ab783          	ld	a5,88(s5)
    80004e54:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e58:	df843783          	ld	a5,-520(s0)
    80004e5c:	0007c703          	lbu	a4,0(a5)
    80004e60:	cf11                	beqz	a4,80004e7c <exec+0x282>
    80004e62:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e64:	02f00693          	li	a3,47
    80004e68:	a039                	j	80004e76 <exec+0x27c>
      last = s+1;
    80004e6a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e6e:	0785                	addi	a5,a5,1
    80004e70:	fff7c703          	lbu	a4,-1(a5)
    80004e74:	c701                	beqz	a4,80004e7c <exec+0x282>
    if(*s == '/')
    80004e76:	fed71ce3          	bne	a4,a3,80004e6e <exec+0x274>
    80004e7a:	bfc5                	j	80004e6a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e7c:	4641                	li	a2,16
    80004e7e:	df843583          	ld	a1,-520(s0)
    80004e82:	158a8513          	addi	a0,s5,344
    80004e86:	ffffc097          	auipc	ra,0xffffc
    80004e8a:	fac080e7          	jalr	-84(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e8e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e92:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004e96:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e9a:	058ab783          	ld	a5,88(s5)
    80004e9e:	e6843703          	ld	a4,-408(s0)
    80004ea2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ea4:	058ab783          	ld	a5,88(s5)
    80004ea8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004eac:	85ea                	mv	a1,s10
    80004eae:	ffffd097          	auipc	ra,0xffffd
    80004eb2:	c62080e7          	jalr	-926(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004eb6:	0004851b          	sext.w	a0,s1
    80004eba:	bbe1                	j	80004c92 <exec+0x98>
    80004ebc:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004ec0:	e0843583          	ld	a1,-504(s0)
    80004ec4:	855e                	mv	a0,s7
    80004ec6:	ffffd097          	auipc	ra,0xffffd
    80004eca:	c4a080e7          	jalr	-950(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80004ece:	da0498e3          	bnez	s1,80004c7e <exec+0x84>
  return -1;
    80004ed2:	557d                	li	a0,-1
    80004ed4:	bb7d                	j	80004c92 <exec+0x98>
    80004ed6:	e1243423          	sd	s2,-504(s0)
    80004eda:	b7dd                	j	80004ec0 <exec+0x2c6>
    80004edc:	e1243423          	sd	s2,-504(s0)
    80004ee0:	b7c5                	j	80004ec0 <exec+0x2c6>
    80004ee2:	e1243423          	sd	s2,-504(s0)
    80004ee6:	bfe9                	j	80004ec0 <exec+0x2c6>
  sz = sz1;
    80004ee8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eec:	4481                	li	s1,0
    80004eee:	bfc9                	j	80004ec0 <exec+0x2c6>
  sz = sz1;
    80004ef0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ef4:	4481                	li	s1,0
    80004ef6:	b7e9                	j	80004ec0 <exec+0x2c6>
  sz = sz1;
    80004ef8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004efc:	4481                	li	s1,0
    80004efe:	b7c9                	j	80004ec0 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f00:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f04:	2b05                	addiw	s6,s6,1
    80004f06:	0389899b          	addiw	s3,s3,56
    80004f0a:	e8845783          	lhu	a5,-376(s0)
    80004f0e:	e2fb5be3          	bge	s6,a5,80004d44 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f12:	2981                	sext.w	s3,s3
    80004f14:	03800713          	li	a4,56
    80004f18:	86ce                	mv	a3,s3
    80004f1a:	e1840613          	addi	a2,s0,-488
    80004f1e:	4581                	li	a1,0
    80004f20:	8526                	mv	a0,s1
    80004f22:	fffff097          	auipc	ra,0xfffff
    80004f26:	a8e080e7          	jalr	-1394(ra) # 800039b0 <readi>
    80004f2a:	03800793          	li	a5,56
    80004f2e:	f8f517e3          	bne	a0,a5,80004ebc <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004f32:	e1842783          	lw	a5,-488(s0)
    80004f36:	4705                	li	a4,1
    80004f38:	fce796e3          	bne	a5,a4,80004f04 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004f3c:	e4043603          	ld	a2,-448(s0)
    80004f40:	e3843783          	ld	a5,-456(s0)
    80004f44:	f8f669e3          	bltu	a2,a5,80004ed6 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f48:	e2843783          	ld	a5,-472(s0)
    80004f4c:	963e                	add	a2,a2,a5
    80004f4e:	f8f667e3          	bltu	a2,a5,80004edc <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f52:	85ca                	mv	a1,s2
    80004f54:	855e                	mv	a0,s7
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	4cc080e7          	jalr	1228(ra) # 80001422 <uvmalloc>
    80004f5e:	e0a43423          	sd	a0,-504(s0)
    80004f62:	d141                	beqz	a0,80004ee2 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004f64:	e2843d03          	ld	s10,-472(s0)
    80004f68:	df043783          	ld	a5,-528(s0)
    80004f6c:	00fd77b3          	and	a5,s10,a5
    80004f70:	fba1                	bnez	a5,80004ec0 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f72:	e2042d83          	lw	s11,-480(s0)
    80004f76:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f7a:	f80c03e3          	beqz	s8,80004f00 <exec+0x306>
    80004f7e:	8a62                	mv	s4,s8
    80004f80:	4901                	li	s2,0
    80004f82:	b345                	j	80004d22 <exec+0x128>

0000000080004f84 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f84:	7179                	addi	sp,sp,-48
    80004f86:	f406                	sd	ra,40(sp)
    80004f88:	f022                	sd	s0,32(sp)
    80004f8a:	ec26                	sd	s1,24(sp)
    80004f8c:	e84a                	sd	s2,16(sp)
    80004f8e:	1800                	addi	s0,sp,48
    80004f90:	892e                	mv	s2,a1
    80004f92:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f94:	fdc40593          	addi	a1,s0,-36
    80004f98:	ffffe097          	auipc	ra,0xffffe
    80004f9c:	bf2080e7          	jalr	-1038(ra) # 80002b8a <argint>
    80004fa0:	04054063          	bltz	a0,80004fe0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fa4:	fdc42703          	lw	a4,-36(s0)
    80004fa8:	47bd                	li	a5,15
    80004faa:	02e7ed63          	bltu	a5,a4,80004fe4 <argfd+0x60>
    80004fae:	ffffd097          	auipc	ra,0xffffd
    80004fb2:	a02080e7          	jalr	-1534(ra) # 800019b0 <myproc>
    80004fb6:	fdc42703          	lw	a4,-36(s0)
    80004fba:	01a70793          	addi	a5,a4,26
    80004fbe:	078e                	slli	a5,a5,0x3
    80004fc0:	953e                	add	a0,a0,a5
    80004fc2:	611c                	ld	a5,0(a0)
    80004fc4:	c395                	beqz	a5,80004fe8 <argfd+0x64>
    return -1;
  if(pfd)
    80004fc6:	00090463          	beqz	s2,80004fce <argfd+0x4a>
    *pfd = fd;
    80004fca:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fce:	4501                	li	a0,0
  if(pf)
    80004fd0:	c091                	beqz	s1,80004fd4 <argfd+0x50>
    *pf = f;
    80004fd2:	e09c                	sd	a5,0(s1)
}
    80004fd4:	70a2                	ld	ra,40(sp)
    80004fd6:	7402                	ld	s0,32(sp)
    80004fd8:	64e2                	ld	s1,24(sp)
    80004fda:	6942                	ld	s2,16(sp)
    80004fdc:	6145                	addi	sp,sp,48
    80004fde:	8082                	ret
    return -1;
    80004fe0:	557d                	li	a0,-1
    80004fe2:	bfcd                	j	80004fd4 <argfd+0x50>
    return -1;
    80004fe4:	557d                	li	a0,-1
    80004fe6:	b7fd                	j	80004fd4 <argfd+0x50>
    80004fe8:	557d                	li	a0,-1
    80004fea:	b7ed                	j	80004fd4 <argfd+0x50>

0000000080004fec <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fec:	1101                	addi	sp,sp,-32
    80004fee:	ec06                	sd	ra,24(sp)
    80004ff0:	e822                	sd	s0,16(sp)
    80004ff2:	e426                	sd	s1,8(sp)
    80004ff4:	1000                	addi	s0,sp,32
    80004ff6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004ff8:	ffffd097          	auipc	ra,0xffffd
    80004ffc:	9b8080e7          	jalr	-1608(ra) # 800019b0 <myproc>
    80005000:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005002:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005006:	4501                	li	a0,0
    80005008:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000500a:	6398                	ld	a4,0(a5)
    8000500c:	cb19                	beqz	a4,80005022 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000500e:	2505                	addiw	a0,a0,1
    80005010:	07a1                	addi	a5,a5,8
    80005012:	fed51ce3          	bne	a0,a3,8000500a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005016:	557d                	li	a0,-1
}
    80005018:	60e2                	ld	ra,24(sp)
    8000501a:	6442                	ld	s0,16(sp)
    8000501c:	64a2                	ld	s1,8(sp)
    8000501e:	6105                	addi	sp,sp,32
    80005020:	8082                	ret
      p->ofile[fd] = f;
    80005022:	01a50793          	addi	a5,a0,26
    80005026:	078e                	slli	a5,a5,0x3
    80005028:	963e                	add	a2,a2,a5
    8000502a:	e204                	sd	s1,0(a2)
      return fd;
    8000502c:	b7f5                	j	80005018 <fdalloc+0x2c>

000000008000502e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000502e:	715d                	addi	sp,sp,-80
    80005030:	e486                	sd	ra,72(sp)
    80005032:	e0a2                	sd	s0,64(sp)
    80005034:	fc26                	sd	s1,56(sp)
    80005036:	f84a                	sd	s2,48(sp)
    80005038:	f44e                	sd	s3,40(sp)
    8000503a:	f052                	sd	s4,32(sp)
    8000503c:	ec56                	sd	s5,24(sp)
    8000503e:	0880                	addi	s0,sp,80
    80005040:	89ae                	mv	s3,a1
    80005042:	8ab2                	mv	s5,a2
    80005044:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005046:	fb040593          	addi	a1,s0,-80
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	e86080e7          	jalr	-378(ra) # 80003ed0 <nameiparent>
    80005052:	892a                	mv	s2,a0
    80005054:	12050f63          	beqz	a0,80005192 <create+0x164>
    return 0;

  ilock(dp);
    80005058:	ffffe097          	auipc	ra,0xffffe
    8000505c:	6a4080e7          	jalr	1700(ra) # 800036fc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005060:	4601                	li	a2,0
    80005062:	fb040593          	addi	a1,s0,-80
    80005066:	854a                	mv	a0,s2
    80005068:	fffff097          	auipc	ra,0xfffff
    8000506c:	b78080e7          	jalr	-1160(ra) # 80003be0 <dirlookup>
    80005070:	84aa                	mv	s1,a0
    80005072:	c921                	beqz	a0,800050c2 <create+0x94>
    iunlockput(dp);
    80005074:	854a                	mv	a0,s2
    80005076:	fffff097          	auipc	ra,0xfffff
    8000507a:	8e8080e7          	jalr	-1816(ra) # 8000395e <iunlockput>
    ilock(ip);
    8000507e:	8526                	mv	a0,s1
    80005080:	ffffe097          	auipc	ra,0xffffe
    80005084:	67c080e7          	jalr	1660(ra) # 800036fc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005088:	2981                	sext.w	s3,s3
    8000508a:	4789                	li	a5,2
    8000508c:	02f99463          	bne	s3,a5,800050b4 <create+0x86>
    80005090:	0444d783          	lhu	a5,68(s1)
    80005094:	37f9                	addiw	a5,a5,-2
    80005096:	17c2                	slli	a5,a5,0x30
    80005098:	93c1                	srli	a5,a5,0x30
    8000509a:	4705                	li	a4,1
    8000509c:	00f76c63          	bltu	a4,a5,800050b4 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050a0:	8526                	mv	a0,s1
    800050a2:	60a6                	ld	ra,72(sp)
    800050a4:	6406                	ld	s0,64(sp)
    800050a6:	74e2                	ld	s1,56(sp)
    800050a8:	7942                	ld	s2,48(sp)
    800050aa:	79a2                	ld	s3,40(sp)
    800050ac:	7a02                	ld	s4,32(sp)
    800050ae:	6ae2                	ld	s5,24(sp)
    800050b0:	6161                	addi	sp,sp,80
    800050b2:	8082                	ret
    iunlockput(ip);
    800050b4:	8526                	mv	a0,s1
    800050b6:	fffff097          	auipc	ra,0xfffff
    800050ba:	8a8080e7          	jalr	-1880(ra) # 8000395e <iunlockput>
    return 0;
    800050be:	4481                	li	s1,0
    800050c0:	b7c5                	j	800050a0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050c2:	85ce                	mv	a1,s3
    800050c4:	00092503          	lw	a0,0(s2)
    800050c8:	ffffe097          	auipc	ra,0xffffe
    800050cc:	49c080e7          	jalr	1180(ra) # 80003564 <ialloc>
    800050d0:	84aa                	mv	s1,a0
    800050d2:	c529                	beqz	a0,8000511c <create+0xee>
  ilock(ip);
    800050d4:	ffffe097          	auipc	ra,0xffffe
    800050d8:	628080e7          	jalr	1576(ra) # 800036fc <ilock>
  ip->major = major;
    800050dc:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050e0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050e4:	4785                	li	a5,1
    800050e6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800050ea:	8526                	mv	a0,s1
    800050ec:	ffffe097          	auipc	ra,0xffffe
    800050f0:	546080e7          	jalr	1350(ra) # 80003632 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050f4:	2981                	sext.w	s3,s3
    800050f6:	4785                	li	a5,1
    800050f8:	02f98a63          	beq	s3,a5,8000512c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800050fc:	40d0                	lw	a2,4(s1)
    800050fe:	fb040593          	addi	a1,s0,-80
    80005102:	854a                	mv	a0,s2
    80005104:	fffff097          	auipc	ra,0xfffff
    80005108:	cec080e7          	jalr	-788(ra) # 80003df0 <dirlink>
    8000510c:	06054b63          	bltz	a0,80005182 <create+0x154>
  iunlockput(dp);
    80005110:	854a                	mv	a0,s2
    80005112:	fffff097          	auipc	ra,0xfffff
    80005116:	84c080e7          	jalr	-1972(ra) # 8000395e <iunlockput>
  return ip;
    8000511a:	b759                	j	800050a0 <create+0x72>
    panic("create: ialloc");
    8000511c:	00003517          	auipc	a0,0x3
    80005120:	5cc50513          	addi	a0,a0,1484 # 800086e8 <syscalls+0x2a0>
    80005124:	ffffb097          	auipc	ra,0xffffb
    80005128:	41a080e7          	jalr	1050(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000512c:	04a95783          	lhu	a5,74(s2)
    80005130:	2785                	addiw	a5,a5,1
    80005132:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005136:	854a                	mv	a0,s2
    80005138:	ffffe097          	auipc	ra,0xffffe
    8000513c:	4fa080e7          	jalr	1274(ra) # 80003632 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005140:	40d0                	lw	a2,4(s1)
    80005142:	00003597          	auipc	a1,0x3
    80005146:	5b658593          	addi	a1,a1,1462 # 800086f8 <syscalls+0x2b0>
    8000514a:	8526                	mv	a0,s1
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	ca4080e7          	jalr	-860(ra) # 80003df0 <dirlink>
    80005154:	00054f63          	bltz	a0,80005172 <create+0x144>
    80005158:	00492603          	lw	a2,4(s2)
    8000515c:	00003597          	auipc	a1,0x3
    80005160:	5a458593          	addi	a1,a1,1444 # 80008700 <syscalls+0x2b8>
    80005164:	8526                	mv	a0,s1
    80005166:	fffff097          	auipc	ra,0xfffff
    8000516a:	c8a080e7          	jalr	-886(ra) # 80003df0 <dirlink>
    8000516e:	f80557e3          	bgez	a0,800050fc <create+0xce>
      panic("create dots");
    80005172:	00003517          	auipc	a0,0x3
    80005176:	59650513          	addi	a0,a0,1430 # 80008708 <syscalls+0x2c0>
    8000517a:	ffffb097          	auipc	ra,0xffffb
    8000517e:	3c4080e7          	jalr	964(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005182:	00003517          	auipc	a0,0x3
    80005186:	59650513          	addi	a0,a0,1430 # 80008718 <syscalls+0x2d0>
    8000518a:	ffffb097          	auipc	ra,0xffffb
    8000518e:	3b4080e7          	jalr	948(ra) # 8000053e <panic>
    return 0;
    80005192:	84aa                	mv	s1,a0
    80005194:	b731                	j	800050a0 <create+0x72>

0000000080005196 <sys_dup>:
{
    80005196:	7179                	addi	sp,sp,-48
    80005198:	f406                	sd	ra,40(sp)
    8000519a:	f022                	sd	s0,32(sp)
    8000519c:	ec26                	sd	s1,24(sp)
    8000519e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051a0:	fd840613          	addi	a2,s0,-40
    800051a4:	4581                	li	a1,0
    800051a6:	4501                	li	a0,0
    800051a8:	00000097          	auipc	ra,0x0
    800051ac:	ddc080e7          	jalr	-548(ra) # 80004f84 <argfd>
    return -1;
    800051b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051b2:	02054363          	bltz	a0,800051d8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051b6:	fd843503          	ld	a0,-40(s0)
    800051ba:	00000097          	auipc	ra,0x0
    800051be:	e32080e7          	jalr	-462(ra) # 80004fec <fdalloc>
    800051c2:	84aa                	mv	s1,a0
    return -1;
    800051c4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051c6:	00054963          	bltz	a0,800051d8 <sys_dup+0x42>
  filedup(f);
    800051ca:	fd843503          	ld	a0,-40(s0)
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	37a080e7          	jalr	890(ra) # 80004548 <filedup>
  return fd;
    800051d6:	87a6                	mv	a5,s1
}
    800051d8:	853e                	mv	a0,a5
    800051da:	70a2                	ld	ra,40(sp)
    800051dc:	7402                	ld	s0,32(sp)
    800051de:	64e2                	ld	s1,24(sp)
    800051e0:	6145                	addi	sp,sp,48
    800051e2:	8082                	ret

00000000800051e4 <sys_read>:
{
    800051e4:	7179                	addi	sp,sp,-48
    800051e6:	f406                	sd	ra,40(sp)
    800051e8:	f022                	sd	s0,32(sp)
    800051ea:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ec:	fe840613          	addi	a2,s0,-24
    800051f0:	4581                	li	a1,0
    800051f2:	4501                	li	a0,0
    800051f4:	00000097          	auipc	ra,0x0
    800051f8:	d90080e7          	jalr	-624(ra) # 80004f84 <argfd>
    return -1;
    800051fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051fe:	04054163          	bltz	a0,80005240 <sys_read+0x5c>
    80005202:	fe440593          	addi	a1,s0,-28
    80005206:	4509                	li	a0,2
    80005208:	ffffe097          	auipc	ra,0xffffe
    8000520c:	982080e7          	jalr	-1662(ra) # 80002b8a <argint>
    return -1;
    80005210:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005212:	02054763          	bltz	a0,80005240 <sys_read+0x5c>
    80005216:	fd840593          	addi	a1,s0,-40
    8000521a:	4505                	li	a0,1
    8000521c:	ffffe097          	auipc	ra,0xffffe
    80005220:	990080e7          	jalr	-1648(ra) # 80002bac <argaddr>
    return -1;
    80005224:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005226:	00054d63          	bltz	a0,80005240 <sys_read+0x5c>
  return fileread(f, p, n);
    8000522a:	fe442603          	lw	a2,-28(s0)
    8000522e:	fd843583          	ld	a1,-40(s0)
    80005232:	fe843503          	ld	a0,-24(s0)
    80005236:	fffff097          	auipc	ra,0xfffff
    8000523a:	49e080e7          	jalr	1182(ra) # 800046d4 <fileread>
    8000523e:	87aa                	mv	a5,a0
}
    80005240:	853e                	mv	a0,a5
    80005242:	70a2                	ld	ra,40(sp)
    80005244:	7402                	ld	s0,32(sp)
    80005246:	6145                	addi	sp,sp,48
    80005248:	8082                	ret

000000008000524a <sys_write>:
{
    8000524a:	7179                	addi	sp,sp,-48
    8000524c:	f406                	sd	ra,40(sp)
    8000524e:	f022                	sd	s0,32(sp)
    80005250:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005252:	fe840613          	addi	a2,s0,-24
    80005256:	4581                	li	a1,0
    80005258:	4501                	li	a0,0
    8000525a:	00000097          	auipc	ra,0x0
    8000525e:	d2a080e7          	jalr	-726(ra) # 80004f84 <argfd>
    return -1;
    80005262:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005264:	04054163          	bltz	a0,800052a6 <sys_write+0x5c>
    80005268:	fe440593          	addi	a1,s0,-28
    8000526c:	4509                	li	a0,2
    8000526e:	ffffe097          	auipc	ra,0xffffe
    80005272:	91c080e7          	jalr	-1764(ra) # 80002b8a <argint>
    return -1;
    80005276:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005278:	02054763          	bltz	a0,800052a6 <sys_write+0x5c>
    8000527c:	fd840593          	addi	a1,s0,-40
    80005280:	4505                	li	a0,1
    80005282:	ffffe097          	auipc	ra,0xffffe
    80005286:	92a080e7          	jalr	-1750(ra) # 80002bac <argaddr>
    return -1;
    8000528a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000528c:	00054d63          	bltz	a0,800052a6 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005290:	fe442603          	lw	a2,-28(s0)
    80005294:	fd843583          	ld	a1,-40(s0)
    80005298:	fe843503          	ld	a0,-24(s0)
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	4fa080e7          	jalr	1274(ra) # 80004796 <filewrite>
    800052a4:	87aa                	mv	a5,a0
}
    800052a6:	853e                	mv	a0,a5
    800052a8:	70a2                	ld	ra,40(sp)
    800052aa:	7402                	ld	s0,32(sp)
    800052ac:	6145                	addi	sp,sp,48
    800052ae:	8082                	ret

00000000800052b0 <sys_close>:
{
    800052b0:	1101                	addi	sp,sp,-32
    800052b2:	ec06                	sd	ra,24(sp)
    800052b4:	e822                	sd	s0,16(sp)
    800052b6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052b8:	fe040613          	addi	a2,s0,-32
    800052bc:	fec40593          	addi	a1,s0,-20
    800052c0:	4501                	li	a0,0
    800052c2:	00000097          	auipc	ra,0x0
    800052c6:	cc2080e7          	jalr	-830(ra) # 80004f84 <argfd>
    return -1;
    800052ca:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052cc:	02054463          	bltz	a0,800052f4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052d0:	ffffc097          	auipc	ra,0xffffc
    800052d4:	6e0080e7          	jalr	1760(ra) # 800019b0 <myproc>
    800052d8:	fec42783          	lw	a5,-20(s0)
    800052dc:	07e9                	addi	a5,a5,26
    800052de:	078e                	slli	a5,a5,0x3
    800052e0:	97aa                	add	a5,a5,a0
    800052e2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052e6:	fe043503          	ld	a0,-32(s0)
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	2b0080e7          	jalr	688(ra) # 8000459a <fileclose>
  return 0;
    800052f2:	4781                	li	a5,0
}
    800052f4:	853e                	mv	a0,a5
    800052f6:	60e2                	ld	ra,24(sp)
    800052f8:	6442                	ld	s0,16(sp)
    800052fa:	6105                	addi	sp,sp,32
    800052fc:	8082                	ret

00000000800052fe <sys_fstat>:
{
    800052fe:	1101                	addi	sp,sp,-32
    80005300:	ec06                	sd	ra,24(sp)
    80005302:	e822                	sd	s0,16(sp)
    80005304:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005306:	fe840613          	addi	a2,s0,-24
    8000530a:	4581                	li	a1,0
    8000530c:	4501                	li	a0,0
    8000530e:	00000097          	auipc	ra,0x0
    80005312:	c76080e7          	jalr	-906(ra) # 80004f84 <argfd>
    return -1;
    80005316:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005318:	02054563          	bltz	a0,80005342 <sys_fstat+0x44>
    8000531c:	fe040593          	addi	a1,s0,-32
    80005320:	4505                	li	a0,1
    80005322:	ffffe097          	auipc	ra,0xffffe
    80005326:	88a080e7          	jalr	-1910(ra) # 80002bac <argaddr>
    return -1;
    8000532a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000532c:	00054b63          	bltz	a0,80005342 <sys_fstat+0x44>
  return filestat(f, st);
    80005330:	fe043583          	ld	a1,-32(s0)
    80005334:	fe843503          	ld	a0,-24(s0)
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	32a080e7          	jalr	810(ra) # 80004662 <filestat>
    80005340:	87aa                	mv	a5,a0
}
    80005342:	853e                	mv	a0,a5
    80005344:	60e2                	ld	ra,24(sp)
    80005346:	6442                	ld	s0,16(sp)
    80005348:	6105                	addi	sp,sp,32
    8000534a:	8082                	ret

000000008000534c <sys_link>:
{
    8000534c:	7169                	addi	sp,sp,-304
    8000534e:	f606                	sd	ra,296(sp)
    80005350:	f222                	sd	s0,288(sp)
    80005352:	ee26                	sd	s1,280(sp)
    80005354:	ea4a                	sd	s2,272(sp)
    80005356:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005358:	08000613          	li	a2,128
    8000535c:	ed040593          	addi	a1,s0,-304
    80005360:	4501                	li	a0,0
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	86c080e7          	jalr	-1940(ra) # 80002bce <argstr>
    return -1;
    8000536a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000536c:	10054e63          	bltz	a0,80005488 <sys_link+0x13c>
    80005370:	08000613          	li	a2,128
    80005374:	f5040593          	addi	a1,s0,-176
    80005378:	4505                	li	a0,1
    8000537a:	ffffe097          	auipc	ra,0xffffe
    8000537e:	854080e7          	jalr	-1964(ra) # 80002bce <argstr>
    return -1;
    80005382:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005384:	10054263          	bltz	a0,80005488 <sys_link+0x13c>
  begin_op();
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	d46080e7          	jalr	-698(ra) # 800040ce <begin_op>
  if((ip = namei(old)) == 0){
    80005390:	ed040513          	addi	a0,s0,-304
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	b1e080e7          	jalr	-1250(ra) # 80003eb2 <namei>
    8000539c:	84aa                	mv	s1,a0
    8000539e:	c551                	beqz	a0,8000542a <sys_link+0xde>
  ilock(ip);
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	35c080e7          	jalr	860(ra) # 800036fc <ilock>
  if(ip->type == T_DIR){
    800053a8:	04449703          	lh	a4,68(s1)
    800053ac:	4785                	li	a5,1
    800053ae:	08f70463          	beq	a4,a5,80005436 <sys_link+0xea>
  ip->nlink++;
    800053b2:	04a4d783          	lhu	a5,74(s1)
    800053b6:	2785                	addiw	a5,a5,1
    800053b8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053bc:	8526                	mv	a0,s1
    800053be:	ffffe097          	auipc	ra,0xffffe
    800053c2:	274080e7          	jalr	628(ra) # 80003632 <iupdate>
  iunlock(ip);
    800053c6:	8526                	mv	a0,s1
    800053c8:	ffffe097          	auipc	ra,0xffffe
    800053cc:	3f6080e7          	jalr	1014(ra) # 800037be <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053d0:	fd040593          	addi	a1,s0,-48
    800053d4:	f5040513          	addi	a0,s0,-176
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	af8080e7          	jalr	-1288(ra) # 80003ed0 <nameiparent>
    800053e0:	892a                	mv	s2,a0
    800053e2:	c935                	beqz	a0,80005456 <sys_link+0x10a>
  ilock(dp);
    800053e4:	ffffe097          	auipc	ra,0xffffe
    800053e8:	318080e7          	jalr	792(ra) # 800036fc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053ec:	00092703          	lw	a4,0(s2)
    800053f0:	409c                	lw	a5,0(s1)
    800053f2:	04f71d63          	bne	a4,a5,8000544c <sys_link+0x100>
    800053f6:	40d0                	lw	a2,4(s1)
    800053f8:	fd040593          	addi	a1,s0,-48
    800053fc:	854a                	mv	a0,s2
    800053fe:	fffff097          	auipc	ra,0xfffff
    80005402:	9f2080e7          	jalr	-1550(ra) # 80003df0 <dirlink>
    80005406:	04054363          	bltz	a0,8000544c <sys_link+0x100>
  iunlockput(dp);
    8000540a:	854a                	mv	a0,s2
    8000540c:	ffffe097          	auipc	ra,0xffffe
    80005410:	552080e7          	jalr	1362(ra) # 8000395e <iunlockput>
  iput(ip);
    80005414:	8526                	mv	a0,s1
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	4a0080e7          	jalr	1184(ra) # 800038b6 <iput>
  end_op();
    8000541e:	fffff097          	auipc	ra,0xfffff
    80005422:	d30080e7          	jalr	-720(ra) # 8000414e <end_op>
  return 0;
    80005426:	4781                	li	a5,0
    80005428:	a085                	j	80005488 <sys_link+0x13c>
    end_op();
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	d24080e7          	jalr	-732(ra) # 8000414e <end_op>
    return -1;
    80005432:	57fd                	li	a5,-1
    80005434:	a891                	j	80005488 <sys_link+0x13c>
    iunlockput(ip);
    80005436:	8526                	mv	a0,s1
    80005438:	ffffe097          	auipc	ra,0xffffe
    8000543c:	526080e7          	jalr	1318(ra) # 8000395e <iunlockput>
    end_op();
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	d0e080e7          	jalr	-754(ra) # 8000414e <end_op>
    return -1;
    80005448:	57fd                	li	a5,-1
    8000544a:	a83d                	j	80005488 <sys_link+0x13c>
    iunlockput(dp);
    8000544c:	854a                	mv	a0,s2
    8000544e:	ffffe097          	auipc	ra,0xffffe
    80005452:	510080e7          	jalr	1296(ra) # 8000395e <iunlockput>
  ilock(ip);
    80005456:	8526                	mv	a0,s1
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	2a4080e7          	jalr	676(ra) # 800036fc <ilock>
  ip->nlink--;
    80005460:	04a4d783          	lhu	a5,74(s1)
    80005464:	37fd                	addiw	a5,a5,-1
    80005466:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000546a:	8526                	mv	a0,s1
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	1c6080e7          	jalr	454(ra) # 80003632 <iupdate>
  iunlockput(ip);
    80005474:	8526                	mv	a0,s1
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	4e8080e7          	jalr	1256(ra) # 8000395e <iunlockput>
  end_op();
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	cd0080e7          	jalr	-816(ra) # 8000414e <end_op>
  return -1;
    80005486:	57fd                	li	a5,-1
}
    80005488:	853e                	mv	a0,a5
    8000548a:	70b2                	ld	ra,296(sp)
    8000548c:	7412                	ld	s0,288(sp)
    8000548e:	64f2                	ld	s1,280(sp)
    80005490:	6952                	ld	s2,272(sp)
    80005492:	6155                	addi	sp,sp,304
    80005494:	8082                	ret

0000000080005496 <sys_unlink>:
{
    80005496:	7151                	addi	sp,sp,-240
    80005498:	f586                	sd	ra,232(sp)
    8000549a:	f1a2                	sd	s0,224(sp)
    8000549c:	eda6                	sd	s1,216(sp)
    8000549e:	e9ca                	sd	s2,208(sp)
    800054a0:	e5ce                	sd	s3,200(sp)
    800054a2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054a4:	08000613          	li	a2,128
    800054a8:	f3040593          	addi	a1,s0,-208
    800054ac:	4501                	li	a0,0
    800054ae:	ffffd097          	auipc	ra,0xffffd
    800054b2:	720080e7          	jalr	1824(ra) # 80002bce <argstr>
    800054b6:	18054163          	bltz	a0,80005638 <sys_unlink+0x1a2>
  begin_op();
    800054ba:	fffff097          	auipc	ra,0xfffff
    800054be:	c14080e7          	jalr	-1004(ra) # 800040ce <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054c2:	fb040593          	addi	a1,s0,-80
    800054c6:	f3040513          	addi	a0,s0,-208
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	a06080e7          	jalr	-1530(ra) # 80003ed0 <nameiparent>
    800054d2:	84aa                	mv	s1,a0
    800054d4:	c979                	beqz	a0,800055aa <sys_unlink+0x114>
  ilock(dp);
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	226080e7          	jalr	550(ra) # 800036fc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054de:	00003597          	auipc	a1,0x3
    800054e2:	21a58593          	addi	a1,a1,538 # 800086f8 <syscalls+0x2b0>
    800054e6:	fb040513          	addi	a0,s0,-80
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	6dc080e7          	jalr	1756(ra) # 80003bc6 <namecmp>
    800054f2:	14050a63          	beqz	a0,80005646 <sys_unlink+0x1b0>
    800054f6:	00003597          	auipc	a1,0x3
    800054fa:	20a58593          	addi	a1,a1,522 # 80008700 <syscalls+0x2b8>
    800054fe:	fb040513          	addi	a0,s0,-80
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	6c4080e7          	jalr	1732(ra) # 80003bc6 <namecmp>
    8000550a:	12050e63          	beqz	a0,80005646 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000550e:	f2c40613          	addi	a2,s0,-212
    80005512:	fb040593          	addi	a1,s0,-80
    80005516:	8526                	mv	a0,s1
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	6c8080e7          	jalr	1736(ra) # 80003be0 <dirlookup>
    80005520:	892a                	mv	s2,a0
    80005522:	12050263          	beqz	a0,80005646 <sys_unlink+0x1b0>
  ilock(ip);
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	1d6080e7          	jalr	470(ra) # 800036fc <ilock>
  if(ip->nlink < 1)
    8000552e:	04a91783          	lh	a5,74(s2)
    80005532:	08f05263          	blez	a5,800055b6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005536:	04491703          	lh	a4,68(s2)
    8000553a:	4785                	li	a5,1
    8000553c:	08f70563          	beq	a4,a5,800055c6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005540:	4641                	li	a2,16
    80005542:	4581                	li	a1,0
    80005544:	fc040513          	addi	a0,s0,-64
    80005548:	ffffb097          	auipc	ra,0xffffb
    8000554c:	798080e7          	jalr	1944(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005550:	4741                	li	a4,16
    80005552:	f2c42683          	lw	a3,-212(s0)
    80005556:	fc040613          	addi	a2,s0,-64
    8000555a:	4581                	li	a1,0
    8000555c:	8526                	mv	a0,s1
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	54a080e7          	jalr	1354(ra) # 80003aa8 <writei>
    80005566:	47c1                	li	a5,16
    80005568:	0af51563          	bne	a0,a5,80005612 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000556c:	04491703          	lh	a4,68(s2)
    80005570:	4785                	li	a5,1
    80005572:	0af70863          	beq	a4,a5,80005622 <sys_unlink+0x18c>
  iunlockput(dp);
    80005576:	8526                	mv	a0,s1
    80005578:	ffffe097          	auipc	ra,0xffffe
    8000557c:	3e6080e7          	jalr	998(ra) # 8000395e <iunlockput>
  ip->nlink--;
    80005580:	04a95783          	lhu	a5,74(s2)
    80005584:	37fd                	addiw	a5,a5,-1
    80005586:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000558a:	854a                	mv	a0,s2
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	0a6080e7          	jalr	166(ra) # 80003632 <iupdate>
  iunlockput(ip);
    80005594:	854a                	mv	a0,s2
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	3c8080e7          	jalr	968(ra) # 8000395e <iunlockput>
  end_op();
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	bb0080e7          	jalr	-1104(ra) # 8000414e <end_op>
  return 0;
    800055a6:	4501                	li	a0,0
    800055a8:	a84d                	j	8000565a <sys_unlink+0x1c4>
    end_op();
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	ba4080e7          	jalr	-1116(ra) # 8000414e <end_op>
    return -1;
    800055b2:	557d                	li	a0,-1
    800055b4:	a05d                	j	8000565a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055b6:	00003517          	auipc	a0,0x3
    800055ba:	17250513          	addi	a0,a0,370 # 80008728 <syscalls+0x2e0>
    800055be:	ffffb097          	auipc	ra,0xffffb
    800055c2:	f80080e7          	jalr	-128(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055c6:	04c92703          	lw	a4,76(s2)
    800055ca:	02000793          	li	a5,32
    800055ce:	f6e7f9e3          	bgeu	a5,a4,80005540 <sys_unlink+0xaa>
    800055d2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055d6:	4741                	li	a4,16
    800055d8:	86ce                	mv	a3,s3
    800055da:	f1840613          	addi	a2,s0,-232
    800055de:	4581                	li	a1,0
    800055e0:	854a                	mv	a0,s2
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	3ce080e7          	jalr	974(ra) # 800039b0 <readi>
    800055ea:	47c1                	li	a5,16
    800055ec:	00f51b63          	bne	a0,a5,80005602 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055f0:	f1845783          	lhu	a5,-232(s0)
    800055f4:	e7a1                	bnez	a5,8000563c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055f6:	29c1                	addiw	s3,s3,16
    800055f8:	04c92783          	lw	a5,76(s2)
    800055fc:	fcf9ede3          	bltu	s3,a5,800055d6 <sys_unlink+0x140>
    80005600:	b781                	j	80005540 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005602:	00003517          	auipc	a0,0x3
    80005606:	13e50513          	addi	a0,a0,318 # 80008740 <syscalls+0x2f8>
    8000560a:	ffffb097          	auipc	ra,0xffffb
    8000560e:	f34080e7          	jalr	-204(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005612:	00003517          	auipc	a0,0x3
    80005616:	14650513          	addi	a0,a0,326 # 80008758 <syscalls+0x310>
    8000561a:	ffffb097          	auipc	ra,0xffffb
    8000561e:	f24080e7          	jalr	-220(ra) # 8000053e <panic>
    dp->nlink--;
    80005622:	04a4d783          	lhu	a5,74(s1)
    80005626:	37fd                	addiw	a5,a5,-1
    80005628:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	004080e7          	jalr	4(ra) # 80003632 <iupdate>
    80005636:	b781                	j	80005576 <sys_unlink+0xe0>
    return -1;
    80005638:	557d                	li	a0,-1
    8000563a:	a005                	j	8000565a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000563c:	854a                	mv	a0,s2
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	320080e7          	jalr	800(ra) # 8000395e <iunlockput>
  iunlockput(dp);
    80005646:	8526                	mv	a0,s1
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	316080e7          	jalr	790(ra) # 8000395e <iunlockput>
  end_op();
    80005650:	fffff097          	auipc	ra,0xfffff
    80005654:	afe080e7          	jalr	-1282(ra) # 8000414e <end_op>
  return -1;
    80005658:	557d                	li	a0,-1
}
    8000565a:	70ae                	ld	ra,232(sp)
    8000565c:	740e                	ld	s0,224(sp)
    8000565e:	64ee                	ld	s1,216(sp)
    80005660:	694e                	ld	s2,208(sp)
    80005662:	69ae                	ld	s3,200(sp)
    80005664:	616d                	addi	sp,sp,240
    80005666:	8082                	ret

0000000080005668 <sys_open>:

uint64
sys_open(void)
{
    80005668:	7131                	addi	sp,sp,-192
    8000566a:	fd06                	sd	ra,184(sp)
    8000566c:	f922                	sd	s0,176(sp)
    8000566e:	f526                	sd	s1,168(sp)
    80005670:	f14a                	sd	s2,160(sp)
    80005672:	ed4e                	sd	s3,152(sp)
    80005674:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005676:	08000613          	li	a2,128
    8000567a:	f5040593          	addi	a1,s0,-176
    8000567e:	4501                	li	a0,0
    80005680:	ffffd097          	auipc	ra,0xffffd
    80005684:	54e080e7          	jalr	1358(ra) # 80002bce <argstr>
    return -1;
    80005688:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000568a:	0c054163          	bltz	a0,8000574c <sys_open+0xe4>
    8000568e:	f4c40593          	addi	a1,s0,-180
    80005692:	4505                	li	a0,1
    80005694:	ffffd097          	auipc	ra,0xffffd
    80005698:	4f6080e7          	jalr	1270(ra) # 80002b8a <argint>
    8000569c:	0a054863          	bltz	a0,8000574c <sys_open+0xe4>

  begin_op();
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	a2e080e7          	jalr	-1490(ra) # 800040ce <begin_op>

  if(omode & O_CREATE){
    800056a8:	f4c42783          	lw	a5,-180(s0)
    800056ac:	2007f793          	andi	a5,a5,512
    800056b0:	cbdd                	beqz	a5,80005766 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056b2:	4681                	li	a3,0
    800056b4:	4601                	li	a2,0
    800056b6:	4589                	li	a1,2
    800056b8:	f5040513          	addi	a0,s0,-176
    800056bc:	00000097          	auipc	ra,0x0
    800056c0:	972080e7          	jalr	-1678(ra) # 8000502e <create>
    800056c4:	892a                	mv	s2,a0
    if(ip == 0){
    800056c6:	c959                	beqz	a0,8000575c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056c8:	04491703          	lh	a4,68(s2)
    800056cc:	478d                	li	a5,3
    800056ce:	00f71763          	bne	a4,a5,800056dc <sys_open+0x74>
    800056d2:	04695703          	lhu	a4,70(s2)
    800056d6:	47a5                	li	a5,9
    800056d8:	0ce7ec63          	bltu	a5,a4,800057b0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	e02080e7          	jalr	-510(ra) # 800044de <filealloc>
    800056e4:	89aa                	mv	s3,a0
    800056e6:	10050263          	beqz	a0,800057ea <sys_open+0x182>
    800056ea:	00000097          	auipc	ra,0x0
    800056ee:	902080e7          	jalr	-1790(ra) # 80004fec <fdalloc>
    800056f2:	84aa                	mv	s1,a0
    800056f4:	0e054663          	bltz	a0,800057e0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056f8:	04491703          	lh	a4,68(s2)
    800056fc:	478d                	li	a5,3
    800056fe:	0cf70463          	beq	a4,a5,800057c6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005702:	4789                	li	a5,2
    80005704:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005708:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000570c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005710:	f4c42783          	lw	a5,-180(s0)
    80005714:	0017c713          	xori	a4,a5,1
    80005718:	8b05                	andi	a4,a4,1
    8000571a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000571e:	0037f713          	andi	a4,a5,3
    80005722:	00e03733          	snez	a4,a4
    80005726:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000572a:	4007f793          	andi	a5,a5,1024
    8000572e:	c791                	beqz	a5,8000573a <sys_open+0xd2>
    80005730:	04491703          	lh	a4,68(s2)
    80005734:	4789                	li	a5,2
    80005736:	08f70f63          	beq	a4,a5,800057d4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000573a:	854a                	mv	a0,s2
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	082080e7          	jalr	130(ra) # 800037be <iunlock>
  end_op();
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	a0a080e7          	jalr	-1526(ra) # 8000414e <end_op>

  return fd;
}
    8000574c:	8526                	mv	a0,s1
    8000574e:	70ea                	ld	ra,184(sp)
    80005750:	744a                	ld	s0,176(sp)
    80005752:	74aa                	ld	s1,168(sp)
    80005754:	790a                	ld	s2,160(sp)
    80005756:	69ea                	ld	s3,152(sp)
    80005758:	6129                	addi	sp,sp,192
    8000575a:	8082                	ret
      end_op();
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	9f2080e7          	jalr	-1550(ra) # 8000414e <end_op>
      return -1;
    80005764:	b7e5                	j	8000574c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005766:	f5040513          	addi	a0,s0,-176
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	748080e7          	jalr	1864(ra) # 80003eb2 <namei>
    80005772:	892a                	mv	s2,a0
    80005774:	c905                	beqz	a0,800057a4 <sys_open+0x13c>
    ilock(ip);
    80005776:	ffffe097          	auipc	ra,0xffffe
    8000577a:	f86080e7          	jalr	-122(ra) # 800036fc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000577e:	04491703          	lh	a4,68(s2)
    80005782:	4785                	li	a5,1
    80005784:	f4f712e3          	bne	a4,a5,800056c8 <sys_open+0x60>
    80005788:	f4c42783          	lw	a5,-180(s0)
    8000578c:	dba1                	beqz	a5,800056dc <sys_open+0x74>
      iunlockput(ip);
    8000578e:	854a                	mv	a0,s2
    80005790:	ffffe097          	auipc	ra,0xffffe
    80005794:	1ce080e7          	jalr	462(ra) # 8000395e <iunlockput>
      end_op();
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	9b6080e7          	jalr	-1610(ra) # 8000414e <end_op>
      return -1;
    800057a0:	54fd                	li	s1,-1
    800057a2:	b76d                	j	8000574c <sys_open+0xe4>
      end_op();
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	9aa080e7          	jalr	-1622(ra) # 8000414e <end_op>
      return -1;
    800057ac:	54fd                	li	s1,-1
    800057ae:	bf79                	j	8000574c <sys_open+0xe4>
    iunlockput(ip);
    800057b0:	854a                	mv	a0,s2
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	1ac080e7          	jalr	428(ra) # 8000395e <iunlockput>
    end_op();
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	994080e7          	jalr	-1644(ra) # 8000414e <end_op>
    return -1;
    800057c2:	54fd                	li	s1,-1
    800057c4:	b761                	j	8000574c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057c6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057ca:	04691783          	lh	a5,70(s2)
    800057ce:	02f99223          	sh	a5,36(s3)
    800057d2:	bf2d                	j	8000570c <sys_open+0xa4>
    itrunc(ip);
    800057d4:	854a                	mv	a0,s2
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	034080e7          	jalr	52(ra) # 8000380a <itrunc>
    800057de:	bfb1                	j	8000573a <sys_open+0xd2>
      fileclose(f);
    800057e0:	854e                	mv	a0,s3
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	db8080e7          	jalr	-584(ra) # 8000459a <fileclose>
    iunlockput(ip);
    800057ea:	854a                	mv	a0,s2
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	172080e7          	jalr	370(ra) # 8000395e <iunlockput>
    end_op();
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	95a080e7          	jalr	-1702(ra) # 8000414e <end_op>
    return -1;
    800057fc:	54fd                	li	s1,-1
    800057fe:	b7b9                	j	8000574c <sys_open+0xe4>

0000000080005800 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005800:	7175                	addi	sp,sp,-144
    80005802:	e506                	sd	ra,136(sp)
    80005804:	e122                	sd	s0,128(sp)
    80005806:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	8c6080e7          	jalr	-1850(ra) # 800040ce <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005810:	08000613          	li	a2,128
    80005814:	f7040593          	addi	a1,s0,-144
    80005818:	4501                	li	a0,0
    8000581a:	ffffd097          	auipc	ra,0xffffd
    8000581e:	3b4080e7          	jalr	948(ra) # 80002bce <argstr>
    80005822:	02054963          	bltz	a0,80005854 <sys_mkdir+0x54>
    80005826:	4681                	li	a3,0
    80005828:	4601                	li	a2,0
    8000582a:	4585                	li	a1,1
    8000582c:	f7040513          	addi	a0,s0,-144
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	7fe080e7          	jalr	2046(ra) # 8000502e <create>
    80005838:	cd11                	beqz	a0,80005854 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	124080e7          	jalr	292(ra) # 8000395e <iunlockput>
  end_op();
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	90c080e7          	jalr	-1780(ra) # 8000414e <end_op>
  return 0;
    8000584a:	4501                	li	a0,0
}
    8000584c:	60aa                	ld	ra,136(sp)
    8000584e:	640a                	ld	s0,128(sp)
    80005850:	6149                	addi	sp,sp,144
    80005852:	8082                	ret
    end_op();
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	8fa080e7          	jalr	-1798(ra) # 8000414e <end_op>
    return -1;
    8000585c:	557d                	li	a0,-1
    8000585e:	b7fd                	j	8000584c <sys_mkdir+0x4c>

0000000080005860 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005860:	7135                	addi	sp,sp,-160
    80005862:	ed06                	sd	ra,152(sp)
    80005864:	e922                	sd	s0,144(sp)
    80005866:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	866080e7          	jalr	-1946(ra) # 800040ce <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005870:	08000613          	li	a2,128
    80005874:	f7040593          	addi	a1,s0,-144
    80005878:	4501                	li	a0,0
    8000587a:	ffffd097          	auipc	ra,0xffffd
    8000587e:	354080e7          	jalr	852(ra) # 80002bce <argstr>
    80005882:	04054a63          	bltz	a0,800058d6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005886:	f6c40593          	addi	a1,s0,-148
    8000588a:	4505                	li	a0,1
    8000588c:	ffffd097          	auipc	ra,0xffffd
    80005890:	2fe080e7          	jalr	766(ra) # 80002b8a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005894:	04054163          	bltz	a0,800058d6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005898:	f6840593          	addi	a1,s0,-152
    8000589c:	4509                	li	a0,2
    8000589e:	ffffd097          	auipc	ra,0xffffd
    800058a2:	2ec080e7          	jalr	748(ra) # 80002b8a <argint>
     argint(1, &major) < 0 ||
    800058a6:	02054863          	bltz	a0,800058d6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058aa:	f6841683          	lh	a3,-152(s0)
    800058ae:	f6c41603          	lh	a2,-148(s0)
    800058b2:	458d                	li	a1,3
    800058b4:	f7040513          	addi	a0,s0,-144
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	776080e7          	jalr	1910(ra) # 8000502e <create>
     argint(2, &minor) < 0 ||
    800058c0:	c919                	beqz	a0,800058d6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	09c080e7          	jalr	156(ra) # 8000395e <iunlockput>
  end_op();
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	884080e7          	jalr	-1916(ra) # 8000414e <end_op>
  return 0;
    800058d2:	4501                	li	a0,0
    800058d4:	a031                	j	800058e0 <sys_mknod+0x80>
    end_op();
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	878080e7          	jalr	-1928(ra) # 8000414e <end_op>
    return -1;
    800058de:	557d                	li	a0,-1
}
    800058e0:	60ea                	ld	ra,152(sp)
    800058e2:	644a                	ld	s0,144(sp)
    800058e4:	610d                	addi	sp,sp,160
    800058e6:	8082                	ret

00000000800058e8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058e8:	7135                	addi	sp,sp,-160
    800058ea:	ed06                	sd	ra,152(sp)
    800058ec:	e922                	sd	s0,144(sp)
    800058ee:	e526                	sd	s1,136(sp)
    800058f0:	e14a                	sd	s2,128(sp)
    800058f2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058f4:	ffffc097          	auipc	ra,0xffffc
    800058f8:	0bc080e7          	jalr	188(ra) # 800019b0 <myproc>
    800058fc:	892a                	mv	s2,a0
  
  begin_op();
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	7d0080e7          	jalr	2000(ra) # 800040ce <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005906:	08000613          	li	a2,128
    8000590a:	f6040593          	addi	a1,s0,-160
    8000590e:	4501                	li	a0,0
    80005910:	ffffd097          	auipc	ra,0xffffd
    80005914:	2be080e7          	jalr	702(ra) # 80002bce <argstr>
    80005918:	04054b63          	bltz	a0,8000596e <sys_chdir+0x86>
    8000591c:	f6040513          	addi	a0,s0,-160
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	592080e7          	jalr	1426(ra) # 80003eb2 <namei>
    80005928:	84aa                	mv	s1,a0
    8000592a:	c131                	beqz	a0,8000596e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	dd0080e7          	jalr	-560(ra) # 800036fc <ilock>
  if(ip->type != T_DIR){
    80005934:	04449703          	lh	a4,68(s1)
    80005938:	4785                	li	a5,1
    8000593a:	04f71063          	bne	a4,a5,8000597a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000593e:	8526                	mv	a0,s1
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	e7e080e7          	jalr	-386(ra) # 800037be <iunlock>
  iput(p->cwd);
    80005948:	15093503          	ld	a0,336(s2)
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	f6a080e7          	jalr	-150(ra) # 800038b6 <iput>
  end_op();
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	7fa080e7          	jalr	2042(ra) # 8000414e <end_op>
  p->cwd = ip;
    8000595c:	14993823          	sd	s1,336(s2)
  return 0;
    80005960:	4501                	li	a0,0
}
    80005962:	60ea                	ld	ra,152(sp)
    80005964:	644a                	ld	s0,144(sp)
    80005966:	64aa                	ld	s1,136(sp)
    80005968:	690a                	ld	s2,128(sp)
    8000596a:	610d                	addi	sp,sp,160
    8000596c:	8082                	ret
    end_op();
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	7e0080e7          	jalr	2016(ra) # 8000414e <end_op>
    return -1;
    80005976:	557d                	li	a0,-1
    80005978:	b7ed                	j	80005962 <sys_chdir+0x7a>
    iunlockput(ip);
    8000597a:	8526                	mv	a0,s1
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	fe2080e7          	jalr	-30(ra) # 8000395e <iunlockput>
    end_op();
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	7ca080e7          	jalr	1994(ra) # 8000414e <end_op>
    return -1;
    8000598c:	557d                	li	a0,-1
    8000598e:	bfd1                	j	80005962 <sys_chdir+0x7a>

0000000080005990 <sys_exec>:

uint64
sys_exec(void)
{
    80005990:	7145                	addi	sp,sp,-464
    80005992:	e786                	sd	ra,456(sp)
    80005994:	e3a2                	sd	s0,448(sp)
    80005996:	ff26                	sd	s1,440(sp)
    80005998:	fb4a                	sd	s2,432(sp)
    8000599a:	f74e                	sd	s3,424(sp)
    8000599c:	f352                	sd	s4,416(sp)
    8000599e:	ef56                	sd	s5,408(sp)
    800059a0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059a2:	08000613          	li	a2,128
    800059a6:	f4040593          	addi	a1,s0,-192
    800059aa:	4501                	li	a0,0
    800059ac:	ffffd097          	auipc	ra,0xffffd
    800059b0:	222080e7          	jalr	546(ra) # 80002bce <argstr>
    return -1;
    800059b4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059b6:	0c054a63          	bltz	a0,80005a8a <sys_exec+0xfa>
    800059ba:	e3840593          	addi	a1,s0,-456
    800059be:	4505                	li	a0,1
    800059c0:	ffffd097          	auipc	ra,0xffffd
    800059c4:	1ec080e7          	jalr	492(ra) # 80002bac <argaddr>
    800059c8:	0c054163          	bltz	a0,80005a8a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800059cc:	10000613          	li	a2,256
    800059d0:	4581                	li	a1,0
    800059d2:	e4040513          	addi	a0,s0,-448
    800059d6:	ffffb097          	auipc	ra,0xffffb
    800059da:	30a080e7          	jalr	778(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059de:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059e2:	89a6                	mv	s3,s1
    800059e4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059e6:	02000a13          	li	s4,32
    800059ea:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059ee:	00391513          	slli	a0,s2,0x3
    800059f2:	e3040593          	addi	a1,s0,-464
    800059f6:	e3843783          	ld	a5,-456(s0)
    800059fa:	953e                	add	a0,a0,a5
    800059fc:	ffffd097          	auipc	ra,0xffffd
    80005a00:	0f4080e7          	jalr	244(ra) # 80002af0 <fetchaddr>
    80005a04:	02054a63          	bltz	a0,80005a38 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a08:	e3043783          	ld	a5,-464(s0)
    80005a0c:	c3b9                	beqz	a5,80005a52 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a0e:	ffffb097          	auipc	ra,0xffffb
    80005a12:	0e6080e7          	jalr	230(ra) # 80000af4 <kalloc>
    80005a16:	85aa                	mv	a1,a0
    80005a18:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a1c:	cd11                	beqz	a0,80005a38 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a1e:	6605                	lui	a2,0x1
    80005a20:	e3043503          	ld	a0,-464(s0)
    80005a24:	ffffd097          	auipc	ra,0xffffd
    80005a28:	11e080e7          	jalr	286(ra) # 80002b42 <fetchstr>
    80005a2c:	00054663          	bltz	a0,80005a38 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a30:	0905                	addi	s2,s2,1
    80005a32:	09a1                	addi	s3,s3,8
    80005a34:	fb491be3          	bne	s2,s4,800059ea <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a38:	10048913          	addi	s2,s1,256
    80005a3c:	6088                	ld	a0,0(s1)
    80005a3e:	c529                	beqz	a0,80005a88 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a40:	ffffb097          	auipc	ra,0xffffb
    80005a44:	fb8080e7          	jalr	-72(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a48:	04a1                	addi	s1,s1,8
    80005a4a:	ff2499e3          	bne	s1,s2,80005a3c <sys_exec+0xac>
  return -1;
    80005a4e:	597d                	li	s2,-1
    80005a50:	a82d                	j	80005a8a <sys_exec+0xfa>
      argv[i] = 0;
    80005a52:	0a8e                	slli	s5,s5,0x3
    80005a54:	fc040793          	addi	a5,s0,-64
    80005a58:	9abe                	add	s5,s5,a5
    80005a5a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a5e:	e4040593          	addi	a1,s0,-448
    80005a62:	f4040513          	addi	a0,s0,-192
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	194080e7          	jalr	404(ra) # 80004bfa <exec>
    80005a6e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a70:	10048993          	addi	s3,s1,256
    80005a74:	6088                	ld	a0,0(s1)
    80005a76:	c911                	beqz	a0,80005a8a <sys_exec+0xfa>
    kfree(argv[i]);
    80005a78:	ffffb097          	auipc	ra,0xffffb
    80005a7c:	f80080e7          	jalr	-128(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a80:	04a1                	addi	s1,s1,8
    80005a82:	ff3499e3          	bne	s1,s3,80005a74 <sys_exec+0xe4>
    80005a86:	a011                	j	80005a8a <sys_exec+0xfa>
  return -1;
    80005a88:	597d                	li	s2,-1
}
    80005a8a:	854a                	mv	a0,s2
    80005a8c:	60be                	ld	ra,456(sp)
    80005a8e:	641e                	ld	s0,448(sp)
    80005a90:	74fa                	ld	s1,440(sp)
    80005a92:	795a                	ld	s2,432(sp)
    80005a94:	79ba                	ld	s3,424(sp)
    80005a96:	7a1a                	ld	s4,416(sp)
    80005a98:	6afa                	ld	s5,408(sp)
    80005a9a:	6179                	addi	sp,sp,464
    80005a9c:	8082                	ret

0000000080005a9e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a9e:	7139                	addi	sp,sp,-64
    80005aa0:	fc06                	sd	ra,56(sp)
    80005aa2:	f822                	sd	s0,48(sp)
    80005aa4:	f426                	sd	s1,40(sp)
    80005aa6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005aa8:	ffffc097          	auipc	ra,0xffffc
    80005aac:	f08080e7          	jalr	-248(ra) # 800019b0 <myproc>
    80005ab0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ab2:	fd840593          	addi	a1,s0,-40
    80005ab6:	4501                	li	a0,0
    80005ab8:	ffffd097          	auipc	ra,0xffffd
    80005abc:	0f4080e7          	jalr	244(ra) # 80002bac <argaddr>
    return -1;
    80005ac0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ac2:	0e054063          	bltz	a0,80005ba2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ac6:	fc840593          	addi	a1,s0,-56
    80005aca:	fd040513          	addi	a0,s0,-48
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	dfc080e7          	jalr	-516(ra) # 800048ca <pipealloc>
    return -1;
    80005ad6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ad8:	0c054563          	bltz	a0,80005ba2 <sys_pipe+0x104>
  fd0 = -1;
    80005adc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ae0:	fd043503          	ld	a0,-48(s0)
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	508080e7          	jalr	1288(ra) # 80004fec <fdalloc>
    80005aec:	fca42223          	sw	a0,-60(s0)
    80005af0:	08054c63          	bltz	a0,80005b88 <sys_pipe+0xea>
    80005af4:	fc843503          	ld	a0,-56(s0)
    80005af8:	fffff097          	auipc	ra,0xfffff
    80005afc:	4f4080e7          	jalr	1268(ra) # 80004fec <fdalloc>
    80005b00:	fca42023          	sw	a0,-64(s0)
    80005b04:	06054863          	bltz	a0,80005b74 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b08:	4691                	li	a3,4
    80005b0a:	fc440613          	addi	a2,s0,-60
    80005b0e:	fd843583          	ld	a1,-40(s0)
    80005b12:	68a8                	ld	a0,80(s1)
    80005b14:	ffffc097          	auipc	ra,0xffffc
    80005b18:	b5e080e7          	jalr	-1186(ra) # 80001672 <copyout>
    80005b1c:	02054063          	bltz	a0,80005b3c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b20:	4691                	li	a3,4
    80005b22:	fc040613          	addi	a2,s0,-64
    80005b26:	fd843583          	ld	a1,-40(s0)
    80005b2a:	0591                	addi	a1,a1,4
    80005b2c:	68a8                	ld	a0,80(s1)
    80005b2e:	ffffc097          	auipc	ra,0xffffc
    80005b32:	b44080e7          	jalr	-1212(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b36:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b38:	06055563          	bgez	a0,80005ba2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b3c:	fc442783          	lw	a5,-60(s0)
    80005b40:	07e9                	addi	a5,a5,26
    80005b42:	078e                	slli	a5,a5,0x3
    80005b44:	97a6                	add	a5,a5,s1
    80005b46:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b4a:	fc042503          	lw	a0,-64(s0)
    80005b4e:	0569                	addi	a0,a0,26
    80005b50:	050e                	slli	a0,a0,0x3
    80005b52:	9526                	add	a0,a0,s1
    80005b54:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b58:	fd043503          	ld	a0,-48(s0)
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	a3e080e7          	jalr	-1474(ra) # 8000459a <fileclose>
    fileclose(wf);
    80005b64:	fc843503          	ld	a0,-56(s0)
    80005b68:	fffff097          	auipc	ra,0xfffff
    80005b6c:	a32080e7          	jalr	-1486(ra) # 8000459a <fileclose>
    return -1;
    80005b70:	57fd                	li	a5,-1
    80005b72:	a805                	j	80005ba2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b74:	fc442783          	lw	a5,-60(s0)
    80005b78:	0007c863          	bltz	a5,80005b88 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b7c:	01a78513          	addi	a0,a5,26
    80005b80:	050e                	slli	a0,a0,0x3
    80005b82:	9526                	add	a0,a0,s1
    80005b84:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b88:	fd043503          	ld	a0,-48(s0)
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	a0e080e7          	jalr	-1522(ra) # 8000459a <fileclose>
    fileclose(wf);
    80005b94:	fc843503          	ld	a0,-56(s0)
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	a02080e7          	jalr	-1534(ra) # 8000459a <fileclose>
    return -1;
    80005ba0:	57fd                	li	a5,-1
}
    80005ba2:	853e                	mv	a0,a5
    80005ba4:	70e2                	ld	ra,56(sp)
    80005ba6:	7442                	ld	s0,48(sp)
    80005ba8:	74a2                	ld	s1,40(sp)
    80005baa:	6121                	addi	sp,sp,64
    80005bac:	8082                	ret
	...

0000000080005bb0 <kernelvec>:
    80005bb0:	7111                	addi	sp,sp,-256
    80005bb2:	e006                	sd	ra,0(sp)
    80005bb4:	e40a                	sd	sp,8(sp)
    80005bb6:	e80e                	sd	gp,16(sp)
    80005bb8:	ec12                	sd	tp,24(sp)
    80005bba:	f016                	sd	t0,32(sp)
    80005bbc:	f41a                	sd	t1,40(sp)
    80005bbe:	f81e                	sd	t2,48(sp)
    80005bc0:	fc22                	sd	s0,56(sp)
    80005bc2:	e0a6                	sd	s1,64(sp)
    80005bc4:	e4aa                	sd	a0,72(sp)
    80005bc6:	e8ae                	sd	a1,80(sp)
    80005bc8:	ecb2                	sd	a2,88(sp)
    80005bca:	f0b6                	sd	a3,96(sp)
    80005bcc:	f4ba                	sd	a4,104(sp)
    80005bce:	f8be                	sd	a5,112(sp)
    80005bd0:	fcc2                	sd	a6,120(sp)
    80005bd2:	e146                	sd	a7,128(sp)
    80005bd4:	e54a                	sd	s2,136(sp)
    80005bd6:	e94e                	sd	s3,144(sp)
    80005bd8:	ed52                	sd	s4,152(sp)
    80005bda:	f156                	sd	s5,160(sp)
    80005bdc:	f55a                	sd	s6,168(sp)
    80005bde:	f95e                	sd	s7,176(sp)
    80005be0:	fd62                	sd	s8,184(sp)
    80005be2:	e1e6                	sd	s9,192(sp)
    80005be4:	e5ea                	sd	s10,200(sp)
    80005be6:	e9ee                	sd	s11,208(sp)
    80005be8:	edf2                	sd	t3,216(sp)
    80005bea:	f1f6                	sd	t4,224(sp)
    80005bec:	f5fa                	sd	t5,232(sp)
    80005bee:	f9fe                	sd	t6,240(sp)
    80005bf0:	dcdfc0ef          	jal	ra,800029bc <kerneltrap>
    80005bf4:	6082                	ld	ra,0(sp)
    80005bf6:	6122                	ld	sp,8(sp)
    80005bf8:	61c2                	ld	gp,16(sp)
    80005bfa:	7282                	ld	t0,32(sp)
    80005bfc:	7322                	ld	t1,40(sp)
    80005bfe:	73c2                	ld	t2,48(sp)
    80005c00:	7462                	ld	s0,56(sp)
    80005c02:	6486                	ld	s1,64(sp)
    80005c04:	6526                	ld	a0,72(sp)
    80005c06:	65c6                	ld	a1,80(sp)
    80005c08:	6666                	ld	a2,88(sp)
    80005c0a:	7686                	ld	a3,96(sp)
    80005c0c:	7726                	ld	a4,104(sp)
    80005c0e:	77c6                	ld	a5,112(sp)
    80005c10:	7866                	ld	a6,120(sp)
    80005c12:	688a                	ld	a7,128(sp)
    80005c14:	692a                	ld	s2,136(sp)
    80005c16:	69ca                	ld	s3,144(sp)
    80005c18:	6a6a                	ld	s4,152(sp)
    80005c1a:	7a8a                	ld	s5,160(sp)
    80005c1c:	7b2a                	ld	s6,168(sp)
    80005c1e:	7bca                	ld	s7,176(sp)
    80005c20:	7c6a                	ld	s8,184(sp)
    80005c22:	6c8e                	ld	s9,192(sp)
    80005c24:	6d2e                	ld	s10,200(sp)
    80005c26:	6dce                	ld	s11,208(sp)
    80005c28:	6e6e                	ld	t3,216(sp)
    80005c2a:	7e8e                	ld	t4,224(sp)
    80005c2c:	7f2e                	ld	t5,232(sp)
    80005c2e:	7fce                	ld	t6,240(sp)
    80005c30:	6111                	addi	sp,sp,256
    80005c32:	10200073          	sret
    80005c36:	00000013          	nop
    80005c3a:	00000013          	nop
    80005c3e:	0001                	nop

0000000080005c40 <timervec>:
    80005c40:	34051573          	csrrw	a0,mscratch,a0
    80005c44:	e10c                	sd	a1,0(a0)
    80005c46:	e510                	sd	a2,8(a0)
    80005c48:	e914                	sd	a3,16(a0)
    80005c4a:	6d0c                	ld	a1,24(a0)
    80005c4c:	7110                	ld	a2,32(a0)
    80005c4e:	6194                	ld	a3,0(a1)
    80005c50:	96b2                	add	a3,a3,a2
    80005c52:	e194                	sd	a3,0(a1)
    80005c54:	4589                	li	a1,2
    80005c56:	14459073          	csrw	sip,a1
    80005c5a:	6914                	ld	a3,16(a0)
    80005c5c:	6510                	ld	a2,8(a0)
    80005c5e:	610c                	ld	a1,0(a0)
    80005c60:	34051573          	csrrw	a0,mscratch,a0
    80005c64:	30200073          	mret
	...

0000000080005c6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c6a:	1141                	addi	sp,sp,-16
    80005c6c:	e422                	sd	s0,8(sp)
    80005c6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c70:	0c0007b7          	lui	a5,0xc000
    80005c74:	4705                	li	a4,1
    80005c76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c78:	c3d8                	sw	a4,4(a5)
}
    80005c7a:	6422                	ld	s0,8(sp)
    80005c7c:	0141                	addi	sp,sp,16
    80005c7e:	8082                	ret

0000000080005c80 <plicinithart>:

void
plicinithart(void)
{
    80005c80:	1141                	addi	sp,sp,-16
    80005c82:	e406                	sd	ra,8(sp)
    80005c84:	e022                	sd	s0,0(sp)
    80005c86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c88:	ffffc097          	auipc	ra,0xffffc
    80005c8c:	cfc080e7          	jalr	-772(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c90:	0085171b          	slliw	a4,a0,0x8
    80005c94:	0c0027b7          	lui	a5,0xc002
    80005c98:	97ba                	add	a5,a5,a4
    80005c9a:	40200713          	li	a4,1026
    80005c9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ca2:	00d5151b          	slliw	a0,a0,0xd
    80005ca6:	0c2017b7          	lui	a5,0xc201
    80005caa:	953e                	add	a0,a0,a5
    80005cac:	00052023          	sw	zero,0(a0)
}
    80005cb0:	60a2                	ld	ra,8(sp)
    80005cb2:	6402                	ld	s0,0(sp)
    80005cb4:	0141                	addi	sp,sp,16
    80005cb6:	8082                	ret

0000000080005cb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cb8:	1141                	addi	sp,sp,-16
    80005cba:	e406                	sd	ra,8(sp)
    80005cbc:	e022                	sd	s0,0(sp)
    80005cbe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cc0:	ffffc097          	auipc	ra,0xffffc
    80005cc4:	cc4080e7          	jalr	-828(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cc8:	00d5179b          	slliw	a5,a0,0xd
    80005ccc:	0c201537          	lui	a0,0xc201
    80005cd0:	953e                	add	a0,a0,a5
  return irq;
}
    80005cd2:	4148                	lw	a0,4(a0)
    80005cd4:	60a2                	ld	ra,8(sp)
    80005cd6:	6402                	ld	s0,0(sp)
    80005cd8:	0141                	addi	sp,sp,16
    80005cda:	8082                	ret

0000000080005cdc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cdc:	1101                	addi	sp,sp,-32
    80005cde:	ec06                	sd	ra,24(sp)
    80005ce0:	e822                	sd	s0,16(sp)
    80005ce2:	e426                	sd	s1,8(sp)
    80005ce4:	1000                	addi	s0,sp,32
    80005ce6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	c9c080e7          	jalr	-868(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cf0:	00d5151b          	slliw	a0,a0,0xd
    80005cf4:	0c2017b7          	lui	a5,0xc201
    80005cf8:	97aa                	add	a5,a5,a0
    80005cfa:	c3c4                	sw	s1,4(a5)
}
    80005cfc:	60e2                	ld	ra,24(sp)
    80005cfe:	6442                	ld	s0,16(sp)
    80005d00:	64a2                	ld	s1,8(sp)
    80005d02:	6105                	addi	sp,sp,32
    80005d04:	8082                	ret

0000000080005d06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d06:	1141                	addi	sp,sp,-16
    80005d08:	e406                	sd	ra,8(sp)
    80005d0a:	e022                	sd	s0,0(sp)
    80005d0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d0e:	479d                	li	a5,7
    80005d10:	06a7c963          	blt	a5,a0,80005d82 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d14:	0001d797          	auipc	a5,0x1d
    80005d18:	2ec78793          	addi	a5,a5,748 # 80023000 <disk>
    80005d1c:	00a78733          	add	a4,a5,a0
    80005d20:	6789                	lui	a5,0x2
    80005d22:	97ba                	add	a5,a5,a4
    80005d24:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d28:	e7ad                	bnez	a5,80005d92 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d2a:	00451793          	slli	a5,a0,0x4
    80005d2e:	0001f717          	auipc	a4,0x1f
    80005d32:	2d270713          	addi	a4,a4,722 # 80025000 <disk+0x2000>
    80005d36:	6314                	ld	a3,0(a4)
    80005d38:	96be                	add	a3,a3,a5
    80005d3a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d3e:	6314                	ld	a3,0(a4)
    80005d40:	96be                	add	a3,a3,a5
    80005d42:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d46:	6314                	ld	a3,0(a4)
    80005d48:	96be                	add	a3,a3,a5
    80005d4a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d4e:	6318                	ld	a4,0(a4)
    80005d50:	97ba                	add	a5,a5,a4
    80005d52:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d56:	0001d797          	auipc	a5,0x1d
    80005d5a:	2aa78793          	addi	a5,a5,682 # 80023000 <disk>
    80005d5e:	97aa                	add	a5,a5,a0
    80005d60:	6509                	lui	a0,0x2
    80005d62:	953e                	add	a0,a0,a5
    80005d64:	4785                	li	a5,1
    80005d66:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d6a:	0001f517          	auipc	a0,0x1f
    80005d6e:	2ae50513          	addi	a0,a0,686 # 80025018 <disk+0x2018>
    80005d72:	ffffc097          	auipc	ra,0xffffc
    80005d76:	53a080e7          	jalr	1338(ra) # 800022ac <wakeup>
}
    80005d7a:	60a2                	ld	ra,8(sp)
    80005d7c:	6402                	ld	s0,0(sp)
    80005d7e:	0141                	addi	sp,sp,16
    80005d80:	8082                	ret
    panic("free_desc 1");
    80005d82:	00003517          	auipc	a0,0x3
    80005d86:	9e650513          	addi	a0,a0,-1562 # 80008768 <syscalls+0x320>
    80005d8a:	ffffa097          	auipc	ra,0xffffa
    80005d8e:	7b4080e7          	jalr	1972(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005d92:	00003517          	auipc	a0,0x3
    80005d96:	9e650513          	addi	a0,a0,-1562 # 80008778 <syscalls+0x330>
    80005d9a:	ffffa097          	auipc	ra,0xffffa
    80005d9e:	7a4080e7          	jalr	1956(ra) # 8000053e <panic>

0000000080005da2 <virtio_disk_init>:
{
    80005da2:	1101                	addi	sp,sp,-32
    80005da4:	ec06                	sd	ra,24(sp)
    80005da6:	e822                	sd	s0,16(sp)
    80005da8:	e426                	sd	s1,8(sp)
    80005daa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dac:	00003597          	auipc	a1,0x3
    80005db0:	9dc58593          	addi	a1,a1,-1572 # 80008788 <syscalls+0x340>
    80005db4:	0001f517          	auipc	a0,0x1f
    80005db8:	37450513          	addi	a0,a0,884 # 80025128 <disk+0x2128>
    80005dbc:	ffffb097          	auipc	ra,0xffffb
    80005dc0:	d98080e7          	jalr	-616(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dc4:	100017b7          	lui	a5,0x10001
    80005dc8:	4398                	lw	a4,0(a5)
    80005dca:	2701                	sext.w	a4,a4
    80005dcc:	747277b7          	lui	a5,0x74727
    80005dd0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005dd4:	0ef71163          	bne	a4,a5,80005eb6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dd8:	100017b7          	lui	a5,0x10001
    80005ddc:	43dc                	lw	a5,4(a5)
    80005dde:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005de0:	4705                	li	a4,1
    80005de2:	0ce79a63          	bne	a5,a4,80005eb6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005de6:	100017b7          	lui	a5,0x10001
    80005dea:	479c                	lw	a5,8(a5)
    80005dec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dee:	4709                	li	a4,2
    80005df0:	0ce79363          	bne	a5,a4,80005eb6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005df4:	100017b7          	lui	a5,0x10001
    80005df8:	47d8                	lw	a4,12(a5)
    80005dfa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dfc:	554d47b7          	lui	a5,0x554d4
    80005e00:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e04:	0af71963          	bne	a4,a5,80005eb6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e08:	100017b7          	lui	a5,0x10001
    80005e0c:	4705                	li	a4,1
    80005e0e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e10:	470d                	li	a4,3
    80005e12:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e14:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e16:	c7ffe737          	lui	a4,0xc7ffe
    80005e1a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e1e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e20:	2701                	sext.w	a4,a4
    80005e22:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e24:	472d                	li	a4,11
    80005e26:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e28:	473d                	li	a4,15
    80005e2a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e2c:	6705                	lui	a4,0x1
    80005e2e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e30:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e34:	5bdc                	lw	a5,52(a5)
    80005e36:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e38:	c7d9                	beqz	a5,80005ec6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005e3a:	471d                	li	a4,7
    80005e3c:	08f77d63          	bgeu	a4,a5,80005ed6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e40:	100014b7          	lui	s1,0x10001
    80005e44:	47a1                	li	a5,8
    80005e46:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e48:	6609                	lui	a2,0x2
    80005e4a:	4581                	li	a1,0
    80005e4c:	0001d517          	auipc	a0,0x1d
    80005e50:	1b450513          	addi	a0,a0,436 # 80023000 <disk>
    80005e54:	ffffb097          	auipc	ra,0xffffb
    80005e58:	e8c080e7          	jalr	-372(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e5c:	0001d717          	auipc	a4,0x1d
    80005e60:	1a470713          	addi	a4,a4,420 # 80023000 <disk>
    80005e64:	00c75793          	srli	a5,a4,0xc
    80005e68:	2781                	sext.w	a5,a5
    80005e6a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e6c:	0001f797          	auipc	a5,0x1f
    80005e70:	19478793          	addi	a5,a5,404 # 80025000 <disk+0x2000>
    80005e74:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e76:	0001d717          	auipc	a4,0x1d
    80005e7a:	20a70713          	addi	a4,a4,522 # 80023080 <disk+0x80>
    80005e7e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e80:	0001e717          	auipc	a4,0x1e
    80005e84:	18070713          	addi	a4,a4,384 # 80024000 <disk+0x1000>
    80005e88:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e8a:	4705                	li	a4,1
    80005e8c:	00e78c23          	sb	a4,24(a5)
    80005e90:	00e78ca3          	sb	a4,25(a5)
    80005e94:	00e78d23          	sb	a4,26(a5)
    80005e98:	00e78da3          	sb	a4,27(a5)
    80005e9c:	00e78e23          	sb	a4,28(a5)
    80005ea0:	00e78ea3          	sb	a4,29(a5)
    80005ea4:	00e78f23          	sb	a4,30(a5)
    80005ea8:	00e78fa3          	sb	a4,31(a5)
}
    80005eac:	60e2                	ld	ra,24(sp)
    80005eae:	6442                	ld	s0,16(sp)
    80005eb0:	64a2                	ld	s1,8(sp)
    80005eb2:	6105                	addi	sp,sp,32
    80005eb4:	8082                	ret
    panic("could not find virtio disk");
    80005eb6:	00003517          	auipc	a0,0x3
    80005eba:	8e250513          	addi	a0,a0,-1822 # 80008798 <syscalls+0x350>
    80005ebe:	ffffa097          	auipc	ra,0xffffa
    80005ec2:	680080e7          	jalr	1664(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005ec6:	00003517          	auipc	a0,0x3
    80005eca:	8f250513          	addi	a0,a0,-1806 # 800087b8 <syscalls+0x370>
    80005ece:	ffffa097          	auipc	ra,0xffffa
    80005ed2:	670080e7          	jalr	1648(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005ed6:	00003517          	auipc	a0,0x3
    80005eda:	90250513          	addi	a0,a0,-1790 # 800087d8 <syscalls+0x390>
    80005ede:	ffffa097          	auipc	ra,0xffffa
    80005ee2:	660080e7          	jalr	1632(ra) # 8000053e <panic>

0000000080005ee6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ee6:	7159                	addi	sp,sp,-112
    80005ee8:	f486                	sd	ra,104(sp)
    80005eea:	f0a2                	sd	s0,96(sp)
    80005eec:	eca6                	sd	s1,88(sp)
    80005eee:	e8ca                	sd	s2,80(sp)
    80005ef0:	e4ce                	sd	s3,72(sp)
    80005ef2:	e0d2                	sd	s4,64(sp)
    80005ef4:	fc56                	sd	s5,56(sp)
    80005ef6:	f85a                	sd	s6,48(sp)
    80005ef8:	f45e                	sd	s7,40(sp)
    80005efa:	f062                	sd	s8,32(sp)
    80005efc:	ec66                	sd	s9,24(sp)
    80005efe:	e86a                	sd	s10,16(sp)
    80005f00:	1880                	addi	s0,sp,112
    80005f02:	892a                	mv	s2,a0
    80005f04:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f06:	00c52c83          	lw	s9,12(a0)
    80005f0a:	001c9c9b          	slliw	s9,s9,0x1
    80005f0e:	1c82                	slli	s9,s9,0x20
    80005f10:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f14:	0001f517          	auipc	a0,0x1f
    80005f18:	21450513          	addi	a0,a0,532 # 80025128 <disk+0x2128>
    80005f1c:	ffffb097          	auipc	ra,0xffffb
    80005f20:	cc8080e7          	jalr	-824(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005f24:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f26:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f28:	0001db97          	auipc	s7,0x1d
    80005f2c:	0d8b8b93          	addi	s7,s7,216 # 80023000 <disk>
    80005f30:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f32:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f34:	8a4e                	mv	s4,s3
    80005f36:	a051                	j	80005fba <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f38:	00fb86b3          	add	a3,s7,a5
    80005f3c:	96da                	add	a3,a3,s6
    80005f3e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f42:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f44:	0207c563          	bltz	a5,80005f6e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f48:	2485                	addiw	s1,s1,1
    80005f4a:	0711                	addi	a4,a4,4
    80005f4c:	25548063          	beq	s1,s5,8000618c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005f50:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005f52:	0001f697          	auipc	a3,0x1f
    80005f56:	0c668693          	addi	a3,a3,198 # 80025018 <disk+0x2018>
    80005f5a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005f5c:	0006c583          	lbu	a1,0(a3)
    80005f60:	fde1                	bnez	a1,80005f38 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f62:	2785                	addiw	a5,a5,1
    80005f64:	0685                	addi	a3,a3,1
    80005f66:	ff879be3          	bne	a5,s8,80005f5c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f6a:	57fd                	li	a5,-1
    80005f6c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005f6e:	02905a63          	blez	s1,80005fa2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f72:	f9042503          	lw	a0,-112(s0)
    80005f76:	00000097          	auipc	ra,0x0
    80005f7a:	d90080e7          	jalr	-624(ra) # 80005d06 <free_desc>
      for(int j = 0; j < i; j++)
    80005f7e:	4785                	li	a5,1
    80005f80:	0297d163          	bge	a5,s1,80005fa2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f84:	f9442503          	lw	a0,-108(s0)
    80005f88:	00000097          	auipc	ra,0x0
    80005f8c:	d7e080e7          	jalr	-642(ra) # 80005d06 <free_desc>
      for(int j = 0; j < i; j++)
    80005f90:	4789                	li	a5,2
    80005f92:	0097d863          	bge	a5,s1,80005fa2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f96:	f9842503          	lw	a0,-104(s0)
    80005f9a:	00000097          	auipc	ra,0x0
    80005f9e:	d6c080e7          	jalr	-660(ra) # 80005d06 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fa2:	0001f597          	auipc	a1,0x1f
    80005fa6:	18658593          	addi	a1,a1,390 # 80025128 <disk+0x2128>
    80005faa:	0001f517          	auipc	a0,0x1f
    80005fae:	06e50513          	addi	a0,a0,110 # 80025018 <disk+0x2018>
    80005fb2:	ffffc097          	auipc	ra,0xffffc
    80005fb6:	16e080e7          	jalr	366(ra) # 80002120 <sleep>
  for(int i = 0; i < 3; i++){
    80005fba:	f9040713          	addi	a4,s0,-112
    80005fbe:	84ce                	mv	s1,s3
    80005fc0:	bf41                	j	80005f50 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005fc2:	20058713          	addi	a4,a1,512
    80005fc6:	00471693          	slli	a3,a4,0x4
    80005fca:	0001d717          	auipc	a4,0x1d
    80005fce:	03670713          	addi	a4,a4,54 # 80023000 <disk>
    80005fd2:	9736                	add	a4,a4,a3
    80005fd4:	4685                	li	a3,1
    80005fd6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005fda:	20058713          	addi	a4,a1,512
    80005fde:	00471693          	slli	a3,a4,0x4
    80005fe2:	0001d717          	auipc	a4,0x1d
    80005fe6:	01e70713          	addi	a4,a4,30 # 80023000 <disk>
    80005fea:	9736                	add	a4,a4,a3
    80005fec:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005ff0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005ff4:	7679                	lui	a2,0xffffe
    80005ff6:	963e                	add	a2,a2,a5
    80005ff8:	0001f697          	auipc	a3,0x1f
    80005ffc:	00868693          	addi	a3,a3,8 # 80025000 <disk+0x2000>
    80006000:	6298                	ld	a4,0(a3)
    80006002:	9732                	add	a4,a4,a2
    80006004:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006006:	6298                	ld	a4,0(a3)
    80006008:	9732                	add	a4,a4,a2
    8000600a:	4541                	li	a0,16
    8000600c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000600e:	6298                	ld	a4,0(a3)
    80006010:	9732                	add	a4,a4,a2
    80006012:	4505                	li	a0,1
    80006014:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006018:	f9442703          	lw	a4,-108(s0)
    8000601c:	6288                	ld	a0,0(a3)
    8000601e:	962a                	add	a2,a2,a0
    80006020:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006024:	0712                	slli	a4,a4,0x4
    80006026:	6290                	ld	a2,0(a3)
    80006028:	963a                	add	a2,a2,a4
    8000602a:	05890513          	addi	a0,s2,88
    8000602e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006030:	6294                	ld	a3,0(a3)
    80006032:	96ba                	add	a3,a3,a4
    80006034:	40000613          	li	a2,1024
    80006038:	c690                	sw	a2,8(a3)
  if(write)
    8000603a:	140d0063          	beqz	s10,8000617a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000603e:	0001f697          	auipc	a3,0x1f
    80006042:	fc26b683          	ld	a3,-62(a3) # 80025000 <disk+0x2000>
    80006046:	96ba                	add	a3,a3,a4
    80006048:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000604c:	0001d817          	auipc	a6,0x1d
    80006050:	fb480813          	addi	a6,a6,-76 # 80023000 <disk>
    80006054:	0001f517          	auipc	a0,0x1f
    80006058:	fac50513          	addi	a0,a0,-84 # 80025000 <disk+0x2000>
    8000605c:	6114                	ld	a3,0(a0)
    8000605e:	96ba                	add	a3,a3,a4
    80006060:	00c6d603          	lhu	a2,12(a3)
    80006064:	00166613          	ori	a2,a2,1
    80006068:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000606c:	f9842683          	lw	a3,-104(s0)
    80006070:	6110                	ld	a2,0(a0)
    80006072:	9732                	add	a4,a4,a2
    80006074:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006078:	20058613          	addi	a2,a1,512
    8000607c:	0612                	slli	a2,a2,0x4
    8000607e:	9642                	add	a2,a2,a6
    80006080:	577d                	li	a4,-1
    80006082:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006086:	00469713          	slli	a4,a3,0x4
    8000608a:	6114                	ld	a3,0(a0)
    8000608c:	96ba                	add	a3,a3,a4
    8000608e:	03078793          	addi	a5,a5,48
    80006092:	97c2                	add	a5,a5,a6
    80006094:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006096:	611c                	ld	a5,0(a0)
    80006098:	97ba                	add	a5,a5,a4
    8000609a:	4685                	li	a3,1
    8000609c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000609e:	611c                	ld	a5,0(a0)
    800060a0:	97ba                	add	a5,a5,a4
    800060a2:	4809                	li	a6,2
    800060a4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800060a8:	611c                	ld	a5,0(a0)
    800060aa:	973e                	add	a4,a4,a5
    800060ac:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060b0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800060b4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060b8:	6518                	ld	a4,8(a0)
    800060ba:	00275783          	lhu	a5,2(a4)
    800060be:	8b9d                	andi	a5,a5,7
    800060c0:	0786                	slli	a5,a5,0x1
    800060c2:	97ba                	add	a5,a5,a4
    800060c4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800060c8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060cc:	6518                	ld	a4,8(a0)
    800060ce:	00275783          	lhu	a5,2(a4)
    800060d2:	2785                	addiw	a5,a5,1
    800060d4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060d8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060dc:	100017b7          	lui	a5,0x10001
    800060e0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060e4:	00492703          	lw	a4,4(s2)
    800060e8:	4785                	li	a5,1
    800060ea:	02f71163          	bne	a4,a5,8000610c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800060ee:	0001f997          	auipc	s3,0x1f
    800060f2:	03a98993          	addi	s3,s3,58 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800060f6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800060f8:	85ce                	mv	a1,s3
    800060fa:	854a                	mv	a0,s2
    800060fc:	ffffc097          	auipc	ra,0xffffc
    80006100:	024080e7          	jalr	36(ra) # 80002120 <sleep>
  while(b->disk == 1) {
    80006104:	00492783          	lw	a5,4(s2)
    80006108:	fe9788e3          	beq	a5,s1,800060f8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000610c:	f9042903          	lw	s2,-112(s0)
    80006110:	20090793          	addi	a5,s2,512
    80006114:	00479713          	slli	a4,a5,0x4
    80006118:	0001d797          	auipc	a5,0x1d
    8000611c:	ee878793          	addi	a5,a5,-280 # 80023000 <disk>
    80006120:	97ba                	add	a5,a5,a4
    80006122:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006126:	0001f997          	auipc	s3,0x1f
    8000612a:	eda98993          	addi	s3,s3,-294 # 80025000 <disk+0x2000>
    8000612e:	00491713          	slli	a4,s2,0x4
    80006132:	0009b783          	ld	a5,0(s3)
    80006136:	97ba                	add	a5,a5,a4
    80006138:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000613c:	854a                	mv	a0,s2
    8000613e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006142:	00000097          	auipc	ra,0x0
    80006146:	bc4080e7          	jalr	-1084(ra) # 80005d06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000614a:	8885                	andi	s1,s1,1
    8000614c:	f0ed                	bnez	s1,8000612e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000614e:	0001f517          	auipc	a0,0x1f
    80006152:	fda50513          	addi	a0,a0,-38 # 80025128 <disk+0x2128>
    80006156:	ffffb097          	auipc	ra,0xffffb
    8000615a:	b42080e7          	jalr	-1214(ra) # 80000c98 <release>
}
    8000615e:	70a6                	ld	ra,104(sp)
    80006160:	7406                	ld	s0,96(sp)
    80006162:	64e6                	ld	s1,88(sp)
    80006164:	6946                	ld	s2,80(sp)
    80006166:	69a6                	ld	s3,72(sp)
    80006168:	6a06                	ld	s4,64(sp)
    8000616a:	7ae2                	ld	s5,56(sp)
    8000616c:	7b42                	ld	s6,48(sp)
    8000616e:	7ba2                	ld	s7,40(sp)
    80006170:	7c02                	ld	s8,32(sp)
    80006172:	6ce2                	ld	s9,24(sp)
    80006174:	6d42                	ld	s10,16(sp)
    80006176:	6165                	addi	sp,sp,112
    80006178:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000617a:	0001f697          	auipc	a3,0x1f
    8000617e:	e866b683          	ld	a3,-378(a3) # 80025000 <disk+0x2000>
    80006182:	96ba                	add	a3,a3,a4
    80006184:	4609                	li	a2,2
    80006186:	00c69623          	sh	a2,12(a3)
    8000618a:	b5c9                	j	8000604c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000618c:	f9042583          	lw	a1,-112(s0)
    80006190:	20058793          	addi	a5,a1,512
    80006194:	0792                	slli	a5,a5,0x4
    80006196:	0001d517          	auipc	a0,0x1d
    8000619a:	f1250513          	addi	a0,a0,-238 # 800230a8 <disk+0xa8>
    8000619e:	953e                	add	a0,a0,a5
  if(write)
    800061a0:	e20d11e3          	bnez	s10,80005fc2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800061a4:	20058713          	addi	a4,a1,512
    800061a8:	00471693          	slli	a3,a4,0x4
    800061ac:	0001d717          	auipc	a4,0x1d
    800061b0:	e5470713          	addi	a4,a4,-428 # 80023000 <disk>
    800061b4:	9736                	add	a4,a4,a3
    800061b6:	0a072423          	sw	zero,168(a4)
    800061ba:	b505                	j	80005fda <virtio_disk_rw+0xf4>

00000000800061bc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061bc:	1101                	addi	sp,sp,-32
    800061be:	ec06                	sd	ra,24(sp)
    800061c0:	e822                	sd	s0,16(sp)
    800061c2:	e426                	sd	s1,8(sp)
    800061c4:	e04a                	sd	s2,0(sp)
    800061c6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061c8:	0001f517          	auipc	a0,0x1f
    800061cc:	f6050513          	addi	a0,a0,-160 # 80025128 <disk+0x2128>
    800061d0:	ffffb097          	auipc	ra,0xffffb
    800061d4:	a14080e7          	jalr	-1516(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061d8:	10001737          	lui	a4,0x10001
    800061dc:	533c                	lw	a5,96(a4)
    800061de:	8b8d                	andi	a5,a5,3
    800061e0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061e2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061e6:	0001f797          	auipc	a5,0x1f
    800061ea:	e1a78793          	addi	a5,a5,-486 # 80025000 <disk+0x2000>
    800061ee:	6b94                	ld	a3,16(a5)
    800061f0:	0207d703          	lhu	a4,32(a5)
    800061f4:	0026d783          	lhu	a5,2(a3)
    800061f8:	06f70163          	beq	a4,a5,8000625a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061fc:	0001d917          	auipc	s2,0x1d
    80006200:	e0490913          	addi	s2,s2,-508 # 80023000 <disk>
    80006204:	0001f497          	auipc	s1,0x1f
    80006208:	dfc48493          	addi	s1,s1,-516 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000620c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006210:	6898                	ld	a4,16(s1)
    80006212:	0204d783          	lhu	a5,32(s1)
    80006216:	8b9d                	andi	a5,a5,7
    80006218:	078e                	slli	a5,a5,0x3
    8000621a:	97ba                	add	a5,a5,a4
    8000621c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000621e:	20078713          	addi	a4,a5,512
    80006222:	0712                	slli	a4,a4,0x4
    80006224:	974a                	add	a4,a4,s2
    80006226:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000622a:	e731                	bnez	a4,80006276 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000622c:	20078793          	addi	a5,a5,512
    80006230:	0792                	slli	a5,a5,0x4
    80006232:	97ca                	add	a5,a5,s2
    80006234:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006236:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000623a:	ffffc097          	auipc	ra,0xffffc
    8000623e:	072080e7          	jalr	114(ra) # 800022ac <wakeup>

    disk.used_idx += 1;
    80006242:	0204d783          	lhu	a5,32(s1)
    80006246:	2785                	addiw	a5,a5,1
    80006248:	17c2                	slli	a5,a5,0x30
    8000624a:	93c1                	srli	a5,a5,0x30
    8000624c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006250:	6898                	ld	a4,16(s1)
    80006252:	00275703          	lhu	a4,2(a4)
    80006256:	faf71be3          	bne	a4,a5,8000620c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000625a:	0001f517          	auipc	a0,0x1f
    8000625e:	ece50513          	addi	a0,a0,-306 # 80025128 <disk+0x2128>
    80006262:	ffffb097          	auipc	ra,0xffffb
    80006266:	a36080e7          	jalr	-1482(ra) # 80000c98 <release>
}
    8000626a:	60e2                	ld	ra,24(sp)
    8000626c:	6442                	ld	s0,16(sp)
    8000626e:	64a2                	ld	s1,8(sp)
    80006270:	6902                	ld	s2,0(sp)
    80006272:	6105                	addi	sp,sp,32
    80006274:	8082                	ret
      panic("virtio_disk_intr status");
    80006276:	00002517          	auipc	a0,0x2
    8000627a:	58250513          	addi	a0,a0,1410 # 800087f8 <syscalls+0x3b0>
    8000627e:	ffffa097          	auipc	ra,0xffffa
    80006282:	2c0080e7          	jalr	704(ra) # 8000053e <panic>
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
