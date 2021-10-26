
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9e013103          	ld	sp,-1568(sp) # 800089e0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	ddc78793          	addi	a5,a5,-548 # 80005e40 <timervec>
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
    80000130:	384080e7          	jalr	900(ra) # 800024b0 <either_copyin>
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
    800001d8:	ec8080e7          	jalr	-312(ra) # 8000209c <sleep>
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
    80000214:	24a080e7          	jalr	586(ra) # 8000245a <either_copyout>
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
    800002f6:	214080e7          	jalr	532(ra) # 80002506 <procdump>
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
    8000044a:	de2080e7          	jalr	-542(ra) # 80002228 <wakeup>
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
    800008a4:	988080e7          	jalr	-1656(ra) # 80002228 <wakeup>
    
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
    80000930:	770080e7          	jalr	1904(ra) # 8000209c <sleep>
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
    80000ed8:	920080e7          	jalr	-1760(ra) # 800027f4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	fa4080e7          	jalr	-92(ra) # 80005e80 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	006080e7          	jalr	6(ra) # 80001eea <scheduler>
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
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	880080e7          	jalr	-1920(ra) # 800027cc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	8a0080e7          	jalr	-1888(ra) # 800027f4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	f0e080e7          	jalr	-242(ra) # 80005e6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	f1c080e7          	jalr	-228(ra) # 80005e80 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	0f6080e7          	jalr	246(ra) # 80003062 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	786080e7          	jalr	1926(ra) # 800036fa <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	730080e7          	jalr	1840(ra) # 800046ac <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	01e080e7          	jalr	30(ra) # 80005fa2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d24080e7          	jalr	-732(ra) # 80001cb0 <userinit>
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
    80001a04:	f907a783          	lw	a5,-112(a5) # 80008990 <first.1682>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	e02080e7          	jalr	-510(ra) # 8000280c <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	f607ab23          	sw	zero,-138(a5) # 80008990 <first.1682>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	c56080e7          	jalr	-938(ra) # 8000367a <fsinit>
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
    80001a50:	f4878793          	addi	a5,a5,-184 # 80008994 <nextpid>
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
    80001bf8:	a8ad                	j	80001c72 <allocproc+0xb8>
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
    80001c28:	cd21                	beqz	a0,80001c80 <allocproc+0xc6>
  p->pagetable = proc_pagetable(p);
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	e48080e7          	jalr	-440(ra) # 80001a74 <proc_pagetable>
    80001c34:	892a                	mv	s2,a0
    80001c36:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c38:	c125                	beqz	a0,80001c98 <allocproc+0xde>
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
  p->runTime = 0;
    80001c5e:	1604a823          	sw	zero,368(s1)
  p->endTime = 0;
    80001c62:	1604a623          	sw	zero,364(s1)
  p->startTime = ticks;
    80001c66:	00007797          	auipc	a5,0x7
    80001c6a:	3ca7a783          	lw	a5,970(a5) # 80009030 <ticks>
    80001c6e:	16f4a423          	sw	a5,360(s1)
}
    80001c72:	8526                	mv	a0,s1
    80001c74:	60e2                	ld	ra,24(sp)
    80001c76:	6442                	ld	s0,16(sp)
    80001c78:	64a2                	ld	s1,8(sp)
    80001c7a:	6902                	ld	s2,0(sp)
    80001c7c:	6105                	addi	sp,sp,32
    80001c7e:	8082                	ret
    freeproc(p);
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	ee0080e7          	jalr	-288(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	00c080e7          	jalr	12(ra) # 80000c98 <release>
    return 0;
    80001c94:	84ca                	mv	s1,s2
    80001c96:	bff1                	j	80001c72 <allocproc+0xb8>
    freeproc(p);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	ec8080e7          	jalr	-312(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	ff4080e7          	jalr	-12(ra) # 80000c98 <release>
    return 0;
    80001cac:	84ca                	mv	s1,s2
    80001cae:	b7d1                	j	80001c72 <allocproc+0xb8>

0000000080001cb0 <userinit>:
{
    80001cb0:	1101                	addi	sp,sp,-32
    80001cb2:	ec06                	sd	ra,24(sp)
    80001cb4:	e822                	sd	s0,16(sp)
    80001cb6:	e426                	sd	s1,8(sp)
    80001cb8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	f00080e7          	jalr	-256(ra) # 80001bba <allocproc>
    80001cc2:	84aa                	mv	s1,a0
  initproc = p;
    80001cc4:	00007797          	auipc	a5,0x7
    80001cc8:	36a7b223          	sd	a0,868(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ccc:	03400613          	li	a2,52
    80001cd0:	00007597          	auipc	a1,0x7
    80001cd4:	cd058593          	addi	a1,a1,-816 # 800089a0 <initcode>
    80001cd8:	6928                	ld	a0,80(a0)
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	68e080e7          	jalr	1678(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001ce2:	6785                	lui	a5,0x1
    80001ce4:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ce6:	6cb8                	ld	a4,88(s1)
    80001ce8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cec:	6cb8                	ld	a4,88(s1)
    80001cee:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf0:	4641                	li	a2,16
    80001cf2:	00006597          	auipc	a1,0x6
    80001cf6:	50e58593          	addi	a1,a1,1294 # 80008200 <digits+0x1c0>
    80001cfa:	15848513          	addi	a0,s1,344
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	134080e7          	jalr	308(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d06:	00006517          	auipc	a0,0x6
    80001d0a:	50a50513          	addi	a0,a0,1290 # 80008210 <digits+0x1d0>
    80001d0e:	00002097          	auipc	ra,0x2
    80001d12:	39a080e7          	jalr	922(ra) # 800040a8 <namei>
    80001d16:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d1a:	478d                	li	a5,3
    80001d1c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d1e:	8526                	mv	a0,s1
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	f78080e7          	jalr	-136(ra) # 80000c98 <release>
}
    80001d28:	60e2                	ld	ra,24(sp)
    80001d2a:	6442                	ld	s0,16(sp)
    80001d2c:	64a2                	ld	s1,8(sp)
    80001d2e:	6105                	addi	sp,sp,32
    80001d30:	8082                	ret

0000000080001d32 <growproc>:
{
    80001d32:	1101                	addi	sp,sp,-32
    80001d34:	ec06                	sd	ra,24(sp)
    80001d36:	e822                	sd	s0,16(sp)
    80001d38:	e426                	sd	s1,8(sp)
    80001d3a:	e04a                	sd	s2,0(sp)
    80001d3c:	1000                	addi	s0,sp,32
    80001d3e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	c70080e7          	jalr	-912(ra) # 800019b0 <myproc>
    80001d48:	892a                	mv	s2,a0
  sz = p->sz;
    80001d4a:	652c                	ld	a1,72(a0)
    80001d4c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d50:	00904f63          	bgtz	s1,80001d6e <growproc+0x3c>
  } else if(n < 0){
    80001d54:	0204cc63          	bltz	s1,80001d8c <growproc+0x5a>
  p->sz = sz;
    80001d58:	1602                	slli	a2,a2,0x20
    80001d5a:	9201                	srli	a2,a2,0x20
    80001d5c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d60:	4501                	li	a0,0
}
    80001d62:	60e2                	ld	ra,24(sp)
    80001d64:	6442                	ld	s0,16(sp)
    80001d66:	64a2                	ld	s1,8(sp)
    80001d68:	6902                	ld	s2,0(sp)
    80001d6a:	6105                	addi	sp,sp,32
    80001d6c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d6e:	9e25                	addw	a2,a2,s1
    80001d70:	1602                	slli	a2,a2,0x20
    80001d72:	9201                	srli	a2,a2,0x20
    80001d74:	1582                	slli	a1,a1,0x20
    80001d76:	9181                	srli	a1,a1,0x20
    80001d78:	6928                	ld	a0,80(a0)
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	6a8080e7          	jalr	1704(ra) # 80001422 <uvmalloc>
    80001d82:	0005061b          	sext.w	a2,a0
    80001d86:	fa69                	bnez	a2,80001d58 <growproc+0x26>
      return -1;
    80001d88:	557d                	li	a0,-1
    80001d8a:	bfe1                	j	80001d62 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d8c:	9e25                	addw	a2,a2,s1
    80001d8e:	1602                	slli	a2,a2,0x20
    80001d90:	9201                	srli	a2,a2,0x20
    80001d92:	1582                	slli	a1,a1,0x20
    80001d94:	9181                	srli	a1,a1,0x20
    80001d96:	6928                	ld	a0,80(a0)
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	642080e7          	jalr	1602(ra) # 800013da <uvmdealloc>
    80001da0:	0005061b          	sext.w	a2,a0
    80001da4:	bf55                	j	80001d58 <growproc+0x26>

0000000080001da6 <fork>:
{
    80001da6:	7179                	addi	sp,sp,-48
    80001da8:	f406                	sd	ra,40(sp)
    80001daa:	f022                	sd	s0,32(sp)
    80001dac:	ec26                	sd	s1,24(sp)
    80001dae:	e84a                	sd	s2,16(sp)
    80001db0:	e44e                	sd	s3,8(sp)
    80001db2:	e052                	sd	s4,0(sp)
    80001db4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001db6:	00000097          	auipc	ra,0x0
    80001dba:	bfa080e7          	jalr	-1030(ra) # 800019b0 <myproc>
    80001dbe:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dc0:	00000097          	auipc	ra,0x0
    80001dc4:	dfa080e7          	jalr	-518(ra) # 80001bba <allocproc>
    80001dc8:	10050f63          	beqz	a0,80001ee6 <fork+0x140>
    80001dcc:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dce:	04893603          	ld	a2,72(s2)
    80001dd2:	692c                	ld	a1,80(a0)
    80001dd4:	05093503          	ld	a0,80(s2)
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	796080e7          	jalr	1942(ra) # 8000156e <uvmcopy>
    80001de0:	04054663          	bltz	a0,80001e2c <fork+0x86>
  np->sz = p->sz;
    80001de4:	04893783          	ld	a5,72(s2)
    80001de8:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dec:	05893683          	ld	a3,88(s2)
    80001df0:	87b6                	mv	a5,a3
    80001df2:	0589b703          	ld	a4,88(s3)
    80001df6:	12068693          	addi	a3,a3,288
    80001dfa:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dfe:	6788                	ld	a0,8(a5)
    80001e00:	6b8c                	ld	a1,16(a5)
    80001e02:	6f90                	ld	a2,24(a5)
    80001e04:	01073023          	sd	a6,0(a4)
    80001e08:	e708                	sd	a0,8(a4)
    80001e0a:	eb0c                	sd	a1,16(a4)
    80001e0c:	ef10                	sd	a2,24(a4)
    80001e0e:	02078793          	addi	a5,a5,32
    80001e12:	02070713          	addi	a4,a4,32
    80001e16:	fed792e3          	bne	a5,a3,80001dfa <fork+0x54>
  np->trapframe->a0 = 0;
    80001e1a:	0589b783          	ld	a5,88(s3)
    80001e1e:	0607b823          	sd	zero,112(a5)
    80001e22:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e26:	15000a13          	li	s4,336
    80001e2a:	a03d                	j	80001e58 <fork+0xb2>
    freeproc(np);
    80001e2c:	854e                	mv	a0,s3
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	d34080e7          	jalr	-716(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e36:	854e                	mv	a0,s3
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	e60080e7          	jalr	-416(ra) # 80000c98 <release>
    return -1;
    80001e40:	5a7d                	li	s4,-1
    80001e42:	a849                	j	80001ed4 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e44:	00003097          	auipc	ra,0x3
    80001e48:	8fa080e7          	jalr	-1798(ra) # 8000473e <filedup>
    80001e4c:	009987b3          	add	a5,s3,s1
    80001e50:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e52:	04a1                	addi	s1,s1,8
    80001e54:	01448763          	beq	s1,s4,80001e62 <fork+0xbc>
    if(p->ofile[i])
    80001e58:	009907b3          	add	a5,s2,s1
    80001e5c:	6388                	ld	a0,0(a5)
    80001e5e:	f17d                	bnez	a0,80001e44 <fork+0x9e>
    80001e60:	bfcd                	j	80001e52 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e62:	15093503          	ld	a0,336(s2)
    80001e66:	00002097          	auipc	ra,0x2
    80001e6a:	a4e080e7          	jalr	-1458(ra) # 800038b4 <idup>
    80001e6e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e72:	4641                	li	a2,16
    80001e74:	15890593          	addi	a1,s2,344
    80001e78:	15898513          	addi	a0,s3,344
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	fb6080e7          	jalr	-74(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e84:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e88:	854e                	mv	a0,s3
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	e0e080e7          	jalr	-498(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e92:	0000f497          	auipc	s1,0xf
    80001e96:	42648493          	addi	s1,s1,1062 # 800112b8 <wait_lock>
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	d48080e7          	jalr	-696(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ea4:	0329bc23          	sd	s2,56(s3)
  np->mask = p->mask; // strace 
    80001ea8:	17492783          	lw	a5,372(s2)
    80001eac:	16f9aa23          	sw	a5,372(s3)
  release(&wait_lock);
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	de6080e7          	jalr	-538(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001eba:	854e                	mv	a0,s3
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	d28080e7          	jalr	-728(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ec4:	478d                	li	a5,3
    80001ec6:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eca:	854e                	mv	a0,s3
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	dcc080e7          	jalr	-564(ra) # 80000c98 <release>
}
    80001ed4:	8552                	mv	a0,s4
    80001ed6:	70a2                	ld	ra,40(sp)
    80001ed8:	7402                	ld	s0,32(sp)
    80001eda:	64e2                	ld	s1,24(sp)
    80001edc:	6942                	ld	s2,16(sp)
    80001ede:	69a2                	ld	s3,8(sp)
    80001ee0:	6a02                	ld	s4,0(sp)
    80001ee2:	6145                	addi	sp,sp,48
    80001ee4:	8082                	ret
    return -1;
    80001ee6:	5a7d                	li	s4,-1
    80001ee8:	b7f5                	j	80001ed4 <fork+0x12e>

0000000080001eea <scheduler>:
{
    80001eea:	7139                	addi	sp,sp,-64
    80001eec:	fc06                	sd	ra,56(sp)
    80001eee:	f822                	sd	s0,48(sp)
    80001ef0:	f426                	sd	s1,40(sp)
    80001ef2:	f04a                	sd	s2,32(sp)
    80001ef4:	ec4e                	sd	s3,24(sp)
    80001ef6:	e852                	sd	s4,16(sp)
    80001ef8:	e456                	sd	s5,8(sp)
    80001efa:	e05a                	sd	s6,0(sp)
    80001efc:	0080                	addi	s0,sp,64
    80001efe:	8792                	mv	a5,tp
  int id = r_tp();
    80001f00:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f02:	00779a93          	slli	s5,a5,0x7
    80001f06:	0000f717          	auipc	a4,0xf
    80001f0a:	39a70713          	addi	a4,a4,922 # 800112a0 <pid_lock>
    80001f0e:	9756                	add	a4,a4,s5
    80001f10:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f14:	0000f717          	auipc	a4,0xf
    80001f18:	3c470713          	addi	a4,a4,964 # 800112d8 <cpus+0x8>
    80001f1c:	9aba                	add	s5,s5,a4
        if(p->state == RUNNABLE) {
    80001f1e:	498d                	li	s3,3
          p->state = RUNNING;
    80001f20:	4b11                	li	s6,4
          c->proc = p;
    80001f22:	079e                	slli	a5,a5,0x7
    80001f24:	0000fa17          	auipc	s4,0xf
    80001f28:	37ca0a13          	addi	s4,s4,892 # 800112a0 <pid_lock>
    80001f2c:	9a3e                	add	s4,s4,a5
      for(p = proc; p < &proc[NPROC]; p++) {
    80001f2e:	00015917          	auipc	s2,0x15
    80001f32:	5a290913          	addi	s2,s2,1442 # 800174d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f36:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f3a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f3e:	10079073          	csrw	sstatus,a5
    80001f42:	0000f497          	auipc	s1,0xf
    80001f46:	78e48493          	addi	s1,s1,1934 # 800116d0 <proc>
    80001f4a:	a03d                	j	80001f78 <scheduler+0x8e>
          p->state = RUNNING;
    80001f4c:	0164ac23          	sw	s6,24(s1)
          c->proc = p;
    80001f50:	029a3823          	sd	s1,48(s4)
          swtch(&c->context, &p->context);
    80001f54:	06048593          	addi	a1,s1,96
    80001f58:	8556                	mv	a0,s5
    80001f5a:	00001097          	auipc	ra,0x1
    80001f5e:	808080e7          	jalr	-2040(ra) # 80002762 <swtch>
          c->proc = 0;
    80001f62:	020a3823          	sd	zero,48(s4)
        release(&p->lock);
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	d30080e7          	jalr	-720(ra) # 80000c98 <release>
      for(p = proc; p < &proc[NPROC]; p++) {
    80001f70:	17848493          	addi	s1,s1,376
    80001f74:	fd2481e3          	beq	s1,s2,80001f36 <scheduler+0x4c>
        acquire(&p->lock);
    80001f78:	8526                	mv	a0,s1
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	c6a080e7          	jalr	-918(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001f82:	4c9c                	lw	a5,24(s1)
    80001f84:	ff3791e3          	bne	a5,s3,80001f66 <scheduler+0x7c>
    80001f88:	b7d1                	j	80001f4c <scheduler+0x62>

0000000080001f8a <sched>:
{
    80001f8a:	7179                	addi	sp,sp,-48
    80001f8c:	f406                	sd	ra,40(sp)
    80001f8e:	f022                	sd	s0,32(sp)
    80001f90:	ec26                	sd	s1,24(sp)
    80001f92:	e84a                	sd	s2,16(sp)
    80001f94:	e44e                	sd	s3,8(sp)
    80001f96:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f98:	00000097          	auipc	ra,0x0
    80001f9c:	a18080e7          	jalr	-1512(ra) # 800019b0 <myproc>
    80001fa0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	bc8080e7          	jalr	-1080(ra) # 80000b6a <holding>
    80001faa:	c93d                	beqz	a0,80002020 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fac:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fae:	2781                	sext.w	a5,a5
    80001fb0:	079e                	slli	a5,a5,0x7
    80001fb2:	0000f717          	auipc	a4,0xf
    80001fb6:	2ee70713          	addi	a4,a4,750 # 800112a0 <pid_lock>
    80001fba:	97ba                	add	a5,a5,a4
    80001fbc:	0a87a703          	lw	a4,168(a5)
    80001fc0:	4785                	li	a5,1
    80001fc2:	06f71763          	bne	a4,a5,80002030 <sched+0xa6>
  if(p->state == RUNNING)
    80001fc6:	4c98                	lw	a4,24(s1)
    80001fc8:	4791                	li	a5,4
    80001fca:	06f70b63          	beq	a4,a5,80002040 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fce:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fd2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fd4:	efb5                	bnez	a5,80002050 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fd6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fd8:	0000f917          	auipc	s2,0xf
    80001fdc:	2c890913          	addi	s2,s2,712 # 800112a0 <pid_lock>
    80001fe0:	2781                	sext.w	a5,a5
    80001fe2:	079e                	slli	a5,a5,0x7
    80001fe4:	97ca                	add	a5,a5,s2
    80001fe6:	0ac7a983          	lw	s3,172(a5)
    80001fea:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fec:	2781                	sext.w	a5,a5
    80001fee:	079e                	slli	a5,a5,0x7
    80001ff0:	0000f597          	auipc	a1,0xf
    80001ff4:	2e858593          	addi	a1,a1,744 # 800112d8 <cpus+0x8>
    80001ff8:	95be                	add	a1,a1,a5
    80001ffa:	06048513          	addi	a0,s1,96
    80001ffe:	00000097          	auipc	ra,0x0
    80002002:	764080e7          	jalr	1892(ra) # 80002762 <swtch>
    80002006:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002008:	2781                	sext.w	a5,a5
    8000200a:	079e                	slli	a5,a5,0x7
    8000200c:	97ca                	add	a5,a5,s2
    8000200e:	0b37a623          	sw	s3,172(a5)
}
    80002012:	70a2                	ld	ra,40(sp)
    80002014:	7402                	ld	s0,32(sp)
    80002016:	64e2                	ld	s1,24(sp)
    80002018:	6942                	ld	s2,16(sp)
    8000201a:	69a2                	ld	s3,8(sp)
    8000201c:	6145                	addi	sp,sp,48
    8000201e:	8082                	ret
    panic("sched p->lock");
    80002020:	00006517          	auipc	a0,0x6
    80002024:	1f850513          	addi	a0,a0,504 # 80008218 <digits+0x1d8>
    80002028:	ffffe097          	auipc	ra,0xffffe
    8000202c:	516080e7          	jalr	1302(ra) # 8000053e <panic>
    panic("sched locks");
    80002030:	00006517          	auipc	a0,0x6
    80002034:	1f850513          	addi	a0,a0,504 # 80008228 <digits+0x1e8>
    80002038:	ffffe097          	auipc	ra,0xffffe
    8000203c:	506080e7          	jalr	1286(ra) # 8000053e <panic>
    panic("sched running");
    80002040:	00006517          	auipc	a0,0x6
    80002044:	1f850513          	addi	a0,a0,504 # 80008238 <digits+0x1f8>
    80002048:	ffffe097          	auipc	ra,0xffffe
    8000204c:	4f6080e7          	jalr	1270(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002050:	00006517          	auipc	a0,0x6
    80002054:	1f850513          	addi	a0,a0,504 # 80008248 <digits+0x208>
    80002058:	ffffe097          	auipc	ra,0xffffe
    8000205c:	4e6080e7          	jalr	1254(ra) # 8000053e <panic>

0000000080002060 <yield>:
{
    80002060:	1101                	addi	sp,sp,-32
    80002062:	ec06                	sd	ra,24(sp)
    80002064:	e822                	sd	s0,16(sp)
    80002066:	e426                	sd	s1,8(sp)
    80002068:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000206a:	00000097          	auipc	ra,0x0
    8000206e:	946080e7          	jalr	-1722(ra) # 800019b0 <myproc>
    80002072:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	b70080e7          	jalr	-1168(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000207c:	478d                	li	a5,3
    8000207e:	cc9c                	sw	a5,24(s1)
  sched();
    80002080:	00000097          	auipc	ra,0x0
    80002084:	f0a080e7          	jalr	-246(ra) # 80001f8a <sched>
  release(&p->lock);
    80002088:	8526                	mv	a0,s1
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	c0e080e7          	jalr	-1010(ra) # 80000c98 <release>
}
    80002092:	60e2                	ld	ra,24(sp)
    80002094:	6442                	ld	s0,16(sp)
    80002096:	64a2                	ld	s1,8(sp)
    80002098:	6105                	addi	sp,sp,32
    8000209a:	8082                	ret

000000008000209c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000209c:	7179                	addi	sp,sp,-48
    8000209e:	f406                	sd	ra,40(sp)
    800020a0:	f022                	sd	s0,32(sp)
    800020a2:	ec26                	sd	s1,24(sp)
    800020a4:	e84a                	sd	s2,16(sp)
    800020a6:	e44e                	sd	s3,8(sp)
    800020a8:	1800                	addi	s0,sp,48
    800020aa:	89aa                	mv	s3,a0
    800020ac:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020ae:	00000097          	auipc	ra,0x0
    800020b2:	902080e7          	jalr	-1790(ra) # 800019b0 <myproc>
    800020b6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	b2c080e7          	jalr	-1236(ra) # 80000be4 <acquire>
  release(lk);
    800020c0:	854a                	mv	a0,s2
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	bd6080e7          	jalr	-1066(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800020ca:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020ce:	4789                	li	a5,2
    800020d0:	cc9c                	sw	a5,24(s1)

  sched();
    800020d2:	00000097          	auipc	ra,0x0
    800020d6:	eb8080e7          	jalr	-328(ra) # 80001f8a <sched>

  // Tidy up.
  p->chan = 0;
    800020da:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020de:	8526                	mv	a0,s1
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	bb8080e7          	jalr	-1096(ra) # 80000c98 <release>
  acquire(lk);
    800020e8:	854a                	mv	a0,s2
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	afa080e7          	jalr	-1286(ra) # 80000be4 <acquire>
}
    800020f2:	70a2                	ld	ra,40(sp)
    800020f4:	7402                	ld	s0,32(sp)
    800020f6:	64e2                	ld	s1,24(sp)
    800020f8:	6942                	ld	s2,16(sp)
    800020fa:	69a2                	ld	s3,8(sp)
    800020fc:	6145                	addi	sp,sp,48
    800020fe:	8082                	ret

0000000080002100 <wait>:
{
    80002100:	715d                	addi	sp,sp,-80
    80002102:	e486                	sd	ra,72(sp)
    80002104:	e0a2                	sd	s0,64(sp)
    80002106:	fc26                	sd	s1,56(sp)
    80002108:	f84a                	sd	s2,48(sp)
    8000210a:	f44e                	sd	s3,40(sp)
    8000210c:	f052                	sd	s4,32(sp)
    8000210e:	ec56                	sd	s5,24(sp)
    80002110:	e85a                	sd	s6,16(sp)
    80002112:	e45e                	sd	s7,8(sp)
    80002114:	e062                	sd	s8,0(sp)
    80002116:	0880                	addi	s0,sp,80
    80002118:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	896080e7          	jalr	-1898(ra) # 800019b0 <myproc>
    80002122:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002124:	0000f517          	auipc	a0,0xf
    80002128:	19450513          	addi	a0,a0,404 # 800112b8 <wait_lock>
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	ab8080e7          	jalr	-1352(ra) # 80000be4 <acquire>
    havekids = 0;
    80002134:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002136:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002138:	00015997          	auipc	s3,0x15
    8000213c:	39898993          	addi	s3,s3,920 # 800174d0 <tickslock>
        havekids = 1;
    80002140:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002142:	0000fc17          	auipc	s8,0xf
    80002146:	176c0c13          	addi	s8,s8,374 # 800112b8 <wait_lock>
    havekids = 0;
    8000214a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000214c:	0000f497          	auipc	s1,0xf
    80002150:	58448493          	addi	s1,s1,1412 # 800116d0 <proc>
    80002154:	a0bd                	j	800021c2 <wait+0xc2>
          pid = np->pid;
    80002156:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000215a:	000b0e63          	beqz	s6,80002176 <wait+0x76>
    8000215e:	4691                	li	a3,4
    80002160:	02c48613          	addi	a2,s1,44
    80002164:	85da                	mv	a1,s6
    80002166:	05093503          	ld	a0,80(s2)
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	508080e7          	jalr	1288(ra) # 80001672 <copyout>
    80002172:	02054563          	bltz	a0,8000219c <wait+0x9c>
          freeproc(np);
    80002176:	8526                	mv	a0,s1
    80002178:	00000097          	auipc	ra,0x0
    8000217c:	9ea080e7          	jalr	-1558(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002180:	8526                	mv	a0,s1
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	b16080e7          	jalr	-1258(ra) # 80000c98 <release>
          release(&wait_lock);
    8000218a:	0000f517          	auipc	a0,0xf
    8000218e:	12e50513          	addi	a0,a0,302 # 800112b8 <wait_lock>
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	b06080e7          	jalr	-1274(ra) # 80000c98 <release>
          return pid;
    8000219a:	a09d                	j	80002200 <wait+0x100>
            release(&np->lock);
    8000219c:	8526                	mv	a0,s1
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	afa080e7          	jalr	-1286(ra) # 80000c98 <release>
            release(&wait_lock);
    800021a6:	0000f517          	auipc	a0,0xf
    800021aa:	11250513          	addi	a0,a0,274 # 800112b8 <wait_lock>
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	aea080e7          	jalr	-1302(ra) # 80000c98 <release>
            return -1;
    800021b6:	59fd                	li	s3,-1
    800021b8:	a0a1                	j	80002200 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021ba:	17848493          	addi	s1,s1,376
    800021be:	03348463          	beq	s1,s3,800021e6 <wait+0xe6>
      if(np->parent == p){
    800021c2:	7c9c                	ld	a5,56(s1)
    800021c4:	ff279be3          	bne	a5,s2,800021ba <wait+0xba>
        acquire(&np->lock);
    800021c8:	8526                	mv	a0,s1
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	a1a080e7          	jalr	-1510(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800021d2:	4c9c                	lw	a5,24(s1)
    800021d4:	f94781e3          	beq	a5,s4,80002156 <wait+0x56>
        release(&np->lock);
    800021d8:	8526                	mv	a0,s1
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	abe080e7          	jalr	-1346(ra) # 80000c98 <release>
        havekids = 1;
    800021e2:	8756                	mv	a4,s5
    800021e4:	bfd9                	j	800021ba <wait+0xba>
    if(!havekids || p->killed){
    800021e6:	c701                	beqz	a4,800021ee <wait+0xee>
    800021e8:	02892783          	lw	a5,40(s2)
    800021ec:	c79d                	beqz	a5,8000221a <wait+0x11a>
      release(&wait_lock);
    800021ee:	0000f517          	auipc	a0,0xf
    800021f2:	0ca50513          	addi	a0,a0,202 # 800112b8 <wait_lock>
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	aa2080e7          	jalr	-1374(ra) # 80000c98 <release>
      return -1;
    800021fe:	59fd                	li	s3,-1
}
    80002200:	854e                	mv	a0,s3
    80002202:	60a6                	ld	ra,72(sp)
    80002204:	6406                	ld	s0,64(sp)
    80002206:	74e2                	ld	s1,56(sp)
    80002208:	7942                	ld	s2,48(sp)
    8000220a:	79a2                	ld	s3,40(sp)
    8000220c:	7a02                	ld	s4,32(sp)
    8000220e:	6ae2                	ld	s5,24(sp)
    80002210:	6b42                	ld	s6,16(sp)
    80002212:	6ba2                	ld	s7,8(sp)
    80002214:	6c02                	ld	s8,0(sp)
    80002216:	6161                	addi	sp,sp,80
    80002218:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000221a:	85e2                	mv	a1,s8
    8000221c:	854a                	mv	a0,s2
    8000221e:	00000097          	auipc	ra,0x0
    80002222:	e7e080e7          	jalr	-386(ra) # 8000209c <sleep>
    havekids = 0;
    80002226:	b715                	j	8000214a <wait+0x4a>

0000000080002228 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002228:	7139                	addi	sp,sp,-64
    8000222a:	fc06                	sd	ra,56(sp)
    8000222c:	f822                	sd	s0,48(sp)
    8000222e:	f426                	sd	s1,40(sp)
    80002230:	f04a                	sd	s2,32(sp)
    80002232:	ec4e                	sd	s3,24(sp)
    80002234:	e852                	sd	s4,16(sp)
    80002236:	e456                	sd	s5,8(sp)
    80002238:	0080                	addi	s0,sp,64
    8000223a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000223c:	0000f497          	auipc	s1,0xf
    80002240:	49448493          	addi	s1,s1,1172 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002244:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002246:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002248:	00015917          	auipc	s2,0x15
    8000224c:	28890913          	addi	s2,s2,648 # 800174d0 <tickslock>
    80002250:	a821                	j	80002268 <wakeup+0x40>
        p->state = RUNNABLE;
    80002252:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002256:	8526                	mv	a0,s1
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	a40080e7          	jalr	-1472(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002260:	17848493          	addi	s1,s1,376
    80002264:	03248463          	beq	s1,s2,8000228c <wakeup+0x64>
    if(p != myproc()){
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	748080e7          	jalr	1864(ra) # 800019b0 <myproc>
    80002270:	fea488e3          	beq	s1,a0,80002260 <wakeup+0x38>
      acquire(&p->lock);
    80002274:	8526                	mv	a0,s1
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	96e080e7          	jalr	-1682(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000227e:	4c9c                	lw	a5,24(s1)
    80002280:	fd379be3          	bne	a5,s3,80002256 <wakeup+0x2e>
    80002284:	709c                	ld	a5,32(s1)
    80002286:	fd4798e3          	bne	a5,s4,80002256 <wakeup+0x2e>
    8000228a:	b7e1                	j	80002252 <wakeup+0x2a>
    }
  }
}
    8000228c:	70e2                	ld	ra,56(sp)
    8000228e:	7442                	ld	s0,48(sp)
    80002290:	74a2                	ld	s1,40(sp)
    80002292:	7902                	ld	s2,32(sp)
    80002294:	69e2                	ld	s3,24(sp)
    80002296:	6a42                	ld	s4,16(sp)
    80002298:	6aa2                	ld	s5,8(sp)
    8000229a:	6121                	addi	sp,sp,64
    8000229c:	8082                	ret

000000008000229e <reparent>:
{
    8000229e:	7179                	addi	sp,sp,-48
    800022a0:	f406                	sd	ra,40(sp)
    800022a2:	f022                	sd	s0,32(sp)
    800022a4:	ec26                	sd	s1,24(sp)
    800022a6:	e84a                	sd	s2,16(sp)
    800022a8:	e44e                	sd	s3,8(sp)
    800022aa:	e052                	sd	s4,0(sp)
    800022ac:	1800                	addi	s0,sp,48
    800022ae:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022b0:	0000f497          	auipc	s1,0xf
    800022b4:	42048493          	addi	s1,s1,1056 # 800116d0 <proc>
      pp->parent = initproc;
    800022b8:	00007a17          	auipc	s4,0x7
    800022bc:	d70a0a13          	addi	s4,s4,-656 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022c0:	00015997          	auipc	s3,0x15
    800022c4:	21098993          	addi	s3,s3,528 # 800174d0 <tickslock>
    800022c8:	a029                	j	800022d2 <reparent+0x34>
    800022ca:	17848493          	addi	s1,s1,376
    800022ce:	01348d63          	beq	s1,s3,800022e8 <reparent+0x4a>
    if(pp->parent == p){
    800022d2:	7c9c                	ld	a5,56(s1)
    800022d4:	ff279be3          	bne	a5,s2,800022ca <reparent+0x2c>
      pp->parent = initproc;
    800022d8:	000a3503          	ld	a0,0(s4)
    800022dc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022de:	00000097          	auipc	ra,0x0
    800022e2:	f4a080e7          	jalr	-182(ra) # 80002228 <wakeup>
    800022e6:	b7d5                	j	800022ca <reparent+0x2c>
}
    800022e8:	70a2                	ld	ra,40(sp)
    800022ea:	7402                	ld	s0,32(sp)
    800022ec:	64e2                	ld	s1,24(sp)
    800022ee:	6942                	ld	s2,16(sp)
    800022f0:	69a2                	ld	s3,8(sp)
    800022f2:	6a02                	ld	s4,0(sp)
    800022f4:	6145                	addi	sp,sp,48
    800022f6:	8082                	ret

00000000800022f8 <exit>:
{
    800022f8:	7179                	addi	sp,sp,-48
    800022fa:	f406                	sd	ra,40(sp)
    800022fc:	f022                	sd	s0,32(sp)
    800022fe:	ec26                	sd	s1,24(sp)
    80002300:	e84a                	sd	s2,16(sp)
    80002302:	e44e                	sd	s3,8(sp)
    80002304:	e052                	sd	s4,0(sp)
    80002306:	1800                	addi	s0,sp,48
    80002308:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	6a6080e7          	jalr	1702(ra) # 800019b0 <myproc>
  if(p == initproc)
    80002312:	00007797          	auipc	a5,0x7
    80002316:	d167b783          	ld	a5,-746(a5) # 80009028 <initproc>
    8000231a:	00a78e63          	beq	a5,a0,80002336 <exit+0x3e>
    8000231e:	89aa                	mv	s3,a0
  p->endTime = ticks;
    80002320:	00007797          	auipc	a5,0x7
    80002324:	d107a783          	lw	a5,-752(a5) # 80009030 <ticks>
    80002328:	16f52623          	sw	a5,364(a0)
  for(int fd = 0; fd < NOFILE; fd++){
    8000232c:	0d050493          	addi	s1,a0,208
    80002330:	15050913          	addi	s2,a0,336
    80002334:	a015                	j	80002358 <exit+0x60>
    panic("init exiting");
    80002336:	00006517          	auipc	a0,0x6
    8000233a:	f2a50513          	addi	a0,a0,-214 # 80008260 <digits+0x220>
    8000233e:	ffffe097          	auipc	ra,0xffffe
    80002342:	200080e7          	jalr	512(ra) # 8000053e <panic>
      fileclose(f);
    80002346:	00002097          	auipc	ra,0x2
    8000234a:	44a080e7          	jalr	1098(ra) # 80004790 <fileclose>
      p->ofile[fd] = 0;
    8000234e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002352:	04a1                	addi	s1,s1,8
    80002354:	01248563          	beq	s1,s2,8000235e <exit+0x66>
    if(p->ofile[fd]){
    80002358:	6088                	ld	a0,0(s1)
    8000235a:	f575                	bnez	a0,80002346 <exit+0x4e>
    8000235c:	bfdd                	j	80002352 <exit+0x5a>
  begin_op();
    8000235e:	00002097          	auipc	ra,0x2
    80002362:	f66080e7          	jalr	-154(ra) # 800042c4 <begin_op>
  iput(p->cwd);
    80002366:	1509b503          	ld	a0,336(s3)
    8000236a:	00001097          	auipc	ra,0x1
    8000236e:	742080e7          	jalr	1858(ra) # 80003aac <iput>
  end_op();
    80002372:	00002097          	auipc	ra,0x2
    80002376:	fd2080e7          	jalr	-46(ra) # 80004344 <end_op>
  p->cwd = 0;
    8000237a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000237e:	0000f497          	auipc	s1,0xf
    80002382:	f3a48493          	addi	s1,s1,-198 # 800112b8 <wait_lock>
    80002386:	8526                	mv	a0,s1
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	85c080e7          	jalr	-1956(ra) # 80000be4 <acquire>
  reparent(p);
    80002390:	854e                	mv	a0,s3
    80002392:	00000097          	auipc	ra,0x0
    80002396:	f0c080e7          	jalr	-244(ra) # 8000229e <reparent>
  wakeup(p->parent);
    8000239a:	0389b503          	ld	a0,56(s3)
    8000239e:	00000097          	auipc	ra,0x0
    800023a2:	e8a080e7          	jalr	-374(ra) # 80002228 <wakeup>
  acquire(&p->lock);
    800023a6:	854e                	mv	a0,s3
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	83c080e7          	jalr	-1988(ra) # 80000be4 <acquire>
  p->xstate = status;
    800023b0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023b4:	4795                	li	a5,5
    800023b6:	00f9ac23          	sw	a5,24(s3)
  p->endTime = ticks;
    800023ba:	00007797          	auipc	a5,0x7
    800023be:	c767a783          	lw	a5,-906(a5) # 80009030 <ticks>
    800023c2:	16f9a623          	sw	a5,364(s3)
  release(&wait_lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	8d0080e7          	jalr	-1840(ra) # 80000c98 <release>
  sched();
    800023d0:	00000097          	auipc	ra,0x0
    800023d4:	bba080e7          	jalr	-1094(ra) # 80001f8a <sched>
  panic("zombie exit");
    800023d8:	00006517          	auipc	a0,0x6
    800023dc:	e9850513          	addi	a0,a0,-360 # 80008270 <digits+0x230>
    800023e0:	ffffe097          	auipc	ra,0xffffe
    800023e4:	15e080e7          	jalr	350(ra) # 8000053e <panic>

00000000800023e8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023e8:	7179                	addi	sp,sp,-48
    800023ea:	f406                	sd	ra,40(sp)
    800023ec:	f022                	sd	s0,32(sp)
    800023ee:	ec26                	sd	s1,24(sp)
    800023f0:	e84a                	sd	s2,16(sp)
    800023f2:	e44e                	sd	s3,8(sp)
    800023f4:	1800                	addi	s0,sp,48
    800023f6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023f8:	0000f497          	auipc	s1,0xf
    800023fc:	2d848493          	addi	s1,s1,728 # 800116d0 <proc>
    80002400:	00015997          	auipc	s3,0x15
    80002404:	0d098993          	addi	s3,s3,208 # 800174d0 <tickslock>
    acquire(&p->lock);
    80002408:	8526                	mv	a0,s1
    8000240a:	ffffe097          	auipc	ra,0xffffe
    8000240e:	7da080e7          	jalr	2010(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002412:	589c                	lw	a5,48(s1)
    80002414:	01278d63          	beq	a5,s2,8000242e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	87e080e7          	jalr	-1922(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002422:	17848493          	addi	s1,s1,376
    80002426:	ff3491e3          	bne	s1,s3,80002408 <kill+0x20>
  }
  return -1;
    8000242a:	557d                	li	a0,-1
    8000242c:	a829                	j	80002446 <kill+0x5e>
      p->killed = 1;
    8000242e:	4785                	li	a5,1
    80002430:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002432:	4c98                	lw	a4,24(s1)
    80002434:	4789                	li	a5,2
    80002436:	00f70f63          	beq	a4,a5,80002454 <kill+0x6c>
      release(&p->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	85c080e7          	jalr	-1956(ra) # 80000c98 <release>
      return 0;
    80002444:	4501                	li	a0,0
}
    80002446:	70a2                	ld	ra,40(sp)
    80002448:	7402                	ld	s0,32(sp)
    8000244a:	64e2                	ld	s1,24(sp)
    8000244c:	6942                	ld	s2,16(sp)
    8000244e:	69a2                	ld	s3,8(sp)
    80002450:	6145                	addi	sp,sp,48
    80002452:	8082                	ret
        p->state = RUNNABLE;
    80002454:	478d                	li	a5,3
    80002456:	cc9c                	sw	a5,24(s1)
    80002458:	b7cd                	j	8000243a <kill+0x52>

000000008000245a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000245a:	7179                	addi	sp,sp,-48
    8000245c:	f406                	sd	ra,40(sp)
    8000245e:	f022                	sd	s0,32(sp)
    80002460:	ec26                	sd	s1,24(sp)
    80002462:	e84a                	sd	s2,16(sp)
    80002464:	e44e                	sd	s3,8(sp)
    80002466:	e052                	sd	s4,0(sp)
    80002468:	1800                	addi	s0,sp,48
    8000246a:	84aa                	mv	s1,a0
    8000246c:	892e                	mv	s2,a1
    8000246e:	89b2                	mv	s3,a2
    80002470:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	53e080e7          	jalr	1342(ra) # 800019b0 <myproc>
  if(user_dst){
    8000247a:	c08d                	beqz	s1,8000249c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000247c:	86d2                	mv	a3,s4
    8000247e:	864e                	mv	a2,s3
    80002480:	85ca                	mv	a1,s2
    80002482:	6928                	ld	a0,80(a0)
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	1ee080e7          	jalr	494(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248c:	70a2                	ld	ra,40(sp)
    8000248e:	7402                	ld	s0,32(sp)
    80002490:	64e2                	ld	s1,24(sp)
    80002492:	6942                	ld	s2,16(sp)
    80002494:	69a2                	ld	s3,8(sp)
    80002496:	6a02                	ld	s4,0(sp)
    80002498:	6145                	addi	sp,sp,48
    8000249a:	8082                	ret
    memmove((char *)dst, src, len);
    8000249c:	000a061b          	sext.w	a2,s4
    800024a0:	85ce                	mv	a1,s3
    800024a2:	854a                	mv	a0,s2
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	89c080e7          	jalr	-1892(ra) # 80000d40 <memmove>
    return 0;
    800024ac:	8526                	mv	a0,s1
    800024ae:	bff9                	j	8000248c <either_copyout+0x32>

00000000800024b0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024b0:	7179                	addi	sp,sp,-48
    800024b2:	f406                	sd	ra,40(sp)
    800024b4:	f022                	sd	s0,32(sp)
    800024b6:	ec26                	sd	s1,24(sp)
    800024b8:	e84a                	sd	s2,16(sp)
    800024ba:	e44e                	sd	s3,8(sp)
    800024bc:	e052                	sd	s4,0(sp)
    800024be:	1800                	addi	s0,sp,48
    800024c0:	892a                	mv	s2,a0
    800024c2:	84ae                	mv	s1,a1
    800024c4:	89b2                	mv	s3,a2
    800024c6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	4e8080e7          	jalr	1256(ra) # 800019b0 <myproc>
  if(user_src){
    800024d0:	c08d                	beqz	s1,800024f2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d2:	86d2                	mv	a3,s4
    800024d4:	864e                	mv	a2,s3
    800024d6:	85ca                	mv	a1,s2
    800024d8:	6928                	ld	a0,80(a0)
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	224080e7          	jalr	548(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e2:	70a2                	ld	ra,40(sp)
    800024e4:	7402                	ld	s0,32(sp)
    800024e6:	64e2                	ld	s1,24(sp)
    800024e8:	6942                	ld	s2,16(sp)
    800024ea:	69a2                	ld	s3,8(sp)
    800024ec:	6a02                	ld	s4,0(sp)
    800024ee:	6145                	addi	sp,sp,48
    800024f0:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f2:	000a061b          	sext.w	a2,s4
    800024f6:	85ce                	mv	a1,s3
    800024f8:	854a                	mv	a0,s2
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	846080e7          	jalr	-1978(ra) # 80000d40 <memmove>
    return 0;
    80002502:	8526                	mv	a0,s1
    80002504:	bff9                	j	800024e2 <either_copyin+0x32>

0000000080002506 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002506:	715d                	addi	sp,sp,-80
    80002508:	e486                	sd	ra,72(sp)
    8000250a:	e0a2                	sd	s0,64(sp)
    8000250c:	fc26                	sd	s1,56(sp)
    8000250e:	f84a                	sd	s2,48(sp)
    80002510:	f44e                	sd	s3,40(sp)
    80002512:	f052                	sd	s4,32(sp)
    80002514:	ec56                	sd	s5,24(sp)
    80002516:	e85a                	sd	s6,16(sp)
    80002518:	e45e                	sd	s7,8(sp)
    8000251a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000251c:	00006517          	auipc	a0,0x6
    80002520:	bac50513          	addi	a0,a0,-1108 # 800080c8 <digits+0x88>
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	064080e7          	jalr	100(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252c:	0000f497          	auipc	s1,0xf
    80002530:	2fc48493          	addi	s1,s1,764 # 80011828 <proc+0x158>
    80002534:	00015917          	auipc	s2,0x15
    80002538:	0f490913          	addi	s2,s2,244 # 80017628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000253e:	00006997          	auipc	s3,0x6
    80002542:	d4298993          	addi	s3,s3,-702 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002546:	00006a97          	auipc	s5,0x6
    8000254a:	d42a8a93          	addi	s5,s5,-702 # 80008288 <digits+0x248>
    printf("\n");
    8000254e:	00006a17          	auipc	s4,0x6
    80002552:	b7aa0a13          	addi	s4,s4,-1158 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002556:	00006b97          	auipc	s7,0x6
    8000255a:	d6ab8b93          	addi	s7,s7,-662 # 800082c0 <states.1719>
    8000255e:	a00d                	j	80002580 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002560:	ed86a583          	lw	a1,-296(a3)
    80002564:	8556                	mv	a0,s5
    80002566:	ffffe097          	auipc	ra,0xffffe
    8000256a:	022080e7          	jalr	34(ra) # 80000588 <printf>
    printf("\n");
    8000256e:	8552                	mv	a0,s4
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	018080e7          	jalr	24(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002578:	17848493          	addi	s1,s1,376
    8000257c:	03248163          	beq	s1,s2,8000259e <procdump+0x98>
    if(p->state == UNUSED)
    80002580:	86a6                	mv	a3,s1
    80002582:	ec04a783          	lw	a5,-320(s1)
    80002586:	dbed                	beqz	a5,80002578 <procdump+0x72>
      state = "???";
    80002588:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258a:	fcfb6be3          	bltu	s6,a5,80002560 <procdump+0x5a>
    8000258e:	1782                	slli	a5,a5,0x20
    80002590:	9381                	srli	a5,a5,0x20
    80002592:	078e                	slli	a5,a5,0x3
    80002594:	97de                	add	a5,a5,s7
    80002596:	6390                	ld	a2,0(a5)
    80002598:	f661                	bnez	a2,80002560 <procdump+0x5a>
      state = "???";
    8000259a:	864e                	mv	a2,s3
    8000259c:	b7d1                	j	80002560 <procdump+0x5a>
  }
}
    8000259e:	60a6                	ld	ra,72(sp)
    800025a0:	6406                	ld	s0,64(sp)
    800025a2:	74e2                	ld	s1,56(sp)
    800025a4:	7942                	ld	s2,48(sp)
    800025a6:	79a2                	ld	s3,40(sp)
    800025a8:	7a02                	ld	s4,32(sp)
    800025aa:	6ae2                	ld	s5,24(sp)
    800025ac:	6b42                	ld	s6,16(sp)
    800025ae:	6ba2                	ld	s7,8(sp)
    800025b0:	6161                	addi	sp,sp,80
    800025b2:	8082                	ret

00000000800025b4 <waitx>:


int
waitx(uint64 addr, uint* rtime, uint* wtime)
{
    800025b4:	711d                	addi	sp,sp,-96
    800025b6:	ec86                	sd	ra,88(sp)
    800025b8:	e8a2                	sd	s0,80(sp)
    800025ba:	e4a6                	sd	s1,72(sp)
    800025bc:	e0ca                	sd	s2,64(sp)
    800025be:	fc4e                	sd	s3,56(sp)
    800025c0:	f852                	sd	s4,48(sp)
    800025c2:	f456                	sd	s5,40(sp)
    800025c4:	f05a                	sd	s6,32(sp)
    800025c6:	ec5e                	sd	s7,24(sp)
    800025c8:	e862                	sd	s8,16(sp)
    800025ca:	e466                	sd	s9,8(sp)
    800025cc:	e06a                	sd	s10,0(sp)
    800025ce:	1080                	addi	s0,sp,96
    800025d0:	8b2a                	mv	s6,a0
    800025d2:	8c2e                	mv	s8,a1
    800025d4:	8bb2                	mv	s7,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800025d6:	fffff097          	auipc	ra,0xfffff
    800025da:	3da080e7          	jalr	986(ra) # 800019b0 <myproc>
    800025de:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800025e0:	0000f517          	auipc	a0,0xf
    800025e4:	cd850513          	addi	a0,a0,-808 # 800112b8 <wait_lock>
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	5fc080e7          	jalr	1532(ra) # 80000be4 <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    800025f0:	4c81                	li	s9,0
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
    800025f2:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800025f4:	00015997          	auipc	s3,0x15
    800025f8:	edc98993          	addi	s3,s3,-292 # 800174d0 <tickslock>
        havekids = 1;
    800025fc:	4a85                	li	s5,1
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025fe:	0000fd17          	auipc	s10,0xf
    80002602:	cbad0d13          	addi	s10,s10,-838 # 800112b8 <wait_lock>
    havekids = 0;
    80002606:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    80002608:	0000f497          	auipc	s1,0xf
    8000260c:	0c848493          	addi	s1,s1,200 # 800116d0 <proc>
    80002610:	a069                	j	8000269a <waitx+0xe6>
          pid = np->pid;
    80002612:	0304a983          	lw	s3,48(s1)
          *rtime = np->runTime;
    80002616:	1704a783          	lw	a5,368(s1)
    8000261a:	00fc2023          	sw	a5,0(s8)
          *wtime = np->endTime - np->startTime - np->runTime;
    8000261e:	16c4a783          	lw	a5,364(s1)
    80002622:	1684a703          	lw	a4,360(s1)
    80002626:	9f99                	subw	a5,a5,a4
    80002628:	1704a703          	lw	a4,368(s1)
    8000262c:	9f99                	subw	a5,a5,a4
    8000262e:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002632:	000b0e63          	beqz	s6,8000264e <waitx+0x9a>
    80002636:	4691                	li	a3,4
    80002638:	02c48613          	addi	a2,s1,44
    8000263c:	85da                	mv	a1,s6
    8000263e:	05093503          	ld	a0,80(s2)
    80002642:	fffff097          	auipc	ra,0xfffff
    80002646:	030080e7          	jalr	48(ra) # 80001672 <copyout>
    8000264a:	02054563          	bltz	a0,80002674 <waitx+0xc0>
          freeproc(np);
    8000264e:	8526                	mv	a0,s1
    80002650:	fffff097          	auipc	ra,0xfffff
    80002654:	512080e7          	jalr	1298(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002658:	8526                	mv	a0,s1
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	63e080e7          	jalr	1598(ra) # 80000c98 <release>
          release(&wait_lock);
    80002662:	0000f517          	auipc	a0,0xf
    80002666:	c5650513          	addi	a0,a0,-938 # 800112b8 <wait_lock>
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	62e080e7          	jalr	1582(ra) # 80000c98 <release>
          return pid;
    80002672:	a09d                	j	800026d8 <waitx+0x124>
            release(&np->lock);
    80002674:	8526                	mv	a0,s1
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	622080e7          	jalr	1570(ra) # 80000c98 <release>
            release(&wait_lock);
    8000267e:	0000f517          	auipc	a0,0xf
    80002682:	c3a50513          	addi	a0,a0,-966 # 800112b8 <wait_lock>
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	612080e7          	jalr	1554(ra) # 80000c98 <release>
            return -1;
    8000268e:	59fd                	li	s3,-1
    80002690:	a0a1                	j	800026d8 <waitx+0x124>
    for(np = proc; np < &proc[NPROC]; np++){
    80002692:	17848493          	addi	s1,s1,376
    80002696:	03348463          	beq	s1,s3,800026be <waitx+0x10a>
      if(np->parent == p){
    8000269a:	7c9c                	ld	a5,56(s1)
    8000269c:	ff279be3          	bne	a5,s2,80002692 <waitx+0xde>
        acquire(&np->lock);
    800026a0:	8526                	mv	a0,s1
    800026a2:	ffffe097          	auipc	ra,0xffffe
    800026a6:	542080e7          	jalr	1346(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800026aa:	4c9c                	lw	a5,24(s1)
    800026ac:	f74783e3          	beq	a5,s4,80002612 <waitx+0x5e>
        release(&np->lock);
    800026b0:	8526                	mv	a0,s1
    800026b2:	ffffe097          	auipc	ra,0xffffe
    800026b6:	5e6080e7          	jalr	1510(ra) # 80000c98 <release>
        havekids = 1;
    800026ba:	8756                	mv	a4,s5
    800026bc:	bfd9                	j	80002692 <waitx+0xde>
    if(!havekids || p->killed){
    800026be:	c701                	beqz	a4,800026c6 <waitx+0x112>
    800026c0:	02892783          	lw	a5,40(s2)
    800026c4:	cb8d                	beqz	a5,800026f6 <waitx+0x142>
      release(&wait_lock);
    800026c6:	0000f517          	auipc	a0,0xf
    800026ca:	bf250513          	addi	a0,a0,-1038 # 800112b8 <wait_lock>
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	5ca080e7          	jalr	1482(ra) # 80000c98 <release>
      return -1;
    800026d6:	59fd                	li	s3,-1
  }
}
    800026d8:	854e                	mv	a0,s3
    800026da:	60e6                	ld	ra,88(sp)
    800026dc:	6446                	ld	s0,80(sp)
    800026de:	64a6                	ld	s1,72(sp)
    800026e0:	6906                	ld	s2,64(sp)
    800026e2:	79e2                	ld	s3,56(sp)
    800026e4:	7a42                	ld	s4,48(sp)
    800026e6:	7aa2                	ld	s5,40(sp)
    800026e8:	7b02                	ld	s6,32(sp)
    800026ea:	6be2                	ld	s7,24(sp)
    800026ec:	6c42                	ld	s8,16(sp)
    800026ee:	6ca2                	ld	s9,8(sp)
    800026f0:	6d02                	ld	s10,0(sp)
    800026f2:	6125                	addi	sp,sp,96
    800026f4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026f6:	85ea                	mv	a1,s10
    800026f8:	854a                	mv	a0,s2
    800026fa:	00000097          	auipc	ra,0x0
    800026fe:	9a2080e7          	jalr	-1630(ra) # 8000209c <sleep>
    havekids = 0;
    80002702:	b711                	j	80002606 <waitx+0x52>

0000000080002704 <increaseRuntime>:

// This function is executed after every CPU cycle with every ticks
// Iterates through each process & increases the run time of every running process.
void increaseRuntime() {
    80002704:	7179                	addi	sp,sp,-48
    80002706:	f406                	sd	ra,40(sp)
    80002708:	f022                	sd	s0,32(sp)
    8000270a:	ec26                	sd	s1,24(sp)
    8000270c:	e84a                	sd	s2,16(sp)
    8000270e:	e44e                	sd	s3,8(sp)
    80002710:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p<&proc[NPROC]; p++) {
    80002712:	0000f497          	auipc	s1,0xf
    80002716:	fbe48493          	addi	s1,s1,-66 # 800116d0 <proc>
    acquire(&p->lock);
    if (p->state == RUNNING)
    8000271a:	4991                	li	s3,4
  for (p = proc; p<&proc[NPROC]; p++) {
    8000271c:	00015917          	auipc	s2,0x15
    80002720:	db490913          	addi	s2,s2,-588 # 800174d0 <tickslock>
    80002724:	a811                	j	80002738 <increaseRuntime+0x34>
      p->runTime++;
    
    release(&p->lock);
    80002726:	8526                	mv	a0,s1
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	570080e7          	jalr	1392(ra) # 80000c98 <release>
  for (p = proc; p<&proc[NPROC]; p++) {
    80002730:	17848493          	addi	s1,s1,376
    80002734:	03248063          	beq	s1,s2,80002754 <increaseRuntime+0x50>
    acquire(&p->lock);
    80002738:	8526                	mv	a0,s1
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	4aa080e7          	jalr	1194(ra) # 80000be4 <acquire>
    if (p->state == RUNNING)
    80002742:	4c9c                	lw	a5,24(s1)
    80002744:	ff3791e3          	bne	a5,s3,80002726 <increaseRuntime+0x22>
      p->runTime++;
    80002748:	1704a783          	lw	a5,368(s1)
    8000274c:	2785                	addiw	a5,a5,1
    8000274e:	16f4a823          	sw	a5,368(s1)
    80002752:	bfd1                	j	80002726 <increaseRuntime+0x22>
  }
}
    80002754:	70a2                	ld	ra,40(sp)
    80002756:	7402                	ld	s0,32(sp)
    80002758:	64e2                	ld	s1,24(sp)
    8000275a:	6942                	ld	s2,16(sp)
    8000275c:	69a2                	ld	s3,8(sp)
    8000275e:	6145                	addi	sp,sp,48
    80002760:	8082                	ret

0000000080002762 <swtch>:
    80002762:	00153023          	sd	ra,0(a0)
    80002766:	00253423          	sd	sp,8(a0)
    8000276a:	e900                	sd	s0,16(a0)
    8000276c:	ed04                	sd	s1,24(a0)
    8000276e:	03253023          	sd	s2,32(a0)
    80002772:	03353423          	sd	s3,40(a0)
    80002776:	03453823          	sd	s4,48(a0)
    8000277a:	03553c23          	sd	s5,56(a0)
    8000277e:	05653023          	sd	s6,64(a0)
    80002782:	05753423          	sd	s7,72(a0)
    80002786:	05853823          	sd	s8,80(a0)
    8000278a:	05953c23          	sd	s9,88(a0)
    8000278e:	07a53023          	sd	s10,96(a0)
    80002792:	07b53423          	sd	s11,104(a0)
    80002796:	0005b083          	ld	ra,0(a1)
    8000279a:	0085b103          	ld	sp,8(a1)
    8000279e:	6980                	ld	s0,16(a1)
    800027a0:	6d84                	ld	s1,24(a1)
    800027a2:	0205b903          	ld	s2,32(a1)
    800027a6:	0285b983          	ld	s3,40(a1)
    800027aa:	0305ba03          	ld	s4,48(a1)
    800027ae:	0385ba83          	ld	s5,56(a1)
    800027b2:	0405bb03          	ld	s6,64(a1)
    800027b6:	0485bb83          	ld	s7,72(a1)
    800027ba:	0505bc03          	ld	s8,80(a1)
    800027be:	0585bc83          	ld	s9,88(a1)
    800027c2:	0605bd03          	ld	s10,96(a1)
    800027c6:	0685bd83          	ld	s11,104(a1)
    800027ca:	8082                	ret

00000000800027cc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027cc:	1141                	addi	sp,sp,-16
    800027ce:	e406                	sd	ra,8(sp)
    800027d0:	e022                	sd	s0,0(sp)
    800027d2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027d4:	00006597          	auipc	a1,0x6
    800027d8:	b1c58593          	addi	a1,a1,-1252 # 800082f0 <states.1719+0x30>
    800027dc:	00015517          	auipc	a0,0x15
    800027e0:	cf450513          	addi	a0,a0,-780 # 800174d0 <tickslock>
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	370080e7          	jalr	880(ra) # 80000b54 <initlock>
}
    800027ec:	60a2                	ld	ra,8(sp)
    800027ee:	6402                	ld	s0,0(sp)
    800027f0:	0141                	addi	sp,sp,16
    800027f2:	8082                	ret

00000000800027f4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027f4:	1141                	addi	sp,sp,-16
    800027f6:	e422                	sd	s0,8(sp)
    800027f8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027fa:	00003797          	auipc	a5,0x3
    800027fe:	5b678793          	addi	a5,a5,1462 # 80005db0 <kernelvec>
    80002802:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002806:	6422                	ld	s0,8(sp)
    80002808:	0141                	addi	sp,sp,16
    8000280a:	8082                	ret

000000008000280c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000280c:	1141                	addi	sp,sp,-16
    8000280e:	e406                	sd	ra,8(sp)
    80002810:	e022                	sd	s0,0(sp)
    80002812:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002814:	fffff097          	auipc	ra,0xfffff
    80002818:	19c080e7          	jalr	412(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000281c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002820:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002822:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002826:	00004617          	auipc	a2,0x4
    8000282a:	7da60613          	addi	a2,a2,2010 # 80007000 <_trampoline>
    8000282e:	00004697          	auipc	a3,0x4
    80002832:	7d268693          	addi	a3,a3,2002 # 80007000 <_trampoline>
    80002836:	8e91                	sub	a3,a3,a2
    80002838:	040007b7          	lui	a5,0x4000
    8000283c:	17fd                	addi	a5,a5,-1
    8000283e:	07b2                	slli	a5,a5,0xc
    80002840:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002842:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002846:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002848:	180026f3          	csrr	a3,satp
    8000284c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000284e:	6d38                	ld	a4,88(a0)
    80002850:	6134                	ld	a3,64(a0)
    80002852:	6585                	lui	a1,0x1
    80002854:	96ae                	add	a3,a3,a1
    80002856:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002858:	6d38                	ld	a4,88(a0)
    8000285a:	00000697          	auipc	a3,0x0
    8000285e:	14668693          	addi	a3,a3,326 # 800029a0 <usertrap>
    80002862:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002864:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002866:	8692                	mv	a3,tp
    80002868:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000286a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000286e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002872:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002876:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000287a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000287c:	6f18                	ld	a4,24(a4)
    8000287e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002882:	692c                	ld	a1,80(a0)
    80002884:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002886:	00005717          	auipc	a4,0x5
    8000288a:	80a70713          	addi	a4,a4,-2038 # 80007090 <userret>
    8000288e:	8f11                	sub	a4,a4,a2
    80002890:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002892:	577d                	li	a4,-1
    80002894:	177e                	slli	a4,a4,0x3f
    80002896:	8dd9                	or	a1,a1,a4
    80002898:	02000537          	lui	a0,0x2000
    8000289c:	157d                	addi	a0,a0,-1
    8000289e:	0536                	slli	a0,a0,0xd
    800028a0:	9782                	jalr	a5
}
    800028a2:	60a2                	ld	ra,8(sp)
    800028a4:	6402                	ld	s0,0(sp)
    800028a6:	0141                	addi	sp,sp,16
    800028a8:	8082                	ret

00000000800028aa <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028aa:	1101                	addi	sp,sp,-32
    800028ac:	ec06                	sd	ra,24(sp)
    800028ae:	e822                	sd	s0,16(sp)
    800028b0:	e426                	sd	s1,8(sp)
    800028b2:	e04a                	sd	s2,0(sp)
    800028b4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028b6:	00015917          	auipc	s2,0x15
    800028ba:	c1a90913          	addi	s2,s2,-998 # 800174d0 <tickslock>
    800028be:	854a                	mv	a0,s2
    800028c0:	ffffe097          	auipc	ra,0xffffe
    800028c4:	324080e7          	jalr	804(ra) # 80000be4 <acquire>
  ticks++;
    800028c8:	00006497          	auipc	s1,0x6
    800028cc:	76848493          	addi	s1,s1,1896 # 80009030 <ticks>
    800028d0:	409c                	lw	a5,0(s1)
    800028d2:	2785                	addiw	a5,a5,1
    800028d4:	c09c                	sw	a5,0(s1)
  increaseRuntime();
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	e2e080e7          	jalr	-466(ra) # 80002704 <increaseRuntime>
  wakeup(&ticks);
    800028de:	8526                	mv	a0,s1
    800028e0:	00000097          	auipc	ra,0x0
    800028e4:	948080e7          	jalr	-1720(ra) # 80002228 <wakeup>
  release(&tickslock);
    800028e8:	854a                	mv	a0,s2
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	3ae080e7          	jalr	942(ra) # 80000c98 <release>
}
    800028f2:	60e2                	ld	ra,24(sp)
    800028f4:	6442                	ld	s0,16(sp)
    800028f6:	64a2                	ld	s1,8(sp)
    800028f8:	6902                	ld	s2,0(sp)
    800028fa:	6105                	addi	sp,sp,32
    800028fc:	8082                	ret

00000000800028fe <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028fe:	1101                	addi	sp,sp,-32
    80002900:	ec06                	sd	ra,24(sp)
    80002902:	e822                	sd	s0,16(sp)
    80002904:	e426                	sd	s1,8(sp)
    80002906:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002908:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000290c:	00074d63          	bltz	a4,80002926 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002910:	57fd                	li	a5,-1
    80002912:	17fe                	slli	a5,a5,0x3f
    80002914:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002916:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002918:	06f70363          	beq	a4,a5,8000297e <devintr+0x80>
  }
}
    8000291c:	60e2                	ld	ra,24(sp)
    8000291e:	6442                	ld	s0,16(sp)
    80002920:	64a2                	ld	s1,8(sp)
    80002922:	6105                	addi	sp,sp,32
    80002924:	8082                	ret
     (scause & 0xff) == 9){
    80002926:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000292a:	46a5                	li	a3,9
    8000292c:	fed792e3          	bne	a5,a3,80002910 <devintr+0x12>
    int irq = plic_claim();
    80002930:	00003097          	auipc	ra,0x3
    80002934:	588080e7          	jalr	1416(ra) # 80005eb8 <plic_claim>
    80002938:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000293a:	47a9                	li	a5,10
    8000293c:	02f50763          	beq	a0,a5,8000296a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002940:	4785                	li	a5,1
    80002942:	02f50963          	beq	a0,a5,80002974 <devintr+0x76>
    return 1;
    80002946:	4505                	li	a0,1
    } else if(irq){
    80002948:	d8f1                	beqz	s1,8000291c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000294a:	85a6                	mv	a1,s1
    8000294c:	00006517          	auipc	a0,0x6
    80002950:	9ac50513          	addi	a0,a0,-1620 # 800082f8 <states.1719+0x38>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	c34080e7          	jalr	-972(ra) # 80000588 <printf>
      plic_complete(irq);
    8000295c:	8526                	mv	a0,s1
    8000295e:	00003097          	auipc	ra,0x3
    80002962:	57e080e7          	jalr	1406(ra) # 80005edc <plic_complete>
    return 1;
    80002966:	4505                	li	a0,1
    80002968:	bf55                	j	8000291c <devintr+0x1e>
      uartintr();
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	03e080e7          	jalr	62(ra) # 800009a8 <uartintr>
    80002972:	b7ed                	j	8000295c <devintr+0x5e>
      virtio_disk_intr();
    80002974:	00004097          	auipc	ra,0x4
    80002978:	a48080e7          	jalr	-1464(ra) # 800063bc <virtio_disk_intr>
    8000297c:	b7c5                	j	8000295c <devintr+0x5e>
    if(cpuid() == 0){
    8000297e:	fffff097          	auipc	ra,0xfffff
    80002982:	006080e7          	jalr	6(ra) # 80001984 <cpuid>
    80002986:	c901                	beqz	a0,80002996 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002988:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000298c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000298e:	14479073          	csrw	sip,a5
    return 2;
    80002992:	4509                	li	a0,2
    80002994:	b761                	j	8000291c <devintr+0x1e>
      clockintr();
    80002996:	00000097          	auipc	ra,0x0
    8000299a:	f14080e7          	jalr	-236(ra) # 800028aa <clockintr>
    8000299e:	b7ed                	j	80002988 <devintr+0x8a>

00000000800029a0 <usertrap>:
{
    800029a0:	1101                	addi	sp,sp,-32
    800029a2:	ec06                	sd	ra,24(sp)
    800029a4:	e822                	sd	s0,16(sp)
    800029a6:	e426                	sd	s1,8(sp)
    800029a8:	e04a                	sd	s2,0(sp)
    800029aa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ac:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029b0:	1007f793          	andi	a5,a5,256
    800029b4:	e3ad                	bnez	a5,80002a16 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029b6:	00003797          	auipc	a5,0x3
    800029ba:	3fa78793          	addi	a5,a5,1018 # 80005db0 <kernelvec>
    800029be:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	fee080e7          	jalr	-18(ra) # 800019b0 <myproc>
    800029ca:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029cc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ce:	14102773          	csrr	a4,sepc
    800029d2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029d4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029d8:	47a1                	li	a5,8
    800029da:	04f71c63          	bne	a4,a5,80002a32 <usertrap+0x92>
    if(p->killed)
    800029de:	551c                	lw	a5,40(a0)
    800029e0:	e3b9                	bnez	a5,80002a26 <usertrap+0x86>
    p->trapframe->epc += 4;
    800029e2:	6cb8                	ld	a4,88(s1)
    800029e4:	6f1c                	ld	a5,24(a4)
    800029e6:	0791                	addi	a5,a5,4
    800029e8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029ee:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029f2:	10079073          	csrw	sstatus,a5
    syscall();
    800029f6:	00000097          	auipc	ra,0x0
    800029fa:	2e0080e7          	jalr	736(ra) # 80002cd6 <syscall>
  if(p->killed)
    800029fe:	549c                	lw	a5,40(s1)
    80002a00:	ebc1                	bnez	a5,80002a90 <usertrap+0xf0>
  usertrapret();
    80002a02:	00000097          	auipc	ra,0x0
    80002a06:	e0a080e7          	jalr	-502(ra) # 8000280c <usertrapret>
}
    80002a0a:	60e2                	ld	ra,24(sp)
    80002a0c:	6442                	ld	s0,16(sp)
    80002a0e:	64a2                	ld	s1,8(sp)
    80002a10:	6902                	ld	s2,0(sp)
    80002a12:	6105                	addi	sp,sp,32
    80002a14:	8082                	ret
    panic("usertrap: not from user mode");
    80002a16:	00006517          	auipc	a0,0x6
    80002a1a:	90250513          	addi	a0,a0,-1790 # 80008318 <states.1719+0x58>
    80002a1e:	ffffe097          	auipc	ra,0xffffe
    80002a22:	b20080e7          	jalr	-1248(ra) # 8000053e <panic>
      exit(-1);
    80002a26:	557d                	li	a0,-1
    80002a28:	00000097          	auipc	ra,0x0
    80002a2c:	8d0080e7          	jalr	-1840(ra) # 800022f8 <exit>
    80002a30:	bf4d                	j	800029e2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a32:	00000097          	auipc	ra,0x0
    80002a36:	ecc080e7          	jalr	-308(ra) # 800028fe <devintr>
    80002a3a:	892a                	mv	s2,a0
    80002a3c:	c501                	beqz	a0,80002a44 <usertrap+0xa4>
  if(p->killed)
    80002a3e:	549c                	lw	a5,40(s1)
    80002a40:	c3a1                	beqz	a5,80002a80 <usertrap+0xe0>
    80002a42:	a815                	j	80002a76 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a44:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a48:	5890                	lw	a2,48(s1)
    80002a4a:	00006517          	auipc	a0,0x6
    80002a4e:	8ee50513          	addi	a0,a0,-1810 # 80008338 <states.1719+0x78>
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	b36080e7          	jalr	-1226(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a5a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a5e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	90650513          	addi	a0,a0,-1786 # 80008368 <states.1719+0xa8>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	b1e080e7          	jalr	-1250(ra) # 80000588 <printf>
    p->killed = 1;
    80002a72:	4785                	li	a5,1
    80002a74:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a76:	557d                	li	a0,-1
    80002a78:	00000097          	auipc	ra,0x0
    80002a7c:	880080e7          	jalr	-1920(ra) # 800022f8 <exit>
  if(which_dev == 2)
    80002a80:	4789                	li	a5,2
    80002a82:	f8f910e3          	bne	s2,a5,80002a02 <usertrap+0x62>
    yield();
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	5da080e7          	jalr	1498(ra) # 80002060 <yield>
    80002a8e:	bf95                	j	80002a02 <usertrap+0x62>
  int which_dev = 0;
    80002a90:	4901                	li	s2,0
    80002a92:	b7d5                	j	80002a76 <usertrap+0xd6>

0000000080002a94 <kerneltrap>:
{
    80002a94:	7179                	addi	sp,sp,-48
    80002a96:	f406                	sd	ra,40(sp)
    80002a98:	f022                	sd	s0,32(sp)
    80002a9a:	ec26                	sd	s1,24(sp)
    80002a9c:	e84a                	sd	s2,16(sp)
    80002a9e:	e44e                	sd	s3,8(sp)
    80002aa0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aa2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aaa:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002aae:	1004f793          	andi	a5,s1,256
    80002ab2:	cb85                	beqz	a5,80002ae2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ab8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002aba:	ef85                	bnez	a5,80002af2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002abc:	00000097          	auipc	ra,0x0
    80002ac0:	e42080e7          	jalr	-446(ra) # 800028fe <devintr>
    80002ac4:	cd1d                	beqz	a0,80002b02 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ac6:	4789                	li	a5,2
    80002ac8:	06f50a63          	beq	a0,a5,80002b3c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002acc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ad0:	10049073          	csrw	sstatus,s1
}
    80002ad4:	70a2                	ld	ra,40(sp)
    80002ad6:	7402                	ld	s0,32(sp)
    80002ad8:	64e2                	ld	s1,24(sp)
    80002ada:	6942                	ld	s2,16(sp)
    80002adc:	69a2                	ld	s3,8(sp)
    80002ade:	6145                	addi	sp,sp,48
    80002ae0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ae2:	00006517          	auipc	a0,0x6
    80002ae6:	8a650513          	addi	a0,a0,-1882 # 80008388 <states.1719+0xc8>
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	a54080e7          	jalr	-1452(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002af2:	00006517          	auipc	a0,0x6
    80002af6:	8be50513          	addi	a0,a0,-1858 # 800083b0 <states.1719+0xf0>
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	a44080e7          	jalr	-1468(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b02:	85ce                	mv	a1,s3
    80002b04:	00006517          	auipc	a0,0x6
    80002b08:	8cc50513          	addi	a0,a0,-1844 # 800083d0 <states.1719+0x110>
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	a7c080e7          	jalr	-1412(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b14:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b18:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b1c:	00006517          	auipc	a0,0x6
    80002b20:	8c450513          	addi	a0,a0,-1852 # 800083e0 <states.1719+0x120>
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	a64080e7          	jalr	-1436(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b2c:	00006517          	auipc	a0,0x6
    80002b30:	8cc50513          	addi	a0,a0,-1844 # 800083f8 <states.1719+0x138>
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	a0a080e7          	jalr	-1526(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	e74080e7          	jalr	-396(ra) # 800019b0 <myproc>
    80002b44:	d541                	beqz	a0,80002acc <kerneltrap+0x38>
    80002b46:	fffff097          	auipc	ra,0xfffff
    80002b4a:	e6a080e7          	jalr	-406(ra) # 800019b0 <myproc>
    80002b4e:	4d18                	lw	a4,24(a0)
    80002b50:	4791                	li	a5,4
    80002b52:	f6f71de3          	bne	a4,a5,80002acc <kerneltrap+0x38>
    yield();
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	50a080e7          	jalr	1290(ra) # 80002060 <yield>
    80002b5e:	b7bd                	j	80002acc <kerneltrap+0x38>

0000000080002b60 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b60:	1101                	addi	sp,sp,-32
    80002b62:	ec06                	sd	ra,24(sp)
    80002b64:	e822                	sd	s0,16(sp)
    80002b66:	e426                	sd	s1,8(sp)
    80002b68:	1000                	addi	s0,sp,32
    80002b6a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b6c:	fffff097          	auipc	ra,0xfffff
    80002b70:	e44080e7          	jalr	-444(ra) # 800019b0 <myproc>
  switch (n) {
    80002b74:	4795                	li	a5,5
    80002b76:	0497e163          	bltu	a5,s1,80002bb8 <argraw+0x58>
    80002b7a:	048a                	slli	s1,s1,0x2
    80002b7c:	00006717          	auipc	a4,0x6
    80002b80:	97470713          	addi	a4,a4,-1676 # 800084f0 <states.1719+0x230>
    80002b84:	94ba                	add	s1,s1,a4
    80002b86:	409c                	lw	a5,0(s1)
    80002b88:	97ba                	add	a5,a5,a4
    80002b8a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b8c:	6d3c                	ld	a5,88(a0)
    80002b8e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b90:	60e2                	ld	ra,24(sp)
    80002b92:	6442                	ld	s0,16(sp)
    80002b94:	64a2                	ld	s1,8(sp)
    80002b96:	6105                	addi	sp,sp,32
    80002b98:	8082                	ret
    return p->trapframe->a1;
    80002b9a:	6d3c                	ld	a5,88(a0)
    80002b9c:	7fa8                	ld	a0,120(a5)
    80002b9e:	bfcd                	j	80002b90 <argraw+0x30>
    return p->trapframe->a2;
    80002ba0:	6d3c                	ld	a5,88(a0)
    80002ba2:	63c8                	ld	a0,128(a5)
    80002ba4:	b7f5                	j	80002b90 <argraw+0x30>
    return p->trapframe->a3;
    80002ba6:	6d3c                	ld	a5,88(a0)
    80002ba8:	67c8                	ld	a0,136(a5)
    80002baa:	b7dd                	j	80002b90 <argraw+0x30>
    return p->trapframe->a4;
    80002bac:	6d3c                	ld	a5,88(a0)
    80002bae:	6bc8                	ld	a0,144(a5)
    80002bb0:	b7c5                	j	80002b90 <argraw+0x30>
    return p->trapframe->a5;
    80002bb2:	6d3c                	ld	a5,88(a0)
    80002bb4:	6fc8                	ld	a0,152(a5)
    80002bb6:	bfe9                	j	80002b90 <argraw+0x30>
  panic("argraw");
    80002bb8:	00006517          	auipc	a0,0x6
    80002bbc:	85050513          	addi	a0,a0,-1968 # 80008408 <states.1719+0x148>
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	97e080e7          	jalr	-1666(ra) # 8000053e <panic>

0000000080002bc8 <fetchaddr>:
{
    80002bc8:	1101                	addi	sp,sp,-32
    80002bca:	ec06                	sd	ra,24(sp)
    80002bcc:	e822                	sd	s0,16(sp)
    80002bce:	e426                	sd	s1,8(sp)
    80002bd0:	e04a                	sd	s2,0(sp)
    80002bd2:	1000                	addi	s0,sp,32
    80002bd4:	84aa                	mv	s1,a0
    80002bd6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bd8:	fffff097          	auipc	ra,0xfffff
    80002bdc:	dd8080e7          	jalr	-552(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002be0:	653c                	ld	a5,72(a0)
    80002be2:	02f4f863          	bgeu	s1,a5,80002c12 <fetchaddr+0x4a>
    80002be6:	00848713          	addi	a4,s1,8
    80002bea:	02e7e663          	bltu	a5,a4,80002c16 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bee:	46a1                	li	a3,8
    80002bf0:	8626                	mv	a2,s1
    80002bf2:	85ca                	mv	a1,s2
    80002bf4:	6928                	ld	a0,80(a0)
    80002bf6:	fffff097          	auipc	ra,0xfffff
    80002bfa:	b08080e7          	jalr	-1272(ra) # 800016fe <copyin>
    80002bfe:	00a03533          	snez	a0,a0
    80002c02:	40a00533          	neg	a0,a0
}
    80002c06:	60e2                	ld	ra,24(sp)
    80002c08:	6442                	ld	s0,16(sp)
    80002c0a:	64a2                	ld	s1,8(sp)
    80002c0c:	6902                	ld	s2,0(sp)
    80002c0e:	6105                	addi	sp,sp,32
    80002c10:	8082                	ret
    return -1;
    80002c12:	557d                	li	a0,-1
    80002c14:	bfcd                	j	80002c06 <fetchaddr+0x3e>
    80002c16:	557d                	li	a0,-1
    80002c18:	b7fd                	j	80002c06 <fetchaddr+0x3e>

0000000080002c1a <fetchstr>:
{
    80002c1a:	7179                	addi	sp,sp,-48
    80002c1c:	f406                	sd	ra,40(sp)
    80002c1e:	f022                	sd	s0,32(sp)
    80002c20:	ec26                	sd	s1,24(sp)
    80002c22:	e84a                	sd	s2,16(sp)
    80002c24:	e44e                	sd	s3,8(sp)
    80002c26:	1800                	addi	s0,sp,48
    80002c28:	892a                	mv	s2,a0
    80002c2a:	84ae                	mv	s1,a1
    80002c2c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c2e:	fffff097          	auipc	ra,0xfffff
    80002c32:	d82080e7          	jalr	-638(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c36:	86ce                	mv	a3,s3
    80002c38:	864a                	mv	a2,s2
    80002c3a:	85a6                	mv	a1,s1
    80002c3c:	6928                	ld	a0,80(a0)
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	b4c080e7          	jalr	-1204(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002c46:	00054763          	bltz	a0,80002c54 <fetchstr+0x3a>
  return strlen(buf);
    80002c4a:	8526                	mv	a0,s1
    80002c4c:	ffffe097          	auipc	ra,0xffffe
    80002c50:	218080e7          	jalr	536(ra) # 80000e64 <strlen>
}
    80002c54:	70a2                	ld	ra,40(sp)
    80002c56:	7402                	ld	s0,32(sp)
    80002c58:	64e2                	ld	s1,24(sp)
    80002c5a:	6942                	ld	s2,16(sp)
    80002c5c:	69a2                	ld	s3,8(sp)
    80002c5e:	6145                	addi	sp,sp,48
    80002c60:	8082                	ret

0000000080002c62 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c62:	1101                	addi	sp,sp,-32
    80002c64:	ec06                	sd	ra,24(sp)
    80002c66:	e822                	sd	s0,16(sp)
    80002c68:	e426                	sd	s1,8(sp)
    80002c6a:	1000                	addi	s0,sp,32
    80002c6c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c6e:	00000097          	auipc	ra,0x0
    80002c72:	ef2080e7          	jalr	-270(ra) # 80002b60 <argraw>
    80002c76:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c78:	4501                	li	a0,0
    80002c7a:	60e2                	ld	ra,24(sp)
    80002c7c:	6442                	ld	s0,16(sp)
    80002c7e:	64a2                	ld	s1,8(sp)
    80002c80:	6105                	addi	sp,sp,32
    80002c82:	8082                	ret

0000000080002c84 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c84:	1101                	addi	sp,sp,-32
    80002c86:	ec06                	sd	ra,24(sp)
    80002c88:	e822                	sd	s0,16(sp)
    80002c8a:	e426                	sd	s1,8(sp)
    80002c8c:	1000                	addi	s0,sp,32
    80002c8e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c90:	00000097          	auipc	ra,0x0
    80002c94:	ed0080e7          	jalr	-304(ra) # 80002b60 <argraw>
    80002c98:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c9a:	4501                	li	a0,0
    80002c9c:	60e2                	ld	ra,24(sp)
    80002c9e:	6442                	ld	s0,16(sp)
    80002ca0:	64a2                	ld	s1,8(sp)
    80002ca2:	6105                	addi	sp,sp,32
    80002ca4:	8082                	ret

0000000080002ca6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ca6:	1101                	addi	sp,sp,-32
    80002ca8:	ec06                	sd	ra,24(sp)
    80002caa:	e822                	sd	s0,16(sp)
    80002cac:	e426                	sd	s1,8(sp)
    80002cae:	e04a                	sd	s2,0(sp)
    80002cb0:	1000                	addi	s0,sp,32
    80002cb2:	84ae                	mv	s1,a1
    80002cb4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cb6:	00000097          	auipc	ra,0x0
    80002cba:	eaa080e7          	jalr	-342(ra) # 80002b60 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cbe:	864a                	mv	a2,s2
    80002cc0:	85a6                	mv	a1,s1
    80002cc2:	00000097          	auipc	ra,0x0
    80002cc6:	f58080e7          	jalr	-168(ra) # 80002c1a <fetchstr>
}
    80002cca:	60e2                	ld	ra,24(sp)
    80002ccc:	6442                	ld	s0,16(sp)
    80002cce:	64a2                	ld	s1,8(sp)
    80002cd0:	6902                	ld	s2,0(sp)
    80002cd2:	6105                	addi	sp,sp,32
    80002cd4:	8082                	ret

0000000080002cd6 <syscall>:

static char *syscallNames[] = { "", "fork", "exit", "wait", "pipe", "read", "kill", "exec", "fstat", "chdir", "dup", "getpid", "sbrk", "sleep", "uptime", "open", "write", "mknod", "unlink", "link", "mkdir", "close", "strace"};

void
syscall(void)
{
    80002cd6:	7179                	addi	sp,sp,-48
    80002cd8:	f406                	sd	ra,40(sp)
    80002cda:	f022                	sd	s0,32(sp)
    80002cdc:	ec26                	sd	s1,24(sp)
    80002cde:	e84a                	sd	s2,16(sp)
    80002ce0:	e44e                	sd	s3,8(sp)
    80002ce2:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	ccc080e7          	jalr	-820(ra) # 800019b0 <myproc>
    80002cec:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cee:	05853903          	ld	s2,88(a0)
    80002cf2:	0a893783          	ld	a5,168(s2)
    80002cf6:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cfa:	37fd                	addiw	a5,a5,-1
    80002cfc:	4759                	li	a4,22
    80002cfe:	04f76863          	bltu	a4,a5,80002d4e <syscall+0x78>
    80002d02:	00399713          	slli	a4,s3,0x3
    80002d06:	00006797          	auipc	a5,0x6
    80002d0a:	80278793          	addi	a5,a5,-2046 # 80008508 <syscalls>
    80002d0e:	97ba                	add	a5,a5,a4
    80002d10:	639c                	ld	a5,0(a5)
    80002d12:	cf95                	beqz	a5,80002d4e <syscall+0x78>
    p->trapframe->a0 = syscalls[num]();
    80002d14:	9782                	jalr	a5
    80002d16:	06a93823          	sd	a0,112(s2)
  
    if ((1 << num) & p -> mask) {
    80002d1a:	1744a783          	lw	a5,372(s1)
    80002d1e:	4137d7bb          	sraw	a5,a5,s3
    80002d22:	8b85                	andi	a5,a5,1
    80002d24:	c7a1                	beqz	a5,80002d6c <syscall+0x96>
      printf("%d: syscall %s -> %d\n", p->pid, syscallNames[num], p->trapframe->a0);
    80002d26:	6cb8                	ld	a4,88(s1)
    80002d28:	098e                	slli	s3,s3,0x3
    80002d2a:	00005797          	auipc	a5,0x5
    80002d2e:	7de78793          	addi	a5,a5,2014 # 80008508 <syscalls>
    80002d32:	99be                	add	s3,s3,a5
    80002d34:	7b34                	ld	a3,112(a4)
    80002d36:	0c09b603          	ld	a2,192(s3)
    80002d3a:	588c                	lw	a1,48(s1)
    80002d3c:	00005517          	auipc	a0,0x5
    80002d40:	6d450513          	addi	a0,a0,1748 # 80008410 <states.1719+0x150>
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	844080e7          	jalr	-1980(ra) # 80000588 <printf>
    80002d4c:	a005                	j	80002d6c <syscall+0x96>
      // for (int j = 0; j < p->)
    }
  } else {
    printf("%d %s: unknown sys call %d\n", p->pid, p->name, num);
    80002d4e:	86ce                	mv	a3,s3
    80002d50:	15848613          	addi	a2,s1,344
    80002d54:	588c                	lw	a1,48(s1)
    80002d56:	00005517          	auipc	a0,0x5
    80002d5a:	6d250513          	addi	a0,a0,1746 # 80008428 <states.1719+0x168>
    80002d5e:	ffffe097          	auipc	ra,0xffffe
    80002d62:	82a080e7          	jalr	-2006(ra) # 80000588 <printf>
    p->trapframe->a0 = -1;
    80002d66:	6cbc                	ld	a5,88(s1)
    80002d68:	577d                	li	a4,-1
    80002d6a:	fbb8                	sd	a4,112(a5)
  }
}
    80002d6c:	70a2                	ld	ra,40(sp)
    80002d6e:	7402                	ld	s0,32(sp)
    80002d70:	64e2                	ld	s1,24(sp)
    80002d72:	6942                	ld	s2,16(sp)
    80002d74:	69a2                	ld	s3,8(sp)
    80002d76:	6145                	addi	sp,sp,48
    80002d78:	8082                	ret

0000000080002d7a <sys_exit>:
#include "proc.h"
// #include "sysinfo.h"

uint64
sys_exit(void)
{
    80002d7a:	1101                	addi	sp,sp,-32
    80002d7c:	ec06                	sd	ra,24(sp)
    80002d7e:	e822                	sd	s0,16(sp)
    80002d80:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d82:	fec40593          	addi	a1,s0,-20
    80002d86:	4501                	li	a0,0
    80002d88:	00000097          	auipc	ra,0x0
    80002d8c:	eda080e7          	jalr	-294(ra) # 80002c62 <argint>
    return -1;
    80002d90:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d92:	00054963          	bltz	a0,80002da4 <sys_exit+0x2a>
  exit(n);
    80002d96:	fec42503          	lw	a0,-20(s0)
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	55e080e7          	jalr	1374(ra) # 800022f8 <exit>
  return 0;  // not reached
    80002da2:	4781                	li	a5,0
}
    80002da4:	853e                	mv	a0,a5
    80002da6:	60e2                	ld	ra,24(sp)
    80002da8:	6442                	ld	s0,16(sp)
    80002daa:	6105                	addi	sp,sp,32
    80002dac:	8082                	ret

0000000080002dae <sys_strace>:
//   return 0;
// }

uint64
sys_strace(void)
{
    80002dae:	1101                	addi	sp,sp,-32
    80002db0:	ec06                	sd	ra,24(sp)
    80002db2:	e822                	sd	s0,16(sp)
    80002db4:	1000                	addi	s0,sp,32
  int straceMask;

  int val = argint(0, &straceMask);
    80002db6:	fec40593          	addi	a1,s0,-20
    80002dba:	4501                	li	a0,0
    80002dbc:	00000097          	auipc	ra,0x0
    80002dc0:	ea6080e7          	jalr	-346(ra) # 80002c62 <argint>
  if (val < 0)
    return -1;
    80002dc4:	57fd                	li	a5,-1
  if (val < 0)
    80002dc6:	00054b63          	bltz	a0,80002ddc <sys_strace+0x2e>

  struct proc *p = myproc();
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	be6080e7          	jalr	-1050(ra) # 800019b0 <myproc>
  p->mask = straceMask;
    80002dd2:	fec42783          	lw	a5,-20(s0)
    80002dd6:	16f52a23          	sw	a5,372(a0)

  return 0;
    80002dda:	4781                	li	a5,0
}
    80002ddc:	853e                	mv	a0,a5
    80002dde:	60e2                	ld	ra,24(sp)
    80002de0:	6442                	ld	s0,16(sp)
    80002de2:	6105                	addi	sp,sp,32
    80002de4:	8082                	ret

0000000080002de6 <sys_getpid>:


uint64
sys_getpid(void)
{
    80002de6:	1141                	addi	sp,sp,-16
    80002de8:	e406                	sd	ra,8(sp)
    80002dea:	e022                	sd	s0,0(sp)
    80002dec:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	bc2080e7          	jalr	-1086(ra) # 800019b0 <myproc>
}
    80002df6:	5908                	lw	a0,48(a0)
    80002df8:	60a2                	ld	ra,8(sp)
    80002dfa:	6402                	ld	s0,0(sp)
    80002dfc:	0141                	addi	sp,sp,16
    80002dfe:	8082                	ret

0000000080002e00 <sys_fork>:

uint64
sys_fork(void)
{
    80002e00:	1141                	addi	sp,sp,-16
    80002e02:	e406                	sd	ra,8(sp)
    80002e04:	e022                	sd	s0,0(sp)
    80002e06:	0800                	addi	s0,sp,16
  // np->mask = p->mask;
  return fork();
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	f9e080e7          	jalr	-98(ra) # 80001da6 <fork>
}
    80002e10:	60a2                	ld	ra,8(sp)
    80002e12:	6402                	ld	s0,0(sp)
    80002e14:	0141                	addi	sp,sp,16
    80002e16:	8082                	ret

0000000080002e18 <sys_wait>:

uint64
sys_wait(void)
{
    80002e18:	1101                	addi	sp,sp,-32
    80002e1a:	ec06                	sd	ra,24(sp)
    80002e1c:	e822                	sd	s0,16(sp)
    80002e1e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e20:	fe840593          	addi	a1,s0,-24
    80002e24:	4501                	li	a0,0
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	e5e080e7          	jalr	-418(ra) # 80002c84 <argaddr>
    80002e2e:	87aa                	mv	a5,a0
    return -1;
    80002e30:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e32:	0007c863          	bltz	a5,80002e42 <sys_wait+0x2a>
  return wait(p);
    80002e36:	fe843503          	ld	a0,-24(s0)
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	2c6080e7          	jalr	710(ra) # 80002100 <wait>
}
    80002e42:	60e2                	ld	ra,24(sp)
    80002e44:	6442                	ld	s0,16(sp)
    80002e46:	6105                	addi	sp,sp,32
    80002e48:	8082                	ret

0000000080002e4a <sys_waitx>:

uint64
sys_waitx(void)
{
    80002e4a:	7139                	addi	sp,sp,-64
    80002e4c:	fc06                	sd	ra,56(sp)
    80002e4e:	f822                	sd	s0,48(sp)
    80002e50:	f426                	sd	s1,40(sp)
    80002e52:	f04a                	sd	s2,32(sp)
    80002e54:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    80002e56:	fd840593          	addi	a1,s0,-40
    80002e5a:	4501                	li	a0,0
    80002e5c:	00000097          	auipc	ra,0x0
    80002e60:	e28080e7          	jalr	-472(ra) # 80002c84 <argaddr>
    return -1;
    80002e64:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    80002e66:	08054063          	bltz	a0,80002ee6 <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80002e6a:	fd040593          	addi	a1,s0,-48
    80002e6e:	4505                	li	a0,1
    80002e70:	00000097          	auipc	ra,0x0
    80002e74:	e14080e7          	jalr	-492(ra) # 80002c84 <argaddr>
    return -1;
    80002e78:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80002e7a:	06054663          	bltz	a0,80002ee6 <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    80002e7e:	fc840593          	addi	a1,s0,-56
    80002e82:	4509                	li	a0,2
    80002e84:	00000097          	auipc	ra,0x0
    80002e88:	e00080e7          	jalr	-512(ra) # 80002c84 <argaddr>
    return -1;
    80002e8c:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    80002e8e:	04054c63          	bltz	a0,80002ee6 <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    80002e92:	fc040613          	addi	a2,s0,-64
    80002e96:	fc440593          	addi	a1,s0,-60
    80002e9a:	fd843503          	ld	a0,-40(s0)
    80002e9e:	fffff097          	auipc	ra,0xfffff
    80002ea2:	716080e7          	jalr	1814(ra) # 800025b4 <waitx>
    80002ea6:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	b08080e7          	jalr	-1272(ra) # 800019b0 <myproc>
    80002eb0:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002eb2:	4691                	li	a3,4
    80002eb4:	fc440613          	addi	a2,s0,-60
    80002eb8:	fd043583          	ld	a1,-48(s0)
    80002ebc:	6928                	ld	a0,80(a0)
    80002ebe:	ffffe097          	auipc	ra,0xffffe
    80002ec2:	7b4080e7          	jalr	1972(ra) # 80001672 <copyout>
    return -1;
    80002ec6:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002ec8:	00054f63          	bltz	a0,80002ee6 <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80002ecc:	4691                	li	a3,4
    80002ece:	fc040613          	addi	a2,s0,-64
    80002ed2:	fc843583          	ld	a1,-56(s0)
    80002ed6:	68a8                	ld	a0,80(s1)
    80002ed8:	ffffe097          	auipc	ra,0xffffe
    80002edc:	79a080e7          	jalr	1946(ra) # 80001672 <copyout>
    80002ee0:	00054a63          	bltz	a0,80002ef4 <sys_waitx+0xaa>
    return -1;
  return ret;
    80002ee4:	87ca                	mv	a5,s2
}
    80002ee6:	853e                	mv	a0,a5
    80002ee8:	70e2                	ld	ra,56(sp)
    80002eea:	7442                	ld	s0,48(sp)
    80002eec:	74a2                	ld	s1,40(sp)
    80002eee:	7902                	ld	s2,32(sp)
    80002ef0:	6121                	addi	sp,sp,64
    80002ef2:	8082                	ret
    return -1;
    80002ef4:	57fd                	li	a5,-1
    80002ef6:	bfc5                	j	80002ee6 <sys_waitx+0x9c>

0000000080002ef8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ef8:	7179                	addi	sp,sp,-48
    80002efa:	f406                	sd	ra,40(sp)
    80002efc:	f022                	sd	s0,32(sp)
    80002efe:	ec26                	sd	s1,24(sp)
    80002f00:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f02:	fdc40593          	addi	a1,s0,-36
    80002f06:	4501                	li	a0,0
    80002f08:	00000097          	auipc	ra,0x0
    80002f0c:	d5a080e7          	jalr	-678(ra) # 80002c62 <argint>
    80002f10:	87aa                	mv	a5,a0
    return -1;
    80002f12:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f14:	0207c063          	bltz	a5,80002f34 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	a98080e7          	jalr	-1384(ra) # 800019b0 <myproc>
    80002f20:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f22:	fdc42503          	lw	a0,-36(s0)
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	e0c080e7          	jalr	-500(ra) # 80001d32 <growproc>
    80002f2e:	00054863          	bltz	a0,80002f3e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f32:	8526                	mv	a0,s1
}
    80002f34:	70a2                	ld	ra,40(sp)
    80002f36:	7402                	ld	s0,32(sp)
    80002f38:	64e2                	ld	s1,24(sp)
    80002f3a:	6145                	addi	sp,sp,48
    80002f3c:	8082                	ret
    return -1;
    80002f3e:	557d                	li	a0,-1
    80002f40:	bfd5                	j	80002f34 <sys_sbrk+0x3c>

0000000080002f42 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f42:	7139                	addi	sp,sp,-64
    80002f44:	fc06                	sd	ra,56(sp)
    80002f46:	f822                	sd	s0,48(sp)
    80002f48:	f426                	sd	s1,40(sp)
    80002f4a:	f04a                	sd	s2,32(sp)
    80002f4c:	ec4e                	sd	s3,24(sp)
    80002f4e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f50:	fcc40593          	addi	a1,s0,-52
    80002f54:	4501                	li	a0,0
    80002f56:	00000097          	auipc	ra,0x0
    80002f5a:	d0c080e7          	jalr	-756(ra) # 80002c62 <argint>
    return -1;
    80002f5e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f60:	06054563          	bltz	a0,80002fca <sys_sleep+0x88>
  acquire(&tickslock);
    80002f64:	00014517          	auipc	a0,0x14
    80002f68:	56c50513          	addi	a0,a0,1388 # 800174d0 <tickslock>
    80002f6c:	ffffe097          	auipc	ra,0xffffe
    80002f70:	c78080e7          	jalr	-904(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f74:	00006917          	auipc	s2,0x6
    80002f78:	0bc92903          	lw	s2,188(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002f7c:	fcc42783          	lw	a5,-52(s0)
    80002f80:	cf85                	beqz	a5,80002fb8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f82:	00014997          	auipc	s3,0x14
    80002f86:	54e98993          	addi	s3,s3,1358 # 800174d0 <tickslock>
    80002f8a:	00006497          	auipc	s1,0x6
    80002f8e:	0a648493          	addi	s1,s1,166 # 80009030 <ticks>
    if(myproc()->killed){
    80002f92:	fffff097          	auipc	ra,0xfffff
    80002f96:	a1e080e7          	jalr	-1506(ra) # 800019b0 <myproc>
    80002f9a:	551c                	lw	a5,40(a0)
    80002f9c:	ef9d                	bnez	a5,80002fda <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f9e:	85ce                	mv	a1,s3
    80002fa0:	8526                	mv	a0,s1
    80002fa2:	fffff097          	auipc	ra,0xfffff
    80002fa6:	0fa080e7          	jalr	250(ra) # 8000209c <sleep>
  while(ticks - ticks0 < n){
    80002faa:	409c                	lw	a5,0(s1)
    80002fac:	412787bb          	subw	a5,a5,s2
    80002fb0:	fcc42703          	lw	a4,-52(s0)
    80002fb4:	fce7efe3          	bltu	a5,a4,80002f92 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002fb8:	00014517          	auipc	a0,0x14
    80002fbc:	51850513          	addi	a0,a0,1304 # 800174d0 <tickslock>
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	cd8080e7          	jalr	-808(ra) # 80000c98 <release>
  return 0;
    80002fc8:	4781                	li	a5,0
}
    80002fca:	853e                	mv	a0,a5
    80002fcc:	70e2                	ld	ra,56(sp)
    80002fce:	7442                	ld	s0,48(sp)
    80002fd0:	74a2                	ld	s1,40(sp)
    80002fd2:	7902                	ld	s2,32(sp)
    80002fd4:	69e2                	ld	s3,24(sp)
    80002fd6:	6121                	addi	sp,sp,64
    80002fd8:	8082                	ret
      release(&tickslock);
    80002fda:	00014517          	auipc	a0,0x14
    80002fde:	4f650513          	addi	a0,a0,1270 # 800174d0 <tickslock>
    80002fe2:	ffffe097          	auipc	ra,0xffffe
    80002fe6:	cb6080e7          	jalr	-842(ra) # 80000c98 <release>
      return -1;
    80002fea:	57fd                	li	a5,-1
    80002fec:	bff9                	j	80002fca <sys_sleep+0x88>

0000000080002fee <sys_kill>:

uint64
sys_kill(void)
{
    80002fee:	1101                	addi	sp,sp,-32
    80002ff0:	ec06                	sd	ra,24(sp)
    80002ff2:	e822                	sd	s0,16(sp)
    80002ff4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ff6:	fec40593          	addi	a1,s0,-20
    80002ffa:	4501                	li	a0,0
    80002ffc:	00000097          	auipc	ra,0x0
    80003000:	c66080e7          	jalr	-922(ra) # 80002c62 <argint>
    80003004:	87aa                	mv	a5,a0
    return -1;
    80003006:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003008:	0007c863          	bltz	a5,80003018 <sys_kill+0x2a>
  return kill(pid);
    8000300c:	fec42503          	lw	a0,-20(s0)
    80003010:	fffff097          	auipc	ra,0xfffff
    80003014:	3d8080e7          	jalr	984(ra) # 800023e8 <kill>
}
    80003018:	60e2                	ld	ra,24(sp)
    8000301a:	6442                	ld	s0,16(sp)
    8000301c:	6105                	addi	sp,sp,32
    8000301e:	8082                	ret

0000000080003020 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003020:	1101                	addi	sp,sp,-32
    80003022:	ec06                	sd	ra,24(sp)
    80003024:	e822                	sd	s0,16(sp)
    80003026:	e426                	sd	s1,8(sp)
    80003028:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000302a:	00014517          	auipc	a0,0x14
    8000302e:	4a650513          	addi	a0,a0,1190 # 800174d0 <tickslock>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	bb2080e7          	jalr	-1102(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000303a:	00006497          	auipc	s1,0x6
    8000303e:	ff64a483          	lw	s1,-10(s1) # 80009030 <ticks>
  release(&tickslock);
    80003042:	00014517          	auipc	a0,0x14
    80003046:	48e50513          	addi	a0,a0,1166 # 800174d0 <tickslock>
    8000304a:	ffffe097          	auipc	ra,0xffffe
    8000304e:	c4e080e7          	jalr	-946(ra) # 80000c98 <release>
  return xticks;
}
    80003052:	02049513          	slli	a0,s1,0x20
    80003056:	9101                	srli	a0,a0,0x20
    80003058:	60e2                	ld	ra,24(sp)
    8000305a:	6442                	ld	s0,16(sp)
    8000305c:	64a2                	ld	s1,8(sp)
    8000305e:	6105                	addi	sp,sp,32
    80003060:	8082                	ret

0000000080003062 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003062:	7179                	addi	sp,sp,-48
    80003064:	f406                	sd	ra,40(sp)
    80003066:	f022                	sd	s0,32(sp)
    80003068:	ec26                	sd	s1,24(sp)
    8000306a:	e84a                	sd	s2,16(sp)
    8000306c:	e44e                	sd	s3,8(sp)
    8000306e:	e052                	sd	s4,0(sp)
    80003070:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003072:	00005597          	auipc	a1,0x5
    80003076:	60e58593          	addi	a1,a1,1550 # 80008680 <syscallNames+0xb8>
    8000307a:	00014517          	auipc	a0,0x14
    8000307e:	46e50513          	addi	a0,a0,1134 # 800174e8 <bcache>
    80003082:	ffffe097          	auipc	ra,0xffffe
    80003086:	ad2080e7          	jalr	-1326(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000308a:	0001c797          	auipc	a5,0x1c
    8000308e:	45e78793          	addi	a5,a5,1118 # 8001f4e8 <bcache+0x8000>
    80003092:	0001c717          	auipc	a4,0x1c
    80003096:	6be70713          	addi	a4,a4,1726 # 8001f750 <bcache+0x8268>
    8000309a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000309e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030a2:	00014497          	auipc	s1,0x14
    800030a6:	45e48493          	addi	s1,s1,1118 # 80017500 <bcache+0x18>
    b->next = bcache.head.next;
    800030aa:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030ac:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030ae:	00005a17          	auipc	s4,0x5
    800030b2:	5daa0a13          	addi	s4,s4,1498 # 80008688 <syscallNames+0xc0>
    b->next = bcache.head.next;
    800030b6:	2b893783          	ld	a5,696(s2)
    800030ba:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030bc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030c0:	85d2                	mv	a1,s4
    800030c2:	01048513          	addi	a0,s1,16
    800030c6:	00001097          	auipc	ra,0x1
    800030ca:	4bc080e7          	jalr	1212(ra) # 80004582 <initsleeplock>
    bcache.head.next->prev = b;
    800030ce:	2b893783          	ld	a5,696(s2)
    800030d2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030d4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030d8:	45848493          	addi	s1,s1,1112
    800030dc:	fd349de3          	bne	s1,s3,800030b6 <binit+0x54>
  }
}
    800030e0:	70a2                	ld	ra,40(sp)
    800030e2:	7402                	ld	s0,32(sp)
    800030e4:	64e2                	ld	s1,24(sp)
    800030e6:	6942                	ld	s2,16(sp)
    800030e8:	69a2                	ld	s3,8(sp)
    800030ea:	6a02                	ld	s4,0(sp)
    800030ec:	6145                	addi	sp,sp,48
    800030ee:	8082                	ret

00000000800030f0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030f0:	7179                	addi	sp,sp,-48
    800030f2:	f406                	sd	ra,40(sp)
    800030f4:	f022                	sd	s0,32(sp)
    800030f6:	ec26                	sd	s1,24(sp)
    800030f8:	e84a                	sd	s2,16(sp)
    800030fa:	e44e                	sd	s3,8(sp)
    800030fc:	1800                	addi	s0,sp,48
    800030fe:	89aa                	mv	s3,a0
    80003100:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003102:	00014517          	auipc	a0,0x14
    80003106:	3e650513          	addi	a0,a0,998 # 800174e8 <bcache>
    8000310a:	ffffe097          	auipc	ra,0xffffe
    8000310e:	ada080e7          	jalr	-1318(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003112:	0001c497          	auipc	s1,0x1c
    80003116:	68e4b483          	ld	s1,1678(s1) # 8001f7a0 <bcache+0x82b8>
    8000311a:	0001c797          	auipc	a5,0x1c
    8000311e:	63678793          	addi	a5,a5,1590 # 8001f750 <bcache+0x8268>
    80003122:	02f48f63          	beq	s1,a5,80003160 <bread+0x70>
    80003126:	873e                	mv	a4,a5
    80003128:	a021                	j	80003130 <bread+0x40>
    8000312a:	68a4                	ld	s1,80(s1)
    8000312c:	02e48a63          	beq	s1,a4,80003160 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003130:	449c                	lw	a5,8(s1)
    80003132:	ff379ce3          	bne	a5,s3,8000312a <bread+0x3a>
    80003136:	44dc                	lw	a5,12(s1)
    80003138:	ff2799e3          	bne	a5,s2,8000312a <bread+0x3a>
      b->refcnt++;
    8000313c:	40bc                	lw	a5,64(s1)
    8000313e:	2785                	addiw	a5,a5,1
    80003140:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003142:	00014517          	auipc	a0,0x14
    80003146:	3a650513          	addi	a0,a0,934 # 800174e8 <bcache>
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	b4e080e7          	jalr	-1202(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003152:	01048513          	addi	a0,s1,16
    80003156:	00001097          	auipc	ra,0x1
    8000315a:	466080e7          	jalr	1126(ra) # 800045bc <acquiresleep>
      return b;
    8000315e:	a8b9                	j	800031bc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003160:	0001c497          	auipc	s1,0x1c
    80003164:	6384b483          	ld	s1,1592(s1) # 8001f798 <bcache+0x82b0>
    80003168:	0001c797          	auipc	a5,0x1c
    8000316c:	5e878793          	addi	a5,a5,1512 # 8001f750 <bcache+0x8268>
    80003170:	00f48863          	beq	s1,a5,80003180 <bread+0x90>
    80003174:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003176:	40bc                	lw	a5,64(s1)
    80003178:	cf81                	beqz	a5,80003190 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000317a:	64a4                	ld	s1,72(s1)
    8000317c:	fee49de3          	bne	s1,a4,80003176 <bread+0x86>
  panic("bget: no buffers");
    80003180:	00005517          	auipc	a0,0x5
    80003184:	51050513          	addi	a0,a0,1296 # 80008690 <syscallNames+0xc8>
    80003188:	ffffd097          	auipc	ra,0xffffd
    8000318c:	3b6080e7          	jalr	950(ra) # 8000053e <panic>
      b->dev = dev;
    80003190:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003194:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003198:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000319c:	4785                	li	a5,1
    8000319e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031a0:	00014517          	auipc	a0,0x14
    800031a4:	34850513          	addi	a0,a0,840 # 800174e8 <bcache>
    800031a8:	ffffe097          	auipc	ra,0xffffe
    800031ac:	af0080e7          	jalr	-1296(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800031b0:	01048513          	addi	a0,s1,16
    800031b4:	00001097          	auipc	ra,0x1
    800031b8:	408080e7          	jalr	1032(ra) # 800045bc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031bc:	409c                	lw	a5,0(s1)
    800031be:	cb89                	beqz	a5,800031d0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031c0:	8526                	mv	a0,s1
    800031c2:	70a2                	ld	ra,40(sp)
    800031c4:	7402                	ld	s0,32(sp)
    800031c6:	64e2                	ld	s1,24(sp)
    800031c8:	6942                	ld	s2,16(sp)
    800031ca:	69a2                	ld	s3,8(sp)
    800031cc:	6145                	addi	sp,sp,48
    800031ce:	8082                	ret
    virtio_disk_rw(b, 0);
    800031d0:	4581                	li	a1,0
    800031d2:	8526                	mv	a0,s1
    800031d4:	00003097          	auipc	ra,0x3
    800031d8:	f12080e7          	jalr	-238(ra) # 800060e6 <virtio_disk_rw>
    b->valid = 1;
    800031dc:	4785                	li	a5,1
    800031de:	c09c                	sw	a5,0(s1)
  return b;
    800031e0:	b7c5                	j	800031c0 <bread+0xd0>

00000000800031e2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031e2:	1101                	addi	sp,sp,-32
    800031e4:	ec06                	sd	ra,24(sp)
    800031e6:	e822                	sd	s0,16(sp)
    800031e8:	e426                	sd	s1,8(sp)
    800031ea:	1000                	addi	s0,sp,32
    800031ec:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031ee:	0541                	addi	a0,a0,16
    800031f0:	00001097          	auipc	ra,0x1
    800031f4:	466080e7          	jalr	1126(ra) # 80004656 <holdingsleep>
    800031f8:	cd01                	beqz	a0,80003210 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031fa:	4585                	li	a1,1
    800031fc:	8526                	mv	a0,s1
    800031fe:	00003097          	auipc	ra,0x3
    80003202:	ee8080e7          	jalr	-280(ra) # 800060e6 <virtio_disk_rw>
}
    80003206:	60e2                	ld	ra,24(sp)
    80003208:	6442                	ld	s0,16(sp)
    8000320a:	64a2                	ld	s1,8(sp)
    8000320c:	6105                	addi	sp,sp,32
    8000320e:	8082                	ret
    panic("bwrite");
    80003210:	00005517          	auipc	a0,0x5
    80003214:	49850513          	addi	a0,a0,1176 # 800086a8 <syscallNames+0xe0>
    80003218:	ffffd097          	auipc	ra,0xffffd
    8000321c:	326080e7          	jalr	806(ra) # 8000053e <panic>

0000000080003220 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003220:	1101                	addi	sp,sp,-32
    80003222:	ec06                	sd	ra,24(sp)
    80003224:	e822                	sd	s0,16(sp)
    80003226:	e426                	sd	s1,8(sp)
    80003228:	e04a                	sd	s2,0(sp)
    8000322a:	1000                	addi	s0,sp,32
    8000322c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000322e:	01050913          	addi	s2,a0,16
    80003232:	854a                	mv	a0,s2
    80003234:	00001097          	auipc	ra,0x1
    80003238:	422080e7          	jalr	1058(ra) # 80004656 <holdingsleep>
    8000323c:	c92d                	beqz	a0,800032ae <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000323e:	854a                	mv	a0,s2
    80003240:	00001097          	auipc	ra,0x1
    80003244:	3d2080e7          	jalr	978(ra) # 80004612 <releasesleep>

  acquire(&bcache.lock);
    80003248:	00014517          	auipc	a0,0x14
    8000324c:	2a050513          	addi	a0,a0,672 # 800174e8 <bcache>
    80003250:	ffffe097          	auipc	ra,0xffffe
    80003254:	994080e7          	jalr	-1644(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003258:	40bc                	lw	a5,64(s1)
    8000325a:	37fd                	addiw	a5,a5,-1
    8000325c:	0007871b          	sext.w	a4,a5
    80003260:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003262:	eb05                	bnez	a4,80003292 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003264:	68bc                	ld	a5,80(s1)
    80003266:	64b8                	ld	a4,72(s1)
    80003268:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000326a:	64bc                	ld	a5,72(s1)
    8000326c:	68b8                	ld	a4,80(s1)
    8000326e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003270:	0001c797          	auipc	a5,0x1c
    80003274:	27878793          	addi	a5,a5,632 # 8001f4e8 <bcache+0x8000>
    80003278:	2b87b703          	ld	a4,696(a5)
    8000327c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000327e:	0001c717          	auipc	a4,0x1c
    80003282:	4d270713          	addi	a4,a4,1234 # 8001f750 <bcache+0x8268>
    80003286:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003288:	2b87b703          	ld	a4,696(a5)
    8000328c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000328e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003292:	00014517          	auipc	a0,0x14
    80003296:	25650513          	addi	a0,a0,598 # 800174e8 <bcache>
    8000329a:	ffffe097          	auipc	ra,0xffffe
    8000329e:	9fe080e7          	jalr	-1538(ra) # 80000c98 <release>
}
    800032a2:	60e2                	ld	ra,24(sp)
    800032a4:	6442                	ld	s0,16(sp)
    800032a6:	64a2                	ld	s1,8(sp)
    800032a8:	6902                	ld	s2,0(sp)
    800032aa:	6105                	addi	sp,sp,32
    800032ac:	8082                	ret
    panic("brelse");
    800032ae:	00005517          	auipc	a0,0x5
    800032b2:	40250513          	addi	a0,a0,1026 # 800086b0 <syscallNames+0xe8>
    800032b6:	ffffd097          	auipc	ra,0xffffd
    800032ba:	288080e7          	jalr	648(ra) # 8000053e <panic>

00000000800032be <bpin>:

void
bpin(struct buf *b) {
    800032be:	1101                	addi	sp,sp,-32
    800032c0:	ec06                	sd	ra,24(sp)
    800032c2:	e822                	sd	s0,16(sp)
    800032c4:	e426                	sd	s1,8(sp)
    800032c6:	1000                	addi	s0,sp,32
    800032c8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032ca:	00014517          	auipc	a0,0x14
    800032ce:	21e50513          	addi	a0,a0,542 # 800174e8 <bcache>
    800032d2:	ffffe097          	auipc	ra,0xffffe
    800032d6:	912080e7          	jalr	-1774(ra) # 80000be4 <acquire>
  b->refcnt++;
    800032da:	40bc                	lw	a5,64(s1)
    800032dc:	2785                	addiw	a5,a5,1
    800032de:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032e0:	00014517          	auipc	a0,0x14
    800032e4:	20850513          	addi	a0,a0,520 # 800174e8 <bcache>
    800032e8:	ffffe097          	auipc	ra,0xffffe
    800032ec:	9b0080e7          	jalr	-1616(ra) # 80000c98 <release>
}
    800032f0:	60e2                	ld	ra,24(sp)
    800032f2:	6442                	ld	s0,16(sp)
    800032f4:	64a2                	ld	s1,8(sp)
    800032f6:	6105                	addi	sp,sp,32
    800032f8:	8082                	ret

00000000800032fa <bunpin>:

void
bunpin(struct buf *b) {
    800032fa:	1101                	addi	sp,sp,-32
    800032fc:	ec06                	sd	ra,24(sp)
    800032fe:	e822                	sd	s0,16(sp)
    80003300:	e426                	sd	s1,8(sp)
    80003302:	1000                	addi	s0,sp,32
    80003304:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003306:	00014517          	auipc	a0,0x14
    8000330a:	1e250513          	addi	a0,a0,482 # 800174e8 <bcache>
    8000330e:	ffffe097          	auipc	ra,0xffffe
    80003312:	8d6080e7          	jalr	-1834(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003316:	40bc                	lw	a5,64(s1)
    80003318:	37fd                	addiw	a5,a5,-1
    8000331a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000331c:	00014517          	auipc	a0,0x14
    80003320:	1cc50513          	addi	a0,a0,460 # 800174e8 <bcache>
    80003324:	ffffe097          	auipc	ra,0xffffe
    80003328:	974080e7          	jalr	-1676(ra) # 80000c98 <release>
}
    8000332c:	60e2                	ld	ra,24(sp)
    8000332e:	6442                	ld	s0,16(sp)
    80003330:	64a2                	ld	s1,8(sp)
    80003332:	6105                	addi	sp,sp,32
    80003334:	8082                	ret

0000000080003336 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003336:	1101                	addi	sp,sp,-32
    80003338:	ec06                	sd	ra,24(sp)
    8000333a:	e822                	sd	s0,16(sp)
    8000333c:	e426                	sd	s1,8(sp)
    8000333e:	e04a                	sd	s2,0(sp)
    80003340:	1000                	addi	s0,sp,32
    80003342:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003344:	00d5d59b          	srliw	a1,a1,0xd
    80003348:	0001d797          	auipc	a5,0x1d
    8000334c:	87c7a783          	lw	a5,-1924(a5) # 8001fbc4 <sb+0x1c>
    80003350:	9dbd                	addw	a1,a1,a5
    80003352:	00000097          	auipc	ra,0x0
    80003356:	d9e080e7          	jalr	-610(ra) # 800030f0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000335a:	0074f713          	andi	a4,s1,7
    8000335e:	4785                	li	a5,1
    80003360:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003364:	14ce                	slli	s1,s1,0x33
    80003366:	90d9                	srli	s1,s1,0x36
    80003368:	00950733          	add	a4,a0,s1
    8000336c:	05874703          	lbu	a4,88(a4)
    80003370:	00e7f6b3          	and	a3,a5,a4
    80003374:	c69d                	beqz	a3,800033a2 <bfree+0x6c>
    80003376:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003378:	94aa                	add	s1,s1,a0
    8000337a:	fff7c793          	not	a5,a5
    8000337e:	8ff9                	and	a5,a5,a4
    80003380:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003384:	00001097          	auipc	ra,0x1
    80003388:	118080e7          	jalr	280(ra) # 8000449c <log_write>
  brelse(bp);
    8000338c:	854a                	mv	a0,s2
    8000338e:	00000097          	auipc	ra,0x0
    80003392:	e92080e7          	jalr	-366(ra) # 80003220 <brelse>
}
    80003396:	60e2                	ld	ra,24(sp)
    80003398:	6442                	ld	s0,16(sp)
    8000339a:	64a2                	ld	s1,8(sp)
    8000339c:	6902                	ld	s2,0(sp)
    8000339e:	6105                	addi	sp,sp,32
    800033a0:	8082                	ret
    panic("freeing free block");
    800033a2:	00005517          	auipc	a0,0x5
    800033a6:	31650513          	addi	a0,a0,790 # 800086b8 <syscallNames+0xf0>
    800033aa:	ffffd097          	auipc	ra,0xffffd
    800033ae:	194080e7          	jalr	404(ra) # 8000053e <panic>

00000000800033b2 <balloc>:
{
    800033b2:	711d                	addi	sp,sp,-96
    800033b4:	ec86                	sd	ra,88(sp)
    800033b6:	e8a2                	sd	s0,80(sp)
    800033b8:	e4a6                	sd	s1,72(sp)
    800033ba:	e0ca                	sd	s2,64(sp)
    800033bc:	fc4e                	sd	s3,56(sp)
    800033be:	f852                	sd	s4,48(sp)
    800033c0:	f456                	sd	s5,40(sp)
    800033c2:	f05a                	sd	s6,32(sp)
    800033c4:	ec5e                	sd	s7,24(sp)
    800033c6:	e862                	sd	s8,16(sp)
    800033c8:	e466                	sd	s9,8(sp)
    800033ca:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033cc:	0001c797          	auipc	a5,0x1c
    800033d0:	7e07a783          	lw	a5,2016(a5) # 8001fbac <sb+0x4>
    800033d4:	cbd1                	beqz	a5,80003468 <balloc+0xb6>
    800033d6:	8baa                	mv	s7,a0
    800033d8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033da:	0001cb17          	auipc	s6,0x1c
    800033de:	7ceb0b13          	addi	s6,s6,1998 # 8001fba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033e2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033e4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033e6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033e8:	6c89                	lui	s9,0x2
    800033ea:	a831                	j	80003406 <balloc+0x54>
    brelse(bp);
    800033ec:	854a                	mv	a0,s2
    800033ee:	00000097          	auipc	ra,0x0
    800033f2:	e32080e7          	jalr	-462(ra) # 80003220 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033f6:	015c87bb          	addw	a5,s9,s5
    800033fa:	00078a9b          	sext.w	s5,a5
    800033fe:	004b2703          	lw	a4,4(s6)
    80003402:	06eaf363          	bgeu	s5,a4,80003468 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003406:	41fad79b          	sraiw	a5,s5,0x1f
    8000340a:	0137d79b          	srliw	a5,a5,0x13
    8000340e:	015787bb          	addw	a5,a5,s5
    80003412:	40d7d79b          	sraiw	a5,a5,0xd
    80003416:	01cb2583          	lw	a1,28(s6)
    8000341a:	9dbd                	addw	a1,a1,a5
    8000341c:	855e                	mv	a0,s7
    8000341e:	00000097          	auipc	ra,0x0
    80003422:	cd2080e7          	jalr	-814(ra) # 800030f0 <bread>
    80003426:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003428:	004b2503          	lw	a0,4(s6)
    8000342c:	000a849b          	sext.w	s1,s5
    80003430:	8662                	mv	a2,s8
    80003432:	faa4fde3          	bgeu	s1,a0,800033ec <balloc+0x3a>
      m = 1 << (bi % 8);
    80003436:	41f6579b          	sraiw	a5,a2,0x1f
    8000343a:	01d7d69b          	srliw	a3,a5,0x1d
    8000343e:	00c6873b          	addw	a4,a3,a2
    80003442:	00777793          	andi	a5,a4,7
    80003446:	9f95                	subw	a5,a5,a3
    80003448:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000344c:	4037571b          	sraiw	a4,a4,0x3
    80003450:	00e906b3          	add	a3,s2,a4
    80003454:	0586c683          	lbu	a3,88(a3)
    80003458:	00d7f5b3          	and	a1,a5,a3
    8000345c:	cd91                	beqz	a1,80003478 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000345e:	2605                	addiw	a2,a2,1
    80003460:	2485                	addiw	s1,s1,1
    80003462:	fd4618e3          	bne	a2,s4,80003432 <balloc+0x80>
    80003466:	b759                	j	800033ec <balloc+0x3a>
  panic("balloc: out of blocks");
    80003468:	00005517          	auipc	a0,0x5
    8000346c:	26850513          	addi	a0,a0,616 # 800086d0 <syscallNames+0x108>
    80003470:	ffffd097          	auipc	ra,0xffffd
    80003474:	0ce080e7          	jalr	206(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003478:	974a                	add	a4,a4,s2
    8000347a:	8fd5                	or	a5,a5,a3
    8000347c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003480:	854a                	mv	a0,s2
    80003482:	00001097          	auipc	ra,0x1
    80003486:	01a080e7          	jalr	26(ra) # 8000449c <log_write>
        brelse(bp);
    8000348a:	854a                	mv	a0,s2
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	d94080e7          	jalr	-620(ra) # 80003220 <brelse>
  bp = bread(dev, bno);
    80003494:	85a6                	mv	a1,s1
    80003496:	855e                	mv	a0,s7
    80003498:	00000097          	auipc	ra,0x0
    8000349c:	c58080e7          	jalr	-936(ra) # 800030f0 <bread>
    800034a0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034a2:	40000613          	li	a2,1024
    800034a6:	4581                	li	a1,0
    800034a8:	05850513          	addi	a0,a0,88
    800034ac:	ffffe097          	auipc	ra,0xffffe
    800034b0:	834080e7          	jalr	-1996(ra) # 80000ce0 <memset>
  log_write(bp);
    800034b4:	854a                	mv	a0,s2
    800034b6:	00001097          	auipc	ra,0x1
    800034ba:	fe6080e7          	jalr	-26(ra) # 8000449c <log_write>
  brelse(bp);
    800034be:	854a                	mv	a0,s2
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	d60080e7          	jalr	-672(ra) # 80003220 <brelse>
}
    800034c8:	8526                	mv	a0,s1
    800034ca:	60e6                	ld	ra,88(sp)
    800034cc:	6446                	ld	s0,80(sp)
    800034ce:	64a6                	ld	s1,72(sp)
    800034d0:	6906                	ld	s2,64(sp)
    800034d2:	79e2                	ld	s3,56(sp)
    800034d4:	7a42                	ld	s4,48(sp)
    800034d6:	7aa2                	ld	s5,40(sp)
    800034d8:	7b02                	ld	s6,32(sp)
    800034da:	6be2                	ld	s7,24(sp)
    800034dc:	6c42                	ld	s8,16(sp)
    800034de:	6ca2                	ld	s9,8(sp)
    800034e0:	6125                	addi	sp,sp,96
    800034e2:	8082                	ret

00000000800034e4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034e4:	7179                	addi	sp,sp,-48
    800034e6:	f406                	sd	ra,40(sp)
    800034e8:	f022                	sd	s0,32(sp)
    800034ea:	ec26                	sd	s1,24(sp)
    800034ec:	e84a                	sd	s2,16(sp)
    800034ee:	e44e                	sd	s3,8(sp)
    800034f0:	e052                	sd	s4,0(sp)
    800034f2:	1800                	addi	s0,sp,48
    800034f4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034f6:	47ad                	li	a5,11
    800034f8:	04b7fe63          	bgeu	a5,a1,80003554 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034fc:	ff45849b          	addiw	s1,a1,-12
    80003500:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003504:	0ff00793          	li	a5,255
    80003508:	0ae7e363          	bltu	a5,a4,800035ae <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000350c:	08052583          	lw	a1,128(a0)
    80003510:	c5ad                	beqz	a1,8000357a <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003512:	00092503          	lw	a0,0(s2)
    80003516:	00000097          	auipc	ra,0x0
    8000351a:	bda080e7          	jalr	-1062(ra) # 800030f0 <bread>
    8000351e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003520:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003524:	02049593          	slli	a1,s1,0x20
    80003528:	9181                	srli	a1,a1,0x20
    8000352a:	058a                	slli	a1,a1,0x2
    8000352c:	00b784b3          	add	s1,a5,a1
    80003530:	0004a983          	lw	s3,0(s1)
    80003534:	04098d63          	beqz	s3,8000358e <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003538:	8552                	mv	a0,s4
    8000353a:	00000097          	auipc	ra,0x0
    8000353e:	ce6080e7          	jalr	-794(ra) # 80003220 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003542:	854e                	mv	a0,s3
    80003544:	70a2                	ld	ra,40(sp)
    80003546:	7402                	ld	s0,32(sp)
    80003548:	64e2                	ld	s1,24(sp)
    8000354a:	6942                	ld	s2,16(sp)
    8000354c:	69a2                	ld	s3,8(sp)
    8000354e:	6a02                	ld	s4,0(sp)
    80003550:	6145                	addi	sp,sp,48
    80003552:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003554:	02059493          	slli	s1,a1,0x20
    80003558:	9081                	srli	s1,s1,0x20
    8000355a:	048a                	slli	s1,s1,0x2
    8000355c:	94aa                	add	s1,s1,a0
    8000355e:	0504a983          	lw	s3,80(s1)
    80003562:	fe0990e3          	bnez	s3,80003542 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003566:	4108                	lw	a0,0(a0)
    80003568:	00000097          	auipc	ra,0x0
    8000356c:	e4a080e7          	jalr	-438(ra) # 800033b2 <balloc>
    80003570:	0005099b          	sext.w	s3,a0
    80003574:	0534a823          	sw	s3,80(s1)
    80003578:	b7e9                	j	80003542 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000357a:	4108                	lw	a0,0(a0)
    8000357c:	00000097          	auipc	ra,0x0
    80003580:	e36080e7          	jalr	-458(ra) # 800033b2 <balloc>
    80003584:	0005059b          	sext.w	a1,a0
    80003588:	08b92023          	sw	a1,128(s2)
    8000358c:	b759                	j	80003512 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000358e:	00092503          	lw	a0,0(s2)
    80003592:	00000097          	auipc	ra,0x0
    80003596:	e20080e7          	jalr	-480(ra) # 800033b2 <balloc>
    8000359a:	0005099b          	sext.w	s3,a0
    8000359e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800035a2:	8552                	mv	a0,s4
    800035a4:	00001097          	auipc	ra,0x1
    800035a8:	ef8080e7          	jalr	-264(ra) # 8000449c <log_write>
    800035ac:	b771                	j	80003538 <bmap+0x54>
  panic("bmap: out of range");
    800035ae:	00005517          	auipc	a0,0x5
    800035b2:	13a50513          	addi	a0,a0,314 # 800086e8 <syscallNames+0x120>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	f88080e7          	jalr	-120(ra) # 8000053e <panic>

00000000800035be <iget>:
{
    800035be:	7179                	addi	sp,sp,-48
    800035c0:	f406                	sd	ra,40(sp)
    800035c2:	f022                	sd	s0,32(sp)
    800035c4:	ec26                	sd	s1,24(sp)
    800035c6:	e84a                	sd	s2,16(sp)
    800035c8:	e44e                	sd	s3,8(sp)
    800035ca:	e052                	sd	s4,0(sp)
    800035cc:	1800                	addi	s0,sp,48
    800035ce:	89aa                	mv	s3,a0
    800035d0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035d2:	0001c517          	auipc	a0,0x1c
    800035d6:	5f650513          	addi	a0,a0,1526 # 8001fbc8 <itable>
    800035da:	ffffd097          	auipc	ra,0xffffd
    800035de:	60a080e7          	jalr	1546(ra) # 80000be4 <acquire>
  empty = 0;
    800035e2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035e4:	0001c497          	auipc	s1,0x1c
    800035e8:	5fc48493          	addi	s1,s1,1532 # 8001fbe0 <itable+0x18>
    800035ec:	0001e697          	auipc	a3,0x1e
    800035f0:	08468693          	addi	a3,a3,132 # 80021670 <log>
    800035f4:	a039                	j	80003602 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035f6:	02090b63          	beqz	s2,8000362c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035fa:	08848493          	addi	s1,s1,136
    800035fe:	02d48a63          	beq	s1,a3,80003632 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003602:	449c                	lw	a5,8(s1)
    80003604:	fef059e3          	blez	a5,800035f6 <iget+0x38>
    80003608:	4098                	lw	a4,0(s1)
    8000360a:	ff3716e3          	bne	a4,s3,800035f6 <iget+0x38>
    8000360e:	40d8                	lw	a4,4(s1)
    80003610:	ff4713e3          	bne	a4,s4,800035f6 <iget+0x38>
      ip->ref++;
    80003614:	2785                	addiw	a5,a5,1
    80003616:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003618:	0001c517          	auipc	a0,0x1c
    8000361c:	5b050513          	addi	a0,a0,1456 # 8001fbc8 <itable>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	678080e7          	jalr	1656(ra) # 80000c98 <release>
      return ip;
    80003628:	8926                	mv	s2,s1
    8000362a:	a03d                	j	80003658 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000362c:	f7f9                	bnez	a5,800035fa <iget+0x3c>
    8000362e:	8926                	mv	s2,s1
    80003630:	b7e9                	j	800035fa <iget+0x3c>
  if(empty == 0)
    80003632:	02090c63          	beqz	s2,8000366a <iget+0xac>
  ip->dev = dev;
    80003636:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000363a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000363e:	4785                	li	a5,1
    80003640:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003644:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003648:	0001c517          	auipc	a0,0x1c
    8000364c:	58050513          	addi	a0,a0,1408 # 8001fbc8 <itable>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	648080e7          	jalr	1608(ra) # 80000c98 <release>
}
    80003658:	854a                	mv	a0,s2
    8000365a:	70a2                	ld	ra,40(sp)
    8000365c:	7402                	ld	s0,32(sp)
    8000365e:	64e2                	ld	s1,24(sp)
    80003660:	6942                	ld	s2,16(sp)
    80003662:	69a2                	ld	s3,8(sp)
    80003664:	6a02                	ld	s4,0(sp)
    80003666:	6145                	addi	sp,sp,48
    80003668:	8082                	ret
    panic("iget: no inodes");
    8000366a:	00005517          	auipc	a0,0x5
    8000366e:	09650513          	addi	a0,a0,150 # 80008700 <syscallNames+0x138>
    80003672:	ffffd097          	auipc	ra,0xffffd
    80003676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>

000000008000367a <fsinit>:
fsinit(int dev) {
    8000367a:	7179                	addi	sp,sp,-48
    8000367c:	f406                	sd	ra,40(sp)
    8000367e:	f022                	sd	s0,32(sp)
    80003680:	ec26                	sd	s1,24(sp)
    80003682:	e84a                	sd	s2,16(sp)
    80003684:	e44e                	sd	s3,8(sp)
    80003686:	1800                	addi	s0,sp,48
    80003688:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000368a:	4585                	li	a1,1
    8000368c:	00000097          	auipc	ra,0x0
    80003690:	a64080e7          	jalr	-1436(ra) # 800030f0 <bread>
    80003694:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003696:	0001c997          	auipc	s3,0x1c
    8000369a:	51298993          	addi	s3,s3,1298 # 8001fba8 <sb>
    8000369e:	02000613          	li	a2,32
    800036a2:	05850593          	addi	a1,a0,88
    800036a6:	854e                	mv	a0,s3
    800036a8:	ffffd097          	auipc	ra,0xffffd
    800036ac:	698080e7          	jalr	1688(ra) # 80000d40 <memmove>
  brelse(bp);
    800036b0:	8526                	mv	a0,s1
    800036b2:	00000097          	auipc	ra,0x0
    800036b6:	b6e080e7          	jalr	-1170(ra) # 80003220 <brelse>
  if(sb.magic != FSMAGIC)
    800036ba:	0009a703          	lw	a4,0(s3)
    800036be:	102037b7          	lui	a5,0x10203
    800036c2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036c6:	02f71263          	bne	a4,a5,800036ea <fsinit+0x70>
  initlog(dev, &sb);
    800036ca:	0001c597          	auipc	a1,0x1c
    800036ce:	4de58593          	addi	a1,a1,1246 # 8001fba8 <sb>
    800036d2:	854a                	mv	a0,s2
    800036d4:	00001097          	auipc	ra,0x1
    800036d8:	b4c080e7          	jalr	-1204(ra) # 80004220 <initlog>
}
    800036dc:	70a2                	ld	ra,40(sp)
    800036de:	7402                	ld	s0,32(sp)
    800036e0:	64e2                	ld	s1,24(sp)
    800036e2:	6942                	ld	s2,16(sp)
    800036e4:	69a2                	ld	s3,8(sp)
    800036e6:	6145                	addi	sp,sp,48
    800036e8:	8082                	ret
    panic("invalid file system");
    800036ea:	00005517          	auipc	a0,0x5
    800036ee:	02650513          	addi	a0,a0,38 # 80008710 <syscallNames+0x148>
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	e4c080e7          	jalr	-436(ra) # 8000053e <panic>

00000000800036fa <iinit>:
{
    800036fa:	7179                	addi	sp,sp,-48
    800036fc:	f406                	sd	ra,40(sp)
    800036fe:	f022                	sd	s0,32(sp)
    80003700:	ec26                	sd	s1,24(sp)
    80003702:	e84a                	sd	s2,16(sp)
    80003704:	e44e                	sd	s3,8(sp)
    80003706:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003708:	00005597          	auipc	a1,0x5
    8000370c:	02058593          	addi	a1,a1,32 # 80008728 <syscallNames+0x160>
    80003710:	0001c517          	auipc	a0,0x1c
    80003714:	4b850513          	addi	a0,a0,1208 # 8001fbc8 <itable>
    80003718:	ffffd097          	auipc	ra,0xffffd
    8000371c:	43c080e7          	jalr	1084(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003720:	0001c497          	auipc	s1,0x1c
    80003724:	4d048493          	addi	s1,s1,1232 # 8001fbf0 <itable+0x28>
    80003728:	0001e997          	auipc	s3,0x1e
    8000372c:	f5898993          	addi	s3,s3,-168 # 80021680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003730:	00005917          	auipc	s2,0x5
    80003734:	00090913          	mv	s2,s2
    80003738:	85ca                	mv	a1,s2
    8000373a:	8526                	mv	a0,s1
    8000373c:	00001097          	auipc	ra,0x1
    80003740:	e46080e7          	jalr	-442(ra) # 80004582 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003744:	08848493          	addi	s1,s1,136
    80003748:	ff3498e3          	bne	s1,s3,80003738 <iinit+0x3e>
}
    8000374c:	70a2                	ld	ra,40(sp)
    8000374e:	7402                	ld	s0,32(sp)
    80003750:	64e2                	ld	s1,24(sp)
    80003752:	6942                	ld	s2,16(sp)
    80003754:	69a2                	ld	s3,8(sp)
    80003756:	6145                	addi	sp,sp,48
    80003758:	8082                	ret

000000008000375a <ialloc>:
{
    8000375a:	715d                	addi	sp,sp,-80
    8000375c:	e486                	sd	ra,72(sp)
    8000375e:	e0a2                	sd	s0,64(sp)
    80003760:	fc26                	sd	s1,56(sp)
    80003762:	f84a                	sd	s2,48(sp)
    80003764:	f44e                	sd	s3,40(sp)
    80003766:	f052                	sd	s4,32(sp)
    80003768:	ec56                	sd	s5,24(sp)
    8000376a:	e85a                	sd	s6,16(sp)
    8000376c:	e45e                	sd	s7,8(sp)
    8000376e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003770:	0001c717          	auipc	a4,0x1c
    80003774:	44472703          	lw	a4,1092(a4) # 8001fbb4 <sb+0xc>
    80003778:	4785                	li	a5,1
    8000377a:	04e7fa63          	bgeu	a5,a4,800037ce <ialloc+0x74>
    8000377e:	8aaa                	mv	s5,a0
    80003780:	8bae                	mv	s7,a1
    80003782:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003784:	0001ca17          	auipc	s4,0x1c
    80003788:	424a0a13          	addi	s4,s4,1060 # 8001fba8 <sb>
    8000378c:	00048b1b          	sext.w	s6,s1
    80003790:	0044d593          	srli	a1,s1,0x4
    80003794:	018a2783          	lw	a5,24(s4)
    80003798:	9dbd                	addw	a1,a1,a5
    8000379a:	8556                	mv	a0,s5
    8000379c:	00000097          	auipc	ra,0x0
    800037a0:	954080e7          	jalr	-1708(ra) # 800030f0 <bread>
    800037a4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037a6:	05850993          	addi	s3,a0,88
    800037aa:	00f4f793          	andi	a5,s1,15
    800037ae:	079a                	slli	a5,a5,0x6
    800037b0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037b2:	00099783          	lh	a5,0(s3)
    800037b6:	c785                	beqz	a5,800037de <ialloc+0x84>
    brelse(bp);
    800037b8:	00000097          	auipc	ra,0x0
    800037bc:	a68080e7          	jalr	-1432(ra) # 80003220 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037c0:	0485                	addi	s1,s1,1
    800037c2:	00ca2703          	lw	a4,12(s4)
    800037c6:	0004879b          	sext.w	a5,s1
    800037ca:	fce7e1e3          	bltu	a5,a4,8000378c <ialloc+0x32>
  panic("ialloc: no inodes");
    800037ce:	00005517          	auipc	a0,0x5
    800037d2:	f6a50513          	addi	a0,a0,-150 # 80008738 <syscallNames+0x170>
    800037d6:	ffffd097          	auipc	ra,0xffffd
    800037da:	d68080e7          	jalr	-664(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800037de:	04000613          	li	a2,64
    800037e2:	4581                	li	a1,0
    800037e4:	854e                	mv	a0,s3
    800037e6:	ffffd097          	auipc	ra,0xffffd
    800037ea:	4fa080e7          	jalr	1274(ra) # 80000ce0 <memset>
      dip->type = type;
    800037ee:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037f2:	854a                	mv	a0,s2
    800037f4:	00001097          	auipc	ra,0x1
    800037f8:	ca8080e7          	jalr	-856(ra) # 8000449c <log_write>
      brelse(bp);
    800037fc:	854a                	mv	a0,s2
    800037fe:	00000097          	auipc	ra,0x0
    80003802:	a22080e7          	jalr	-1502(ra) # 80003220 <brelse>
      return iget(dev, inum);
    80003806:	85da                	mv	a1,s6
    80003808:	8556                	mv	a0,s5
    8000380a:	00000097          	auipc	ra,0x0
    8000380e:	db4080e7          	jalr	-588(ra) # 800035be <iget>
}
    80003812:	60a6                	ld	ra,72(sp)
    80003814:	6406                	ld	s0,64(sp)
    80003816:	74e2                	ld	s1,56(sp)
    80003818:	7942                	ld	s2,48(sp)
    8000381a:	79a2                	ld	s3,40(sp)
    8000381c:	7a02                	ld	s4,32(sp)
    8000381e:	6ae2                	ld	s5,24(sp)
    80003820:	6b42                	ld	s6,16(sp)
    80003822:	6ba2                	ld	s7,8(sp)
    80003824:	6161                	addi	sp,sp,80
    80003826:	8082                	ret

0000000080003828 <iupdate>:
{
    80003828:	1101                	addi	sp,sp,-32
    8000382a:	ec06                	sd	ra,24(sp)
    8000382c:	e822                	sd	s0,16(sp)
    8000382e:	e426                	sd	s1,8(sp)
    80003830:	e04a                	sd	s2,0(sp)
    80003832:	1000                	addi	s0,sp,32
    80003834:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003836:	415c                	lw	a5,4(a0)
    80003838:	0047d79b          	srliw	a5,a5,0x4
    8000383c:	0001c597          	auipc	a1,0x1c
    80003840:	3845a583          	lw	a1,900(a1) # 8001fbc0 <sb+0x18>
    80003844:	9dbd                	addw	a1,a1,a5
    80003846:	4108                	lw	a0,0(a0)
    80003848:	00000097          	auipc	ra,0x0
    8000384c:	8a8080e7          	jalr	-1880(ra) # 800030f0 <bread>
    80003850:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003852:	05850793          	addi	a5,a0,88
    80003856:	40c8                	lw	a0,4(s1)
    80003858:	893d                	andi	a0,a0,15
    8000385a:	051a                	slli	a0,a0,0x6
    8000385c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000385e:	04449703          	lh	a4,68(s1)
    80003862:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003866:	04649703          	lh	a4,70(s1)
    8000386a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000386e:	04849703          	lh	a4,72(s1)
    80003872:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003876:	04a49703          	lh	a4,74(s1)
    8000387a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000387e:	44f8                	lw	a4,76(s1)
    80003880:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003882:	03400613          	li	a2,52
    80003886:	05048593          	addi	a1,s1,80
    8000388a:	0531                	addi	a0,a0,12
    8000388c:	ffffd097          	auipc	ra,0xffffd
    80003890:	4b4080e7          	jalr	1204(ra) # 80000d40 <memmove>
  log_write(bp);
    80003894:	854a                	mv	a0,s2
    80003896:	00001097          	auipc	ra,0x1
    8000389a:	c06080e7          	jalr	-1018(ra) # 8000449c <log_write>
  brelse(bp);
    8000389e:	854a                	mv	a0,s2
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	980080e7          	jalr	-1664(ra) # 80003220 <brelse>
}
    800038a8:	60e2                	ld	ra,24(sp)
    800038aa:	6442                	ld	s0,16(sp)
    800038ac:	64a2                	ld	s1,8(sp)
    800038ae:	6902                	ld	s2,0(sp)
    800038b0:	6105                	addi	sp,sp,32
    800038b2:	8082                	ret

00000000800038b4 <idup>:
{
    800038b4:	1101                	addi	sp,sp,-32
    800038b6:	ec06                	sd	ra,24(sp)
    800038b8:	e822                	sd	s0,16(sp)
    800038ba:	e426                	sd	s1,8(sp)
    800038bc:	1000                	addi	s0,sp,32
    800038be:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038c0:	0001c517          	auipc	a0,0x1c
    800038c4:	30850513          	addi	a0,a0,776 # 8001fbc8 <itable>
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	31c080e7          	jalr	796(ra) # 80000be4 <acquire>
  ip->ref++;
    800038d0:	449c                	lw	a5,8(s1)
    800038d2:	2785                	addiw	a5,a5,1
    800038d4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038d6:	0001c517          	auipc	a0,0x1c
    800038da:	2f250513          	addi	a0,a0,754 # 8001fbc8 <itable>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	3ba080e7          	jalr	954(ra) # 80000c98 <release>
}
    800038e6:	8526                	mv	a0,s1
    800038e8:	60e2                	ld	ra,24(sp)
    800038ea:	6442                	ld	s0,16(sp)
    800038ec:	64a2                	ld	s1,8(sp)
    800038ee:	6105                	addi	sp,sp,32
    800038f0:	8082                	ret

00000000800038f2 <ilock>:
{
    800038f2:	1101                	addi	sp,sp,-32
    800038f4:	ec06                	sd	ra,24(sp)
    800038f6:	e822                	sd	s0,16(sp)
    800038f8:	e426                	sd	s1,8(sp)
    800038fa:	e04a                	sd	s2,0(sp)
    800038fc:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038fe:	c115                	beqz	a0,80003922 <ilock+0x30>
    80003900:	84aa                	mv	s1,a0
    80003902:	451c                	lw	a5,8(a0)
    80003904:	00f05f63          	blez	a5,80003922 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003908:	0541                	addi	a0,a0,16
    8000390a:	00001097          	auipc	ra,0x1
    8000390e:	cb2080e7          	jalr	-846(ra) # 800045bc <acquiresleep>
  if(ip->valid == 0){
    80003912:	40bc                	lw	a5,64(s1)
    80003914:	cf99                	beqz	a5,80003932 <ilock+0x40>
}
    80003916:	60e2                	ld	ra,24(sp)
    80003918:	6442                	ld	s0,16(sp)
    8000391a:	64a2                	ld	s1,8(sp)
    8000391c:	6902                	ld	s2,0(sp)
    8000391e:	6105                	addi	sp,sp,32
    80003920:	8082                	ret
    panic("ilock");
    80003922:	00005517          	auipc	a0,0x5
    80003926:	e2e50513          	addi	a0,a0,-466 # 80008750 <syscallNames+0x188>
    8000392a:	ffffd097          	auipc	ra,0xffffd
    8000392e:	c14080e7          	jalr	-1004(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003932:	40dc                	lw	a5,4(s1)
    80003934:	0047d79b          	srliw	a5,a5,0x4
    80003938:	0001c597          	auipc	a1,0x1c
    8000393c:	2885a583          	lw	a1,648(a1) # 8001fbc0 <sb+0x18>
    80003940:	9dbd                	addw	a1,a1,a5
    80003942:	4088                	lw	a0,0(s1)
    80003944:	fffff097          	auipc	ra,0xfffff
    80003948:	7ac080e7          	jalr	1964(ra) # 800030f0 <bread>
    8000394c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000394e:	05850593          	addi	a1,a0,88
    80003952:	40dc                	lw	a5,4(s1)
    80003954:	8bbd                	andi	a5,a5,15
    80003956:	079a                	slli	a5,a5,0x6
    80003958:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000395a:	00059783          	lh	a5,0(a1)
    8000395e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003962:	00259783          	lh	a5,2(a1)
    80003966:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000396a:	00459783          	lh	a5,4(a1)
    8000396e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003972:	00659783          	lh	a5,6(a1)
    80003976:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000397a:	459c                	lw	a5,8(a1)
    8000397c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000397e:	03400613          	li	a2,52
    80003982:	05b1                	addi	a1,a1,12
    80003984:	05048513          	addi	a0,s1,80
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	3b8080e7          	jalr	952(ra) # 80000d40 <memmove>
    brelse(bp);
    80003990:	854a                	mv	a0,s2
    80003992:	00000097          	auipc	ra,0x0
    80003996:	88e080e7          	jalr	-1906(ra) # 80003220 <brelse>
    ip->valid = 1;
    8000399a:	4785                	li	a5,1
    8000399c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000399e:	04449783          	lh	a5,68(s1)
    800039a2:	fbb5                	bnez	a5,80003916 <ilock+0x24>
      panic("ilock: no type");
    800039a4:	00005517          	auipc	a0,0x5
    800039a8:	db450513          	addi	a0,a0,-588 # 80008758 <syscallNames+0x190>
    800039ac:	ffffd097          	auipc	ra,0xffffd
    800039b0:	b92080e7          	jalr	-1134(ra) # 8000053e <panic>

00000000800039b4 <iunlock>:
{
    800039b4:	1101                	addi	sp,sp,-32
    800039b6:	ec06                	sd	ra,24(sp)
    800039b8:	e822                	sd	s0,16(sp)
    800039ba:	e426                	sd	s1,8(sp)
    800039bc:	e04a                	sd	s2,0(sp)
    800039be:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039c0:	c905                	beqz	a0,800039f0 <iunlock+0x3c>
    800039c2:	84aa                	mv	s1,a0
    800039c4:	01050913          	addi	s2,a0,16
    800039c8:	854a                	mv	a0,s2
    800039ca:	00001097          	auipc	ra,0x1
    800039ce:	c8c080e7          	jalr	-884(ra) # 80004656 <holdingsleep>
    800039d2:	cd19                	beqz	a0,800039f0 <iunlock+0x3c>
    800039d4:	449c                	lw	a5,8(s1)
    800039d6:	00f05d63          	blez	a5,800039f0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039da:	854a                	mv	a0,s2
    800039dc:	00001097          	auipc	ra,0x1
    800039e0:	c36080e7          	jalr	-970(ra) # 80004612 <releasesleep>
}
    800039e4:	60e2                	ld	ra,24(sp)
    800039e6:	6442                	ld	s0,16(sp)
    800039e8:	64a2                	ld	s1,8(sp)
    800039ea:	6902                	ld	s2,0(sp)
    800039ec:	6105                	addi	sp,sp,32
    800039ee:	8082                	ret
    panic("iunlock");
    800039f0:	00005517          	auipc	a0,0x5
    800039f4:	d7850513          	addi	a0,a0,-648 # 80008768 <syscallNames+0x1a0>
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	b46080e7          	jalr	-1210(ra) # 8000053e <panic>

0000000080003a00 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a00:	7179                	addi	sp,sp,-48
    80003a02:	f406                	sd	ra,40(sp)
    80003a04:	f022                	sd	s0,32(sp)
    80003a06:	ec26                	sd	s1,24(sp)
    80003a08:	e84a                	sd	s2,16(sp)
    80003a0a:	e44e                	sd	s3,8(sp)
    80003a0c:	e052                	sd	s4,0(sp)
    80003a0e:	1800                	addi	s0,sp,48
    80003a10:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a12:	05050493          	addi	s1,a0,80
    80003a16:	08050913          	addi	s2,a0,128
    80003a1a:	a021                	j	80003a22 <itrunc+0x22>
    80003a1c:	0491                	addi	s1,s1,4
    80003a1e:	01248d63          	beq	s1,s2,80003a38 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a22:	408c                	lw	a1,0(s1)
    80003a24:	dde5                	beqz	a1,80003a1c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a26:	0009a503          	lw	a0,0(s3)
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	90c080e7          	jalr	-1780(ra) # 80003336 <bfree>
      ip->addrs[i] = 0;
    80003a32:	0004a023          	sw	zero,0(s1)
    80003a36:	b7dd                	j	80003a1c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a38:	0809a583          	lw	a1,128(s3)
    80003a3c:	e185                	bnez	a1,80003a5c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a3e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a42:	854e                	mv	a0,s3
    80003a44:	00000097          	auipc	ra,0x0
    80003a48:	de4080e7          	jalr	-540(ra) # 80003828 <iupdate>
}
    80003a4c:	70a2                	ld	ra,40(sp)
    80003a4e:	7402                	ld	s0,32(sp)
    80003a50:	64e2                	ld	s1,24(sp)
    80003a52:	6942                	ld	s2,16(sp)
    80003a54:	69a2                	ld	s3,8(sp)
    80003a56:	6a02                	ld	s4,0(sp)
    80003a58:	6145                	addi	sp,sp,48
    80003a5a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a5c:	0009a503          	lw	a0,0(s3)
    80003a60:	fffff097          	auipc	ra,0xfffff
    80003a64:	690080e7          	jalr	1680(ra) # 800030f0 <bread>
    80003a68:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a6a:	05850493          	addi	s1,a0,88
    80003a6e:	45850913          	addi	s2,a0,1112
    80003a72:	a811                	j	80003a86 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a74:	0009a503          	lw	a0,0(s3)
    80003a78:	00000097          	auipc	ra,0x0
    80003a7c:	8be080e7          	jalr	-1858(ra) # 80003336 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a80:	0491                	addi	s1,s1,4
    80003a82:	01248563          	beq	s1,s2,80003a8c <itrunc+0x8c>
      if(a[j])
    80003a86:	408c                	lw	a1,0(s1)
    80003a88:	dde5                	beqz	a1,80003a80 <itrunc+0x80>
    80003a8a:	b7ed                	j	80003a74 <itrunc+0x74>
    brelse(bp);
    80003a8c:	8552                	mv	a0,s4
    80003a8e:	fffff097          	auipc	ra,0xfffff
    80003a92:	792080e7          	jalr	1938(ra) # 80003220 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a96:	0809a583          	lw	a1,128(s3)
    80003a9a:	0009a503          	lw	a0,0(s3)
    80003a9e:	00000097          	auipc	ra,0x0
    80003aa2:	898080e7          	jalr	-1896(ra) # 80003336 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003aa6:	0809a023          	sw	zero,128(s3)
    80003aaa:	bf51                	j	80003a3e <itrunc+0x3e>

0000000080003aac <iput>:
{
    80003aac:	1101                	addi	sp,sp,-32
    80003aae:	ec06                	sd	ra,24(sp)
    80003ab0:	e822                	sd	s0,16(sp)
    80003ab2:	e426                	sd	s1,8(sp)
    80003ab4:	e04a                	sd	s2,0(sp)
    80003ab6:	1000                	addi	s0,sp,32
    80003ab8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aba:	0001c517          	auipc	a0,0x1c
    80003abe:	10e50513          	addi	a0,a0,270 # 8001fbc8 <itable>
    80003ac2:	ffffd097          	auipc	ra,0xffffd
    80003ac6:	122080e7          	jalr	290(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aca:	4498                	lw	a4,8(s1)
    80003acc:	4785                	li	a5,1
    80003ace:	02f70363          	beq	a4,a5,80003af4 <iput+0x48>
  ip->ref--;
    80003ad2:	449c                	lw	a5,8(s1)
    80003ad4:	37fd                	addiw	a5,a5,-1
    80003ad6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ad8:	0001c517          	auipc	a0,0x1c
    80003adc:	0f050513          	addi	a0,a0,240 # 8001fbc8 <itable>
    80003ae0:	ffffd097          	auipc	ra,0xffffd
    80003ae4:	1b8080e7          	jalr	440(ra) # 80000c98 <release>
}
    80003ae8:	60e2                	ld	ra,24(sp)
    80003aea:	6442                	ld	s0,16(sp)
    80003aec:	64a2                	ld	s1,8(sp)
    80003aee:	6902                	ld	s2,0(sp)
    80003af0:	6105                	addi	sp,sp,32
    80003af2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003af4:	40bc                	lw	a5,64(s1)
    80003af6:	dff1                	beqz	a5,80003ad2 <iput+0x26>
    80003af8:	04a49783          	lh	a5,74(s1)
    80003afc:	fbf9                	bnez	a5,80003ad2 <iput+0x26>
    acquiresleep(&ip->lock);
    80003afe:	01048913          	addi	s2,s1,16
    80003b02:	854a                	mv	a0,s2
    80003b04:	00001097          	auipc	ra,0x1
    80003b08:	ab8080e7          	jalr	-1352(ra) # 800045bc <acquiresleep>
    release(&itable.lock);
    80003b0c:	0001c517          	auipc	a0,0x1c
    80003b10:	0bc50513          	addi	a0,a0,188 # 8001fbc8 <itable>
    80003b14:	ffffd097          	auipc	ra,0xffffd
    80003b18:	184080e7          	jalr	388(ra) # 80000c98 <release>
    itrunc(ip);
    80003b1c:	8526                	mv	a0,s1
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	ee2080e7          	jalr	-286(ra) # 80003a00 <itrunc>
    ip->type = 0;
    80003b26:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b2a:	8526                	mv	a0,s1
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	cfc080e7          	jalr	-772(ra) # 80003828 <iupdate>
    ip->valid = 0;
    80003b34:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b38:	854a                	mv	a0,s2
    80003b3a:	00001097          	auipc	ra,0x1
    80003b3e:	ad8080e7          	jalr	-1320(ra) # 80004612 <releasesleep>
    acquire(&itable.lock);
    80003b42:	0001c517          	auipc	a0,0x1c
    80003b46:	08650513          	addi	a0,a0,134 # 8001fbc8 <itable>
    80003b4a:	ffffd097          	auipc	ra,0xffffd
    80003b4e:	09a080e7          	jalr	154(ra) # 80000be4 <acquire>
    80003b52:	b741                	j	80003ad2 <iput+0x26>

0000000080003b54 <iunlockput>:
{
    80003b54:	1101                	addi	sp,sp,-32
    80003b56:	ec06                	sd	ra,24(sp)
    80003b58:	e822                	sd	s0,16(sp)
    80003b5a:	e426                	sd	s1,8(sp)
    80003b5c:	1000                	addi	s0,sp,32
    80003b5e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b60:	00000097          	auipc	ra,0x0
    80003b64:	e54080e7          	jalr	-428(ra) # 800039b4 <iunlock>
  iput(ip);
    80003b68:	8526                	mv	a0,s1
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	f42080e7          	jalr	-190(ra) # 80003aac <iput>
}
    80003b72:	60e2                	ld	ra,24(sp)
    80003b74:	6442                	ld	s0,16(sp)
    80003b76:	64a2                	ld	s1,8(sp)
    80003b78:	6105                	addi	sp,sp,32
    80003b7a:	8082                	ret

0000000080003b7c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b7c:	1141                	addi	sp,sp,-16
    80003b7e:	e422                	sd	s0,8(sp)
    80003b80:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b82:	411c                	lw	a5,0(a0)
    80003b84:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b86:	415c                	lw	a5,4(a0)
    80003b88:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b8a:	04451783          	lh	a5,68(a0)
    80003b8e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b92:	04a51783          	lh	a5,74(a0)
    80003b96:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b9a:	04c56783          	lwu	a5,76(a0)
    80003b9e:	e99c                	sd	a5,16(a1)
}
    80003ba0:	6422                	ld	s0,8(sp)
    80003ba2:	0141                	addi	sp,sp,16
    80003ba4:	8082                	ret

0000000080003ba6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ba6:	457c                	lw	a5,76(a0)
    80003ba8:	0ed7e963          	bltu	a5,a3,80003c9a <readi+0xf4>
{
    80003bac:	7159                	addi	sp,sp,-112
    80003bae:	f486                	sd	ra,104(sp)
    80003bb0:	f0a2                	sd	s0,96(sp)
    80003bb2:	eca6                	sd	s1,88(sp)
    80003bb4:	e8ca                	sd	s2,80(sp)
    80003bb6:	e4ce                	sd	s3,72(sp)
    80003bb8:	e0d2                	sd	s4,64(sp)
    80003bba:	fc56                	sd	s5,56(sp)
    80003bbc:	f85a                	sd	s6,48(sp)
    80003bbe:	f45e                	sd	s7,40(sp)
    80003bc0:	f062                	sd	s8,32(sp)
    80003bc2:	ec66                	sd	s9,24(sp)
    80003bc4:	e86a                	sd	s10,16(sp)
    80003bc6:	e46e                	sd	s11,8(sp)
    80003bc8:	1880                	addi	s0,sp,112
    80003bca:	8baa                	mv	s7,a0
    80003bcc:	8c2e                	mv	s8,a1
    80003bce:	8ab2                	mv	s5,a2
    80003bd0:	84b6                	mv	s1,a3
    80003bd2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bd4:	9f35                	addw	a4,a4,a3
    return 0;
    80003bd6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bd8:	0ad76063          	bltu	a4,a3,80003c78 <readi+0xd2>
  if(off + n > ip->size)
    80003bdc:	00e7f463          	bgeu	a5,a4,80003be4 <readi+0x3e>
    n = ip->size - off;
    80003be0:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003be4:	0a0b0963          	beqz	s6,80003c96 <readi+0xf0>
    80003be8:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bea:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bee:	5cfd                	li	s9,-1
    80003bf0:	a82d                	j	80003c2a <readi+0x84>
    80003bf2:	020a1d93          	slli	s11,s4,0x20
    80003bf6:	020ddd93          	srli	s11,s11,0x20
    80003bfa:	05890613          	addi	a2,s2,88 # 80008788 <syscallNames+0x1c0>
    80003bfe:	86ee                	mv	a3,s11
    80003c00:	963a                	add	a2,a2,a4
    80003c02:	85d6                	mv	a1,s5
    80003c04:	8562                	mv	a0,s8
    80003c06:	fffff097          	auipc	ra,0xfffff
    80003c0a:	854080e7          	jalr	-1964(ra) # 8000245a <either_copyout>
    80003c0e:	05950d63          	beq	a0,s9,80003c68 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c12:	854a                	mv	a0,s2
    80003c14:	fffff097          	auipc	ra,0xfffff
    80003c18:	60c080e7          	jalr	1548(ra) # 80003220 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c1c:	013a09bb          	addw	s3,s4,s3
    80003c20:	009a04bb          	addw	s1,s4,s1
    80003c24:	9aee                	add	s5,s5,s11
    80003c26:	0569f763          	bgeu	s3,s6,80003c74 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c2a:	000ba903          	lw	s2,0(s7)
    80003c2e:	00a4d59b          	srliw	a1,s1,0xa
    80003c32:	855e                	mv	a0,s7
    80003c34:	00000097          	auipc	ra,0x0
    80003c38:	8b0080e7          	jalr	-1872(ra) # 800034e4 <bmap>
    80003c3c:	0005059b          	sext.w	a1,a0
    80003c40:	854a                	mv	a0,s2
    80003c42:	fffff097          	auipc	ra,0xfffff
    80003c46:	4ae080e7          	jalr	1198(ra) # 800030f0 <bread>
    80003c4a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c4c:	3ff4f713          	andi	a4,s1,1023
    80003c50:	40ed07bb          	subw	a5,s10,a4
    80003c54:	413b06bb          	subw	a3,s6,s3
    80003c58:	8a3e                	mv	s4,a5
    80003c5a:	2781                	sext.w	a5,a5
    80003c5c:	0006861b          	sext.w	a2,a3
    80003c60:	f8f679e3          	bgeu	a2,a5,80003bf2 <readi+0x4c>
    80003c64:	8a36                	mv	s4,a3
    80003c66:	b771                	j	80003bf2 <readi+0x4c>
      brelse(bp);
    80003c68:	854a                	mv	a0,s2
    80003c6a:	fffff097          	auipc	ra,0xfffff
    80003c6e:	5b6080e7          	jalr	1462(ra) # 80003220 <brelse>
      tot = -1;
    80003c72:	59fd                	li	s3,-1
  }
  return tot;
    80003c74:	0009851b          	sext.w	a0,s3
}
    80003c78:	70a6                	ld	ra,104(sp)
    80003c7a:	7406                	ld	s0,96(sp)
    80003c7c:	64e6                	ld	s1,88(sp)
    80003c7e:	6946                	ld	s2,80(sp)
    80003c80:	69a6                	ld	s3,72(sp)
    80003c82:	6a06                	ld	s4,64(sp)
    80003c84:	7ae2                	ld	s5,56(sp)
    80003c86:	7b42                	ld	s6,48(sp)
    80003c88:	7ba2                	ld	s7,40(sp)
    80003c8a:	7c02                	ld	s8,32(sp)
    80003c8c:	6ce2                	ld	s9,24(sp)
    80003c8e:	6d42                	ld	s10,16(sp)
    80003c90:	6da2                	ld	s11,8(sp)
    80003c92:	6165                	addi	sp,sp,112
    80003c94:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c96:	89da                	mv	s3,s6
    80003c98:	bff1                	j	80003c74 <readi+0xce>
    return 0;
    80003c9a:	4501                	li	a0,0
}
    80003c9c:	8082                	ret

0000000080003c9e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c9e:	457c                	lw	a5,76(a0)
    80003ca0:	10d7e863          	bltu	a5,a3,80003db0 <writei+0x112>
{
    80003ca4:	7159                	addi	sp,sp,-112
    80003ca6:	f486                	sd	ra,104(sp)
    80003ca8:	f0a2                	sd	s0,96(sp)
    80003caa:	eca6                	sd	s1,88(sp)
    80003cac:	e8ca                	sd	s2,80(sp)
    80003cae:	e4ce                	sd	s3,72(sp)
    80003cb0:	e0d2                	sd	s4,64(sp)
    80003cb2:	fc56                	sd	s5,56(sp)
    80003cb4:	f85a                	sd	s6,48(sp)
    80003cb6:	f45e                	sd	s7,40(sp)
    80003cb8:	f062                	sd	s8,32(sp)
    80003cba:	ec66                	sd	s9,24(sp)
    80003cbc:	e86a                	sd	s10,16(sp)
    80003cbe:	e46e                	sd	s11,8(sp)
    80003cc0:	1880                	addi	s0,sp,112
    80003cc2:	8b2a                	mv	s6,a0
    80003cc4:	8c2e                	mv	s8,a1
    80003cc6:	8ab2                	mv	s5,a2
    80003cc8:	8936                	mv	s2,a3
    80003cca:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ccc:	00e687bb          	addw	a5,a3,a4
    80003cd0:	0ed7e263          	bltu	a5,a3,80003db4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cd4:	00043737          	lui	a4,0x43
    80003cd8:	0ef76063          	bltu	a4,a5,80003db8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cdc:	0c0b8863          	beqz	s7,80003dac <writei+0x10e>
    80003ce0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce2:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ce6:	5cfd                	li	s9,-1
    80003ce8:	a091                	j	80003d2c <writei+0x8e>
    80003cea:	02099d93          	slli	s11,s3,0x20
    80003cee:	020ddd93          	srli	s11,s11,0x20
    80003cf2:	05848513          	addi	a0,s1,88
    80003cf6:	86ee                	mv	a3,s11
    80003cf8:	8656                	mv	a2,s5
    80003cfa:	85e2                	mv	a1,s8
    80003cfc:	953a                	add	a0,a0,a4
    80003cfe:	ffffe097          	auipc	ra,0xffffe
    80003d02:	7b2080e7          	jalr	1970(ra) # 800024b0 <either_copyin>
    80003d06:	07950263          	beq	a0,s9,80003d6a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d0a:	8526                	mv	a0,s1
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	790080e7          	jalr	1936(ra) # 8000449c <log_write>
    brelse(bp);
    80003d14:	8526                	mv	a0,s1
    80003d16:	fffff097          	auipc	ra,0xfffff
    80003d1a:	50a080e7          	jalr	1290(ra) # 80003220 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d1e:	01498a3b          	addw	s4,s3,s4
    80003d22:	0129893b          	addw	s2,s3,s2
    80003d26:	9aee                	add	s5,s5,s11
    80003d28:	057a7663          	bgeu	s4,s7,80003d74 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d2c:	000b2483          	lw	s1,0(s6)
    80003d30:	00a9559b          	srliw	a1,s2,0xa
    80003d34:	855a                	mv	a0,s6
    80003d36:	fffff097          	auipc	ra,0xfffff
    80003d3a:	7ae080e7          	jalr	1966(ra) # 800034e4 <bmap>
    80003d3e:	0005059b          	sext.w	a1,a0
    80003d42:	8526                	mv	a0,s1
    80003d44:	fffff097          	auipc	ra,0xfffff
    80003d48:	3ac080e7          	jalr	940(ra) # 800030f0 <bread>
    80003d4c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d4e:	3ff97713          	andi	a4,s2,1023
    80003d52:	40ed07bb          	subw	a5,s10,a4
    80003d56:	414b86bb          	subw	a3,s7,s4
    80003d5a:	89be                	mv	s3,a5
    80003d5c:	2781                	sext.w	a5,a5
    80003d5e:	0006861b          	sext.w	a2,a3
    80003d62:	f8f674e3          	bgeu	a2,a5,80003cea <writei+0x4c>
    80003d66:	89b6                	mv	s3,a3
    80003d68:	b749                	j	80003cea <writei+0x4c>
      brelse(bp);
    80003d6a:	8526                	mv	a0,s1
    80003d6c:	fffff097          	auipc	ra,0xfffff
    80003d70:	4b4080e7          	jalr	1204(ra) # 80003220 <brelse>
  }

  if(off > ip->size)
    80003d74:	04cb2783          	lw	a5,76(s6)
    80003d78:	0127f463          	bgeu	a5,s2,80003d80 <writei+0xe2>
    ip->size = off;
    80003d7c:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d80:	855a                	mv	a0,s6
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	aa6080e7          	jalr	-1370(ra) # 80003828 <iupdate>

  return tot;
    80003d8a:	000a051b          	sext.w	a0,s4
}
    80003d8e:	70a6                	ld	ra,104(sp)
    80003d90:	7406                	ld	s0,96(sp)
    80003d92:	64e6                	ld	s1,88(sp)
    80003d94:	6946                	ld	s2,80(sp)
    80003d96:	69a6                	ld	s3,72(sp)
    80003d98:	6a06                	ld	s4,64(sp)
    80003d9a:	7ae2                	ld	s5,56(sp)
    80003d9c:	7b42                	ld	s6,48(sp)
    80003d9e:	7ba2                	ld	s7,40(sp)
    80003da0:	7c02                	ld	s8,32(sp)
    80003da2:	6ce2                	ld	s9,24(sp)
    80003da4:	6d42                	ld	s10,16(sp)
    80003da6:	6da2                	ld	s11,8(sp)
    80003da8:	6165                	addi	sp,sp,112
    80003daa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dac:	8a5e                	mv	s4,s7
    80003dae:	bfc9                	j	80003d80 <writei+0xe2>
    return -1;
    80003db0:	557d                	li	a0,-1
}
    80003db2:	8082                	ret
    return -1;
    80003db4:	557d                	li	a0,-1
    80003db6:	bfe1                	j	80003d8e <writei+0xf0>
    return -1;
    80003db8:	557d                	li	a0,-1
    80003dba:	bfd1                	j	80003d8e <writei+0xf0>

0000000080003dbc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003dbc:	1141                	addi	sp,sp,-16
    80003dbe:	e406                	sd	ra,8(sp)
    80003dc0:	e022                	sd	s0,0(sp)
    80003dc2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003dc4:	4639                	li	a2,14
    80003dc6:	ffffd097          	auipc	ra,0xffffd
    80003dca:	ff2080e7          	jalr	-14(ra) # 80000db8 <strncmp>
}
    80003dce:	60a2                	ld	ra,8(sp)
    80003dd0:	6402                	ld	s0,0(sp)
    80003dd2:	0141                	addi	sp,sp,16
    80003dd4:	8082                	ret

0000000080003dd6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dd6:	7139                	addi	sp,sp,-64
    80003dd8:	fc06                	sd	ra,56(sp)
    80003dda:	f822                	sd	s0,48(sp)
    80003ddc:	f426                	sd	s1,40(sp)
    80003dde:	f04a                	sd	s2,32(sp)
    80003de0:	ec4e                	sd	s3,24(sp)
    80003de2:	e852                	sd	s4,16(sp)
    80003de4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003de6:	04451703          	lh	a4,68(a0)
    80003dea:	4785                	li	a5,1
    80003dec:	00f71a63          	bne	a4,a5,80003e00 <dirlookup+0x2a>
    80003df0:	892a                	mv	s2,a0
    80003df2:	89ae                	mv	s3,a1
    80003df4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003df6:	457c                	lw	a5,76(a0)
    80003df8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dfa:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dfc:	e79d                	bnez	a5,80003e2a <dirlookup+0x54>
    80003dfe:	a8a5                	j	80003e76 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e00:	00005517          	auipc	a0,0x5
    80003e04:	97050513          	addi	a0,a0,-1680 # 80008770 <syscallNames+0x1a8>
    80003e08:	ffffc097          	auipc	ra,0xffffc
    80003e0c:	736080e7          	jalr	1846(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e10:	00005517          	auipc	a0,0x5
    80003e14:	97850513          	addi	a0,a0,-1672 # 80008788 <syscallNames+0x1c0>
    80003e18:	ffffc097          	auipc	ra,0xffffc
    80003e1c:	726080e7          	jalr	1830(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e20:	24c1                	addiw	s1,s1,16
    80003e22:	04c92783          	lw	a5,76(s2)
    80003e26:	04f4f763          	bgeu	s1,a5,80003e74 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e2a:	4741                	li	a4,16
    80003e2c:	86a6                	mv	a3,s1
    80003e2e:	fc040613          	addi	a2,s0,-64
    80003e32:	4581                	li	a1,0
    80003e34:	854a                	mv	a0,s2
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	d70080e7          	jalr	-656(ra) # 80003ba6 <readi>
    80003e3e:	47c1                	li	a5,16
    80003e40:	fcf518e3          	bne	a0,a5,80003e10 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e44:	fc045783          	lhu	a5,-64(s0)
    80003e48:	dfe1                	beqz	a5,80003e20 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e4a:	fc240593          	addi	a1,s0,-62
    80003e4e:	854e                	mv	a0,s3
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	f6c080e7          	jalr	-148(ra) # 80003dbc <namecmp>
    80003e58:	f561                	bnez	a0,80003e20 <dirlookup+0x4a>
      if(poff)
    80003e5a:	000a0463          	beqz	s4,80003e62 <dirlookup+0x8c>
        *poff = off;
    80003e5e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e62:	fc045583          	lhu	a1,-64(s0)
    80003e66:	00092503          	lw	a0,0(s2)
    80003e6a:	fffff097          	auipc	ra,0xfffff
    80003e6e:	754080e7          	jalr	1876(ra) # 800035be <iget>
    80003e72:	a011                	j	80003e76 <dirlookup+0xa0>
  return 0;
    80003e74:	4501                	li	a0,0
}
    80003e76:	70e2                	ld	ra,56(sp)
    80003e78:	7442                	ld	s0,48(sp)
    80003e7a:	74a2                	ld	s1,40(sp)
    80003e7c:	7902                	ld	s2,32(sp)
    80003e7e:	69e2                	ld	s3,24(sp)
    80003e80:	6a42                	ld	s4,16(sp)
    80003e82:	6121                	addi	sp,sp,64
    80003e84:	8082                	ret

0000000080003e86 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e86:	711d                	addi	sp,sp,-96
    80003e88:	ec86                	sd	ra,88(sp)
    80003e8a:	e8a2                	sd	s0,80(sp)
    80003e8c:	e4a6                	sd	s1,72(sp)
    80003e8e:	e0ca                	sd	s2,64(sp)
    80003e90:	fc4e                	sd	s3,56(sp)
    80003e92:	f852                	sd	s4,48(sp)
    80003e94:	f456                	sd	s5,40(sp)
    80003e96:	f05a                	sd	s6,32(sp)
    80003e98:	ec5e                	sd	s7,24(sp)
    80003e9a:	e862                	sd	s8,16(sp)
    80003e9c:	e466                	sd	s9,8(sp)
    80003e9e:	1080                	addi	s0,sp,96
    80003ea0:	84aa                	mv	s1,a0
    80003ea2:	8b2e                	mv	s6,a1
    80003ea4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ea6:	00054703          	lbu	a4,0(a0)
    80003eaa:	02f00793          	li	a5,47
    80003eae:	02f70363          	beq	a4,a5,80003ed4 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003eb2:	ffffe097          	auipc	ra,0xffffe
    80003eb6:	afe080e7          	jalr	-1282(ra) # 800019b0 <myproc>
    80003eba:	15053503          	ld	a0,336(a0)
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	9f6080e7          	jalr	-1546(ra) # 800038b4 <idup>
    80003ec6:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ec8:	02f00913          	li	s2,47
  len = path - s;
    80003ecc:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003ece:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ed0:	4c05                	li	s8,1
    80003ed2:	a865                	j	80003f8a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ed4:	4585                	li	a1,1
    80003ed6:	4505                	li	a0,1
    80003ed8:	fffff097          	auipc	ra,0xfffff
    80003edc:	6e6080e7          	jalr	1766(ra) # 800035be <iget>
    80003ee0:	89aa                	mv	s3,a0
    80003ee2:	b7dd                	j	80003ec8 <namex+0x42>
      iunlockput(ip);
    80003ee4:	854e                	mv	a0,s3
    80003ee6:	00000097          	auipc	ra,0x0
    80003eea:	c6e080e7          	jalr	-914(ra) # 80003b54 <iunlockput>
      return 0;
    80003eee:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ef0:	854e                	mv	a0,s3
    80003ef2:	60e6                	ld	ra,88(sp)
    80003ef4:	6446                	ld	s0,80(sp)
    80003ef6:	64a6                	ld	s1,72(sp)
    80003ef8:	6906                	ld	s2,64(sp)
    80003efa:	79e2                	ld	s3,56(sp)
    80003efc:	7a42                	ld	s4,48(sp)
    80003efe:	7aa2                	ld	s5,40(sp)
    80003f00:	7b02                	ld	s6,32(sp)
    80003f02:	6be2                	ld	s7,24(sp)
    80003f04:	6c42                	ld	s8,16(sp)
    80003f06:	6ca2                	ld	s9,8(sp)
    80003f08:	6125                	addi	sp,sp,96
    80003f0a:	8082                	ret
      iunlock(ip);
    80003f0c:	854e                	mv	a0,s3
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	aa6080e7          	jalr	-1370(ra) # 800039b4 <iunlock>
      return ip;
    80003f16:	bfe9                	j	80003ef0 <namex+0x6a>
      iunlockput(ip);
    80003f18:	854e                	mv	a0,s3
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	c3a080e7          	jalr	-966(ra) # 80003b54 <iunlockput>
      return 0;
    80003f22:	89d2                	mv	s3,s4
    80003f24:	b7f1                	j	80003ef0 <namex+0x6a>
  len = path - s;
    80003f26:	40b48633          	sub	a2,s1,a1
    80003f2a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f2e:	094cd463          	bge	s9,s4,80003fb6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f32:	4639                	li	a2,14
    80003f34:	8556                	mv	a0,s5
    80003f36:	ffffd097          	auipc	ra,0xffffd
    80003f3a:	e0a080e7          	jalr	-502(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003f3e:	0004c783          	lbu	a5,0(s1)
    80003f42:	01279763          	bne	a5,s2,80003f50 <namex+0xca>
    path++;
    80003f46:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f48:	0004c783          	lbu	a5,0(s1)
    80003f4c:	ff278de3          	beq	a5,s2,80003f46 <namex+0xc0>
    ilock(ip);
    80003f50:	854e                	mv	a0,s3
    80003f52:	00000097          	auipc	ra,0x0
    80003f56:	9a0080e7          	jalr	-1632(ra) # 800038f2 <ilock>
    if(ip->type != T_DIR){
    80003f5a:	04499783          	lh	a5,68(s3)
    80003f5e:	f98793e3          	bne	a5,s8,80003ee4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f62:	000b0563          	beqz	s6,80003f6c <namex+0xe6>
    80003f66:	0004c783          	lbu	a5,0(s1)
    80003f6a:	d3cd                	beqz	a5,80003f0c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f6c:	865e                	mv	a2,s7
    80003f6e:	85d6                	mv	a1,s5
    80003f70:	854e                	mv	a0,s3
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	e64080e7          	jalr	-412(ra) # 80003dd6 <dirlookup>
    80003f7a:	8a2a                	mv	s4,a0
    80003f7c:	dd51                	beqz	a0,80003f18 <namex+0x92>
    iunlockput(ip);
    80003f7e:	854e                	mv	a0,s3
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	bd4080e7          	jalr	-1068(ra) # 80003b54 <iunlockput>
    ip = next;
    80003f88:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f8a:	0004c783          	lbu	a5,0(s1)
    80003f8e:	05279763          	bne	a5,s2,80003fdc <namex+0x156>
    path++;
    80003f92:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f94:	0004c783          	lbu	a5,0(s1)
    80003f98:	ff278de3          	beq	a5,s2,80003f92 <namex+0x10c>
  if(*path == 0)
    80003f9c:	c79d                	beqz	a5,80003fca <namex+0x144>
    path++;
    80003f9e:	85a6                	mv	a1,s1
  len = path - s;
    80003fa0:	8a5e                	mv	s4,s7
    80003fa2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003fa4:	01278963          	beq	a5,s2,80003fb6 <namex+0x130>
    80003fa8:	dfbd                	beqz	a5,80003f26 <namex+0xa0>
    path++;
    80003faa:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fac:	0004c783          	lbu	a5,0(s1)
    80003fb0:	ff279ce3          	bne	a5,s2,80003fa8 <namex+0x122>
    80003fb4:	bf8d                	j	80003f26 <namex+0xa0>
    memmove(name, s, len);
    80003fb6:	2601                	sext.w	a2,a2
    80003fb8:	8556                	mv	a0,s5
    80003fba:	ffffd097          	auipc	ra,0xffffd
    80003fbe:	d86080e7          	jalr	-634(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003fc2:	9a56                	add	s4,s4,s5
    80003fc4:	000a0023          	sb	zero,0(s4)
    80003fc8:	bf9d                	j	80003f3e <namex+0xb8>
  if(nameiparent){
    80003fca:	f20b03e3          	beqz	s6,80003ef0 <namex+0x6a>
    iput(ip);
    80003fce:	854e                	mv	a0,s3
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	adc080e7          	jalr	-1316(ra) # 80003aac <iput>
    return 0;
    80003fd8:	4981                	li	s3,0
    80003fda:	bf19                	j	80003ef0 <namex+0x6a>
  if(*path == 0)
    80003fdc:	d7fd                	beqz	a5,80003fca <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fde:	0004c783          	lbu	a5,0(s1)
    80003fe2:	85a6                	mv	a1,s1
    80003fe4:	b7d1                	j	80003fa8 <namex+0x122>

0000000080003fe6 <dirlink>:
{
    80003fe6:	7139                	addi	sp,sp,-64
    80003fe8:	fc06                	sd	ra,56(sp)
    80003fea:	f822                	sd	s0,48(sp)
    80003fec:	f426                	sd	s1,40(sp)
    80003fee:	f04a                	sd	s2,32(sp)
    80003ff0:	ec4e                	sd	s3,24(sp)
    80003ff2:	e852                	sd	s4,16(sp)
    80003ff4:	0080                	addi	s0,sp,64
    80003ff6:	892a                	mv	s2,a0
    80003ff8:	8a2e                	mv	s4,a1
    80003ffa:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ffc:	4601                	li	a2,0
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	dd8080e7          	jalr	-552(ra) # 80003dd6 <dirlookup>
    80004006:	e93d                	bnez	a0,8000407c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004008:	04c92483          	lw	s1,76(s2)
    8000400c:	c49d                	beqz	s1,8000403a <dirlink+0x54>
    8000400e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004010:	4741                	li	a4,16
    80004012:	86a6                	mv	a3,s1
    80004014:	fc040613          	addi	a2,s0,-64
    80004018:	4581                	li	a1,0
    8000401a:	854a                	mv	a0,s2
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	b8a080e7          	jalr	-1142(ra) # 80003ba6 <readi>
    80004024:	47c1                	li	a5,16
    80004026:	06f51163          	bne	a0,a5,80004088 <dirlink+0xa2>
    if(de.inum == 0)
    8000402a:	fc045783          	lhu	a5,-64(s0)
    8000402e:	c791                	beqz	a5,8000403a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004030:	24c1                	addiw	s1,s1,16
    80004032:	04c92783          	lw	a5,76(s2)
    80004036:	fcf4ede3          	bltu	s1,a5,80004010 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000403a:	4639                	li	a2,14
    8000403c:	85d2                	mv	a1,s4
    8000403e:	fc240513          	addi	a0,s0,-62
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	db2080e7          	jalr	-590(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000404a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000404e:	4741                	li	a4,16
    80004050:	86a6                	mv	a3,s1
    80004052:	fc040613          	addi	a2,s0,-64
    80004056:	4581                	li	a1,0
    80004058:	854a                	mv	a0,s2
    8000405a:	00000097          	auipc	ra,0x0
    8000405e:	c44080e7          	jalr	-956(ra) # 80003c9e <writei>
    80004062:	872a                	mv	a4,a0
    80004064:	47c1                	li	a5,16
  return 0;
    80004066:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004068:	02f71863          	bne	a4,a5,80004098 <dirlink+0xb2>
}
    8000406c:	70e2                	ld	ra,56(sp)
    8000406e:	7442                	ld	s0,48(sp)
    80004070:	74a2                	ld	s1,40(sp)
    80004072:	7902                	ld	s2,32(sp)
    80004074:	69e2                	ld	s3,24(sp)
    80004076:	6a42                	ld	s4,16(sp)
    80004078:	6121                	addi	sp,sp,64
    8000407a:	8082                	ret
    iput(ip);
    8000407c:	00000097          	auipc	ra,0x0
    80004080:	a30080e7          	jalr	-1488(ra) # 80003aac <iput>
    return -1;
    80004084:	557d                	li	a0,-1
    80004086:	b7dd                	j	8000406c <dirlink+0x86>
      panic("dirlink read");
    80004088:	00004517          	auipc	a0,0x4
    8000408c:	71050513          	addi	a0,a0,1808 # 80008798 <syscallNames+0x1d0>
    80004090:	ffffc097          	auipc	ra,0xffffc
    80004094:	4ae080e7          	jalr	1198(ra) # 8000053e <panic>
    panic("dirlink");
    80004098:	00005517          	auipc	a0,0x5
    8000409c:	80850513          	addi	a0,a0,-2040 # 800088a0 <syscallNames+0x2d8>
    800040a0:	ffffc097          	auipc	ra,0xffffc
    800040a4:	49e080e7          	jalr	1182(ra) # 8000053e <panic>

00000000800040a8 <namei>:

struct inode*
namei(char *path)
{
    800040a8:	1101                	addi	sp,sp,-32
    800040aa:	ec06                	sd	ra,24(sp)
    800040ac:	e822                	sd	s0,16(sp)
    800040ae:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040b0:	fe040613          	addi	a2,s0,-32
    800040b4:	4581                	li	a1,0
    800040b6:	00000097          	auipc	ra,0x0
    800040ba:	dd0080e7          	jalr	-560(ra) # 80003e86 <namex>
}
    800040be:	60e2                	ld	ra,24(sp)
    800040c0:	6442                	ld	s0,16(sp)
    800040c2:	6105                	addi	sp,sp,32
    800040c4:	8082                	ret

00000000800040c6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040c6:	1141                	addi	sp,sp,-16
    800040c8:	e406                	sd	ra,8(sp)
    800040ca:	e022                	sd	s0,0(sp)
    800040cc:	0800                	addi	s0,sp,16
    800040ce:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040d0:	4585                	li	a1,1
    800040d2:	00000097          	auipc	ra,0x0
    800040d6:	db4080e7          	jalr	-588(ra) # 80003e86 <namex>
}
    800040da:	60a2                	ld	ra,8(sp)
    800040dc:	6402                	ld	s0,0(sp)
    800040de:	0141                	addi	sp,sp,16
    800040e0:	8082                	ret

00000000800040e2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040e2:	1101                	addi	sp,sp,-32
    800040e4:	ec06                	sd	ra,24(sp)
    800040e6:	e822                	sd	s0,16(sp)
    800040e8:	e426                	sd	s1,8(sp)
    800040ea:	e04a                	sd	s2,0(sp)
    800040ec:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040ee:	0001d917          	auipc	s2,0x1d
    800040f2:	58290913          	addi	s2,s2,1410 # 80021670 <log>
    800040f6:	01892583          	lw	a1,24(s2)
    800040fa:	02892503          	lw	a0,40(s2)
    800040fe:	fffff097          	auipc	ra,0xfffff
    80004102:	ff2080e7          	jalr	-14(ra) # 800030f0 <bread>
    80004106:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004108:	02c92683          	lw	a3,44(s2)
    8000410c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000410e:	02d05763          	blez	a3,8000413c <write_head+0x5a>
    80004112:	0001d797          	auipc	a5,0x1d
    80004116:	58e78793          	addi	a5,a5,1422 # 800216a0 <log+0x30>
    8000411a:	05c50713          	addi	a4,a0,92
    8000411e:	36fd                	addiw	a3,a3,-1
    80004120:	1682                	slli	a3,a3,0x20
    80004122:	9281                	srli	a3,a3,0x20
    80004124:	068a                	slli	a3,a3,0x2
    80004126:	0001d617          	auipc	a2,0x1d
    8000412a:	57e60613          	addi	a2,a2,1406 # 800216a4 <log+0x34>
    8000412e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004130:	4390                	lw	a2,0(a5)
    80004132:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004134:	0791                	addi	a5,a5,4
    80004136:	0711                	addi	a4,a4,4
    80004138:	fed79ce3          	bne	a5,a3,80004130 <write_head+0x4e>
  }
  bwrite(buf);
    8000413c:	8526                	mv	a0,s1
    8000413e:	fffff097          	auipc	ra,0xfffff
    80004142:	0a4080e7          	jalr	164(ra) # 800031e2 <bwrite>
  brelse(buf);
    80004146:	8526                	mv	a0,s1
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	0d8080e7          	jalr	216(ra) # 80003220 <brelse>
}
    80004150:	60e2                	ld	ra,24(sp)
    80004152:	6442                	ld	s0,16(sp)
    80004154:	64a2                	ld	s1,8(sp)
    80004156:	6902                	ld	s2,0(sp)
    80004158:	6105                	addi	sp,sp,32
    8000415a:	8082                	ret

000000008000415c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000415c:	0001d797          	auipc	a5,0x1d
    80004160:	5407a783          	lw	a5,1344(a5) # 8002169c <log+0x2c>
    80004164:	0af05d63          	blez	a5,8000421e <install_trans+0xc2>
{
    80004168:	7139                	addi	sp,sp,-64
    8000416a:	fc06                	sd	ra,56(sp)
    8000416c:	f822                	sd	s0,48(sp)
    8000416e:	f426                	sd	s1,40(sp)
    80004170:	f04a                	sd	s2,32(sp)
    80004172:	ec4e                	sd	s3,24(sp)
    80004174:	e852                	sd	s4,16(sp)
    80004176:	e456                	sd	s5,8(sp)
    80004178:	e05a                	sd	s6,0(sp)
    8000417a:	0080                	addi	s0,sp,64
    8000417c:	8b2a                	mv	s6,a0
    8000417e:	0001da97          	auipc	s5,0x1d
    80004182:	522a8a93          	addi	s5,s5,1314 # 800216a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004186:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004188:	0001d997          	auipc	s3,0x1d
    8000418c:	4e898993          	addi	s3,s3,1256 # 80021670 <log>
    80004190:	a035                	j	800041bc <install_trans+0x60>
      bunpin(dbuf);
    80004192:	8526                	mv	a0,s1
    80004194:	fffff097          	auipc	ra,0xfffff
    80004198:	166080e7          	jalr	358(ra) # 800032fa <bunpin>
    brelse(lbuf);
    8000419c:	854a                	mv	a0,s2
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	082080e7          	jalr	130(ra) # 80003220 <brelse>
    brelse(dbuf);
    800041a6:	8526                	mv	a0,s1
    800041a8:	fffff097          	auipc	ra,0xfffff
    800041ac:	078080e7          	jalr	120(ra) # 80003220 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041b0:	2a05                	addiw	s4,s4,1
    800041b2:	0a91                	addi	s5,s5,4
    800041b4:	02c9a783          	lw	a5,44(s3)
    800041b8:	04fa5963          	bge	s4,a5,8000420a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041bc:	0189a583          	lw	a1,24(s3)
    800041c0:	014585bb          	addw	a1,a1,s4
    800041c4:	2585                	addiw	a1,a1,1
    800041c6:	0289a503          	lw	a0,40(s3)
    800041ca:	fffff097          	auipc	ra,0xfffff
    800041ce:	f26080e7          	jalr	-218(ra) # 800030f0 <bread>
    800041d2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041d4:	000aa583          	lw	a1,0(s5)
    800041d8:	0289a503          	lw	a0,40(s3)
    800041dc:	fffff097          	auipc	ra,0xfffff
    800041e0:	f14080e7          	jalr	-236(ra) # 800030f0 <bread>
    800041e4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041e6:	40000613          	li	a2,1024
    800041ea:	05890593          	addi	a1,s2,88
    800041ee:	05850513          	addi	a0,a0,88
    800041f2:	ffffd097          	auipc	ra,0xffffd
    800041f6:	b4e080e7          	jalr	-1202(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041fa:	8526                	mv	a0,s1
    800041fc:	fffff097          	auipc	ra,0xfffff
    80004200:	fe6080e7          	jalr	-26(ra) # 800031e2 <bwrite>
    if(recovering == 0)
    80004204:	f80b1ce3          	bnez	s6,8000419c <install_trans+0x40>
    80004208:	b769                	j	80004192 <install_trans+0x36>
}
    8000420a:	70e2                	ld	ra,56(sp)
    8000420c:	7442                	ld	s0,48(sp)
    8000420e:	74a2                	ld	s1,40(sp)
    80004210:	7902                	ld	s2,32(sp)
    80004212:	69e2                	ld	s3,24(sp)
    80004214:	6a42                	ld	s4,16(sp)
    80004216:	6aa2                	ld	s5,8(sp)
    80004218:	6b02                	ld	s6,0(sp)
    8000421a:	6121                	addi	sp,sp,64
    8000421c:	8082                	ret
    8000421e:	8082                	ret

0000000080004220 <initlog>:
{
    80004220:	7179                	addi	sp,sp,-48
    80004222:	f406                	sd	ra,40(sp)
    80004224:	f022                	sd	s0,32(sp)
    80004226:	ec26                	sd	s1,24(sp)
    80004228:	e84a                	sd	s2,16(sp)
    8000422a:	e44e                	sd	s3,8(sp)
    8000422c:	1800                	addi	s0,sp,48
    8000422e:	892a                	mv	s2,a0
    80004230:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004232:	0001d497          	auipc	s1,0x1d
    80004236:	43e48493          	addi	s1,s1,1086 # 80021670 <log>
    8000423a:	00004597          	auipc	a1,0x4
    8000423e:	56e58593          	addi	a1,a1,1390 # 800087a8 <syscallNames+0x1e0>
    80004242:	8526                	mv	a0,s1
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	910080e7          	jalr	-1776(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000424c:	0149a583          	lw	a1,20(s3)
    80004250:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004252:	0109a783          	lw	a5,16(s3)
    80004256:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004258:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000425c:	854a                	mv	a0,s2
    8000425e:	fffff097          	auipc	ra,0xfffff
    80004262:	e92080e7          	jalr	-366(ra) # 800030f0 <bread>
  log.lh.n = lh->n;
    80004266:	4d3c                	lw	a5,88(a0)
    80004268:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000426a:	02f05563          	blez	a5,80004294 <initlog+0x74>
    8000426e:	05c50713          	addi	a4,a0,92
    80004272:	0001d697          	auipc	a3,0x1d
    80004276:	42e68693          	addi	a3,a3,1070 # 800216a0 <log+0x30>
    8000427a:	37fd                	addiw	a5,a5,-1
    8000427c:	1782                	slli	a5,a5,0x20
    8000427e:	9381                	srli	a5,a5,0x20
    80004280:	078a                	slli	a5,a5,0x2
    80004282:	06050613          	addi	a2,a0,96
    80004286:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004288:	4310                	lw	a2,0(a4)
    8000428a:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000428c:	0711                	addi	a4,a4,4
    8000428e:	0691                	addi	a3,a3,4
    80004290:	fef71ce3          	bne	a4,a5,80004288 <initlog+0x68>
  brelse(buf);
    80004294:	fffff097          	auipc	ra,0xfffff
    80004298:	f8c080e7          	jalr	-116(ra) # 80003220 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000429c:	4505                	li	a0,1
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	ebe080e7          	jalr	-322(ra) # 8000415c <install_trans>
  log.lh.n = 0;
    800042a6:	0001d797          	auipc	a5,0x1d
    800042aa:	3e07ab23          	sw	zero,1014(a5) # 8002169c <log+0x2c>
  write_head(); // clear the log
    800042ae:	00000097          	auipc	ra,0x0
    800042b2:	e34080e7          	jalr	-460(ra) # 800040e2 <write_head>
}
    800042b6:	70a2                	ld	ra,40(sp)
    800042b8:	7402                	ld	s0,32(sp)
    800042ba:	64e2                	ld	s1,24(sp)
    800042bc:	6942                	ld	s2,16(sp)
    800042be:	69a2                	ld	s3,8(sp)
    800042c0:	6145                	addi	sp,sp,48
    800042c2:	8082                	ret

00000000800042c4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042c4:	1101                	addi	sp,sp,-32
    800042c6:	ec06                	sd	ra,24(sp)
    800042c8:	e822                	sd	s0,16(sp)
    800042ca:	e426                	sd	s1,8(sp)
    800042cc:	e04a                	sd	s2,0(sp)
    800042ce:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042d0:	0001d517          	auipc	a0,0x1d
    800042d4:	3a050513          	addi	a0,a0,928 # 80021670 <log>
    800042d8:	ffffd097          	auipc	ra,0xffffd
    800042dc:	90c080e7          	jalr	-1780(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800042e0:	0001d497          	auipc	s1,0x1d
    800042e4:	39048493          	addi	s1,s1,912 # 80021670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042e8:	4979                	li	s2,30
    800042ea:	a039                	j	800042f8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042ec:	85a6                	mv	a1,s1
    800042ee:	8526                	mv	a0,s1
    800042f0:	ffffe097          	auipc	ra,0xffffe
    800042f4:	dac080e7          	jalr	-596(ra) # 8000209c <sleep>
    if(log.committing){
    800042f8:	50dc                	lw	a5,36(s1)
    800042fa:	fbed                	bnez	a5,800042ec <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042fc:	509c                	lw	a5,32(s1)
    800042fe:	0017871b          	addiw	a4,a5,1
    80004302:	0007069b          	sext.w	a3,a4
    80004306:	0027179b          	slliw	a5,a4,0x2
    8000430a:	9fb9                	addw	a5,a5,a4
    8000430c:	0017979b          	slliw	a5,a5,0x1
    80004310:	54d8                	lw	a4,44(s1)
    80004312:	9fb9                	addw	a5,a5,a4
    80004314:	00f95963          	bge	s2,a5,80004326 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004318:	85a6                	mv	a1,s1
    8000431a:	8526                	mv	a0,s1
    8000431c:	ffffe097          	auipc	ra,0xffffe
    80004320:	d80080e7          	jalr	-640(ra) # 8000209c <sleep>
    80004324:	bfd1                	j	800042f8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004326:	0001d517          	auipc	a0,0x1d
    8000432a:	34a50513          	addi	a0,a0,842 # 80021670 <log>
    8000432e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004330:	ffffd097          	auipc	ra,0xffffd
    80004334:	968080e7          	jalr	-1688(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004338:	60e2                	ld	ra,24(sp)
    8000433a:	6442                	ld	s0,16(sp)
    8000433c:	64a2                	ld	s1,8(sp)
    8000433e:	6902                	ld	s2,0(sp)
    80004340:	6105                	addi	sp,sp,32
    80004342:	8082                	ret

0000000080004344 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004344:	7139                	addi	sp,sp,-64
    80004346:	fc06                	sd	ra,56(sp)
    80004348:	f822                	sd	s0,48(sp)
    8000434a:	f426                	sd	s1,40(sp)
    8000434c:	f04a                	sd	s2,32(sp)
    8000434e:	ec4e                	sd	s3,24(sp)
    80004350:	e852                	sd	s4,16(sp)
    80004352:	e456                	sd	s5,8(sp)
    80004354:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004356:	0001d497          	auipc	s1,0x1d
    8000435a:	31a48493          	addi	s1,s1,794 # 80021670 <log>
    8000435e:	8526                	mv	a0,s1
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	884080e7          	jalr	-1916(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004368:	509c                	lw	a5,32(s1)
    8000436a:	37fd                	addiw	a5,a5,-1
    8000436c:	0007891b          	sext.w	s2,a5
    80004370:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004372:	50dc                	lw	a5,36(s1)
    80004374:	efb9                	bnez	a5,800043d2 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004376:	06091663          	bnez	s2,800043e2 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000437a:	0001d497          	auipc	s1,0x1d
    8000437e:	2f648493          	addi	s1,s1,758 # 80021670 <log>
    80004382:	4785                	li	a5,1
    80004384:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004386:	8526                	mv	a0,s1
    80004388:	ffffd097          	auipc	ra,0xffffd
    8000438c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004390:	54dc                	lw	a5,44(s1)
    80004392:	06f04763          	bgtz	a5,80004400 <end_op+0xbc>
    acquire(&log.lock);
    80004396:	0001d497          	auipc	s1,0x1d
    8000439a:	2da48493          	addi	s1,s1,730 # 80021670 <log>
    8000439e:	8526                	mv	a0,s1
    800043a0:	ffffd097          	auipc	ra,0xffffd
    800043a4:	844080e7          	jalr	-1980(ra) # 80000be4 <acquire>
    log.committing = 0;
    800043a8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043ac:	8526                	mv	a0,s1
    800043ae:	ffffe097          	auipc	ra,0xffffe
    800043b2:	e7a080e7          	jalr	-390(ra) # 80002228 <wakeup>
    release(&log.lock);
    800043b6:	8526                	mv	a0,s1
    800043b8:	ffffd097          	auipc	ra,0xffffd
    800043bc:	8e0080e7          	jalr	-1824(ra) # 80000c98 <release>
}
    800043c0:	70e2                	ld	ra,56(sp)
    800043c2:	7442                	ld	s0,48(sp)
    800043c4:	74a2                	ld	s1,40(sp)
    800043c6:	7902                	ld	s2,32(sp)
    800043c8:	69e2                	ld	s3,24(sp)
    800043ca:	6a42                	ld	s4,16(sp)
    800043cc:	6aa2                	ld	s5,8(sp)
    800043ce:	6121                	addi	sp,sp,64
    800043d0:	8082                	ret
    panic("log.committing");
    800043d2:	00004517          	auipc	a0,0x4
    800043d6:	3de50513          	addi	a0,a0,990 # 800087b0 <syscallNames+0x1e8>
    800043da:	ffffc097          	auipc	ra,0xffffc
    800043de:	164080e7          	jalr	356(ra) # 8000053e <panic>
    wakeup(&log);
    800043e2:	0001d497          	auipc	s1,0x1d
    800043e6:	28e48493          	addi	s1,s1,654 # 80021670 <log>
    800043ea:	8526                	mv	a0,s1
    800043ec:	ffffe097          	auipc	ra,0xffffe
    800043f0:	e3c080e7          	jalr	-452(ra) # 80002228 <wakeup>
  release(&log.lock);
    800043f4:	8526                	mv	a0,s1
    800043f6:	ffffd097          	auipc	ra,0xffffd
    800043fa:	8a2080e7          	jalr	-1886(ra) # 80000c98 <release>
  if(do_commit){
    800043fe:	b7c9                	j	800043c0 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004400:	0001da97          	auipc	s5,0x1d
    80004404:	2a0a8a93          	addi	s5,s5,672 # 800216a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004408:	0001da17          	auipc	s4,0x1d
    8000440c:	268a0a13          	addi	s4,s4,616 # 80021670 <log>
    80004410:	018a2583          	lw	a1,24(s4)
    80004414:	012585bb          	addw	a1,a1,s2
    80004418:	2585                	addiw	a1,a1,1
    8000441a:	028a2503          	lw	a0,40(s4)
    8000441e:	fffff097          	auipc	ra,0xfffff
    80004422:	cd2080e7          	jalr	-814(ra) # 800030f0 <bread>
    80004426:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004428:	000aa583          	lw	a1,0(s5)
    8000442c:	028a2503          	lw	a0,40(s4)
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	cc0080e7          	jalr	-832(ra) # 800030f0 <bread>
    80004438:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000443a:	40000613          	li	a2,1024
    8000443e:	05850593          	addi	a1,a0,88
    80004442:	05848513          	addi	a0,s1,88
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	8fa080e7          	jalr	-1798(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000444e:	8526                	mv	a0,s1
    80004450:	fffff097          	auipc	ra,0xfffff
    80004454:	d92080e7          	jalr	-622(ra) # 800031e2 <bwrite>
    brelse(from);
    80004458:	854e                	mv	a0,s3
    8000445a:	fffff097          	auipc	ra,0xfffff
    8000445e:	dc6080e7          	jalr	-570(ra) # 80003220 <brelse>
    brelse(to);
    80004462:	8526                	mv	a0,s1
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	dbc080e7          	jalr	-580(ra) # 80003220 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000446c:	2905                	addiw	s2,s2,1
    8000446e:	0a91                	addi	s5,s5,4
    80004470:	02ca2783          	lw	a5,44(s4)
    80004474:	f8f94ee3          	blt	s2,a5,80004410 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	c6a080e7          	jalr	-918(ra) # 800040e2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004480:	4501                	li	a0,0
    80004482:	00000097          	auipc	ra,0x0
    80004486:	cda080e7          	jalr	-806(ra) # 8000415c <install_trans>
    log.lh.n = 0;
    8000448a:	0001d797          	auipc	a5,0x1d
    8000448e:	2007a923          	sw	zero,530(a5) # 8002169c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004492:	00000097          	auipc	ra,0x0
    80004496:	c50080e7          	jalr	-944(ra) # 800040e2 <write_head>
    8000449a:	bdf5                	j	80004396 <end_op+0x52>

000000008000449c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000449c:	1101                	addi	sp,sp,-32
    8000449e:	ec06                	sd	ra,24(sp)
    800044a0:	e822                	sd	s0,16(sp)
    800044a2:	e426                	sd	s1,8(sp)
    800044a4:	e04a                	sd	s2,0(sp)
    800044a6:	1000                	addi	s0,sp,32
    800044a8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044aa:	0001d917          	auipc	s2,0x1d
    800044ae:	1c690913          	addi	s2,s2,454 # 80021670 <log>
    800044b2:	854a                	mv	a0,s2
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	730080e7          	jalr	1840(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044bc:	02c92603          	lw	a2,44(s2)
    800044c0:	47f5                	li	a5,29
    800044c2:	06c7c563          	blt	a5,a2,8000452c <log_write+0x90>
    800044c6:	0001d797          	auipc	a5,0x1d
    800044ca:	1c67a783          	lw	a5,454(a5) # 8002168c <log+0x1c>
    800044ce:	37fd                	addiw	a5,a5,-1
    800044d0:	04f65e63          	bge	a2,a5,8000452c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044d4:	0001d797          	auipc	a5,0x1d
    800044d8:	1bc7a783          	lw	a5,444(a5) # 80021690 <log+0x20>
    800044dc:	06f05063          	blez	a5,8000453c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044e0:	4781                	li	a5,0
    800044e2:	06c05563          	blez	a2,8000454c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044e6:	44cc                	lw	a1,12(s1)
    800044e8:	0001d717          	auipc	a4,0x1d
    800044ec:	1b870713          	addi	a4,a4,440 # 800216a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044f0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044f2:	4314                	lw	a3,0(a4)
    800044f4:	04b68c63          	beq	a3,a1,8000454c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044f8:	2785                	addiw	a5,a5,1
    800044fa:	0711                	addi	a4,a4,4
    800044fc:	fef61be3          	bne	a2,a5,800044f2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004500:	0621                	addi	a2,a2,8
    80004502:	060a                	slli	a2,a2,0x2
    80004504:	0001d797          	auipc	a5,0x1d
    80004508:	16c78793          	addi	a5,a5,364 # 80021670 <log>
    8000450c:	963e                	add	a2,a2,a5
    8000450e:	44dc                	lw	a5,12(s1)
    80004510:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004512:	8526                	mv	a0,s1
    80004514:	fffff097          	auipc	ra,0xfffff
    80004518:	daa080e7          	jalr	-598(ra) # 800032be <bpin>
    log.lh.n++;
    8000451c:	0001d717          	auipc	a4,0x1d
    80004520:	15470713          	addi	a4,a4,340 # 80021670 <log>
    80004524:	575c                	lw	a5,44(a4)
    80004526:	2785                	addiw	a5,a5,1
    80004528:	d75c                	sw	a5,44(a4)
    8000452a:	a835                	j	80004566 <log_write+0xca>
    panic("too big a transaction");
    8000452c:	00004517          	auipc	a0,0x4
    80004530:	29450513          	addi	a0,a0,660 # 800087c0 <syscallNames+0x1f8>
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	00a080e7          	jalr	10(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000453c:	00004517          	auipc	a0,0x4
    80004540:	29c50513          	addi	a0,a0,668 # 800087d8 <syscallNames+0x210>
    80004544:	ffffc097          	auipc	ra,0xffffc
    80004548:	ffa080e7          	jalr	-6(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000454c:	00878713          	addi	a4,a5,8
    80004550:	00271693          	slli	a3,a4,0x2
    80004554:	0001d717          	auipc	a4,0x1d
    80004558:	11c70713          	addi	a4,a4,284 # 80021670 <log>
    8000455c:	9736                	add	a4,a4,a3
    8000455e:	44d4                	lw	a3,12(s1)
    80004560:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004562:	faf608e3          	beq	a2,a5,80004512 <log_write+0x76>
  }
  release(&log.lock);
    80004566:	0001d517          	auipc	a0,0x1d
    8000456a:	10a50513          	addi	a0,a0,266 # 80021670 <log>
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	72a080e7          	jalr	1834(ra) # 80000c98 <release>
}
    80004576:	60e2                	ld	ra,24(sp)
    80004578:	6442                	ld	s0,16(sp)
    8000457a:	64a2                	ld	s1,8(sp)
    8000457c:	6902                	ld	s2,0(sp)
    8000457e:	6105                	addi	sp,sp,32
    80004580:	8082                	ret

0000000080004582 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004582:	1101                	addi	sp,sp,-32
    80004584:	ec06                	sd	ra,24(sp)
    80004586:	e822                	sd	s0,16(sp)
    80004588:	e426                	sd	s1,8(sp)
    8000458a:	e04a                	sd	s2,0(sp)
    8000458c:	1000                	addi	s0,sp,32
    8000458e:	84aa                	mv	s1,a0
    80004590:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004592:	00004597          	auipc	a1,0x4
    80004596:	26658593          	addi	a1,a1,614 # 800087f8 <syscallNames+0x230>
    8000459a:	0521                	addi	a0,a0,8
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	5b8080e7          	jalr	1464(ra) # 80000b54 <initlock>
  lk->name = name;
    800045a4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045a8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045ac:	0204a423          	sw	zero,40(s1)
}
    800045b0:	60e2                	ld	ra,24(sp)
    800045b2:	6442                	ld	s0,16(sp)
    800045b4:	64a2                	ld	s1,8(sp)
    800045b6:	6902                	ld	s2,0(sp)
    800045b8:	6105                	addi	sp,sp,32
    800045ba:	8082                	ret

00000000800045bc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045bc:	1101                	addi	sp,sp,-32
    800045be:	ec06                	sd	ra,24(sp)
    800045c0:	e822                	sd	s0,16(sp)
    800045c2:	e426                	sd	s1,8(sp)
    800045c4:	e04a                	sd	s2,0(sp)
    800045c6:	1000                	addi	s0,sp,32
    800045c8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045ca:	00850913          	addi	s2,a0,8
    800045ce:	854a                	mv	a0,s2
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	614080e7          	jalr	1556(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800045d8:	409c                	lw	a5,0(s1)
    800045da:	cb89                	beqz	a5,800045ec <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045dc:	85ca                	mv	a1,s2
    800045de:	8526                	mv	a0,s1
    800045e0:	ffffe097          	auipc	ra,0xffffe
    800045e4:	abc080e7          	jalr	-1348(ra) # 8000209c <sleep>
  while (lk->locked) {
    800045e8:	409c                	lw	a5,0(s1)
    800045ea:	fbed                	bnez	a5,800045dc <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045ec:	4785                	li	a5,1
    800045ee:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045f0:	ffffd097          	auipc	ra,0xffffd
    800045f4:	3c0080e7          	jalr	960(ra) # 800019b0 <myproc>
    800045f8:	591c                	lw	a5,48(a0)
    800045fa:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045fc:	854a                	mv	a0,s2
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	69a080e7          	jalr	1690(ra) # 80000c98 <release>
}
    80004606:	60e2                	ld	ra,24(sp)
    80004608:	6442                	ld	s0,16(sp)
    8000460a:	64a2                	ld	s1,8(sp)
    8000460c:	6902                	ld	s2,0(sp)
    8000460e:	6105                	addi	sp,sp,32
    80004610:	8082                	ret

0000000080004612 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004612:	1101                	addi	sp,sp,-32
    80004614:	ec06                	sd	ra,24(sp)
    80004616:	e822                	sd	s0,16(sp)
    80004618:	e426                	sd	s1,8(sp)
    8000461a:	e04a                	sd	s2,0(sp)
    8000461c:	1000                	addi	s0,sp,32
    8000461e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004620:	00850913          	addi	s2,a0,8
    80004624:	854a                	mv	a0,s2
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	5be080e7          	jalr	1470(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000462e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004632:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004636:	8526                	mv	a0,s1
    80004638:	ffffe097          	auipc	ra,0xffffe
    8000463c:	bf0080e7          	jalr	-1040(ra) # 80002228 <wakeup>
  release(&lk->lk);
    80004640:	854a                	mv	a0,s2
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	656080e7          	jalr	1622(ra) # 80000c98 <release>
}
    8000464a:	60e2                	ld	ra,24(sp)
    8000464c:	6442                	ld	s0,16(sp)
    8000464e:	64a2                	ld	s1,8(sp)
    80004650:	6902                	ld	s2,0(sp)
    80004652:	6105                	addi	sp,sp,32
    80004654:	8082                	ret

0000000080004656 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004656:	7179                	addi	sp,sp,-48
    80004658:	f406                	sd	ra,40(sp)
    8000465a:	f022                	sd	s0,32(sp)
    8000465c:	ec26                	sd	s1,24(sp)
    8000465e:	e84a                	sd	s2,16(sp)
    80004660:	e44e                	sd	s3,8(sp)
    80004662:	1800                	addi	s0,sp,48
    80004664:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004666:	00850913          	addi	s2,a0,8
    8000466a:	854a                	mv	a0,s2
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	578080e7          	jalr	1400(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004674:	409c                	lw	a5,0(s1)
    80004676:	ef99                	bnez	a5,80004694 <holdingsleep+0x3e>
    80004678:	4481                	li	s1,0
  release(&lk->lk);
    8000467a:	854a                	mv	a0,s2
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	61c080e7          	jalr	1564(ra) # 80000c98 <release>
  return r;
}
    80004684:	8526                	mv	a0,s1
    80004686:	70a2                	ld	ra,40(sp)
    80004688:	7402                	ld	s0,32(sp)
    8000468a:	64e2                	ld	s1,24(sp)
    8000468c:	6942                	ld	s2,16(sp)
    8000468e:	69a2                	ld	s3,8(sp)
    80004690:	6145                	addi	sp,sp,48
    80004692:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004694:	0284a983          	lw	s3,40(s1)
    80004698:	ffffd097          	auipc	ra,0xffffd
    8000469c:	318080e7          	jalr	792(ra) # 800019b0 <myproc>
    800046a0:	5904                	lw	s1,48(a0)
    800046a2:	413484b3          	sub	s1,s1,s3
    800046a6:	0014b493          	seqz	s1,s1
    800046aa:	bfc1                	j	8000467a <holdingsleep+0x24>

00000000800046ac <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046ac:	1141                	addi	sp,sp,-16
    800046ae:	e406                	sd	ra,8(sp)
    800046b0:	e022                	sd	s0,0(sp)
    800046b2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046b4:	00004597          	auipc	a1,0x4
    800046b8:	15458593          	addi	a1,a1,340 # 80008808 <syscallNames+0x240>
    800046bc:	0001d517          	auipc	a0,0x1d
    800046c0:	0fc50513          	addi	a0,a0,252 # 800217b8 <ftable>
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	490080e7          	jalr	1168(ra) # 80000b54 <initlock>
}
    800046cc:	60a2                	ld	ra,8(sp)
    800046ce:	6402                	ld	s0,0(sp)
    800046d0:	0141                	addi	sp,sp,16
    800046d2:	8082                	ret

00000000800046d4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046d4:	1101                	addi	sp,sp,-32
    800046d6:	ec06                	sd	ra,24(sp)
    800046d8:	e822                	sd	s0,16(sp)
    800046da:	e426                	sd	s1,8(sp)
    800046dc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046de:	0001d517          	auipc	a0,0x1d
    800046e2:	0da50513          	addi	a0,a0,218 # 800217b8 <ftable>
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	4fe080e7          	jalr	1278(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046ee:	0001d497          	auipc	s1,0x1d
    800046f2:	0e248493          	addi	s1,s1,226 # 800217d0 <ftable+0x18>
    800046f6:	0001e717          	auipc	a4,0x1e
    800046fa:	07a70713          	addi	a4,a4,122 # 80022770 <ftable+0xfb8>
    if(f->ref == 0){
    800046fe:	40dc                	lw	a5,4(s1)
    80004700:	cf99                	beqz	a5,8000471e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004702:	02848493          	addi	s1,s1,40
    80004706:	fee49ce3          	bne	s1,a4,800046fe <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000470a:	0001d517          	auipc	a0,0x1d
    8000470e:	0ae50513          	addi	a0,a0,174 # 800217b8 <ftable>
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	586080e7          	jalr	1414(ra) # 80000c98 <release>
  return 0;
    8000471a:	4481                	li	s1,0
    8000471c:	a819                	j	80004732 <filealloc+0x5e>
      f->ref = 1;
    8000471e:	4785                	li	a5,1
    80004720:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004722:	0001d517          	auipc	a0,0x1d
    80004726:	09650513          	addi	a0,a0,150 # 800217b8 <ftable>
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	56e080e7          	jalr	1390(ra) # 80000c98 <release>
}
    80004732:	8526                	mv	a0,s1
    80004734:	60e2                	ld	ra,24(sp)
    80004736:	6442                	ld	s0,16(sp)
    80004738:	64a2                	ld	s1,8(sp)
    8000473a:	6105                	addi	sp,sp,32
    8000473c:	8082                	ret

000000008000473e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000473e:	1101                	addi	sp,sp,-32
    80004740:	ec06                	sd	ra,24(sp)
    80004742:	e822                	sd	s0,16(sp)
    80004744:	e426                	sd	s1,8(sp)
    80004746:	1000                	addi	s0,sp,32
    80004748:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000474a:	0001d517          	auipc	a0,0x1d
    8000474e:	06e50513          	addi	a0,a0,110 # 800217b8 <ftable>
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	492080e7          	jalr	1170(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000475a:	40dc                	lw	a5,4(s1)
    8000475c:	02f05263          	blez	a5,80004780 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004760:	2785                	addiw	a5,a5,1
    80004762:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004764:	0001d517          	auipc	a0,0x1d
    80004768:	05450513          	addi	a0,a0,84 # 800217b8 <ftable>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	52c080e7          	jalr	1324(ra) # 80000c98 <release>
  return f;
}
    80004774:	8526                	mv	a0,s1
    80004776:	60e2                	ld	ra,24(sp)
    80004778:	6442                	ld	s0,16(sp)
    8000477a:	64a2                	ld	s1,8(sp)
    8000477c:	6105                	addi	sp,sp,32
    8000477e:	8082                	ret
    panic("filedup");
    80004780:	00004517          	auipc	a0,0x4
    80004784:	09050513          	addi	a0,a0,144 # 80008810 <syscallNames+0x248>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	db6080e7          	jalr	-586(ra) # 8000053e <panic>

0000000080004790 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004790:	7139                	addi	sp,sp,-64
    80004792:	fc06                	sd	ra,56(sp)
    80004794:	f822                	sd	s0,48(sp)
    80004796:	f426                	sd	s1,40(sp)
    80004798:	f04a                	sd	s2,32(sp)
    8000479a:	ec4e                	sd	s3,24(sp)
    8000479c:	e852                	sd	s4,16(sp)
    8000479e:	e456                	sd	s5,8(sp)
    800047a0:	0080                	addi	s0,sp,64
    800047a2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047a4:	0001d517          	auipc	a0,0x1d
    800047a8:	01450513          	addi	a0,a0,20 # 800217b8 <ftable>
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	438080e7          	jalr	1080(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047b4:	40dc                	lw	a5,4(s1)
    800047b6:	06f05163          	blez	a5,80004818 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047ba:	37fd                	addiw	a5,a5,-1
    800047bc:	0007871b          	sext.w	a4,a5
    800047c0:	c0dc                	sw	a5,4(s1)
    800047c2:	06e04363          	bgtz	a4,80004828 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047c6:	0004a903          	lw	s2,0(s1)
    800047ca:	0094ca83          	lbu	s5,9(s1)
    800047ce:	0104ba03          	ld	s4,16(s1)
    800047d2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047d6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047da:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047de:	0001d517          	auipc	a0,0x1d
    800047e2:	fda50513          	addi	a0,a0,-38 # 800217b8 <ftable>
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	4b2080e7          	jalr	1202(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800047ee:	4785                	li	a5,1
    800047f0:	04f90d63          	beq	s2,a5,8000484a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047f4:	3979                	addiw	s2,s2,-2
    800047f6:	4785                	li	a5,1
    800047f8:	0527e063          	bltu	a5,s2,80004838 <fileclose+0xa8>
    begin_op();
    800047fc:	00000097          	auipc	ra,0x0
    80004800:	ac8080e7          	jalr	-1336(ra) # 800042c4 <begin_op>
    iput(ff.ip);
    80004804:	854e                	mv	a0,s3
    80004806:	fffff097          	auipc	ra,0xfffff
    8000480a:	2a6080e7          	jalr	678(ra) # 80003aac <iput>
    end_op();
    8000480e:	00000097          	auipc	ra,0x0
    80004812:	b36080e7          	jalr	-1226(ra) # 80004344 <end_op>
    80004816:	a00d                	j	80004838 <fileclose+0xa8>
    panic("fileclose");
    80004818:	00004517          	auipc	a0,0x4
    8000481c:	00050513          	mv	a0,a0
    80004820:	ffffc097          	auipc	ra,0xffffc
    80004824:	d1e080e7          	jalr	-738(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004828:	0001d517          	auipc	a0,0x1d
    8000482c:	f9050513          	addi	a0,a0,-112 # 800217b8 <ftable>
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	468080e7          	jalr	1128(ra) # 80000c98 <release>
  }
}
    80004838:	70e2                	ld	ra,56(sp)
    8000483a:	7442                	ld	s0,48(sp)
    8000483c:	74a2                	ld	s1,40(sp)
    8000483e:	7902                	ld	s2,32(sp)
    80004840:	69e2                	ld	s3,24(sp)
    80004842:	6a42                	ld	s4,16(sp)
    80004844:	6aa2                	ld	s5,8(sp)
    80004846:	6121                	addi	sp,sp,64
    80004848:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000484a:	85d6                	mv	a1,s5
    8000484c:	8552                	mv	a0,s4
    8000484e:	00000097          	auipc	ra,0x0
    80004852:	34c080e7          	jalr	844(ra) # 80004b9a <pipeclose>
    80004856:	b7cd                	j	80004838 <fileclose+0xa8>

0000000080004858 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004858:	715d                	addi	sp,sp,-80
    8000485a:	e486                	sd	ra,72(sp)
    8000485c:	e0a2                	sd	s0,64(sp)
    8000485e:	fc26                	sd	s1,56(sp)
    80004860:	f84a                	sd	s2,48(sp)
    80004862:	f44e                	sd	s3,40(sp)
    80004864:	0880                	addi	s0,sp,80
    80004866:	84aa                	mv	s1,a0
    80004868:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000486a:	ffffd097          	auipc	ra,0xffffd
    8000486e:	146080e7          	jalr	326(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004872:	409c                	lw	a5,0(s1)
    80004874:	37f9                	addiw	a5,a5,-2
    80004876:	4705                	li	a4,1
    80004878:	04f76763          	bltu	a4,a5,800048c6 <filestat+0x6e>
    8000487c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000487e:	6c88                	ld	a0,24(s1)
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	072080e7          	jalr	114(ra) # 800038f2 <ilock>
    stati(f->ip, &st);
    80004888:	fb840593          	addi	a1,s0,-72
    8000488c:	6c88                	ld	a0,24(s1)
    8000488e:	fffff097          	auipc	ra,0xfffff
    80004892:	2ee080e7          	jalr	750(ra) # 80003b7c <stati>
    iunlock(f->ip);
    80004896:	6c88                	ld	a0,24(s1)
    80004898:	fffff097          	auipc	ra,0xfffff
    8000489c:	11c080e7          	jalr	284(ra) # 800039b4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048a0:	46e1                	li	a3,24
    800048a2:	fb840613          	addi	a2,s0,-72
    800048a6:	85ce                	mv	a1,s3
    800048a8:	05093503          	ld	a0,80(s2)
    800048ac:	ffffd097          	auipc	ra,0xffffd
    800048b0:	dc6080e7          	jalr	-570(ra) # 80001672 <copyout>
    800048b4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048b8:	60a6                	ld	ra,72(sp)
    800048ba:	6406                	ld	s0,64(sp)
    800048bc:	74e2                	ld	s1,56(sp)
    800048be:	7942                	ld	s2,48(sp)
    800048c0:	79a2                	ld	s3,40(sp)
    800048c2:	6161                	addi	sp,sp,80
    800048c4:	8082                	ret
  return -1;
    800048c6:	557d                	li	a0,-1
    800048c8:	bfc5                	j	800048b8 <filestat+0x60>

00000000800048ca <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048ca:	7179                	addi	sp,sp,-48
    800048cc:	f406                	sd	ra,40(sp)
    800048ce:	f022                	sd	s0,32(sp)
    800048d0:	ec26                	sd	s1,24(sp)
    800048d2:	e84a                	sd	s2,16(sp)
    800048d4:	e44e                	sd	s3,8(sp)
    800048d6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048d8:	00854783          	lbu	a5,8(a0)
    800048dc:	c3d5                	beqz	a5,80004980 <fileread+0xb6>
    800048de:	84aa                	mv	s1,a0
    800048e0:	89ae                	mv	s3,a1
    800048e2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048e4:	411c                	lw	a5,0(a0)
    800048e6:	4705                	li	a4,1
    800048e8:	04e78963          	beq	a5,a4,8000493a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048ec:	470d                	li	a4,3
    800048ee:	04e78d63          	beq	a5,a4,80004948 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048f2:	4709                	li	a4,2
    800048f4:	06e79e63          	bne	a5,a4,80004970 <fileread+0xa6>
    ilock(f->ip);
    800048f8:	6d08                	ld	a0,24(a0)
    800048fa:	fffff097          	auipc	ra,0xfffff
    800048fe:	ff8080e7          	jalr	-8(ra) # 800038f2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004902:	874a                	mv	a4,s2
    80004904:	5094                	lw	a3,32(s1)
    80004906:	864e                	mv	a2,s3
    80004908:	4585                	li	a1,1
    8000490a:	6c88                	ld	a0,24(s1)
    8000490c:	fffff097          	auipc	ra,0xfffff
    80004910:	29a080e7          	jalr	666(ra) # 80003ba6 <readi>
    80004914:	892a                	mv	s2,a0
    80004916:	00a05563          	blez	a0,80004920 <fileread+0x56>
      f->off += r;
    8000491a:	509c                	lw	a5,32(s1)
    8000491c:	9fa9                	addw	a5,a5,a0
    8000491e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004920:	6c88                	ld	a0,24(s1)
    80004922:	fffff097          	auipc	ra,0xfffff
    80004926:	092080e7          	jalr	146(ra) # 800039b4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000492a:	854a                	mv	a0,s2
    8000492c:	70a2                	ld	ra,40(sp)
    8000492e:	7402                	ld	s0,32(sp)
    80004930:	64e2                	ld	s1,24(sp)
    80004932:	6942                	ld	s2,16(sp)
    80004934:	69a2                	ld	s3,8(sp)
    80004936:	6145                	addi	sp,sp,48
    80004938:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000493a:	6908                	ld	a0,16(a0)
    8000493c:	00000097          	auipc	ra,0x0
    80004940:	3c8080e7          	jalr	968(ra) # 80004d04 <piperead>
    80004944:	892a                	mv	s2,a0
    80004946:	b7d5                	j	8000492a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004948:	02451783          	lh	a5,36(a0)
    8000494c:	03079693          	slli	a3,a5,0x30
    80004950:	92c1                	srli	a3,a3,0x30
    80004952:	4725                	li	a4,9
    80004954:	02d76863          	bltu	a4,a3,80004984 <fileread+0xba>
    80004958:	0792                	slli	a5,a5,0x4
    8000495a:	0001d717          	auipc	a4,0x1d
    8000495e:	dbe70713          	addi	a4,a4,-578 # 80021718 <devsw>
    80004962:	97ba                	add	a5,a5,a4
    80004964:	639c                	ld	a5,0(a5)
    80004966:	c38d                	beqz	a5,80004988 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004968:	4505                	li	a0,1
    8000496a:	9782                	jalr	a5
    8000496c:	892a                	mv	s2,a0
    8000496e:	bf75                	j	8000492a <fileread+0x60>
    panic("fileread");
    80004970:	00004517          	auipc	a0,0x4
    80004974:	eb850513          	addi	a0,a0,-328 # 80008828 <syscallNames+0x260>
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	bc6080e7          	jalr	-1082(ra) # 8000053e <panic>
    return -1;
    80004980:	597d                	li	s2,-1
    80004982:	b765                	j	8000492a <fileread+0x60>
      return -1;
    80004984:	597d                	li	s2,-1
    80004986:	b755                	j	8000492a <fileread+0x60>
    80004988:	597d                	li	s2,-1
    8000498a:	b745                	j	8000492a <fileread+0x60>

000000008000498c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000498c:	715d                	addi	sp,sp,-80
    8000498e:	e486                	sd	ra,72(sp)
    80004990:	e0a2                	sd	s0,64(sp)
    80004992:	fc26                	sd	s1,56(sp)
    80004994:	f84a                	sd	s2,48(sp)
    80004996:	f44e                	sd	s3,40(sp)
    80004998:	f052                	sd	s4,32(sp)
    8000499a:	ec56                	sd	s5,24(sp)
    8000499c:	e85a                	sd	s6,16(sp)
    8000499e:	e45e                	sd	s7,8(sp)
    800049a0:	e062                	sd	s8,0(sp)
    800049a2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049a4:	00954783          	lbu	a5,9(a0)
    800049a8:	10078663          	beqz	a5,80004ab4 <filewrite+0x128>
    800049ac:	892a                	mv	s2,a0
    800049ae:	8aae                	mv	s5,a1
    800049b0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049b2:	411c                	lw	a5,0(a0)
    800049b4:	4705                	li	a4,1
    800049b6:	02e78263          	beq	a5,a4,800049da <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049ba:	470d                	li	a4,3
    800049bc:	02e78663          	beq	a5,a4,800049e8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049c0:	4709                	li	a4,2
    800049c2:	0ee79163          	bne	a5,a4,80004aa4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049c6:	0ac05d63          	blez	a2,80004a80 <filewrite+0xf4>
    int i = 0;
    800049ca:	4981                	li	s3,0
    800049cc:	6b05                	lui	s6,0x1
    800049ce:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049d2:	6b85                	lui	s7,0x1
    800049d4:	c00b8b9b          	addiw	s7,s7,-1024
    800049d8:	a861                	j	80004a70 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049da:	6908                	ld	a0,16(a0)
    800049dc:	00000097          	auipc	ra,0x0
    800049e0:	22e080e7          	jalr	558(ra) # 80004c0a <pipewrite>
    800049e4:	8a2a                	mv	s4,a0
    800049e6:	a045                	j	80004a86 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049e8:	02451783          	lh	a5,36(a0)
    800049ec:	03079693          	slli	a3,a5,0x30
    800049f0:	92c1                	srli	a3,a3,0x30
    800049f2:	4725                	li	a4,9
    800049f4:	0cd76263          	bltu	a4,a3,80004ab8 <filewrite+0x12c>
    800049f8:	0792                	slli	a5,a5,0x4
    800049fa:	0001d717          	auipc	a4,0x1d
    800049fe:	d1e70713          	addi	a4,a4,-738 # 80021718 <devsw>
    80004a02:	97ba                	add	a5,a5,a4
    80004a04:	679c                	ld	a5,8(a5)
    80004a06:	cbdd                	beqz	a5,80004abc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a08:	4505                	li	a0,1
    80004a0a:	9782                	jalr	a5
    80004a0c:	8a2a                	mv	s4,a0
    80004a0e:	a8a5                	j	80004a86 <filewrite+0xfa>
    80004a10:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a14:	00000097          	auipc	ra,0x0
    80004a18:	8b0080e7          	jalr	-1872(ra) # 800042c4 <begin_op>
      ilock(f->ip);
    80004a1c:	01893503          	ld	a0,24(s2)
    80004a20:	fffff097          	auipc	ra,0xfffff
    80004a24:	ed2080e7          	jalr	-302(ra) # 800038f2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a28:	8762                	mv	a4,s8
    80004a2a:	02092683          	lw	a3,32(s2)
    80004a2e:	01598633          	add	a2,s3,s5
    80004a32:	4585                	li	a1,1
    80004a34:	01893503          	ld	a0,24(s2)
    80004a38:	fffff097          	auipc	ra,0xfffff
    80004a3c:	266080e7          	jalr	614(ra) # 80003c9e <writei>
    80004a40:	84aa                	mv	s1,a0
    80004a42:	00a05763          	blez	a0,80004a50 <filewrite+0xc4>
        f->off += r;
    80004a46:	02092783          	lw	a5,32(s2)
    80004a4a:	9fa9                	addw	a5,a5,a0
    80004a4c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a50:	01893503          	ld	a0,24(s2)
    80004a54:	fffff097          	auipc	ra,0xfffff
    80004a58:	f60080e7          	jalr	-160(ra) # 800039b4 <iunlock>
      end_op();
    80004a5c:	00000097          	auipc	ra,0x0
    80004a60:	8e8080e7          	jalr	-1816(ra) # 80004344 <end_op>

      if(r != n1){
    80004a64:	009c1f63          	bne	s8,s1,80004a82 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a68:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a6c:	0149db63          	bge	s3,s4,80004a82 <filewrite+0xf6>
      int n1 = n - i;
    80004a70:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a74:	84be                	mv	s1,a5
    80004a76:	2781                	sext.w	a5,a5
    80004a78:	f8fb5ce3          	bge	s6,a5,80004a10 <filewrite+0x84>
    80004a7c:	84de                	mv	s1,s7
    80004a7e:	bf49                	j	80004a10 <filewrite+0x84>
    int i = 0;
    80004a80:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a82:	013a1f63          	bne	s4,s3,80004aa0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a86:	8552                	mv	a0,s4
    80004a88:	60a6                	ld	ra,72(sp)
    80004a8a:	6406                	ld	s0,64(sp)
    80004a8c:	74e2                	ld	s1,56(sp)
    80004a8e:	7942                	ld	s2,48(sp)
    80004a90:	79a2                	ld	s3,40(sp)
    80004a92:	7a02                	ld	s4,32(sp)
    80004a94:	6ae2                	ld	s5,24(sp)
    80004a96:	6b42                	ld	s6,16(sp)
    80004a98:	6ba2                	ld	s7,8(sp)
    80004a9a:	6c02                	ld	s8,0(sp)
    80004a9c:	6161                	addi	sp,sp,80
    80004a9e:	8082                	ret
    ret = (i == n ? n : -1);
    80004aa0:	5a7d                	li	s4,-1
    80004aa2:	b7d5                	j	80004a86 <filewrite+0xfa>
    panic("filewrite");
    80004aa4:	00004517          	auipc	a0,0x4
    80004aa8:	d9450513          	addi	a0,a0,-620 # 80008838 <syscallNames+0x270>
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	a92080e7          	jalr	-1390(ra) # 8000053e <panic>
    return -1;
    80004ab4:	5a7d                	li	s4,-1
    80004ab6:	bfc1                	j	80004a86 <filewrite+0xfa>
      return -1;
    80004ab8:	5a7d                	li	s4,-1
    80004aba:	b7f1                	j	80004a86 <filewrite+0xfa>
    80004abc:	5a7d                	li	s4,-1
    80004abe:	b7e1                	j	80004a86 <filewrite+0xfa>

0000000080004ac0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ac0:	7179                	addi	sp,sp,-48
    80004ac2:	f406                	sd	ra,40(sp)
    80004ac4:	f022                	sd	s0,32(sp)
    80004ac6:	ec26                	sd	s1,24(sp)
    80004ac8:	e84a                	sd	s2,16(sp)
    80004aca:	e44e                	sd	s3,8(sp)
    80004acc:	e052                	sd	s4,0(sp)
    80004ace:	1800                	addi	s0,sp,48
    80004ad0:	84aa                	mv	s1,a0
    80004ad2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ad4:	0005b023          	sd	zero,0(a1)
    80004ad8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004adc:	00000097          	auipc	ra,0x0
    80004ae0:	bf8080e7          	jalr	-1032(ra) # 800046d4 <filealloc>
    80004ae4:	e088                	sd	a0,0(s1)
    80004ae6:	c551                	beqz	a0,80004b72 <pipealloc+0xb2>
    80004ae8:	00000097          	auipc	ra,0x0
    80004aec:	bec080e7          	jalr	-1044(ra) # 800046d4 <filealloc>
    80004af0:	00aa3023          	sd	a0,0(s4)
    80004af4:	c92d                	beqz	a0,80004b66 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	ffe080e7          	jalr	-2(ra) # 80000af4 <kalloc>
    80004afe:	892a                	mv	s2,a0
    80004b00:	c125                	beqz	a0,80004b60 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b02:	4985                	li	s3,1
    80004b04:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b08:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b0c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b10:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b14:	00004597          	auipc	a1,0x4
    80004b18:	94c58593          	addi	a1,a1,-1716 # 80008460 <states.1719+0x1a0>
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	038080e7          	jalr	56(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004b24:	609c                	ld	a5,0(s1)
    80004b26:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b2a:	609c                	ld	a5,0(s1)
    80004b2c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b30:	609c                	ld	a5,0(s1)
    80004b32:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b36:	609c                	ld	a5,0(s1)
    80004b38:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b3c:	000a3783          	ld	a5,0(s4)
    80004b40:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b44:	000a3783          	ld	a5,0(s4)
    80004b48:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b4c:	000a3783          	ld	a5,0(s4)
    80004b50:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b54:	000a3783          	ld	a5,0(s4)
    80004b58:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b5c:	4501                	li	a0,0
    80004b5e:	a025                	j	80004b86 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b60:	6088                	ld	a0,0(s1)
    80004b62:	e501                	bnez	a0,80004b6a <pipealloc+0xaa>
    80004b64:	a039                	j	80004b72 <pipealloc+0xb2>
    80004b66:	6088                	ld	a0,0(s1)
    80004b68:	c51d                	beqz	a0,80004b96 <pipealloc+0xd6>
    fileclose(*f0);
    80004b6a:	00000097          	auipc	ra,0x0
    80004b6e:	c26080e7          	jalr	-986(ra) # 80004790 <fileclose>
  if(*f1)
    80004b72:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b76:	557d                	li	a0,-1
  if(*f1)
    80004b78:	c799                	beqz	a5,80004b86 <pipealloc+0xc6>
    fileclose(*f1);
    80004b7a:	853e                	mv	a0,a5
    80004b7c:	00000097          	auipc	ra,0x0
    80004b80:	c14080e7          	jalr	-1004(ra) # 80004790 <fileclose>
  return -1;
    80004b84:	557d                	li	a0,-1
}
    80004b86:	70a2                	ld	ra,40(sp)
    80004b88:	7402                	ld	s0,32(sp)
    80004b8a:	64e2                	ld	s1,24(sp)
    80004b8c:	6942                	ld	s2,16(sp)
    80004b8e:	69a2                	ld	s3,8(sp)
    80004b90:	6a02                	ld	s4,0(sp)
    80004b92:	6145                	addi	sp,sp,48
    80004b94:	8082                	ret
  return -1;
    80004b96:	557d                	li	a0,-1
    80004b98:	b7fd                	j	80004b86 <pipealloc+0xc6>

0000000080004b9a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b9a:	1101                	addi	sp,sp,-32
    80004b9c:	ec06                	sd	ra,24(sp)
    80004b9e:	e822                	sd	s0,16(sp)
    80004ba0:	e426                	sd	s1,8(sp)
    80004ba2:	e04a                	sd	s2,0(sp)
    80004ba4:	1000                	addi	s0,sp,32
    80004ba6:	84aa                	mv	s1,a0
    80004ba8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	03a080e7          	jalr	58(ra) # 80000be4 <acquire>
  if(writable){
    80004bb2:	02090d63          	beqz	s2,80004bec <pipeclose+0x52>
    pi->writeopen = 0;
    80004bb6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bba:	21848513          	addi	a0,s1,536
    80004bbe:	ffffd097          	auipc	ra,0xffffd
    80004bc2:	66a080e7          	jalr	1642(ra) # 80002228 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bc6:	2204b783          	ld	a5,544(s1)
    80004bca:	eb95                	bnez	a5,80004bfe <pipeclose+0x64>
    release(&pi->lock);
    80004bcc:	8526                	mv	a0,s1
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	0ca080e7          	jalr	202(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004bd6:	8526                	mv	a0,s1
    80004bd8:	ffffc097          	auipc	ra,0xffffc
    80004bdc:	e20080e7          	jalr	-480(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004be0:	60e2                	ld	ra,24(sp)
    80004be2:	6442                	ld	s0,16(sp)
    80004be4:	64a2                	ld	s1,8(sp)
    80004be6:	6902                	ld	s2,0(sp)
    80004be8:	6105                	addi	sp,sp,32
    80004bea:	8082                	ret
    pi->readopen = 0;
    80004bec:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bf0:	21c48513          	addi	a0,s1,540
    80004bf4:	ffffd097          	auipc	ra,0xffffd
    80004bf8:	634080e7          	jalr	1588(ra) # 80002228 <wakeup>
    80004bfc:	b7e9                	j	80004bc6 <pipeclose+0x2c>
    release(&pi->lock);
    80004bfe:	8526                	mv	a0,s1
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	098080e7          	jalr	152(ra) # 80000c98 <release>
}
    80004c08:	bfe1                	j	80004be0 <pipeclose+0x46>

0000000080004c0a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c0a:	7159                	addi	sp,sp,-112
    80004c0c:	f486                	sd	ra,104(sp)
    80004c0e:	f0a2                	sd	s0,96(sp)
    80004c10:	eca6                	sd	s1,88(sp)
    80004c12:	e8ca                	sd	s2,80(sp)
    80004c14:	e4ce                	sd	s3,72(sp)
    80004c16:	e0d2                	sd	s4,64(sp)
    80004c18:	fc56                	sd	s5,56(sp)
    80004c1a:	f85a                	sd	s6,48(sp)
    80004c1c:	f45e                	sd	s7,40(sp)
    80004c1e:	f062                	sd	s8,32(sp)
    80004c20:	ec66                	sd	s9,24(sp)
    80004c22:	1880                	addi	s0,sp,112
    80004c24:	84aa                	mv	s1,a0
    80004c26:	8aae                	mv	s5,a1
    80004c28:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	d86080e7          	jalr	-634(ra) # 800019b0 <myproc>
    80004c32:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c34:	8526                	mv	a0,s1
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	fae080e7          	jalr	-82(ra) # 80000be4 <acquire>
  while(i < n){
    80004c3e:	0d405163          	blez	s4,80004d00 <pipewrite+0xf6>
    80004c42:	8ba6                	mv	s7,s1
  int i = 0;
    80004c44:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c46:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c48:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c4c:	21c48c13          	addi	s8,s1,540
    80004c50:	a08d                	j	80004cb2 <pipewrite+0xa8>
      release(&pi->lock);
    80004c52:	8526                	mv	a0,s1
    80004c54:	ffffc097          	auipc	ra,0xffffc
    80004c58:	044080e7          	jalr	68(ra) # 80000c98 <release>
      return -1;
    80004c5c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c5e:	854a                	mv	a0,s2
    80004c60:	70a6                	ld	ra,104(sp)
    80004c62:	7406                	ld	s0,96(sp)
    80004c64:	64e6                	ld	s1,88(sp)
    80004c66:	6946                	ld	s2,80(sp)
    80004c68:	69a6                	ld	s3,72(sp)
    80004c6a:	6a06                	ld	s4,64(sp)
    80004c6c:	7ae2                	ld	s5,56(sp)
    80004c6e:	7b42                	ld	s6,48(sp)
    80004c70:	7ba2                	ld	s7,40(sp)
    80004c72:	7c02                	ld	s8,32(sp)
    80004c74:	6ce2                	ld	s9,24(sp)
    80004c76:	6165                	addi	sp,sp,112
    80004c78:	8082                	ret
      wakeup(&pi->nread);
    80004c7a:	8566                	mv	a0,s9
    80004c7c:	ffffd097          	auipc	ra,0xffffd
    80004c80:	5ac080e7          	jalr	1452(ra) # 80002228 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c84:	85de                	mv	a1,s7
    80004c86:	8562                	mv	a0,s8
    80004c88:	ffffd097          	auipc	ra,0xffffd
    80004c8c:	414080e7          	jalr	1044(ra) # 8000209c <sleep>
    80004c90:	a839                	j	80004cae <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c92:	21c4a783          	lw	a5,540(s1)
    80004c96:	0017871b          	addiw	a4,a5,1
    80004c9a:	20e4ae23          	sw	a4,540(s1)
    80004c9e:	1ff7f793          	andi	a5,a5,511
    80004ca2:	97a6                	add	a5,a5,s1
    80004ca4:	f9f44703          	lbu	a4,-97(s0)
    80004ca8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cac:	2905                	addiw	s2,s2,1
  while(i < n){
    80004cae:	03495d63          	bge	s2,s4,80004ce8 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004cb2:	2204a783          	lw	a5,544(s1)
    80004cb6:	dfd1                	beqz	a5,80004c52 <pipewrite+0x48>
    80004cb8:	0289a783          	lw	a5,40(s3)
    80004cbc:	fbd9                	bnez	a5,80004c52 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004cbe:	2184a783          	lw	a5,536(s1)
    80004cc2:	21c4a703          	lw	a4,540(s1)
    80004cc6:	2007879b          	addiw	a5,a5,512
    80004cca:	faf708e3          	beq	a4,a5,80004c7a <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cce:	4685                	li	a3,1
    80004cd0:	01590633          	add	a2,s2,s5
    80004cd4:	f9f40593          	addi	a1,s0,-97
    80004cd8:	0509b503          	ld	a0,80(s3)
    80004cdc:	ffffd097          	auipc	ra,0xffffd
    80004ce0:	a22080e7          	jalr	-1502(ra) # 800016fe <copyin>
    80004ce4:	fb6517e3          	bne	a0,s6,80004c92 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004ce8:	21848513          	addi	a0,s1,536
    80004cec:	ffffd097          	auipc	ra,0xffffd
    80004cf0:	53c080e7          	jalr	1340(ra) # 80002228 <wakeup>
  release(&pi->lock);
    80004cf4:	8526                	mv	a0,s1
    80004cf6:	ffffc097          	auipc	ra,0xffffc
    80004cfa:	fa2080e7          	jalr	-94(ra) # 80000c98 <release>
  return i;
    80004cfe:	b785                	j	80004c5e <pipewrite+0x54>
  int i = 0;
    80004d00:	4901                	li	s2,0
    80004d02:	b7dd                	j	80004ce8 <pipewrite+0xde>

0000000080004d04 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d04:	715d                	addi	sp,sp,-80
    80004d06:	e486                	sd	ra,72(sp)
    80004d08:	e0a2                	sd	s0,64(sp)
    80004d0a:	fc26                	sd	s1,56(sp)
    80004d0c:	f84a                	sd	s2,48(sp)
    80004d0e:	f44e                	sd	s3,40(sp)
    80004d10:	f052                	sd	s4,32(sp)
    80004d12:	ec56                	sd	s5,24(sp)
    80004d14:	e85a                	sd	s6,16(sp)
    80004d16:	0880                	addi	s0,sp,80
    80004d18:	84aa                	mv	s1,a0
    80004d1a:	892e                	mv	s2,a1
    80004d1c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d1e:	ffffd097          	auipc	ra,0xffffd
    80004d22:	c92080e7          	jalr	-878(ra) # 800019b0 <myproc>
    80004d26:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d28:	8b26                	mv	s6,s1
    80004d2a:	8526                	mv	a0,s1
    80004d2c:	ffffc097          	auipc	ra,0xffffc
    80004d30:	eb8080e7          	jalr	-328(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d34:	2184a703          	lw	a4,536(s1)
    80004d38:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d3c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d40:	02f71463          	bne	a4,a5,80004d68 <piperead+0x64>
    80004d44:	2244a783          	lw	a5,548(s1)
    80004d48:	c385                	beqz	a5,80004d68 <piperead+0x64>
    if(pr->killed){
    80004d4a:	028a2783          	lw	a5,40(s4)
    80004d4e:	ebc1                	bnez	a5,80004dde <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d50:	85da                	mv	a1,s6
    80004d52:	854e                	mv	a0,s3
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	348080e7          	jalr	840(ra) # 8000209c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d5c:	2184a703          	lw	a4,536(s1)
    80004d60:	21c4a783          	lw	a5,540(s1)
    80004d64:	fef700e3          	beq	a4,a5,80004d44 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d68:	09505263          	blez	s5,80004dec <piperead+0xe8>
    80004d6c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d6e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d70:	2184a783          	lw	a5,536(s1)
    80004d74:	21c4a703          	lw	a4,540(s1)
    80004d78:	02f70d63          	beq	a4,a5,80004db2 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d7c:	0017871b          	addiw	a4,a5,1
    80004d80:	20e4ac23          	sw	a4,536(s1)
    80004d84:	1ff7f793          	andi	a5,a5,511
    80004d88:	97a6                	add	a5,a5,s1
    80004d8a:	0187c783          	lbu	a5,24(a5)
    80004d8e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d92:	4685                	li	a3,1
    80004d94:	fbf40613          	addi	a2,s0,-65
    80004d98:	85ca                	mv	a1,s2
    80004d9a:	050a3503          	ld	a0,80(s4)
    80004d9e:	ffffd097          	auipc	ra,0xffffd
    80004da2:	8d4080e7          	jalr	-1836(ra) # 80001672 <copyout>
    80004da6:	01650663          	beq	a0,s6,80004db2 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004daa:	2985                	addiw	s3,s3,1
    80004dac:	0905                	addi	s2,s2,1
    80004dae:	fd3a91e3          	bne	s5,s3,80004d70 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004db2:	21c48513          	addi	a0,s1,540
    80004db6:	ffffd097          	auipc	ra,0xffffd
    80004dba:	472080e7          	jalr	1138(ra) # 80002228 <wakeup>
  release(&pi->lock);
    80004dbe:	8526                	mv	a0,s1
    80004dc0:	ffffc097          	auipc	ra,0xffffc
    80004dc4:	ed8080e7          	jalr	-296(ra) # 80000c98 <release>
  return i;
}
    80004dc8:	854e                	mv	a0,s3
    80004dca:	60a6                	ld	ra,72(sp)
    80004dcc:	6406                	ld	s0,64(sp)
    80004dce:	74e2                	ld	s1,56(sp)
    80004dd0:	7942                	ld	s2,48(sp)
    80004dd2:	79a2                	ld	s3,40(sp)
    80004dd4:	7a02                	ld	s4,32(sp)
    80004dd6:	6ae2                	ld	s5,24(sp)
    80004dd8:	6b42                	ld	s6,16(sp)
    80004dda:	6161                	addi	sp,sp,80
    80004ddc:	8082                	ret
      release(&pi->lock);
    80004dde:	8526                	mv	a0,s1
    80004de0:	ffffc097          	auipc	ra,0xffffc
    80004de4:	eb8080e7          	jalr	-328(ra) # 80000c98 <release>
      return -1;
    80004de8:	59fd                	li	s3,-1
    80004dea:	bff9                	j	80004dc8 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dec:	4981                	li	s3,0
    80004dee:	b7d1                	j	80004db2 <piperead+0xae>

0000000080004df0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004df0:	df010113          	addi	sp,sp,-528
    80004df4:	20113423          	sd	ra,520(sp)
    80004df8:	20813023          	sd	s0,512(sp)
    80004dfc:	ffa6                	sd	s1,504(sp)
    80004dfe:	fbca                	sd	s2,496(sp)
    80004e00:	f7ce                	sd	s3,488(sp)
    80004e02:	f3d2                	sd	s4,480(sp)
    80004e04:	efd6                	sd	s5,472(sp)
    80004e06:	ebda                	sd	s6,464(sp)
    80004e08:	e7de                	sd	s7,456(sp)
    80004e0a:	e3e2                	sd	s8,448(sp)
    80004e0c:	ff66                	sd	s9,440(sp)
    80004e0e:	fb6a                	sd	s10,432(sp)
    80004e10:	f76e                	sd	s11,424(sp)
    80004e12:	0c00                	addi	s0,sp,528
    80004e14:	84aa                	mv	s1,a0
    80004e16:	dea43c23          	sd	a0,-520(s0)
    80004e1a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e1e:	ffffd097          	auipc	ra,0xffffd
    80004e22:	b92080e7          	jalr	-1134(ra) # 800019b0 <myproc>
    80004e26:	892a                	mv	s2,a0

  begin_op();
    80004e28:	fffff097          	auipc	ra,0xfffff
    80004e2c:	49c080e7          	jalr	1180(ra) # 800042c4 <begin_op>

  if((ip = namei(path)) == 0){
    80004e30:	8526                	mv	a0,s1
    80004e32:	fffff097          	auipc	ra,0xfffff
    80004e36:	276080e7          	jalr	630(ra) # 800040a8 <namei>
    80004e3a:	c92d                	beqz	a0,80004eac <exec+0xbc>
    80004e3c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e3e:	fffff097          	auipc	ra,0xfffff
    80004e42:	ab4080e7          	jalr	-1356(ra) # 800038f2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e46:	04000713          	li	a4,64
    80004e4a:	4681                	li	a3,0
    80004e4c:	e5040613          	addi	a2,s0,-432
    80004e50:	4581                	li	a1,0
    80004e52:	8526                	mv	a0,s1
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	d52080e7          	jalr	-686(ra) # 80003ba6 <readi>
    80004e5c:	04000793          	li	a5,64
    80004e60:	00f51a63          	bne	a0,a5,80004e74 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e64:	e5042703          	lw	a4,-432(s0)
    80004e68:	464c47b7          	lui	a5,0x464c4
    80004e6c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e70:	04f70463          	beq	a4,a5,80004eb8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e74:	8526                	mv	a0,s1
    80004e76:	fffff097          	auipc	ra,0xfffff
    80004e7a:	cde080e7          	jalr	-802(ra) # 80003b54 <iunlockput>
    end_op();
    80004e7e:	fffff097          	auipc	ra,0xfffff
    80004e82:	4c6080e7          	jalr	1222(ra) # 80004344 <end_op>
  }
  return -1;
    80004e86:	557d                	li	a0,-1
}
    80004e88:	20813083          	ld	ra,520(sp)
    80004e8c:	20013403          	ld	s0,512(sp)
    80004e90:	74fe                	ld	s1,504(sp)
    80004e92:	795e                	ld	s2,496(sp)
    80004e94:	79be                	ld	s3,488(sp)
    80004e96:	7a1e                	ld	s4,480(sp)
    80004e98:	6afe                	ld	s5,472(sp)
    80004e9a:	6b5e                	ld	s6,464(sp)
    80004e9c:	6bbe                	ld	s7,456(sp)
    80004e9e:	6c1e                	ld	s8,448(sp)
    80004ea0:	7cfa                	ld	s9,440(sp)
    80004ea2:	7d5a                	ld	s10,432(sp)
    80004ea4:	7dba                	ld	s11,424(sp)
    80004ea6:	21010113          	addi	sp,sp,528
    80004eaa:	8082                	ret
    end_op();
    80004eac:	fffff097          	auipc	ra,0xfffff
    80004eb0:	498080e7          	jalr	1176(ra) # 80004344 <end_op>
    return -1;
    80004eb4:	557d                	li	a0,-1
    80004eb6:	bfc9                	j	80004e88 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004eb8:	854a                	mv	a0,s2
    80004eba:	ffffd097          	auipc	ra,0xffffd
    80004ebe:	bba080e7          	jalr	-1094(ra) # 80001a74 <proc_pagetable>
    80004ec2:	8baa                	mv	s7,a0
    80004ec4:	d945                	beqz	a0,80004e74 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ec6:	e7042983          	lw	s3,-400(s0)
    80004eca:	e8845783          	lhu	a5,-376(s0)
    80004ece:	c7ad                	beqz	a5,80004f38 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ed0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ed2:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004ed4:	6c85                	lui	s9,0x1
    80004ed6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004eda:	def43823          	sd	a5,-528(s0)
    80004ede:	a42d                	j	80005108 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ee0:	00004517          	auipc	a0,0x4
    80004ee4:	96850513          	addi	a0,a0,-1688 # 80008848 <syscallNames+0x280>
    80004ee8:	ffffb097          	auipc	ra,0xffffb
    80004eec:	656080e7          	jalr	1622(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ef0:	8756                	mv	a4,s5
    80004ef2:	012d86bb          	addw	a3,s11,s2
    80004ef6:	4581                	li	a1,0
    80004ef8:	8526                	mv	a0,s1
    80004efa:	fffff097          	auipc	ra,0xfffff
    80004efe:	cac080e7          	jalr	-852(ra) # 80003ba6 <readi>
    80004f02:	2501                	sext.w	a0,a0
    80004f04:	1aaa9963          	bne	s5,a0,800050b6 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f08:	6785                	lui	a5,0x1
    80004f0a:	0127893b          	addw	s2,a5,s2
    80004f0e:	77fd                	lui	a5,0xfffff
    80004f10:	01478a3b          	addw	s4,a5,s4
    80004f14:	1f897163          	bgeu	s2,s8,800050f6 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f18:	02091593          	slli	a1,s2,0x20
    80004f1c:	9181                	srli	a1,a1,0x20
    80004f1e:	95ea                	add	a1,a1,s10
    80004f20:	855e                	mv	a0,s7
    80004f22:	ffffc097          	auipc	ra,0xffffc
    80004f26:	14c080e7          	jalr	332(ra) # 8000106e <walkaddr>
    80004f2a:	862a                	mv	a2,a0
    if(pa == 0)
    80004f2c:	d955                	beqz	a0,80004ee0 <exec+0xf0>
      n = PGSIZE;
    80004f2e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f30:	fd9a70e3          	bgeu	s4,s9,80004ef0 <exec+0x100>
      n = sz - i;
    80004f34:	8ad2                	mv	s5,s4
    80004f36:	bf6d                	j	80004ef0 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f38:	4901                	li	s2,0
  iunlockput(ip);
    80004f3a:	8526                	mv	a0,s1
    80004f3c:	fffff097          	auipc	ra,0xfffff
    80004f40:	c18080e7          	jalr	-1000(ra) # 80003b54 <iunlockput>
  end_op();
    80004f44:	fffff097          	auipc	ra,0xfffff
    80004f48:	400080e7          	jalr	1024(ra) # 80004344 <end_op>
  p = myproc();
    80004f4c:	ffffd097          	auipc	ra,0xffffd
    80004f50:	a64080e7          	jalr	-1436(ra) # 800019b0 <myproc>
    80004f54:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f56:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f5a:	6785                	lui	a5,0x1
    80004f5c:	17fd                	addi	a5,a5,-1
    80004f5e:	993e                	add	s2,s2,a5
    80004f60:	757d                	lui	a0,0xfffff
    80004f62:	00a977b3          	and	a5,s2,a0
    80004f66:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f6a:	6609                	lui	a2,0x2
    80004f6c:	963e                	add	a2,a2,a5
    80004f6e:	85be                	mv	a1,a5
    80004f70:	855e                	mv	a0,s7
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	4b0080e7          	jalr	1200(ra) # 80001422 <uvmalloc>
    80004f7a:	8b2a                	mv	s6,a0
  ip = 0;
    80004f7c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f7e:	12050c63          	beqz	a0,800050b6 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f82:	75f9                	lui	a1,0xffffe
    80004f84:	95aa                	add	a1,a1,a0
    80004f86:	855e                	mv	a0,s7
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	6b8080e7          	jalr	1720(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f90:	7c7d                	lui	s8,0xfffff
    80004f92:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f94:	e0043783          	ld	a5,-512(s0)
    80004f98:	6388                	ld	a0,0(a5)
    80004f9a:	c535                	beqz	a0,80005006 <exec+0x216>
    80004f9c:	e9040993          	addi	s3,s0,-368
    80004fa0:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004fa4:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004fa6:	ffffc097          	auipc	ra,0xffffc
    80004faa:	ebe080e7          	jalr	-322(ra) # 80000e64 <strlen>
    80004fae:	2505                	addiw	a0,a0,1
    80004fb0:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fb4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fb8:	13896363          	bltu	s2,s8,800050de <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fbc:	e0043d83          	ld	s11,-512(s0)
    80004fc0:	000dba03          	ld	s4,0(s11)
    80004fc4:	8552                	mv	a0,s4
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	e9e080e7          	jalr	-354(ra) # 80000e64 <strlen>
    80004fce:	0015069b          	addiw	a3,a0,1
    80004fd2:	8652                	mv	a2,s4
    80004fd4:	85ca                	mv	a1,s2
    80004fd6:	855e                	mv	a0,s7
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	69a080e7          	jalr	1690(ra) # 80001672 <copyout>
    80004fe0:	10054363          	bltz	a0,800050e6 <exec+0x2f6>
    ustack[argc] = sp;
    80004fe4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fe8:	0485                	addi	s1,s1,1
    80004fea:	008d8793          	addi	a5,s11,8
    80004fee:	e0f43023          	sd	a5,-512(s0)
    80004ff2:	008db503          	ld	a0,8(s11)
    80004ff6:	c911                	beqz	a0,8000500a <exec+0x21a>
    if(argc >= MAXARG)
    80004ff8:	09a1                	addi	s3,s3,8
    80004ffa:	fb3c96e3          	bne	s9,s3,80004fa6 <exec+0x1b6>
  sz = sz1;
    80004ffe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005002:	4481                	li	s1,0
    80005004:	a84d                	j	800050b6 <exec+0x2c6>
  sp = sz;
    80005006:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005008:	4481                	li	s1,0
  ustack[argc] = 0;
    8000500a:	00349793          	slli	a5,s1,0x3
    8000500e:	f9040713          	addi	a4,s0,-112
    80005012:	97ba                	add	a5,a5,a4
    80005014:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005018:	00148693          	addi	a3,s1,1
    8000501c:	068e                	slli	a3,a3,0x3
    8000501e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005022:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005026:	01897663          	bgeu	s2,s8,80005032 <exec+0x242>
  sz = sz1;
    8000502a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000502e:	4481                	li	s1,0
    80005030:	a059                	j	800050b6 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005032:	e9040613          	addi	a2,s0,-368
    80005036:	85ca                	mv	a1,s2
    80005038:	855e                	mv	a0,s7
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	638080e7          	jalr	1592(ra) # 80001672 <copyout>
    80005042:	0a054663          	bltz	a0,800050ee <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005046:	058ab783          	ld	a5,88(s5)
    8000504a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000504e:	df843783          	ld	a5,-520(s0)
    80005052:	0007c703          	lbu	a4,0(a5)
    80005056:	cf11                	beqz	a4,80005072 <exec+0x282>
    80005058:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000505a:	02f00693          	li	a3,47
    8000505e:	a039                	j	8000506c <exec+0x27c>
      last = s+1;
    80005060:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005064:	0785                	addi	a5,a5,1
    80005066:	fff7c703          	lbu	a4,-1(a5)
    8000506a:	c701                	beqz	a4,80005072 <exec+0x282>
    if(*s == '/')
    8000506c:	fed71ce3          	bne	a4,a3,80005064 <exec+0x274>
    80005070:	bfc5                	j	80005060 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005072:	4641                	li	a2,16
    80005074:	df843583          	ld	a1,-520(s0)
    80005078:	158a8513          	addi	a0,s5,344
    8000507c:	ffffc097          	auipc	ra,0xffffc
    80005080:	db6080e7          	jalr	-586(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005084:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005088:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000508c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005090:	058ab783          	ld	a5,88(s5)
    80005094:	e6843703          	ld	a4,-408(s0)
    80005098:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000509a:	058ab783          	ld	a5,88(s5)
    8000509e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050a2:	85ea                	mv	a1,s10
    800050a4:	ffffd097          	auipc	ra,0xffffd
    800050a8:	a6c080e7          	jalr	-1428(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050ac:	0004851b          	sext.w	a0,s1
    800050b0:	bbe1                	j	80004e88 <exec+0x98>
    800050b2:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800050b6:	e0843583          	ld	a1,-504(s0)
    800050ba:	855e                	mv	a0,s7
    800050bc:	ffffd097          	auipc	ra,0xffffd
    800050c0:	a54080e7          	jalr	-1452(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    800050c4:	da0498e3          	bnez	s1,80004e74 <exec+0x84>
  return -1;
    800050c8:	557d                	li	a0,-1
    800050ca:	bb7d                	j	80004e88 <exec+0x98>
    800050cc:	e1243423          	sd	s2,-504(s0)
    800050d0:	b7dd                	j	800050b6 <exec+0x2c6>
    800050d2:	e1243423          	sd	s2,-504(s0)
    800050d6:	b7c5                	j	800050b6 <exec+0x2c6>
    800050d8:	e1243423          	sd	s2,-504(s0)
    800050dc:	bfe9                	j	800050b6 <exec+0x2c6>
  sz = sz1;
    800050de:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050e2:	4481                	li	s1,0
    800050e4:	bfc9                	j	800050b6 <exec+0x2c6>
  sz = sz1;
    800050e6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050ea:	4481                	li	s1,0
    800050ec:	b7e9                	j	800050b6 <exec+0x2c6>
  sz = sz1;
    800050ee:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050f2:	4481                	li	s1,0
    800050f4:	b7c9                	j	800050b6 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050f6:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050fa:	2b05                	addiw	s6,s6,1
    800050fc:	0389899b          	addiw	s3,s3,56
    80005100:	e8845783          	lhu	a5,-376(s0)
    80005104:	e2fb5be3          	bge	s6,a5,80004f3a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005108:	2981                	sext.w	s3,s3
    8000510a:	03800713          	li	a4,56
    8000510e:	86ce                	mv	a3,s3
    80005110:	e1840613          	addi	a2,s0,-488
    80005114:	4581                	li	a1,0
    80005116:	8526                	mv	a0,s1
    80005118:	fffff097          	auipc	ra,0xfffff
    8000511c:	a8e080e7          	jalr	-1394(ra) # 80003ba6 <readi>
    80005120:	03800793          	li	a5,56
    80005124:	f8f517e3          	bne	a0,a5,800050b2 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005128:	e1842783          	lw	a5,-488(s0)
    8000512c:	4705                	li	a4,1
    8000512e:	fce796e3          	bne	a5,a4,800050fa <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005132:	e4043603          	ld	a2,-448(s0)
    80005136:	e3843783          	ld	a5,-456(s0)
    8000513a:	f8f669e3          	bltu	a2,a5,800050cc <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000513e:	e2843783          	ld	a5,-472(s0)
    80005142:	963e                	add	a2,a2,a5
    80005144:	f8f667e3          	bltu	a2,a5,800050d2 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005148:	85ca                	mv	a1,s2
    8000514a:	855e                	mv	a0,s7
    8000514c:	ffffc097          	auipc	ra,0xffffc
    80005150:	2d6080e7          	jalr	726(ra) # 80001422 <uvmalloc>
    80005154:	e0a43423          	sd	a0,-504(s0)
    80005158:	d141                	beqz	a0,800050d8 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000515a:	e2843d03          	ld	s10,-472(s0)
    8000515e:	df043783          	ld	a5,-528(s0)
    80005162:	00fd77b3          	and	a5,s10,a5
    80005166:	fba1                	bnez	a5,800050b6 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005168:	e2042d83          	lw	s11,-480(s0)
    8000516c:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005170:	f80c03e3          	beqz	s8,800050f6 <exec+0x306>
    80005174:	8a62                	mv	s4,s8
    80005176:	4901                	li	s2,0
    80005178:	b345                	j	80004f18 <exec+0x128>

000000008000517a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000517a:	7179                	addi	sp,sp,-48
    8000517c:	f406                	sd	ra,40(sp)
    8000517e:	f022                	sd	s0,32(sp)
    80005180:	ec26                	sd	s1,24(sp)
    80005182:	e84a                	sd	s2,16(sp)
    80005184:	1800                	addi	s0,sp,48
    80005186:	892e                	mv	s2,a1
    80005188:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000518a:	fdc40593          	addi	a1,s0,-36
    8000518e:	ffffe097          	auipc	ra,0xffffe
    80005192:	ad4080e7          	jalr	-1324(ra) # 80002c62 <argint>
    80005196:	04054063          	bltz	a0,800051d6 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000519a:	fdc42703          	lw	a4,-36(s0)
    8000519e:	47bd                	li	a5,15
    800051a0:	02e7ed63          	bltu	a5,a4,800051da <argfd+0x60>
    800051a4:	ffffd097          	auipc	ra,0xffffd
    800051a8:	80c080e7          	jalr	-2036(ra) # 800019b0 <myproc>
    800051ac:	fdc42703          	lw	a4,-36(s0)
    800051b0:	01a70793          	addi	a5,a4,26
    800051b4:	078e                	slli	a5,a5,0x3
    800051b6:	953e                	add	a0,a0,a5
    800051b8:	611c                	ld	a5,0(a0)
    800051ba:	c395                	beqz	a5,800051de <argfd+0x64>
    return -1;
  if(pfd)
    800051bc:	00090463          	beqz	s2,800051c4 <argfd+0x4a>
    *pfd = fd;
    800051c0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051c4:	4501                	li	a0,0
  if(pf)
    800051c6:	c091                	beqz	s1,800051ca <argfd+0x50>
    *pf = f;
    800051c8:	e09c                	sd	a5,0(s1)
}
    800051ca:	70a2                	ld	ra,40(sp)
    800051cc:	7402                	ld	s0,32(sp)
    800051ce:	64e2                	ld	s1,24(sp)
    800051d0:	6942                	ld	s2,16(sp)
    800051d2:	6145                	addi	sp,sp,48
    800051d4:	8082                	ret
    return -1;
    800051d6:	557d                	li	a0,-1
    800051d8:	bfcd                	j	800051ca <argfd+0x50>
    return -1;
    800051da:	557d                	li	a0,-1
    800051dc:	b7fd                	j	800051ca <argfd+0x50>
    800051de:	557d                	li	a0,-1
    800051e0:	b7ed                	j	800051ca <argfd+0x50>

00000000800051e2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051e2:	1101                	addi	sp,sp,-32
    800051e4:	ec06                	sd	ra,24(sp)
    800051e6:	e822                	sd	s0,16(sp)
    800051e8:	e426                	sd	s1,8(sp)
    800051ea:	1000                	addi	s0,sp,32
    800051ec:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051ee:	ffffc097          	auipc	ra,0xffffc
    800051f2:	7c2080e7          	jalr	1986(ra) # 800019b0 <myproc>
    800051f6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051f8:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800051fc:	4501                	li	a0,0
    800051fe:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005200:	6398                	ld	a4,0(a5)
    80005202:	cb19                	beqz	a4,80005218 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005204:	2505                	addiw	a0,a0,1
    80005206:	07a1                	addi	a5,a5,8
    80005208:	fed51ce3          	bne	a0,a3,80005200 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000520c:	557d                	li	a0,-1
}
    8000520e:	60e2                	ld	ra,24(sp)
    80005210:	6442                	ld	s0,16(sp)
    80005212:	64a2                	ld	s1,8(sp)
    80005214:	6105                	addi	sp,sp,32
    80005216:	8082                	ret
      p->ofile[fd] = f;
    80005218:	01a50793          	addi	a5,a0,26
    8000521c:	078e                	slli	a5,a5,0x3
    8000521e:	963e                	add	a2,a2,a5
    80005220:	e204                	sd	s1,0(a2)
      return fd;
    80005222:	b7f5                	j	8000520e <fdalloc+0x2c>

0000000080005224 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005224:	715d                	addi	sp,sp,-80
    80005226:	e486                	sd	ra,72(sp)
    80005228:	e0a2                	sd	s0,64(sp)
    8000522a:	fc26                	sd	s1,56(sp)
    8000522c:	f84a                	sd	s2,48(sp)
    8000522e:	f44e                	sd	s3,40(sp)
    80005230:	f052                	sd	s4,32(sp)
    80005232:	ec56                	sd	s5,24(sp)
    80005234:	0880                	addi	s0,sp,80
    80005236:	89ae                	mv	s3,a1
    80005238:	8ab2                	mv	s5,a2
    8000523a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000523c:	fb040593          	addi	a1,s0,-80
    80005240:	fffff097          	auipc	ra,0xfffff
    80005244:	e86080e7          	jalr	-378(ra) # 800040c6 <nameiparent>
    80005248:	892a                	mv	s2,a0
    8000524a:	12050f63          	beqz	a0,80005388 <create+0x164>
    return 0;

  ilock(dp);
    8000524e:	ffffe097          	auipc	ra,0xffffe
    80005252:	6a4080e7          	jalr	1700(ra) # 800038f2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005256:	4601                	li	a2,0
    80005258:	fb040593          	addi	a1,s0,-80
    8000525c:	854a                	mv	a0,s2
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	b78080e7          	jalr	-1160(ra) # 80003dd6 <dirlookup>
    80005266:	84aa                	mv	s1,a0
    80005268:	c921                	beqz	a0,800052b8 <create+0x94>
    iunlockput(dp);
    8000526a:	854a                	mv	a0,s2
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	8e8080e7          	jalr	-1816(ra) # 80003b54 <iunlockput>
    ilock(ip);
    80005274:	8526                	mv	a0,s1
    80005276:	ffffe097          	auipc	ra,0xffffe
    8000527a:	67c080e7          	jalr	1660(ra) # 800038f2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000527e:	2981                	sext.w	s3,s3
    80005280:	4789                	li	a5,2
    80005282:	02f99463          	bne	s3,a5,800052aa <create+0x86>
    80005286:	0444d783          	lhu	a5,68(s1)
    8000528a:	37f9                	addiw	a5,a5,-2
    8000528c:	17c2                	slli	a5,a5,0x30
    8000528e:	93c1                	srli	a5,a5,0x30
    80005290:	4705                	li	a4,1
    80005292:	00f76c63          	bltu	a4,a5,800052aa <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005296:	8526                	mv	a0,s1
    80005298:	60a6                	ld	ra,72(sp)
    8000529a:	6406                	ld	s0,64(sp)
    8000529c:	74e2                	ld	s1,56(sp)
    8000529e:	7942                	ld	s2,48(sp)
    800052a0:	79a2                	ld	s3,40(sp)
    800052a2:	7a02                	ld	s4,32(sp)
    800052a4:	6ae2                	ld	s5,24(sp)
    800052a6:	6161                	addi	sp,sp,80
    800052a8:	8082                	ret
    iunlockput(ip);
    800052aa:	8526                	mv	a0,s1
    800052ac:	fffff097          	auipc	ra,0xfffff
    800052b0:	8a8080e7          	jalr	-1880(ra) # 80003b54 <iunlockput>
    return 0;
    800052b4:	4481                	li	s1,0
    800052b6:	b7c5                	j	80005296 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052b8:	85ce                	mv	a1,s3
    800052ba:	00092503          	lw	a0,0(s2)
    800052be:	ffffe097          	auipc	ra,0xffffe
    800052c2:	49c080e7          	jalr	1180(ra) # 8000375a <ialloc>
    800052c6:	84aa                	mv	s1,a0
    800052c8:	c529                	beqz	a0,80005312 <create+0xee>
  ilock(ip);
    800052ca:	ffffe097          	auipc	ra,0xffffe
    800052ce:	628080e7          	jalr	1576(ra) # 800038f2 <ilock>
  ip->major = major;
    800052d2:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052d6:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052da:	4785                	li	a5,1
    800052dc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052e0:	8526                	mv	a0,s1
    800052e2:	ffffe097          	auipc	ra,0xffffe
    800052e6:	546080e7          	jalr	1350(ra) # 80003828 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052ea:	2981                	sext.w	s3,s3
    800052ec:	4785                	li	a5,1
    800052ee:	02f98a63          	beq	s3,a5,80005322 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052f2:	40d0                	lw	a2,4(s1)
    800052f4:	fb040593          	addi	a1,s0,-80
    800052f8:	854a                	mv	a0,s2
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	cec080e7          	jalr	-788(ra) # 80003fe6 <dirlink>
    80005302:	06054b63          	bltz	a0,80005378 <create+0x154>
  iunlockput(dp);
    80005306:	854a                	mv	a0,s2
    80005308:	fffff097          	auipc	ra,0xfffff
    8000530c:	84c080e7          	jalr	-1972(ra) # 80003b54 <iunlockput>
  return ip;
    80005310:	b759                	j	80005296 <create+0x72>
    panic("create: ialloc");
    80005312:	00003517          	auipc	a0,0x3
    80005316:	55650513          	addi	a0,a0,1366 # 80008868 <syscallNames+0x2a0>
    8000531a:	ffffb097          	auipc	ra,0xffffb
    8000531e:	224080e7          	jalr	548(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005322:	04a95783          	lhu	a5,74(s2)
    80005326:	2785                	addiw	a5,a5,1
    80005328:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000532c:	854a                	mv	a0,s2
    8000532e:	ffffe097          	auipc	ra,0xffffe
    80005332:	4fa080e7          	jalr	1274(ra) # 80003828 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005336:	40d0                	lw	a2,4(s1)
    80005338:	00003597          	auipc	a1,0x3
    8000533c:	54058593          	addi	a1,a1,1344 # 80008878 <syscallNames+0x2b0>
    80005340:	8526                	mv	a0,s1
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	ca4080e7          	jalr	-860(ra) # 80003fe6 <dirlink>
    8000534a:	00054f63          	bltz	a0,80005368 <create+0x144>
    8000534e:	00492603          	lw	a2,4(s2)
    80005352:	00003597          	auipc	a1,0x3
    80005356:	52e58593          	addi	a1,a1,1326 # 80008880 <syscallNames+0x2b8>
    8000535a:	8526                	mv	a0,s1
    8000535c:	fffff097          	auipc	ra,0xfffff
    80005360:	c8a080e7          	jalr	-886(ra) # 80003fe6 <dirlink>
    80005364:	f80557e3          	bgez	a0,800052f2 <create+0xce>
      panic("create dots");
    80005368:	00003517          	auipc	a0,0x3
    8000536c:	52050513          	addi	a0,a0,1312 # 80008888 <syscallNames+0x2c0>
    80005370:	ffffb097          	auipc	ra,0xffffb
    80005374:	1ce080e7          	jalr	462(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005378:	00003517          	auipc	a0,0x3
    8000537c:	52050513          	addi	a0,a0,1312 # 80008898 <syscallNames+0x2d0>
    80005380:	ffffb097          	auipc	ra,0xffffb
    80005384:	1be080e7          	jalr	446(ra) # 8000053e <panic>
    return 0;
    80005388:	84aa                	mv	s1,a0
    8000538a:	b731                	j	80005296 <create+0x72>

000000008000538c <sys_dup>:
{
    8000538c:	7179                	addi	sp,sp,-48
    8000538e:	f406                	sd	ra,40(sp)
    80005390:	f022                	sd	s0,32(sp)
    80005392:	ec26                	sd	s1,24(sp)
    80005394:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005396:	fd840613          	addi	a2,s0,-40
    8000539a:	4581                	li	a1,0
    8000539c:	4501                	li	a0,0
    8000539e:	00000097          	auipc	ra,0x0
    800053a2:	ddc080e7          	jalr	-548(ra) # 8000517a <argfd>
    return -1;
    800053a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053a8:	02054363          	bltz	a0,800053ce <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053ac:	fd843503          	ld	a0,-40(s0)
    800053b0:	00000097          	auipc	ra,0x0
    800053b4:	e32080e7          	jalr	-462(ra) # 800051e2 <fdalloc>
    800053b8:	84aa                	mv	s1,a0
    return -1;
    800053ba:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053bc:	00054963          	bltz	a0,800053ce <sys_dup+0x42>
  filedup(f);
    800053c0:	fd843503          	ld	a0,-40(s0)
    800053c4:	fffff097          	auipc	ra,0xfffff
    800053c8:	37a080e7          	jalr	890(ra) # 8000473e <filedup>
  return fd;
    800053cc:	87a6                	mv	a5,s1
}
    800053ce:	853e                	mv	a0,a5
    800053d0:	70a2                	ld	ra,40(sp)
    800053d2:	7402                	ld	s0,32(sp)
    800053d4:	64e2                	ld	s1,24(sp)
    800053d6:	6145                	addi	sp,sp,48
    800053d8:	8082                	ret

00000000800053da <sys_read>:
{
    800053da:	7179                	addi	sp,sp,-48
    800053dc:	f406                	sd	ra,40(sp)
    800053de:	f022                	sd	s0,32(sp)
    800053e0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e2:	fe840613          	addi	a2,s0,-24
    800053e6:	4581                	li	a1,0
    800053e8:	4501                	li	a0,0
    800053ea:	00000097          	auipc	ra,0x0
    800053ee:	d90080e7          	jalr	-624(ra) # 8000517a <argfd>
    return -1;
    800053f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f4:	04054163          	bltz	a0,80005436 <sys_read+0x5c>
    800053f8:	fe440593          	addi	a1,s0,-28
    800053fc:	4509                	li	a0,2
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	864080e7          	jalr	-1948(ra) # 80002c62 <argint>
    return -1;
    80005406:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005408:	02054763          	bltz	a0,80005436 <sys_read+0x5c>
    8000540c:	fd840593          	addi	a1,s0,-40
    80005410:	4505                	li	a0,1
    80005412:	ffffe097          	auipc	ra,0xffffe
    80005416:	872080e7          	jalr	-1934(ra) # 80002c84 <argaddr>
    return -1;
    8000541a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000541c:	00054d63          	bltz	a0,80005436 <sys_read+0x5c>
  return fileread(f, p, n);
    80005420:	fe442603          	lw	a2,-28(s0)
    80005424:	fd843583          	ld	a1,-40(s0)
    80005428:	fe843503          	ld	a0,-24(s0)
    8000542c:	fffff097          	auipc	ra,0xfffff
    80005430:	49e080e7          	jalr	1182(ra) # 800048ca <fileread>
    80005434:	87aa                	mv	a5,a0
}
    80005436:	853e                	mv	a0,a5
    80005438:	70a2                	ld	ra,40(sp)
    8000543a:	7402                	ld	s0,32(sp)
    8000543c:	6145                	addi	sp,sp,48
    8000543e:	8082                	ret

0000000080005440 <sys_write>:
{
    80005440:	7179                	addi	sp,sp,-48
    80005442:	f406                	sd	ra,40(sp)
    80005444:	f022                	sd	s0,32(sp)
    80005446:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005448:	fe840613          	addi	a2,s0,-24
    8000544c:	4581                	li	a1,0
    8000544e:	4501                	li	a0,0
    80005450:	00000097          	auipc	ra,0x0
    80005454:	d2a080e7          	jalr	-726(ra) # 8000517a <argfd>
    return -1;
    80005458:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545a:	04054163          	bltz	a0,8000549c <sys_write+0x5c>
    8000545e:	fe440593          	addi	a1,s0,-28
    80005462:	4509                	li	a0,2
    80005464:	ffffd097          	auipc	ra,0xffffd
    80005468:	7fe080e7          	jalr	2046(ra) # 80002c62 <argint>
    return -1;
    8000546c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546e:	02054763          	bltz	a0,8000549c <sys_write+0x5c>
    80005472:	fd840593          	addi	a1,s0,-40
    80005476:	4505                	li	a0,1
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	80c080e7          	jalr	-2036(ra) # 80002c84 <argaddr>
    return -1;
    80005480:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005482:	00054d63          	bltz	a0,8000549c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005486:	fe442603          	lw	a2,-28(s0)
    8000548a:	fd843583          	ld	a1,-40(s0)
    8000548e:	fe843503          	ld	a0,-24(s0)
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	4fa080e7          	jalr	1274(ra) # 8000498c <filewrite>
    8000549a:	87aa                	mv	a5,a0
}
    8000549c:	853e                	mv	a0,a5
    8000549e:	70a2                	ld	ra,40(sp)
    800054a0:	7402                	ld	s0,32(sp)
    800054a2:	6145                	addi	sp,sp,48
    800054a4:	8082                	ret

00000000800054a6 <sys_close>:
{
    800054a6:	1101                	addi	sp,sp,-32
    800054a8:	ec06                	sd	ra,24(sp)
    800054aa:	e822                	sd	s0,16(sp)
    800054ac:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054ae:	fe040613          	addi	a2,s0,-32
    800054b2:	fec40593          	addi	a1,s0,-20
    800054b6:	4501                	li	a0,0
    800054b8:	00000097          	auipc	ra,0x0
    800054bc:	cc2080e7          	jalr	-830(ra) # 8000517a <argfd>
    return -1;
    800054c0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054c2:	02054463          	bltz	a0,800054ea <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054c6:	ffffc097          	auipc	ra,0xffffc
    800054ca:	4ea080e7          	jalr	1258(ra) # 800019b0 <myproc>
    800054ce:	fec42783          	lw	a5,-20(s0)
    800054d2:	07e9                	addi	a5,a5,26
    800054d4:	078e                	slli	a5,a5,0x3
    800054d6:	97aa                	add	a5,a5,a0
    800054d8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054dc:	fe043503          	ld	a0,-32(s0)
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	2b0080e7          	jalr	688(ra) # 80004790 <fileclose>
  return 0;
    800054e8:	4781                	li	a5,0
}
    800054ea:	853e                	mv	a0,a5
    800054ec:	60e2                	ld	ra,24(sp)
    800054ee:	6442                	ld	s0,16(sp)
    800054f0:	6105                	addi	sp,sp,32
    800054f2:	8082                	ret

00000000800054f4 <sys_fstat>:
{
    800054f4:	1101                	addi	sp,sp,-32
    800054f6:	ec06                	sd	ra,24(sp)
    800054f8:	e822                	sd	s0,16(sp)
    800054fa:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054fc:	fe840613          	addi	a2,s0,-24
    80005500:	4581                	li	a1,0
    80005502:	4501                	li	a0,0
    80005504:	00000097          	auipc	ra,0x0
    80005508:	c76080e7          	jalr	-906(ra) # 8000517a <argfd>
    return -1;
    8000550c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000550e:	02054563          	bltz	a0,80005538 <sys_fstat+0x44>
    80005512:	fe040593          	addi	a1,s0,-32
    80005516:	4505                	li	a0,1
    80005518:	ffffd097          	auipc	ra,0xffffd
    8000551c:	76c080e7          	jalr	1900(ra) # 80002c84 <argaddr>
    return -1;
    80005520:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005522:	00054b63          	bltz	a0,80005538 <sys_fstat+0x44>
  return filestat(f, st);
    80005526:	fe043583          	ld	a1,-32(s0)
    8000552a:	fe843503          	ld	a0,-24(s0)
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	32a080e7          	jalr	810(ra) # 80004858 <filestat>
    80005536:	87aa                	mv	a5,a0
}
    80005538:	853e                	mv	a0,a5
    8000553a:	60e2                	ld	ra,24(sp)
    8000553c:	6442                	ld	s0,16(sp)
    8000553e:	6105                	addi	sp,sp,32
    80005540:	8082                	ret

0000000080005542 <sys_link>:
{
    80005542:	7169                	addi	sp,sp,-304
    80005544:	f606                	sd	ra,296(sp)
    80005546:	f222                	sd	s0,288(sp)
    80005548:	ee26                	sd	s1,280(sp)
    8000554a:	ea4a                	sd	s2,272(sp)
    8000554c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000554e:	08000613          	li	a2,128
    80005552:	ed040593          	addi	a1,s0,-304
    80005556:	4501                	li	a0,0
    80005558:	ffffd097          	auipc	ra,0xffffd
    8000555c:	74e080e7          	jalr	1870(ra) # 80002ca6 <argstr>
    return -1;
    80005560:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005562:	10054e63          	bltz	a0,8000567e <sys_link+0x13c>
    80005566:	08000613          	li	a2,128
    8000556a:	f5040593          	addi	a1,s0,-176
    8000556e:	4505                	li	a0,1
    80005570:	ffffd097          	auipc	ra,0xffffd
    80005574:	736080e7          	jalr	1846(ra) # 80002ca6 <argstr>
    return -1;
    80005578:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000557a:	10054263          	bltz	a0,8000567e <sys_link+0x13c>
  begin_op();
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	d46080e7          	jalr	-698(ra) # 800042c4 <begin_op>
  if((ip = namei(old)) == 0){
    80005586:	ed040513          	addi	a0,s0,-304
    8000558a:	fffff097          	auipc	ra,0xfffff
    8000558e:	b1e080e7          	jalr	-1250(ra) # 800040a8 <namei>
    80005592:	84aa                	mv	s1,a0
    80005594:	c551                	beqz	a0,80005620 <sys_link+0xde>
  ilock(ip);
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	35c080e7          	jalr	860(ra) # 800038f2 <ilock>
  if(ip->type == T_DIR){
    8000559e:	04449703          	lh	a4,68(s1)
    800055a2:	4785                	li	a5,1
    800055a4:	08f70463          	beq	a4,a5,8000562c <sys_link+0xea>
  ip->nlink++;
    800055a8:	04a4d783          	lhu	a5,74(s1)
    800055ac:	2785                	addiw	a5,a5,1
    800055ae:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055b2:	8526                	mv	a0,s1
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	274080e7          	jalr	628(ra) # 80003828 <iupdate>
  iunlock(ip);
    800055bc:	8526                	mv	a0,s1
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	3f6080e7          	jalr	1014(ra) # 800039b4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055c6:	fd040593          	addi	a1,s0,-48
    800055ca:	f5040513          	addi	a0,s0,-176
    800055ce:	fffff097          	auipc	ra,0xfffff
    800055d2:	af8080e7          	jalr	-1288(ra) # 800040c6 <nameiparent>
    800055d6:	892a                	mv	s2,a0
    800055d8:	c935                	beqz	a0,8000564c <sys_link+0x10a>
  ilock(dp);
    800055da:	ffffe097          	auipc	ra,0xffffe
    800055de:	318080e7          	jalr	792(ra) # 800038f2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055e2:	00092703          	lw	a4,0(s2)
    800055e6:	409c                	lw	a5,0(s1)
    800055e8:	04f71d63          	bne	a4,a5,80005642 <sys_link+0x100>
    800055ec:	40d0                	lw	a2,4(s1)
    800055ee:	fd040593          	addi	a1,s0,-48
    800055f2:	854a                	mv	a0,s2
    800055f4:	fffff097          	auipc	ra,0xfffff
    800055f8:	9f2080e7          	jalr	-1550(ra) # 80003fe6 <dirlink>
    800055fc:	04054363          	bltz	a0,80005642 <sys_link+0x100>
  iunlockput(dp);
    80005600:	854a                	mv	a0,s2
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	552080e7          	jalr	1362(ra) # 80003b54 <iunlockput>
  iput(ip);
    8000560a:	8526                	mv	a0,s1
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	4a0080e7          	jalr	1184(ra) # 80003aac <iput>
  end_op();
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	d30080e7          	jalr	-720(ra) # 80004344 <end_op>
  return 0;
    8000561c:	4781                	li	a5,0
    8000561e:	a085                	j	8000567e <sys_link+0x13c>
    end_op();
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	d24080e7          	jalr	-732(ra) # 80004344 <end_op>
    return -1;
    80005628:	57fd                	li	a5,-1
    8000562a:	a891                	j	8000567e <sys_link+0x13c>
    iunlockput(ip);
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	526080e7          	jalr	1318(ra) # 80003b54 <iunlockput>
    end_op();
    80005636:	fffff097          	auipc	ra,0xfffff
    8000563a:	d0e080e7          	jalr	-754(ra) # 80004344 <end_op>
    return -1;
    8000563e:	57fd                	li	a5,-1
    80005640:	a83d                	j	8000567e <sys_link+0x13c>
    iunlockput(dp);
    80005642:	854a                	mv	a0,s2
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	510080e7          	jalr	1296(ra) # 80003b54 <iunlockput>
  ilock(ip);
    8000564c:	8526                	mv	a0,s1
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	2a4080e7          	jalr	676(ra) # 800038f2 <ilock>
  ip->nlink--;
    80005656:	04a4d783          	lhu	a5,74(s1)
    8000565a:	37fd                	addiw	a5,a5,-1
    8000565c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005660:	8526                	mv	a0,s1
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	1c6080e7          	jalr	454(ra) # 80003828 <iupdate>
  iunlockput(ip);
    8000566a:	8526                	mv	a0,s1
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	4e8080e7          	jalr	1256(ra) # 80003b54 <iunlockput>
  end_op();
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	cd0080e7          	jalr	-816(ra) # 80004344 <end_op>
  return -1;
    8000567c:	57fd                	li	a5,-1
}
    8000567e:	853e                	mv	a0,a5
    80005680:	70b2                	ld	ra,296(sp)
    80005682:	7412                	ld	s0,288(sp)
    80005684:	64f2                	ld	s1,280(sp)
    80005686:	6952                	ld	s2,272(sp)
    80005688:	6155                	addi	sp,sp,304
    8000568a:	8082                	ret

000000008000568c <sys_unlink>:
{
    8000568c:	7151                	addi	sp,sp,-240
    8000568e:	f586                	sd	ra,232(sp)
    80005690:	f1a2                	sd	s0,224(sp)
    80005692:	eda6                	sd	s1,216(sp)
    80005694:	e9ca                	sd	s2,208(sp)
    80005696:	e5ce                	sd	s3,200(sp)
    80005698:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000569a:	08000613          	li	a2,128
    8000569e:	f3040593          	addi	a1,s0,-208
    800056a2:	4501                	li	a0,0
    800056a4:	ffffd097          	auipc	ra,0xffffd
    800056a8:	602080e7          	jalr	1538(ra) # 80002ca6 <argstr>
    800056ac:	18054163          	bltz	a0,8000582e <sys_unlink+0x1a2>
  begin_op();
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	c14080e7          	jalr	-1004(ra) # 800042c4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056b8:	fb040593          	addi	a1,s0,-80
    800056bc:	f3040513          	addi	a0,s0,-208
    800056c0:	fffff097          	auipc	ra,0xfffff
    800056c4:	a06080e7          	jalr	-1530(ra) # 800040c6 <nameiparent>
    800056c8:	84aa                	mv	s1,a0
    800056ca:	c979                	beqz	a0,800057a0 <sys_unlink+0x114>
  ilock(dp);
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	226080e7          	jalr	550(ra) # 800038f2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056d4:	00003597          	auipc	a1,0x3
    800056d8:	1a458593          	addi	a1,a1,420 # 80008878 <syscallNames+0x2b0>
    800056dc:	fb040513          	addi	a0,s0,-80
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	6dc080e7          	jalr	1756(ra) # 80003dbc <namecmp>
    800056e8:	14050a63          	beqz	a0,8000583c <sys_unlink+0x1b0>
    800056ec:	00003597          	auipc	a1,0x3
    800056f0:	19458593          	addi	a1,a1,404 # 80008880 <syscallNames+0x2b8>
    800056f4:	fb040513          	addi	a0,s0,-80
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	6c4080e7          	jalr	1732(ra) # 80003dbc <namecmp>
    80005700:	12050e63          	beqz	a0,8000583c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005704:	f2c40613          	addi	a2,s0,-212
    80005708:	fb040593          	addi	a1,s0,-80
    8000570c:	8526                	mv	a0,s1
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	6c8080e7          	jalr	1736(ra) # 80003dd6 <dirlookup>
    80005716:	892a                	mv	s2,a0
    80005718:	12050263          	beqz	a0,8000583c <sys_unlink+0x1b0>
  ilock(ip);
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	1d6080e7          	jalr	470(ra) # 800038f2 <ilock>
  if(ip->nlink < 1)
    80005724:	04a91783          	lh	a5,74(s2)
    80005728:	08f05263          	blez	a5,800057ac <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000572c:	04491703          	lh	a4,68(s2)
    80005730:	4785                	li	a5,1
    80005732:	08f70563          	beq	a4,a5,800057bc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005736:	4641                	li	a2,16
    80005738:	4581                	li	a1,0
    8000573a:	fc040513          	addi	a0,s0,-64
    8000573e:	ffffb097          	auipc	ra,0xffffb
    80005742:	5a2080e7          	jalr	1442(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005746:	4741                	li	a4,16
    80005748:	f2c42683          	lw	a3,-212(s0)
    8000574c:	fc040613          	addi	a2,s0,-64
    80005750:	4581                	li	a1,0
    80005752:	8526                	mv	a0,s1
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	54a080e7          	jalr	1354(ra) # 80003c9e <writei>
    8000575c:	47c1                	li	a5,16
    8000575e:	0af51563          	bne	a0,a5,80005808 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005762:	04491703          	lh	a4,68(s2)
    80005766:	4785                	li	a5,1
    80005768:	0af70863          	beq	a4,a5,80005818 <sys_unlink+0x18c>
  iunlockput(dp);
    8000576c:	8526                	mv	a0,s1
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	3e6080e7          	jalr	998(ra) # 80003b54 <iunlockput>
  ip->nlink--;
    80005776:	04a95783          	lhu	a5,74(s2)
    8000577a:	37fd                	addiw	a5,a5,-1
    8000577c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005780:	854a                	mv	a0,s2
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	0a6080e7          	jalr	166(ra) # 80003828 <iupdate>
  iunlockput(ip);
    8000578a:	854a                	mv	a0,s2
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	3c8080e7          	jalr	968(ra) # 80003b54 <iunlockput>
  end_op();
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	bb0080e7          	jalr	-1104(ra) # 80004344 <end_op>
  return 0;
    8000579c:	4501                	li	a0,0
    8000579e:	a84d                	j	80005850 <sys_unlink+0x1c4>
    end_op();
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	ba4080e7          	jalr	-1116(ra) # 80004344 <end_op>
    return -1;
    800057a8:	557d                	li	a0,-1
    800057aa:	a05d                	j	80005850 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057ac:	00003517          	auipc	a0,0x3
    800057b0:	0fc50513          	addi	a0,a0,252 # 800088a8 <syscallNames+0x2e0>
    800057b4:	ffffb097          	auipc	ra,0xffffb
    800057b8:	d8a080e7          	jalr	-630(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057bc:	04c92703          	lw	a4,76(s2)
    800057c0:	02000793          	li	a5,32
    800057c4:	f6e7f9e3          	bgeu	a5,a4,80005736 <sys_unlink+0xaa>
    800057c8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057cc:	4741                	li	a4,16
    800057ce:	86ce                	mv	a3,s3
    800057d0:	f1840613          	addi	a2,s0,-232
    800057d4:	4581                	li	a1,0
    800057d6:	854a                	mv	a0,s2
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	3ce080e7          	jalr	974(ra) # 80003ba6 <readi>
    800057e0:	47c1                	li	a5,16
    800057e2:	00f51b63          	bne	a0,a5,800057f8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057e6:	f1845783          	lhu	a5,-232(s0)
    800057ea:	e7a1                	bnez	a5,80005832 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ec:	29c1                	addiw	s3,s3,16
    800057ee:	04c92783          	lw	a5,76(s2)
    800057f2:	fcf9ede3          	bltu	s3,a5,800057cc <sys_unlink+0x140>
    800057f6:	b781                	j	80005736 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057f8:	00003517          	auipc	a0,0x3
    800057fc:	0c850513          	addi	a0,a0,200 # 800088c0 <syscallNames+0x2f8>
    80005800:	ffffb097          	auipc	ra,0xffffb
    80005804:	d3e080e7          	jalr	-706(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005808:	00003517          	auipc	a0,0x3
    8000580c:	0d050513          	addi	a0,a0,208 # 800088d8 <syscallNames+0x310>
    80005810:	ffffb097          	auipc	ra,0xffffb
    80005814:	d2e080e7          	jalr	-722(ra) # 8000053e <panic>
    dp->nlink--;
    80005818:	04a4d783          	lhu	a5,74(s1)
    8000581c:	37fd                	addiw	a5,a5,-1
    8000581e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005822:	8526                	mv	a0,s1
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	004080e7          	jalr	4(ra) # 80003828 <iupdate>
    8000582c:	b781                	j	8000576c <sys_unlink+0xe0>
    return -1;
    8000582e:	557d                	li	a0,-1
    80005830:	a005                	j	80005850 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005832:	854a                	mv	a0,s2
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	320080e7          	jalr	800(ra) # 80003b54 <iunlockput>
  iunlockput(dp);
    8000583c:	8526                	mv	a0,s1
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	316080e7          	jalr	790(ra) # 80003b54 <iunlockput>
  end_op();
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	afe080e7          	jalr	-1282(ra) # 80004344 <end_op>
  return -1;
    8000584e:	557d                	li	a0,-1
}
    80005850:	70ae                	ld	ra,232(sp)
    80005852:	740e                	ld	s0,224(sp)
    80005854:	64ee                	ld	s1,216(sp)
    80005856:	694e                	ld	s2,208(sp)
    80005858:	69ae                	ld	s3,200(sp)
    8000585a:	616d                	addi	sp,sp,240
    8000585c:	8082                	ret

000000008000585e <sys_open>:

uint64
sys_open(void)
{
    8000585e:	7131                	addi	sp,sp,-192
    80005860:	fd06                	sd	ra,184(sp)
    80005862:	f922                	sd	s0,176(sp)
    80005864:	f526                	sd	s1,168(sp)
    80005866:	f14a                	sd	s2,160(sp)
    80005868:	ed4e                	sd	s3,152(sp)
    8000586a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000586c:	08000613          	li	a2,128
    80005870:	f5040593          	addi	a1,s0,-176
    80005874:	4501                	li	a0,0
    80005876:	ffffd097          	auipc	ra,0xffffd
    8000587a:	430080e7          	jalr	1072(ra) # 80002ca6 <argstr>
    return -1;
    8000587e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005880:	0c054163          	bltz	a0,80005942 <sys_open+0xe4>
    80005884:	f4c40593          	addi	a1,s0,-180
    80005888:	4505                	li	a0,1
    8000588a:	ffffd097          	auipc	ra,0xffffd
    8000588e:	3d8080e7          	jalr	984(ra) # 80002c62 <argint>
    80005892:	0a054863          	bltz	a0,80005942 <sys_open+0xe4>

  begin_op();
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	a2e080e7          	jalr	-1490(ra) # 800042c4 <begin_op>

  if(omode & O_CREATE){
    8000589e:	f4c42783          	lw	a5,-180(s0)
    800058a2:	2007f793          	andi	a5,a5,512
    800058a6:	cbdd                	beqz	a5,8000595c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058a8:	4681                	li	a3,0
    800058aa:	4601                	li	a2,0
    800058ac:	4589                	li	a1,2
    800058ae:	f5040513          	addi	a0,s0,-176
    800058b2:	00000097          	auipc	ra,0x0
    800058b6:	972080e7          	jalr	-1678(ra) # 80005224 <create>
    800058ba:	892a                	mv	s2,a0
    if(ip == 0){
    800058bc:	c959                	beqz	a0,80005952 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058be:	04491703          	lh	a4,68(s2)
    800058c2:	478d                	li	a5,3
    800058c4:	00f71763          	bne	a4,a5,800058d2 <sys_open+0x74>
    800058c8:	04695703          	lhu	a4,70(s2)
    800058cc:	47a5                	li	a5,9
    800058ce:	0ce7ec63          	bltu	a5,a4,800059a6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	e02080e7          	jalr	-510(ra) # 800046d4 <filealloc>
    800058da:	89aa                	mv	s3,a0
    800058dc:	10050263          	beqz	a0,800059e0 <sys_open+0x182>
    800058e0:	00000097          	auipc	ra,0x0
    800058e4:	902080e7          	jalr	-1790(ra) # 800051e2 <fdalloc>
    800058e8:	84aa                	mv	s1,a0
    800058ea:	0e054663          	bltz	a0,800059d6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058ee:	04491703          	lh	a4,68(s2)
    800058f2:	478d                	li	a5,3
    800058f4:	0cf70463          	beq	a4,a5,800059bc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058f8:	4789                	li	a5,2
    800058fa:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058fe:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005902:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005906:	f4c42783          	lw	a5,-180(s0)
    8000590a:	0017c713          	xori	a4,a5,1
    8000590e:	8b05                	andi	a4,a4,1
    80005910:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005914:	0037f713          	andi	a4,a5,3
    80005918:	00e03733          	snez	a4,a4
    8000591c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005920:	4007f793          	andi	a5,a5,1024
    80005924:	c791                	beqz	a5,80005930 <sys_open+0xd2>
    80005926:	04491703          	lh	a4,68(s2)
    8000592a:	4789                	li	a5,2
    8000592c:	08f70f63          	beq	a4,a5,800059ca <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005930:	854a                	mv	a0,s2
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	082080e7          	jalr	130(ra) # 800039b4 <iunlock>
  end_op();
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	a0a080e7          	jalr	-1526(ra) # 80004344 <end_op>

  return fd;
}
    80005942:	8526                	mv	a0,s1
    80005944:	70ea                	ld	ra,184(sp)
    80005946:	744a                	ld	s0,176(sp)
    80005948:	74aa                	ld	s1,168(sp)
    8000594a:	790a                	ld	s2,160(sp)
    8000594c:	69ea                	ld	s3,152(sp)
    8000594e:	6129                	addi	sp,sp,192
    80005950:	8082                	ret
      end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	9f2080e7          	jalr	-1550(ra) # 80004344 <end_op>
      return -1;
    8000595a:	b7e5                	j	80005942 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000595c:	f5040513          	addi	a0,s0,-176
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	748080e7          	jalr	1864(ra) # 800040a8 <namei>
    80005968:	892a                	mv	s2,a0
    8000596a:	c905                	beqz	a0,8000599a <sys_open+0x13c>
    ilock(ip);
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	f86080e7          	jalr	-122(ra) # 800038f2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005974:	04491703          	lh	a4,68(s2)
    80005978:	4785                	li	a5,1
    8000597a:	f4f712e3          	bne	a4,a5,800058be <sys_open+0x60>
    8000597e:	f4c42783          	lw	a5,-180(s0)
    80005982:	dba1                	beqz	a5,800058d2 <sys_open+0x74>
      iunlockput(ip);
    80005984:	854a                	mv	a0,s2
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	1ce080e7          	jalr	462(ra) # 80003b54 <iunlockput>
      end_op();
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	9b6080e7          	jalr	-1610(ra) # 80004344 <end_op>
      return -1;
    80005996:	54fd                	li	s1,-1
    80005998:	b76d                	j	80005942 <sys_open+0xe4>
      end_op();
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	9aa080e7          	jalr	-1622(ra) # 80004344 <end_op>
      return -1;
    800059a2:	54fd                	li	s1,-1
    800059a4:	bf79                	j	80005942 <sys_open+0xe4>
    iunlockput(ip);
    800059a6:	854a                	mv	a0,s2
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	1ac080e7          	jalr	428(ra) # 80003b54 <iunlockput>
    end_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	994080e7          	jalr	-1644(ra) # 80004344 <end_op>
    return -1;
    800059b8:	54fd                	li	s1,-1
    800059ba:	b761                	j	80005942 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059bc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059c0:	04691783          	lh	a5,70(s2)
    800059c4:	02f99223          	sh	a5,36(s3)
    800059c8:	bf2d                	j	80005902 <sys_open+0xa4>
    itrunc(ip);
    800059ca:	854a                	mv	a0,s2
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	034080e7          	jalr	52(ra) # 80003a00 <itrunc>
    800059d4:	bfb1                	j	80005930 <sys_open+0xd2>
      fileclose(f);
    800059d6:	854e                	mv	a0,s3
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	db8080e7          	jalr	-584(ra) # 80004790 <fileclose>
    iunlockput(ip);
    800059e0:	854a                	mv	a0,s2
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	172080e7          	jalr	370(ra) # 80003b54 <iunlockput>
    end_op();
    800059ea:	fffff097          	auipc	ra,0xfffff
    800059ee:	95a080e7          	jalr	-1702(ra) # 80004344 <end_op>
    return -1;
    800059f2:	54fd                	li	s1,-1
    800059f4:	b7b9                	j	80005942 <sys_open+0xe4>

00000000800059f6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059f6:	7175                	addi	sp,sp,-144
    800059f8:	e506                	sd	ra,136(sp)
    800059fa:	e122                	sd	s0,128(sp)
    800059fc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	8c6080e7          	jalr	-1850(ra) # 800042c4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a06:	08000613          	li	a2,128
    80005a0a:	f7040593          	addi	a1,s0,-144
    80005a0e:	4501                	li	a0,0
    80005a10:	ffffd097          	auipc	ra,0xffffd
    80005a14:	296080e7          	jalr	662(ra) # 80002ca6 <argstr>
    80005a18:	02054963          	bltz	a0,80005a4a <sys_mkdir+0x54>
    80005a1c:	4681                	li	a3,0
    80005a1e:	4601                	li	a2,0
    80005a20:	4585                	li	a1,1
    80005a22:	f7040513          	addi	a0,s0,-144
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	7fe080e7          	jalr	2046(ra) # 80005224 <create>
    80005a2e:	cd11                	beqz	a0,80005a4a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	124080e7          	jalr	292(ra) # 80003b54 <iunlockput>
  end_op();
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	90c080e7          	jalr	-1780(ra) # 80004344 <end_op>
  return 0;
    80005a40:	4501                	li	a0,0
}
    80005a42:	60aa                	ld	ra,136(sp)
    80005a44:	640a                	ld	s0,128(sp)
    80005a46:	6149                	addi	sp,sp,144
    80005a48:	8082                	ret
    end_op();
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	8fa080e7          	jalr	-1798(ra) # 80004344 <end_op>
    return -1;
    80005a52:	557d                	li	a0,-1
    80005a54:	b7fd                	j	80005a42 <sys_mkdir+0x4c>

0000000080005a56 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a56:	7135                	addi	sp,sp,-160
    80005a58:	ed06                	sd	ra,152(sp)
    80005a5a:	e922                	sd	s0,144(sp)
    80005a5c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	866080e7          	jalr	-1946(ra) # 800042c4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a66:	08000613          	li	a2,128
    80005a6a:	f7040593          	addi	a1,s0,-144
    80005a6e:	4501                	li	a0,0
    80005a70:	ffffd097          	auipc	ra,0xffffd
    80005a74:	236080e7          	jalr	566(ra) # 80002ca6 <argstr>
    80005a78:	04054a63          	bltz	a0,80005acc <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a7c:	f6c40593          	addi	a1,s0,-148
    80005a80:	4505                	li	a0,1
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	1e0080e7          	jalr	480(ra) # 80002c62 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a8a:	04054163          	bltz	a0,80005acc <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a8e:	f6840593          	addi	a1,s0,-152
    80005a92:	4509                	li	a0,2
    80005a94:	ffffd097          	auipc	ra,0xffffd
    80005a98:	1ce080e7          	jalr	462(ra) # 80002c62 <argint>
     argint(1, &major) < 0 ||
    80005a9c:	02054863          	bltz	a0,80005acc <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005aa0:	f6841683          	lh	a3,-152(s0)
    80005aa4:	f6c41603          	lh	a2,-148(s0)
    80005aa8:	458d                	li	a1,3
    80005aaa:	f7040513          	addi	a0,s0,-144
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	776080e7          	jalr	1910(ra) # 80005224 <create>
     argint(2, &minor) < 0 ||
    80005ab6:	c919                	beqz	a0,80005acc <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	09c080e7          	jalr	156(ra) # 80003b54 <iunlockput>
  end_op();
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	884080e7          	jalr	-1916(ra) # 80004344 <end_op>
  return 0;
    80005ac8:	4501                	li	a0,0
    80005aca:	a031                	j	80005ad6 <sys_mknod+0x80>
    end_op();
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	878080e7          	jalr	-1928(ra) # 80004344 <end_op>
    return -1;
    80005ad4:	557d                	li	a0,-1
}
    80005ad6:	60ea                	ld	ra,152(sp)
    80005ad8:	644a                	ld	s0,144(sp)
    80005ada:	610d                	addi	sp,sp,160
    80005adc:	8082                	ret

0000000080005ade <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ade:	7135                	addi	sp,sp,-160
    80005ae0:	ed06                	sd	ra,152(sp)
    80005ae2:	e922                	sd	s0,144(sp)
    80005ae4:	e526                	sd	s1,136(sp)
    80005ae6:	e14a                	sd	s2,128(sp)
    80005ae8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005aea:	ffffc097          	auipc	ra,0xffffc
    80005aee:	ec6080e7          	jalr	-314(ra) # 800019b0 <myproc>
    80005af2:	892a                	mv	s2,a0
  
  begin_op();
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	7d0080e7          	jalr	2000(ra) # 800042c4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005afc:	08000613          	li	a2,128
    80005b00:	f6040593          	addi	a1,s0,-160
    80005b04:	4501                	li	a0,0
    80005b06:	ffffd097          	auipc	ra,0xffffd
    80005b0a:	1a0080e7          	jalr	416(ra) # 80002ca6 <argstr>
    80005b0e:	04054b63          	bltz	a0,80005b64 <sys_chdir+0x86>
    80005b12:	f6040513          	addi	a0,s0,-160
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	592080e7          	jalr	1426(ra) # 800040a8 <namei>
    80005b1e:	84aa                	mv	s1,a0
    80005b20:	c131                	beqz	a0,80005b64 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	dd0080e7          	jalr	-560(ra) # 800038f2 <ilock>
  if(ip->type != T_DIR){
    80005b2a:	04449703          	lh	a4,68(s1)
    80005b2e:	4785                	li	a5,1
    80005b30:	04f71063          	bne	a4,a5,80005b70 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b34:	8526                	mv	a0,s1
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	e7e080e7          	jalr	-386(ra) # 800039b4 <iunlock>
  iput(p->cwd);
    80005b3e:	15093503          	ld	a0,336(s2)
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	f6a080e7          	jalr	-150(ra) # 80003aac <iput>
  end_op();
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	7fa080e7          	jalr	2042(ra) # 80004344 <end_op>
  p->cwd = ip;
    80005b52:	14993823          	sd	s1,336(s2)
  return 0;
    80005b56:	4501                	li	a0,0
}
    80005b58:	60ea                	ld	ra,152(sp)
    80005b5a:	644a                	ld	s0,144(sp)
    80005b5c:	64aa                	ld	s1,136(sp)
    80005b5e:	690a                	ld	s2,128(sp)
    80005b60:	610d                	addi	sp,sp,160
    80005b62:	8082                	ret
    end_op();
    80005b64:	ffffe097          	auipc	ra,0xffffe
    80005b68:	7e0080e7          	jalr	2016(ra) # 80004344 <end_op>
    return -1;
    80005b6c:	557d                	li	a0,-1
    80005b6e:	b7ed                	j	80005b58 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b70:	8526                	mv	a0,s1
    80005b72:	ffffe097          	auipc	ra,0xffffe
    80005b76:	fe2080e7          	jalr	-30(ra) # 80003b54 <iunlockput>
    end_op();
    80005b7a:	ffffe097          	auipc	ra,0xffffe
    80005b7e:	7ca080e7          	jalr	1994(ra) # 80004344 <end_op>
    return -1;
    80005b82:	557d                	li	a0,-1
    80005b84:	bfd1                	j	80005b58 <sys_chdir+0x7a>

0000000080005b86 <sys_exec>:

uint64
sys_exec(void)
{
    80005b86:	7145                	addi	sp,sp,-464
    80005b88:	e786                	sd	ra,456(sp)
    80005b8a:	e3a2                	sd	s0,448(sp)
    80005b8c:	ff26                	sd	s1,440(sp)
    80005b8e:	fb4a                	sd	s2,432(sp)
    80005b90:	f74e                	sd	s3,424(sp)
    80005b92:	f352                	sd	s4,416(sp)
    80005b94:	ef56                	sd	s5,408(sp)
    80005b96:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b98:	08000613          	li	a2,128
    80005b9c:	f4040593          	addi	a1,s0,-192
    80005ba0:	4501                	li	a0,0
    80005ba2:	ffffd097          	auipc	ra,0xffffd
    80005ba6:	104080e7          	jalr	260(ra) # 80002ca6 <argstr>
    return -1;
    80005baa:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bac:	0c054a63          	bltz	a0,80005c80 <sys_exec+0xfa>
    80005bb0:	e3840593          	addi	a1,s0,-456
    80005bb4:	4505                	li	a0,1
    80005bb6:	ffffd097          	auipc	ra,0xffffd
    80005bba:	0ce080e7          	jalr	206(ra) # 80002c84 <argaddr>
    80005bbe:	0c054163          	bltz	a0,80005c80 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bc2:	10000613          	li	a2,256
    80005bc6:	4581                	li	a1,0
    80005bc8:	e4040513          	addi	a0,s0,-448
    80005bcc:	ffffb097          	auipc	ra,0xffffb
    80005bd0:	114080e7          	jalr	276(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bd4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bd8:	89a6                	mv	s3,s1
    80005bda:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bdc:	02000a13          	li	s4,32
    80005be0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005be4:	00391513          	slli	a0,s2,0x3
    80005be8:	e3040593          	addi	a1,s0,-464
    80005bec:	e3843783          	ld	a5,-456(s0)
    80005bf0:	953e                	add	a0,a0,a5
    80005bf2:	ffffd097          	auipc	ra,0xffffd
    80005bf6:	fd6080e7          	jalr	-42(ra) # 80002bc8 <fetchaddr>
    80005bfa:	02054a63          	bltz	a0,80005c2e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bfe:	e3043783          	ld	a5,-464(s0)
    80005c02:	c3b9                	beqz	a5,80005c48 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c04:	ffffb097          	auipc	ra,0xffffb
    80005c08:	ef0080e7          	jalr	-272(ra) # 80000af4 <kalloc>
    80005c0c:	85aa                	mv	a1,a0
    80005c0e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c12:	cd11                	beqz	a0,80005c2e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c14:	6605                	lui	a2,0x1
    80005c16:	e3043503          	ld	a0,-464(s0)
    80005c1a:	ffffd097          	auipc	ra,0xffffd
    80005c1e:	000080e7          	jalr	ra # 80002c1a <fetchstr>
    80005c22:	00054663          	bltz	a0,80005c2e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c26:	0905                	addi	s2,s2,1
    80005c28:	09a1                	addi	s3,s3,8
    80005c2a:	fb491be3          	bne	s2,s4,80005be0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c2e:	10048913          	addi	s2,s1,256
    80005c32:	6088                	ld	a0,0(s1)
    80005c34:	c529                	beqz	a0,80005c7e <sys_exec+0xf8>
    kfree(argv[i]);
    80005c36:	ffffb097          	auipc	ra,0xffffb
    80005c3a:	dc2080e7          	jalr	-574(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c3e:	04a1                	addi	s1,s1,8
    80005c40:	ff2499e3          	bne	s1,s2,80005c32 <sys_exec+0xac>
  return -1;
    80005c44:	597d                	li	s2,-1
    80005c46:	a82d                	j	80005c80 <sys_exec+0xfa>
      argv[i] = 0;
    80005c48:	0a8e                	slli	s5,s5,0x3
    80005c4a:	fc040793          	addi	a5,s0,-64
    80005c4e:	9abe                	add	s5,s5,a5
    80005c50:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c54:	e4040593          	addi	a1,s0,-448
    80005c58:	f4040513          	addi	a0,s0,-192
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	194080e7          	jalr	404(ra) # 80004df0 <exec>
    80005c64:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c66:	10048993          	addi	s3,s1,256
    80005c6a:	6088                	ld	a0,0(s1)
    80005c6c:	c911                	beqz	a0,80005c80 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c6e:	ffffb097          	auipc	ra,0xffffb
    80005c72:	d8a080e7          	jalr	-630(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c76:	04a1                	addi	s1,s1,8
    80005c78:	ff3499e3          	bne	s1,s3,80005c6a <sys_exec+0xe4>
    80005c7c:	a011                	j	80005c80 <sys_exec+0xfa>
  return -1;
    80005c7e:	597d                	li	s2,-1
}
    80005c80:	854a                	mv	a0,s2
    80005c82:	60be                	ld	ra,456(sp)
    80005c84:	641e                	ld	s0,448(sp)
    80005c86:	74fa                	ld	s1,440(sp)
    80005c88:	795a                	ld	s2,432(sp)
    80005c8a:	79ba                	ld	s3,424(sp)
    80005c8c:	7a1a                	ld	s4,416(sp)
    80005c8e:	6afa                	ld	s5,408(sp)
    80005c90:	6179                	addi	sp,sp,464
    80005c92:	8082                	ret

0000000080005c94 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c94:	7139                	addi	sp,sp,-64
    80005c96:	fc06                	sd	ra,56(sp)
    80005c98:	f822                	sd	s0,48(sp)
    80005c9a:	f426                	sd	s1,40(sp)
    80005c9c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c9e:	ffffc097          	auipc	ra,0xffffc
    80005ca2:	d12080e7          	jalr	-750(ra) # 800019b0 <myproc>
    80005ca6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ca8:	fd840593          	addi	a1,s0,-40
    80005cac:	4501                	li	a0,0
    80005cae:	ffffd097          	auipc	ra,0xffffd
    80005cb2:	fd6080e7          	jalr	-42(ra) # 80002c84 <argaddr>
    return -1;
    80005cb6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005cb8:	0e054063          	bltz	a0,80005d98 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005cbc:	fc840593          	addi	a1,s0,-56
    80005cc0:	fd040513          	addi	a0,s0,-48
    80005cc4:	fffff097          	auipc	ra,0xfffff
    80005cc8:	dfc080e7          	jalr	-516(ra) # 80004ac0 <pipealloc>
    return -1;
    80005ccc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cce:	0c054563          	bltz	a0,80005d98 <sys_pipe+0x104>
  fd0 = -1;
    80005cd2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cd6:	fd043503          	ld	a0,-48(s0)
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	508080e7          	jalr	1288(ra) # 800051e2 <fdalloc>
    80005ce2:	fca42223          	sw	a0,-60(s0)
    80005ce6:	08054c63          	bltz	a0,80005d7e <sys_pipe+0xea>
    80005cea:	fc843503          	ld	a0,-56(s0)
    80005cee:	fffff097          	auipc	ra,0xfffff
    80005cf2:	4f4080e7          	jalr	1268(ra) # 800051e2 <fdalloc>
    80005cf6:	fca42023          	sw	a0,-64(s0)
    80005cfa:	06054863          	bltz	a0,80005d6a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cfe:	4691                	li	a3,4
    80005d00:	fc440613          	addi	a2,s0,-60
    80005d04:	fd843583          	ld	a1,-40(s0)
    80005d08:	68a8                	ld	a0,80(s1)
    80005d0a:	ffffc097          	auipc	ra,0xffffc
    80005d0e:	968080e7          	jalr	-1688(ra) # 80001672 <copyout>
    80005d12:	02054063          	bltz	a0,80005d32 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d16:	4691                	li	a3,4
    80005d18:	fc040613          	addi	a2,s0,-64
    80005d1c:	fd843583          	ld	a1,-40(s0)
    80005d20:	0591                	addi	a1,a1,4
    80005d22:	68a8                	ld	a0,80(s1)
    80005d24:	ffffc097          	auipc	ra,0xffffc
    80005d28:	94e080e7          	jalr	-1714(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d2c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d2e:	06055563          	bgez	a0,80005d98 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d32:	fc442783          	lw	a5,-60(s0)
    80005d36:	07e9                	addi	a5,a5,26
    80005d38:	078e                	slli	a5,a5,0x3
    80005d3a:	97a6                	add	a5,a5,s1
    80005d3c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d40:	fc042503          	lw	a0,-64(s0)
    80005d44:	0569                	addi	a0,a0,26
    80005d46:	050e                	slli	a0,a0,0x3
    80005d48:	9526                	add	a0,a0,s1
    80005d4a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d4e:	fd043503          	ld	a0,-48(s0)
    80005d52:	fffff097          	auipc	ra,0xfffff
    80005d56:	a3e080e7          	jalr	-1474(ra) # 80004790 <fileclose>
    fileclose(wf);
    80005d5a:	fc843503          	ld	a0,-56(s0)
    80005d5e:	fffff097          	auipc	ra,0xfffff
    80005d62:	a32080e7          	jalr	-1486(ra) # 80004790 <fileclose>
    return -1;
    80005d66:	57fd                	li	a5,-1
    80005d68:	a805                	j	80005d98 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d6a:	fc442783          	lw	a5,-60(s0)
    80005d6e:	0007c863          	bltz	a5,80005d7e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d72:	01a78513          	addi	a0,a5,26
    80005d76:	050e                	slli	a0,a0,0x3
    80005d78:	9526                	add	a0,a0,s1
    80005d7a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d7e:	fd043503          	ld	a0,-48(s0)
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	a0e080e7          	jalr	-1522(ra) # 80004790 <fileclose>
    fileclose(wf);
    80005d8a:	fc843503          	ld	a0,-56(s0)
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	a02080e7          	jalr	-1534(ra) # 80004790 <fileclose>
    return -1;
    80005d96:	57fd                	li	a5,-1
}
    80005d98:	853e                	mv	a0,a5
    80005d9a:	70e2                	ld	ra,56(sp)
    80005d9c:	7442                	ld	s0,48(sp)
    80005d9e:	74a2                	ld	s1,40(sp)
    80005da0:	6121                	addi	sp,sp,64
    80005da2:	8082                	ret
	...

0000000080005db0 <kernelvec>:
    80005db0:	7111                	addi	sp,sp,-256
    80005db2:	e006                	sd	ra,0(sp)
    80005db4:	e40a                	sd	sp,8(sp)
    80005db6:	e80e                	sd	gp,16(sp)
    80005db8:	ec12                	sd	tp,24(sp)
    80005dba:	f016                	sd	t0,32(sp)
    80005dbc:	f41a                	sd	t1,40(sp)
    80005dbe:	f81e                	sd	t2,48(sp)
    80005dc0:	fc22                	sd	s0,56(sp)
    80005dc2:	e0a6                	sd	s1,64(sp)
    80005dc4:	e4aa                	sd	a0,72(sp)
    80005dc6:	e8ae                	sd	a1,80(sp)
    80005dc8:	ecb2                	sd	a2,88(sp)
    80005dca:	f0b6                	sd	a3,96(sp)
    80005dcc:	f4ba                	sd	a4,104(sp)
    80005dce:	f8be                	sd	a5,112(sp)
    80005dd0:	fcc2                	sd	a6,120(sp)
    80005dd2:	e146                	sd	a7,128(sp)
    80005dd4:	e54a                	sd	s2,136(sp)
    80005dd6:	e94e                	sd	s3,144(sp)
    80005dd8:	ed52                	sd	s4,152(sp)
    80005dda:	f156                	sd	s5,160(sp)
    80005ddc:	f55a                	sd	s6,168(sp)
    80005dde:	f95e                	sd	s7,176(sp)
    80005de0:	fd62                	sd	s8,184(sp)
    80005de2:	e1e6                	sd	s9,192(sp)
    80005de4:	e5ea                	sd	s10,200(sp)
    80005de6:	e9ee                	sd	s11,208(sp)
    80005de8:	edf2                	sd	t3,216(sp)
    80005dea:	f1f6                	sd	t4,224(sp)
    80005dec:	f5fa                	sd	t5,232(sp)
    80005dee:	f9fe                	sd	t6,240(sp)
    80005df0:	ca5fc0ef          	jal	ra,80002a94 <kerneltrap>
    80005df4:	6082                	ld	ra,0(sp)
    80005df6:	6122                	ld	sp,8(sp)
    80005df8:	61c2                	ld	gp,16(sp)
    80005dfa:	7282                	ld	t0,32(sp)
    80005dfc:	7322                	ld	t1,40(sp)
    80005dfe:	73c2                	ld	t2,48(sp)
    80005e00:	7462                	ld	s0,56(sp)
    80005e02:	6486                	ld	s1,64(sp)
    80005e04:	6526                	ld	a0,72(sp)
    80005e06:	65c6                	ld	a1,80(sp)
    80005e08:	6666                	ld	a2,88(sp)
    80005e0a:	7686                	ld	a3,96(sp)
    80005e0c:	7726                	ld	a4,104(sp)
    80005e0e:	77c6                	ld	a5,112(sp)
    80005e10:	7866                	ld	a6,120(sp)
    80005e12:	688a                	ld	a7,128(sp)
    80005e14:	692a                	ld	s2,136(sp)
    80005e16:	69ca                	ld	s3,144(sp)
    80005e18:	6a6a                	ld	s4,152(sp)
    80005e1a:	7a8a                	ld	s5,160(sp)
    80005e1c:	7b2a                	ld	s6,168(sp)
    80005e1e:	7bca                	ld	s7,176(sp)
    80005e20:	7c6a                	ld	s8,184(sp)
    80005e22:	6c8e                	ld	s9,192(sp)
    80005e24:	6d2e                	ld	s10,200(sp)
    80005e26:	6dce                	ld	s11,208(sp)
    80005e28:	6e6e                	ld	t3,216(sp)
    80005e2a:	7e8e                	ld	t4,224(sp)
    80005e2c:	7f2e                	ld	t5,232(sp)
    80005e2e:	7fce                	ld	t6,240(sp)
    80005e30:	6111                	addi	sp,sp,256
    80005e32:	10200073          	sret
    80005e36:	00000013          	nop
    80005e3a:	00000013          	nop
    80005e3e:	0001                	nop

0000000080005e40 <timervec>:
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	e10c                	sd	a1,0(a0)
    80005e46:	e510                	sd	a2,8(a0)
    80005e48:	e914                	sd	a3,16(a0)
    80005e4a:	6d0c                	ld	a1,24(a0)
    80005e4c:	7110                	ld	a2,32(a0)
    80005e4e:	6194                	ld	a3,0(a1)
    80005e50:	96b2                	add	a3,a3,a2
    80005e52:	e194                	sd	a3,0(a1)
    80005e54:	4589                	li	a1,2
    80005e56:	14459073          	csrw	sip,a1
    80005e5a:	6914                	ld	a3,16(a0)
    80005e5c:	6510                	ld	a2,8(a0)
    80005e5e:	610c                	ld	a1,0(a0)
    80005e60:	34051573          	csrrw	a0,mscratch,a0
    80005e64:	30200073          	mret
	...

0000000080005e6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e6a:	1141                	addi	sp,sp,-16
    80005e6c:	e422                	sd	s0,8(sp)
    80005e6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e70:	0c0007b7          	lui	a5,0xc000
    80005e74:	4705                	li	a4,1
    80005e76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e78:	c3d8                	sw	a4,4(a5)
}
    80005e7a:	6422                	ld	s0,8(sp)
    80005e7c:	0141                	addi	sp,sp,16
    80005e7e:	8082                	ret

0000000080005e80 <plicinithart>:

void
plicinithart(void)
{
    80005e80:	1141                	addi	sp,sp,-16
    80005e82:	e406                	sd	ra,8(sp)
    80005e84:	e022                	sd	s0,0(sp)
    80005e86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	afc080e7          	jalr	-1284(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e90:	0085171b          	slliw	a4,a0,0x8
    80005e94:	0c0027b7          	lui	a5,0xc002
    80005e98:	97ba                	add	a5,a5,a4
    80005e9a:	40200713          	li	a4,1026
    80005e9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ea2:	00d5151b          	slliw	a0,a0,0xd
    80005ea6:	0c2017b7          	lui	a5,0xc201
    80005eaa:	953e                	add	a0,a0,a5
    80005eac:	00052023          	sw	zero,0(a0)
}
    80005eb0:	60a2                	ld	ra,8(sp)
    80005eb2:	6402                	ld	s0,0(sp)
    80005eb4:	0141                	addi	sp,sp,16
    80005eb6:	8082                	ret

0000000080005eb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005eb8:	1141                	addi	sp,sp,-16
    80005eba:	e406                	sd	ra,8(sp)
    80005ebc:	e022                	sd	s0,0(sp)
    80005ebe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ec0:	ffffc097          	auipc	ra,0xffffc
    80005ec4:	ac4080e7          	jalr	-1340(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ec8:	00d5179b          	slliw	a5,a0,0xd
    80005ecc:	0c201537          	lui	a0,0xc201
    80005ed0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ed2:	4148                	lw	a0,4(a0)
    80005ed4:	60a2                	ld	ra,8(sp)
    80005ed6:	6402                	ld	s0,0(sp)
    80005ed8:	0141                	addi	sp,sp,16
    80005eda:	8082                	ret

0000000080005edc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005edc:	1101                	addi	sp,sp,-32
    80005ede:	ec06                	sd	ra,24(sp)
    80005ee0:	e822                	sd	s0,16(sp)
    80005ee2:	e426                	sd	s1,8(sp)
    80005ee4:	1000                	addi	s0,sp,32
    80005ee6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ee8:	ffffc097          	auipc	ra,0xffffc
    80005eec:	a9c080e7          	jalr	-1380(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ef0:	00d5151b          	slliw	a0,a0,0xd
    80005ef4:	0c2017b7          	lui	a5,0xc201
    80005ef8:	97aa                	add	a5,a5,a0
    80005efa:	c3c4                	sw	s1,4(a5)
}
    80005efc:	60e2                	ld	ra,24(sp)
    80005efe:	6442                	ld	s0,16(sp)
    80005f00:	64a2                	ld	s1,8(sp)
    80005f02:	6105                	addi	sp,sp,32
    80005f04:	8082                	ret

0000000080005f06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f06:	1141                	addi	sp,sp,-16
    80005f08:	e406                	sd	ra,8(sp)
    80005f0a:	e022                	sd	s0,0(sp)
    80005f0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f0e:	479d                	li	a5,7
    80005f10:	06a7c963          	blt	a5,a0,80005f82 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f14:	0001d797          	auipc	a5,0x1d
    80005f18:	0ec78793          	addi	a5,a5,236 # 80023000 <disk>
    80005f1c:	00a78733          	add	a4,a5,a0
    80005f20:	6789                	lui	a5,0x2
    80005f22:	97ba                	add	a5,a5,a4
    80005f24:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f28:	e7ad                	bnez	a5,80005f92 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f2a:	00451793          	slli	a5,a0,0x4
    80005f2e:	0001f717          	auipc	a4,0x1f
    80005f32:	0d270713          	addi	a4,a4,210 # 80025000 <disk+0x2000>
    80005f36:	6314                	ld	a3,0(a4)
    80005f38:	96be                	add	a3,a3,a5
    80005f3a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f3e:	6314                	ld	a3,0(a4)
    80005f40:	96be                	add	a3,a3,a5
    80005f42:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f46:	6314                	ld	a3,0(a4)
    80005f48:	96be                	add	a3,a3,a5
    80005f4a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f4e:	6318                	ld	a4,0(a4)
    80005f50:	97ba                	add	a5,a5,a4
    80005f52:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f56:	0001d797          	auipc	a5,0x1d
    80005f5a:	0aa78793          	addi	a5,a5,170 # 80023000 <disk>
    80005f5e:	97aa                	add	a5,a5,a0
    80005f60:	6509                	lui	a0,0x2
    80005f62:	953e                	add	a0,a0,a5
    80005f64:	4785                	li	a5,1
    80005f66:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f6a:	0001f517          	auipc	a0,0x1f
    80005f6e:	0ae50513          	addi	a0,a0,174 # 80025018 <disk+0x2018>
    80005f72:	ffffc097          	auipc	ra,0xffffc
    80005f76:	2b6080e7          	jalr	694(ra) # 80002228 <wakeup>
}
    80005f7a:	60a2                	ld	ra,8(sp)
    80005f7c:	6402                	ld	s0,0(sp)
    80005f7e:	0141                	addi	sp,sp,16
    80005f80:	8082                	ret
    panic("free_desc 1");
    80005f82:	00003517          	auipc	a0,0x3
    80005f86:	96650513          	addi	a0,a0,-1690 # 800088e8 <syscallNames+0x320>
    80005f8a:	ffffa097          	auipc	ra,0xffffa
    80005f8e:	5b4080e7          	jalr	1460(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f92:	00003517          	auipc	a0,0x3
    80005f96:	96650513          	addi	a0,a0,-1690 # 800088f8 <syscallNames+0x330>
    80005f9a:	ffffa097          	auipc	ra,0xffffa
    80005f9e:	5a4080e7          	jalr	1444(ra) # 8000053e <panic>

0000000080005fa2 <virtio_disk_init>:
{
    80005fa2:	1101                	addi	sp,sp,-32
    80005fa4:	ec06                	sd	ra,24(sp)
    80005fa6:	e822                	sd	s0,16(sp)
    80005fa8:	e426                	sd	s1,8(sp)
    80005faa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fac:	00003597          	auipc	a1,0x3
    80005fb0:	95c58593          	addi	a1,a1,-1700 # 80008908 <syscallNames+0x340>
    80005fb4:	0001f517          	auipc	a0,0x1f
    80005fb8:	17450513          	addi	a0,a0,372 # 80025128 <disk+0x2128>
    80005fbc:	ffffb097          	auipc	ra,0xffffb
    80005fc0:	b98080e7          	jalr	-1128(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fc4:	100017b7          	lui	a5,0x10001
    80005fc8:	4398                	lw	a4,0(a5)
    80005fca:	2701                	sext.w	a4,a4
    80005fcc:	747277b7          	lui	a5,0x74727
    80005fd0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fd4:	0ef71163          	bne	a4,a5,800060b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fd8:	100017b7          	lui	a5,0x10001
    80005fdc:	43dc                	lw	a5,4(a5)
    80005fde:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fe0:	4705                	li	a4,1
    80005fe2:	0ce79a63          	bne	a5,a4,800060b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fe6:	100017b7          	lui	a5,0x10001
    80005fea:	479c                	lw	a5,8(a5)
    80005fec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fee:	4709                	li	a4,2
    80005ff0:	0ce79363          	bne	a5,a4,800060b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ff4:	100017b7          	lui	a5,0x10001
    80005ff8:	47d8                	lw	a4,12(a5)
    80005ffa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ffc:	554d47b7          	lui	a5,0x554d4
    80006000:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006004:	0af71963          	bne	a4,a5,800060b6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006008:	100017b7          	lui	a5,0x10001
    8000600c:	4705                	li	a4,1
    8000600e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006010:	470d                	li	a4,3
    80006012:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006014:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006016:	c7ffe737          	lui	a4,0xc7ffe
    8000601a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000601e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006020:	2701                	sext.w	a4,a4
    80006022:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006024:	472d                	li	a4,11
    80006026:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006028:	473d                	li	a4,15
    8000602a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000602c:	6705                	lui	a4,0x1
    8000602e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006030:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006034:	5bdc                	lw	a5,52(a5)
    80006036:	2781                	sext.w	a5,a5
  if(max == 0)
    80006038:	c7d9                	beqz	a5,800060c6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000603a:	471d                	li	a4,7
    8000603c:	08f77d63          	bgeu	a4,a5,800060d6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006040:	100014b7          	lui	s1,0x10001
    80006044:	47a1                	li	a5,8
    80006046:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006048:	6609                	lui	a2,0x2
    8000604a:	4581                	li	a1,0
    8000604c:	0001d517          	auipc	a0,0x1d
    80006050:	fb450513          	addi	a0,a0,-76 # 80023000 <disk>
    80006054:	ffffb097          	auipc	ra,0xffffb
    80006058:	c8c080e7          	jalr	-884(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000605c:	0001d717          	auipc	a4,0x1d
    80006060:	fa470713          	addi	a4,a4,-92 # 80023000 <disk>
    80006064:	00c75793          	srli	a5,a4,0xc
    80006068:	2781                	sext.w	a5,a5
    8000606a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000606c:	0001f797          	auipc	a5,0x1f
    80006070:	f9478793          	addi	a5,a5,-108 # 80025000 <disk+0x2000>
    80006074:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006076:	0001d717          	auipc	a4,0x1d
    8000607a:	00a70713          	addi	a4,a4,10 # 80023080 <disk+0x80>
    8000607e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006080:	0001e717          	auipc	a4,0x1e
    80006084:	f8070713          	addi	a4,a4,-128 # 80024000 <disk+0x1000>
    80006088:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000608a:	4705                	li	a4,1
    8000608c:	00e78c23          	sb	a4,24(a5)
    80006090:	00e78ca3          	sb	a4,25(a5)
    80006094:	00e78d23          	sb	a4,26(a5)
    80006098:	00e78da3          	sb	a4,27(a5)
    8000609c:	00e78e23          	sb	a4,28(a5)
    800060a0:	00e78ea3          	sb	a4,29(a5)
    800060a4:	00e78f23          	sb	a4,30(a5)
    800060a8:	00e78fa3          	sb	a4,31(a5)
}
    800060ac:	60e2                	ld	ra,24(sp)
    800060ae:	6442                	ld	s0,16(sp)
    800060b0:	64a2                	ld	s1,8(sp)
    800060b2:	6105                	addi	sp,sp,32
    800060b4:	8082                	ret
    panic("could not find virtio disk");
    800060b6:	00003517          	auipc	a0,0x3
    800060ba:	86250513          	addi	a0,a0,-1950 # 80008918 <syscallNames+0x350>
    800060be:	ffffa097          	auipc	ra,0xffffa
    800060c2:	480080e7          	jalr	1152(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800060c6:	00003517          	auipc	a0,0x3
    800060ca:	87250513          	addi	a0,a0,-1934 # 80008938 <syscallNames+0x370>
    800060ce:	ffffa097          	auipc	ra,0xffffa
    800060d2:	470080e7          	jalr	1136(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800060d6:	00003517          	auipc	a0,0x3
    800060da:	88250513          	addi	a0,a0,-1918 # 80008958 <syscallNames+0x390>
    800060de:	ffffa097          	auipc	ra,0xffffa
    800060e2:	460080e7          	jalr	1120(ra) # 8000053e <panic>

00000000800060e6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060e6:	7159                	addi	sp,sp,-112
    800060e8:	f486                	sd	ra,104(sp)
    800060ea:	f0a2                	sd	s0,96(sp)
    800060ec:	eca6                	sd	s1,88(sp)
    800060ee:	e8ca                	sd	s2,80(sp)
    800060f0:	e4ce                	sd	s3,72(sp)
    800060f2:	e0d2                	sd	s4,64(sp)
    800060f4:	fc56                	sd	s5,56(sp)
    800060f6:	f85a                	sd	s6,48(sp)
    800060f8:	f45e                	sd	s7,40(sp)
    800060fa:	f062                	sd	s8,32(sp)
    800060fc:	ec66                	sd	s9,24(sp)
    800060fe:	e86a                	sd	s10,16(sp)
    80006100:	1880                	addi	s0,sp,112
    80006102:	892a                	mv	s2,a0
    80006104:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006106:	00c52c83          	lw	s9,12(a0)
    8000610a:	001c9c9b          	slliw	s9,s9,0x1
    8000610e:	1c82                	slli	s9,s9,0x20
    80006110:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006114:	0001f517          	auipc	a0,0x1f
    80006118:	01450513          	addi	a0,a0,20 # 80025128 <disk+0x2128>
    8000611c:	ffffb097          	auipc	ra,0xffffb
    80006120:	ac8080e7          	jalr	-1336(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006124:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006126:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006128:	0001db97          	auipc	s7,0x1d
    8000612c:	ed8b8b93          	addi	s7,s7,-296 # 80023000 <disk>
    80006130:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006132:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006134:	8a4e                	mv	s4,s3
    80006136:	a051                	j	800061ba <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006138:	00fb86b3          	add	a3,s7,a5
    8000613c:	96da                	add	a3,a3,s6
    8000613e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006142:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006144:	0207c563          	bltz	a5,8000616e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006148:	2485                	addiw	s1,s1,1
    8000614a:	0711                	addi	a4,a4,4
    8000614c:	25548063          	beq	s1,s5,8000638c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006150:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006152:	0001f697          	auipc	a3,0x1f
    80006156:	ec668693          	addi	a3,a3,-314 # 80025018 <disk+0x2018>
    8000615a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000615c:	0006c583          	lbu	a1,0(a3)
    80006160:	fde1                	bnez	a1,80006138 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006162:	2785                	addiw	a5,a5,1
    80006164:	0685                	addi	a3,a3,1
    80006166:	ff879be3          	bne	a5,s8,8000615c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000616a:	57fd                	li	a5,-1
    8000616c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000616e:	02905a63          	blez	s1,800061a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006172:	f9042503          	lw	a0,-112(s0)
    80006176:	00000097          	auipc	ra,0x0
    8000617a:	d90080e7          	jalr	-624(ra) # 80005f06 <free_desc>
      for(int j = 0; j < i; j++)
    8000617e:	4785                	li	a5,1
    80006180:	0297d163          	bge	a5,s1,800061a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006184:	f9442503          	lw	a0,-108(s0)
    80006188:	00000097          	auipc	ra,0x0
    8000618c:	d7e080e7          	jalr	-642(ra) # 80005f06 <free_desc>
      for(int j = 0; j < i; j++)
    80006190:	4789                	li	a5,2
    80006192:	0097d863          	bge	a5,s1,800061a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006196:	f9842503          	lw	a0,-104(s0)
    8000619a:	00000097          	auipc	ra,0x0
    8000619e:	d6c080e7          	jalr	-660(ra) # 80005f06 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061a2:	0001f597          	auipc	a1,0x1f
    800061a6:	f8658593          	addi	a1,a1,-122 # 80025128 <disk+0x2128>
    800061aa:	0001f517          	auipc	a0,0x1f
    800061ae:	e6e50513          	addi	a0,a0,-402 # 80025018 <disk+0x2018>
    800061b2:	ffffc097          	auipc	ra,0xffffc
    800061b6:	eea080e7          	jalr	-278(ra) # 8000209c <sleep>
  for(int i = 0; i < 3; i++){
    800061ba:	f9040713          	addi	a4,s0,-112
    800061be:	84ce                	mv	s1,s3
    800061c0:	bf41                	j	80006150 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800061c2:	20058713          	addi	a4,a1,512
    800061c6:	00471693          	slli	a3,a4,0x4
    800061ca:	0001d717          	auipc	a4,0x1d
    800061ce:	e3670713          	addi	a4,a4,-458 # 80023000 <disk>
    800061d2:	9736                	add	a4,a4,a3
    800061d4:	4685                	li	a3,1
    800061d6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061da:	20058713          	addi	a4,a1,512
    800061de:	00471693          	slli	a3,a4,0x4
    800061e2:	0001d717          	auipc	a4,0x1d
    800061e6:	e1e70713          	addi	a4,a4,-482 # 80023000 <disk>
    800061ea:	9736                	add	a4,a4,a3
    800061ec:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800061f0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061f4:	7679                	lui	a2,0xffffe
    800061f6:	963e                	add	a2,a2,a5
    800061f8:	0001f697          	auipc	a3,0x1f
    800061fc:	e0868693          	addi	a3,a3,-504 # 80025000 <disk+0x2000>
    80006200:	6298                	ld	a4,0(a3)
    80006202:	9732                	add	a4,a4,a2
    80006204:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006206:	6298                	ld	a4,0(a3)
    80006208:	9732                	add	a4,a4,a2
    8000620a:	4541                	li	a0,16
    8000620c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000620e:	6298                	ld	a4,0(a3)
    80006210:	9732                	add	a4,a4,a2
    80006212:	4505                	li	a0,1
    80006214:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006218:	f9442703          	lw	a4,-108(s0)
    8000621c:	6288                	ld	a0,0(a3)
    8000621e:	962a                	add	a2,a2,a0
    80006220:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006224:	0712                	slli	a4,a4,0x4
    80006226:	6290                	ld	a2,0(a3)
    80006228:	963a                	add	a2,a2,a4
    8000622a:	05890513          	addi	a0,s2,88
    8000622e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006230:	6294                	ld	a3,0(a3)
    80006232:	96ba                	add	a3,a3,a4
    80006234:	40000613          	li	a2,1024
    80006238:	c690                	sw	a2,8(a3)
  if(write)
    8000623a:	140d0063          	beqz	s10,8000637a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000623e:	0001f697          	auipc	a3,0x1f
    80006242:	dc26b683          	ld	a3,-574(a3) # 80025000 <disk+0x2000>
    80006246:	96ba                	add	a3,a3,a4
    80006248:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000624c:	0001d817          	auipc	a6,0x1d
    80006250:	db480813          	addi	a6,a6,-588 # 80023000 <disk>
    80006254:	0001f517          	auipc	a0,0x1f
    80006258:	dac50513          	addi	a0,a0,-596 # 80025000 <disk+0x2000>
    8000625c:	6114                	ld	a3,0(a0)
    8000625e:	96ba                	add	a3,a3,a4
    80006260:	00c6d603          	lhu	a2,12(a3)
    80006264:	00166613          	ori	a2,a2,1
    80006268:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000626c:	f9842683          	lw	a3,-104(s0)
    80006270:	6110                	ld	a2,0(a0)
    80006272:	9732                	add	a4,a4,a2
    80006274:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006278:	20058613          	addi	a2,a1,512
    8000627c:	0612                	slli	a2,a2,0x4
    8000627e:	9642                	add	a2,a2,a6
    80006280:	577d                	li	a4,-1
    80006282:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006286:	00469713          	slli	a4,a3,0x4
    8000628a:	6114                	ld	a3,0(a0)
    8000628c:	96ba                	add	a3,a3,a4
    8000628e:	03078793          	addi	a5,a5,48
    80006292:	97c2                	add	a5,a5,a6
    80006294:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006296:	611c                	ld	a5,0(a0)
    80006298:	97ba                	add	a5,a5,a4
    8000629a:	4685                	li	a3,1
    8000629c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000629e:	611c                	ld	a5,0(a0)
    800062a0:	97ba                	add	a5,a5,a4
    800062a2:	4809                	li	a6,2
    800062a4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800062a8:	611c                	ld	a5,0(a0)
    800062aa:	973e                	add	a4,a4,a5
    800062ac:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062b0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800062b4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062b8:	6518                	ld	a4,8(a0)
    800062ba:	00275783          	lhu	a5,2(a4)
    800062be:	8b9d                	andi	a5,a5,7
    800062c0:	0786                	slli	a5,a5,0x1
    800062c2:	97ba                	add	a5,a5,a4
    800062c4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800062c8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062cc:	6518                	ld	a4,8(a0)
    800062ce:	00275783          	lhu	a5,2(a4)
    800062d2:	2785                	addiw	a5,a5,1
    800062d4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062d8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062dc:	100017b7          	lui	a5,0x10001
    800062e0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062e4:	00492703          	lw	a4,4(s2)
    800062e8:	4785                	li	a5,1
    800062ea:	02f71163          	bne	a4,a5,8000630c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800062ee:	0001f997          	auipc	s3,0x1f
    800062f2:	e3a98993          	addi	s3,s3,-454 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800062f6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062f8:	85ce                	mv	a1,s3
    800062fa:	854a                	mv	a0,s2
    800062fc:	ffffc097          	auipc	ra,0xffffc
    80006300:	da0080e7          	jalr	-608(ra) # 8000209c <sleep>
  while(b->disk == 1) {
    80006304:	00492783          	lw	a5,4(s2)
    80006308:	fe9788e3          	beq	a5,s1,800062f8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000630c:	f9042903          	lw	s2,-112(s0)
    80006310:	20090793          	addi	a5,s2,512
    80006314:	00479713          	slli	a4,a5,0x4
    80006318:	0001d797          	auipc	a5,0x1d
    8000631c:	ce878793          	addi	a5,a5,-792 # 80023000 <disk>
    80006320:	97ba                	add	a5,a5,a4
    80006322:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006326:	0001f997          	auipc	s3,0x1f
    8000632a:	cda98993          	addi	s3,s3,-806 # 80025000 <disk+0x2000>
    8000632e:	00491713          	slli	a4,s2,0x4
    80006332:	0009b783          	ld	a5,0(s3)
    80006336:	97ba                	add	a5,a5,a4
    80006338:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000633c:	854a                	mv	a0,s2
    8000633e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006342:	00000097          	auipc	ra,0x0
    80006346:	bc4080e7          	jalr	-1084(ra) # 80005f06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000634a:	8885                	andi	s1,s1,1
    8000634c:	f0ed                	bnez	s1,8000632e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000634e:	0001f517          	auipc	a0,0x1f
    80006352:	dda50513          	addi	a0,a0,-550 # 80025128 <disk+0x2128>
    80006356:	ffffb097          	auipc	ra,0xffffb
    8000635a:	942080e7          	jalr	-1726(ra) # 80000c98 <release>
}
    8000635e:	70a6                	ld	ra,104(sp)
    80006360:	7406                	ld	s0,96(sp)
    80006362:	64e6                	ld	s1,88(sp)
    80006364:	6946                	ld	s2,80(sp)
    80006366:	69a6                	ld	s3,72(sp)
    80006368:	6a06                	ld	s4,64(sp)
    8000636a:	7ae2                	ld	s5,56(sp)
    8000636c:	7b42                	ld	s6,48(sp)
    8000636e:	7ba2                	ld	s7,40(sp)
    80006370:	7c02                	ld	s8,32(sp)
    80006372:	6ce2                	ld	s9,24(sp)
    80006374:	6d42                	ld	s10,16(sp)
    80006376:	6165                	addi	sp,sp,112
    80006378:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000637a:	0001f697          	auipc	a3,0x1f
    8000637e:	c866b683          	ld	a3,-890(a3) # 80025000 <disk+0x2000>
    80006382:	96ba                	add	a3,a3,a4
    80006384:	4609                	li	a2,2
    80006386:	00c69623          	sh	a2,12(a3)
    8000638a:	b5c9                	j	8000624c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000638c:	f9042583          	lw	a1,-112(s0)
    80006390:	20058793          	addi	a5,a1,512
    80006394:	0792                	slli	a5,a5,0x4
    80006396:	0001d517          	auipc	a0,0x1d
    8000639a:	d1250513          	addi	a0,a0,-750 # 800230a8 <disk+0xa8>
    8000639e:	953e                	add	a0,a0,a5
  if(write)
    800063a0:	e20d11e3          	bnez	s10,800061c2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800063a4:	20058713          	addi	a4,a1,512
    800063a8:	00471693          	slli	a3,a4,0x4
    800063ac:	0001d717          	auipc	a4,0x1d
    800063b0:	c5470713          	addi	a4,a4,-940 # 80023000 <disk>
    800063b4:	9736                	add	a4,a4,a3
    800063b6:	0a072423          	sw	zero,168(a4)
    800063ba:	b505                	j	800061da <virtio_disk_rw+0xf4>

00000000800063bc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063bc:	1101                	addi	sp,sp,-32
    800063be:	ec06                	sd	ra,24(sp)
    800063c0:	e822                	sd	s0,16(sp)
    800063c2:	e426                	sd	s1,8(sp)
    800063c4:	e04a                	sd	s2,0(sp)
    800063c6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063c8:	0001f517          	auipc	a0,0x1f
    800063cc:	d6050513          	addi	a0,a0,-672 # 80025128 <disk+0x2128>
    800063d0:	ffffb097          	auipc	ra,0xffffb
    800063d4:	814080e7          	jalr	-2028(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063d8:	10001737          	lui	a4,0x10001
    800063dc:	533c                	lw	a5,96(a4)
    800063de:	8b8d                	andi	a5,a5,3
    800063e0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063e2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063e6:	0001f797          	auipc	a5,0x1f
    800063ea:	c1a78793          	addi	a5,a5,-998 # 80025000 <disk+0x2000>
    800063ee:	6b94                	ld	a3,16(a5)
    800063f0:	0207d703          	lhu	a4,32(a5)
    800063f4:	0026d783          	lhu	a5,2(a3)
    800063f8:	06f70163          	beq	a4,a5,8000645a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063fc:	0001d917          	auipc	s2,0x1d
    80006400:	c0490913          	addi	s2,s2,-1020 # 80023000 <disk>
    80006404:	0001f497          	auipc	s1,0x1f
    80006408:	bfc48493          	addi	s1,s1,-1028 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000640c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006410:	6898                	ld	a4,16(s1)
    80006412:	0204d783          	lhu	a5,32(s1)
    80006416:	8b9d                	andi	a5,a5,7
    80006418:	078e                	slli	a5,a5,0x3
    8000641a:	97ba                	add	a5,a5,a4
    8000641c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000641e:	20078713          	addi	a4,a5,512
    80006422:	0712                	slli	a4,a4,0x4
    80006424:	974a                	add	a4,a4,s2
    80006426:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000642a:	e731                	bnez	a4,80006476 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000642c:	20078793          	addi	a5,a5,512
    80006430:	0792                	slli	a5,a5,0x4
    80006432:	97ca                	add	a5,a5,s2
    80006434:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006436:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000643a:	ffffc097          	auipc	ra,0xffffc
    8000643e:	dee080e7          	jalr	-530(ra) # 80002228 <wakeup>

    disk.used_idx += 1;
    80006442:	0204d783          	lhu	a5,32(s1)
    80006446:	2785                	addiw	a5,a5,1
    80006448:	17c2                	slli	a5,a5,0x30
    8000644a:	93c1                	srli	a5,a5,0x30
    8000644c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006450:	6898                	ld	a4,16(s1)
    80006452:	00275703          	lhu	a4,2(a4)
    80006456:	faf71be3          	bne	a4,a5,8000640c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000645a:	0001f517          	auipc	a0,0x1f
    8000645e:	cce50513          	addi	a0,a0,-818 # 80025128 <disk+0x2128>
    80006462:	ffffb097          	auipc	ra,0xffffb
    80006466:	836080e7          	jalr	-1994(ra) # 80000c98 <release>
}
    8000646a:	60e2                	ld	ra,24(sp)
    8000646c:	6442                	ld	s0,16(sp)
    8000646e:	64a2                	ld	s1,8(sp)
    80006470:	6902                	ld	s2,0(sp)
    80006472:	6105                	addi	sp,sp,32
    80006474:	8082                	ret
      panic("virtio_disk_intr status");
    80006476:	00002517          	auipc	a0,0x2
    8000647a:	50250513          	addi	a0,a0,1282 # 80008978 <syscallNames+0x3b0>
    8000647e:	ffffa097          	auipc	ra,0xffffa
    80006482:	0c0080e7          	jalr	192(ra) # 8000053e <panic>
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
