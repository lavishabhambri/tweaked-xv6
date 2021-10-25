
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	87013103          	ld	sp,-1936(sp) # 80008870 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	d5c78793          	addi	a5,a5,-676 # 80005dc0 <timervec>
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
    80000130:	37c080e7          	jalr	892(ra) # 800024a8 <either_copyin>
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
    800001d8:	ec0080e7          	jalr	-320(ra) # 80002094 <sleep>
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
    80000214:	242080e7          	jalr	578(ra) # 80002452 <either_copyout>
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
    800002f6:	20c080e7          	jalr	524(ra) # 800024fe <procdump>
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
    8000044a:	dda080e7          	jalr	-550(ra) # 80002220 <wakeup>
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
    800008a4:	980080e7          	jalr	-1664(ra) # 80002220 <wakeup>
    
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
    80000930:	768080e7          	jalr	1896(ra) # 80002094 <sleep>
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
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    80000cf6:	00b78023          	sb	a1,0(a5)
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
    80000d32:	40e7853b          	subw	a0,a5,a4
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    80000d7e:	96aa                	add	a3,a3,a0
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    80000e5a:	00078023          	sb	zero,0(a5)
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
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
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
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
    80000ed8:	918080e7          	jalr	-1768(ra) # 800027ec <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	f24080e7          	jalr	-220(ra) # 80005e00 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	ffe080e7          	jalr	-2(ra) # 80001ee2 <scheduler>
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
    80000f50:	878080e7          	jalr	-1928(ra) # 800027c4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	898080e7          	jalr	-1896(ra) # 800027ec <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	e8e080e7          	jalr	-370(ra) # 80005dea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	e9c080e7          	jalr	-356(ra) # 80005e00 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	07e080e7          	jalr	126(ra) # 80002fea <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	70e080e7          	jalr	1806(ra) # 80003682 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	6b8080e7          	jalr	1720(ra) # 80004634 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	f9e080e7          	jalr	-98(ra) # 80005f22 <virtio_disk_init>
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
    80001a04:	e207a783          	lw	a5,-480(a5) # 80008820 <first.1681>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	dfa080e7          	jalr	-518(ra) # 80002804 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	e007a323          	sw	zero,-506(a5) # 80008820 <first.1681>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	bde080e7          	jalr	-1058(ra) # 80003602 <fsinit>
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
    80001a50:	dd878793          	addi	a5,a5,-552 # 80008824 <nextpid>
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
    80001cd4:	b6058593          	addi	a1,a1,-1184 # 80008830 <initcode>
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
    80001d12:	322080e7          	jalr	802(ra) # 80004030 <namei>
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
    80001dc8:	10050b63          	beqz	a0,80001ede <fork+0x138>
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
    80001e42:	a069                	j	80001ecc <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e44:	00003097          	auipc	ra,0x3
    80001e48:	882080e7          	jalr	-1918(ra) # 800046c6 <filedup>
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
    80001e6a:	9d6080e7          	jalr	-1578(ra) # 8000383c <idup>
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
  release(&wait_lock);
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	dee080e7          	jalr	-530(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001eb2:	854e                	mv	a0,s3
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	d30080e7          	jalr	-720(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ebc:	478d                	li	a5,3
    80001ebe:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ec2:	854e                	mv	a0,s3
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	dd4080e7          	jalr	-556(ra) # 80000c98 <release>
}
    80001ecc:	8552                	mv	a0,s4
    80001ece:	70a2                	ld	ra,40(sp)
    80001ed0:	7402                	ld	s0,32(sp)
    80001ed2:	64e2                	ld	s1,24(sp)
    80001ed4:	6942                	ld	s2,16(sp)
    80001ed6:	69a2                	ld	s3,8(sp)
    80001ed8:	6a02                	ld	s4,0(sp)
    80001eda:	6145                	addi	sp,sp,48
    80001edc:	8082                	ret
    return -1;
    80001ede:	5a7d                	li	s4,-1
    80001ee0:	b7f5                	j	80001ecc <fork+0x126>

0000000080001ee2 <scheduler>:
{
    80001ee2:	7139                	addi	sp,sp,-64
    80001ee4:	fc06                	sd	ra,56(sp)
    80001ee6:	f822                	sd	s0,48(sp)
    80001ee8:	f426                	sd	s1,40(sp)
    80001eea:	f04a                	sd	s2,32(sp)
    80001eec:	ec4e                	sd	s3,24(sp)
    80001eee:	e852                	sd	s4,16(sp)
    80001ef0:	e456                	sd	s5,8(sp)
    80001ef2:	e05a                	sd	s6,0(sp)
    80001ef4:	0080                	addi	s0,sp,64
    80001ef6:	8792                	mv	a5,tp
  int id = r_tp();
    80001ef8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001efa:	00779a93          	slli	s5,a5,0x7
    80001efe:	0000f717          	auipc	a4,0xf
    80001f02:	3a270713          	addi	a4,a4,930 # 800112a0 <pid_lock>
    80001f06:	9756                	add	a4,a4,s5
    80001f08:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f0c:	0000f717          	auipc	a4,0xf
    80001f10:	3cc70713          	addi	a4,a4,972 # 800112d8 <cpus+0x8>
    80001f14:	9aba                	add	s5,s5,a4
        if(p->state == RUNNABLE) {
    80001f16:	498d                	li	s3,3
          p->state = RUNNING;
    80001f18:	4b11                	li	s6,4
          c->proc = p;
    80001f1a:	079e                	slli	a5,a5,0x7
    80001f1c:	0000fa17          	auipc	s4,0xf
    80001f20:	384a0a13          	addi	s4,s4,900 # 800112a0 <pid_lock>
    80001f24:	9a3e                	add	s4,s4,a5
      for(p = proc; p < &proc[NPROC]; p++) {
    80001f26:	00015917          	auipc	s2,0x15
    80001f2a:	5aa90913          	addi	s2,s2,1450 # 800174d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f2e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f32:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f36:	10079073          	csrw	sstatus,a5
    80001f3a:	0000f497          	auipc	s1,0xf
    80001f3e:	79648493          	addi	s1,s1,1942 # 800116d0 <proc>
    80001f42:	a03d                	j	80001f70 <scheduler+0x8e>
          p->state = RUNNING;
    80001f44:	0164ac23          	sw	s6,24(s1)
          c->proc = p;
    80001f48:	029a3823          	sd	s1,48(s4)
          swtch(&c->context, &p->context);
    80001f4c:	06048593          	addi	a1,s1,96
    80001f50:	8556                	mv	a0,s5
    80001f52:	00001097          	auipc	ra,0x1
    80001f56:	808080e7          	jalr	-2040(ra) # 8000275a <swtch>
          c->proc = 0;
    80001f5a:	020a3823          	sd	zero,48(s4)
        release(&p->lock);
    80001f5e:	8526                	mv	a0,s1
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	d38080e7          	jalr	-712(ra) # 80000c98 <release>
      for(p = proc; p < &proc[NPROC]; p++) {
    80001f68:	17848493          	addi	s1,s1,376
    80001f6c:	fd2481e3          	beq	s1,s2,80001f2e <scheduler+0x4c>
        acquire(&p->lock);
    80001f70:	8526                	mv	a0,s1
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	c72080e7          	jalr	-910(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001f7a:	4c9c                	lw	a5,24(s1)
    80001f7c:	ff3791e3          	bne	a5,s3,80001f5e <scheduler+0x7c>
    80001f80:	b7d1                	j	80001f44 <scheduler+0x62>

0000000080001f82 <sched>:
{
    80001f82:	7179                	addi	sp,sp,-48
    80001f84:	f406                	sd	ra,40(sp)
    80001f86:	f022                	sd	s0,32(sp)
    80001f88:	ec26                	sd	s1,24(sp)
    80001f8a:	e84a                	sd	s2,16(sp)
    80001f8c:	e44e                	sd	s3,8(sp)
    80001f8e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f90:	00000097          	auipc	ra,0x0
    80001f94:	a20080e7          	jalr	-1504(ra) # 800019b0 <myproc>
    80001f98:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	bd0080e7          	jalr	-1072(ra) # 80000b6a <holding>
    80001fa2:	c93d                	beqz	a0,80002018 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fa6:	2781                	sext.w	a5,a5
    80001fa8:	079e                	slli	a5,a5,0x7
    80001faa:	0000f717          	auipc	a4,0xf
    80001fae:	2f670713          	addi	a4,a4,758 # 800112a0 <pid_lock>
    80001fb2:	97ba                	add	a5,a5,a4
    80001fb4:	0a87a703          	lw	a4,168(a5)
    80001fb8:	4785                	li	a5,1
    80001fba:	06f71763          	bne	a4,a5,80002028 <sched+0xa6>
  if(p->state == RUNNING)
    80001fbe:	4c98                	lw	a4,24(s1)
    80001fc0:	4791                	li	a5,4
    80001fc2:	06f70b63          	beq	a4,a5,80002038 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fc6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fca:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fcc:	efb5                	bnez	a5,80002048 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fce:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fd0:	0000f917          	auipc	s2,0xf
    80001fd4:	2d090913          	addi	s2,s2,720 # 800112a0 <pid_lock>
    80001fd8:	2781                	sext.w	a5,a5
    80001fda:	079e                	slli	a5,a5,0x7
    80001fdc:	97ca                	add	a5,a5,s2
    80001fde:	0ac7a983          	lw	s3,172(a5)
    80001fe2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fe4:	2781                	sext.w	a5,a5
    80001fe6:	079e                	slli	a5,a5,0x7
    80001fe8:	0000f597          	auipc	a1,0xf
    80001fec:	2f058593          	addi	a1,a1,752 # 800112d8 <cpus+0x8>
    80001ff0:	95be                	add	a1,a1,a5
    80001ff2:	06048513          	addi	a0,s1,96
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	764080e7          	jalr	1892(ra) # 8000275a <swtch>
    80001ffe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002000:	2781                	sext.w	a5,a5
    80002002:	079e                	slli	a5,a5,0x7
    80002004:	97ca                	add	a5,a5,s2
    80002006:	0b37a623          	sw	s3,172(a5)
}
    8000200a:	70a2                	ld	ra,40(sp)
    8000200c:	7402                	ld	s0,32(sp)
    8000200e:	64e2                	ld	s1,24(sp)
    80002010:	6942                	ld	s2,16(sp)
    80002012:	69a2                	ld	s3,8(sp)
    80002014:	6145                	addi	sp,sp,48
    80002016:	8082                	ret
    panic("sched p->lock");
    80002018:	00006517          	auipc	a0,0x6
    8000201c:	20050513          	addi	a0,a0,512 # 80008218 <digits+0x1d8>
    80002020:	ffffe097          	auipc	ra,0xffffe
    80002024:	51e080e7          	jalr	1310(ra) # 8000053e <panic>
    panic("sched locks");
    80002028:	00006517          	auipc	a0,0x6
    8000202c:	20050513          	addi	a0,a0,512 # 80008228 <digits+0x1e8>
    80002030:	ffffe097          	auipc	ra,0xffffe
    80002034:	50e080e7          	jalr	1294(ra) # 8000053e <panic>
    panic("sched running");
    80002038:	00006517          	auipc	a0,0x6
    8000203c:	20050513          	addi	a0,a0,512 # 80008238 <digits+0x1f8>
    80002040:	ffffe097          	auipc	ra,0xffffe
    80002044:	4fe080e7          	jalr	1278(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002048:	00006517          	auipc	a0,0x6
    8000204c:	20050513          	addi	a0,a0,512 # 80008248 <digits+0x208>
    80002050:	ffffe097          	auipc	ra,0xffffe
    80002054:	4ee080e7          	jalr	1262(ra) # 8000053e <panic>

0000000080002058 <yield>:
{
    80002058:	1101                	addi	sp,sp,-32
    8000205a:	ec06                	sd	ra,24(sp)
    8000205c:	e822                	sd	s0,16(sp)
    8000205e:	e426                	sd	s1,8(sp)
    80002060:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002062:	00000097          	auipc	ra,0x0
    80002066:	94e080e7          	jalr	-1714(ra) # 800019b0 <myproc>
    8000206a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	b78080e7          	jalr	-1160(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002074:	478d                	li	a5,3
    80002076:	cc9c                	sw	a5,24(s1)
  sched();
    80002078:	00000097          	auipc	ra,0x0
    8000207c:	f0a080e7          	jalr	-246(ra) # 80001f82 <sched>
  release(&p->lock);
    80002080:	8526                	mv	a0,s1
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	c16080e7          	jalr	-1002(ra) # 80000c98 <release>
}
    8000208a:	60e2                	ld	ra,24(sp)
    8000208c:	6442                	ld	s0,16(sp)
    8000208e:	64a2                	ld	s1,8(sp)
    80002090:	6105                	addi	sp,sp,32
    80002092:	8082                	ret

0000000080002094 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002094:	7179                	addi	sp,sp,-48
    80002096:	f406                	sd	ra,40(sp)
    80002098:	f022                	sd	s0,32(sp)
    8000209a:	ec26                	sd	s1,24(sp)
    8000209c:	e84a                	sd	s2,16(sp)
    8000209e:	e44e                	sd	s3,8(sp)
    800020a0:	1800                	addi	s0,sp,48
    800020a2:	89aa                	mv	s3,a0
    800020a4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020a6:	00000097          	auipc	ra,0x0
    800020aa:	90a080e7          	jalr	-1782(ra) # 800019b0 <myproc>
    800020ae:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	b34080e7          	jalr	-1228(ra) # 80000be4 <acquire>
  release(lk);
    800020b8:	854a                	mv	a0,s2
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	bde080e7          	jalr	-1058(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800020c2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020c6:	4789                	li	a5,2
    800020c8:	cc9c                	sw	a5,24(s1)

  sched();
    800020ca:	00000097          	auipc	ra,0x0
    800020ce:	eb8080e7          	jalr	-328(ra) # 80001f82 <sched>

  // Tidy up.
  p->chan = 0;
    800020d2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020d6:	8526                	mv	a0,s1
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	bc0080e7          	jalr	-1088(ra) # 80000c98 <release>
  acquire(lk);
    800020e0:	854a                	mv	a0,s2
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	b02080e7          	jalr	-1278(ra) # 80000be4 <acquire>
}
    800020ea:	70a2                	ld	ra,40(sp)
    800020ec:	7402                	ld	s0,32(sp)
    800020ee:	64e2                	ld	s1,24(sp)
    800020f0:	6942                	ld	s2,16(sp)
    800020f2:	69a2                	ld	s3,8(sp)
    800020f4:	6145                	addi	sp,sp,48
    800020f6:	8082                	ret

00000000800020f8 <wait>:
{
    800020f8:	715d                	addi	sp,sp,-80
    800020fa:	e486                	sd	ra,72(sp)
    800020fc:	e0a2                	sd	s0,64(sp)
    800020fe:	fc26                	sd	s1,56(sp)
    80002100:	f84a                	sd	s2,48(sp)
    80002102:	f44e                	sd	s3,40(sp)
    80002104:	f052                	sd	s4,32(sp)
    80002106:	ec56                	sd	s5,24(sp)
    80002108:	e85a                	sd	s6,16(sp)
    8000210a:	e45e                	sd	s7,8(sp)
    8000210c:	e062                	sd	s8,0(sp)
    8000210e:	0880                	addi	s0,sp,80
    80002110:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002112:	00000097          	auipc	ra,0x0
    80002116:	89e080e7          	jalr	-1890(ra) # 800019b0 <myproc>
    8000211a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000211c:	0000f517          	auipc	a0,0xf
    80002120:	19c50513          	addi	a0,a0,412 # 800112b8 <wait_lock>
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	ac0080e7          	jalr	-1344(ra) # 80000be4 <acquire>
    havekids = 0;
    8000212c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000212e:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002130:	00015997          	auipc	s3,0x15
    80002134:	3a098993          	addi	s3,s3,928 # 800174d0 <tickslock>
        havekids = 1;
    80002138:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000213a:	0000fc17          	auipc	s8,0xf
    8000213e:	17ec0c13          	addi	s8,s8,382 # 800112b8 <wait_lock>
    havekids = 0;
    80002142:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002144:	0000f497          	auipc	s1,0xf
    80002148:	58c48493          	addi	s1,s1,1420 # 800116d0 <proc>
    8000214c:	a0bd                	j	800021ba <wait+0xc2>
          pid = np->pid;
    8000214e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002152:	000b0e63          	beqz	s6,8000216e <wait+0x76>
    80002156:	4691                	li	a3,4
    80002158:	02c48613          	addi	a2,s1,44
    8000215c:	85da                	mv	a1,s6
    8000215e:	05093503          	ld	a0,80(s2)
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	510080e7          	jalr	1296(ra) # 80001672 <copyout>
    8000216a:	02054563          	bltz	a0,80002194 <wait+0x9c>
          freeproc(np);
    8000216e:	8526                	mv	a0,s1
    80002170:	00000097          	auipc	ra,0x0
    80002174:	9f2080e7          	jalr	-1550(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002178:	8526                	mv	a0,s1
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	b1e080e7          	jalr	-1250(ra) # 80000c98 <release>
          release(&wait_lock);
    80002182:	0000f517          	auipc	a0,0xf
    80002186:	13650513          	addi	a0,a0,310 # 800112b8 <wait_lock>
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	b0e080e7          	jalr	-1266(ra) # 80000c98 <release>
          return pid;
    80002192:	a09d                	j	800021f8 <wait+0x100>
            release(&np->lock);
    80002194:	8526                	mv	a0,s1
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	b02080e7          	jalr	-1278(ra) # 80000c98 <release>
            release(&wait_lock);
    8000219e:	0000f517          	auipc	a0,0xf
    800021a2:	11a50513          	addi	a0,a0,282 # 800112b8 <wait_lock>
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	af2080e7          	jalr	-1294(ra) # 80000c98 <release>
            return -1;
    800021ae:	59fd                	li	s3,-1
    800021b0:	a0a1                	j	800021f8 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021b2:	17848493          	addi	s1,s1,376
    800021b6:	03348463          	beq	s1,s3,800021de <wait+0xe6>
      if(np->parent == p){
    800021ba:	7c9c                	ld	a5,56(s1)
    800021bc:	ff279be3          	bne	a5,s2,800021b2 <wait+0xba>
        acquire(&np->lock);
    800021c0:	8526                	mv	a0,s1
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	a22080e7          	jalr	-1502(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800021ca:	4c9c                	lw	a5,24(s1)
    800021cc:	f94781e3          	beq	a5,s4,8000214e <wait+0x56>
        release(&np->lock);
    800021d0:	8526                	mv	a0,s1
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	ac6080e7          	jalr	-1338(ra) # 80000c98 <release>
        havekids = 1;
    800021da:	8756                	mv	a4,s5
    800021dc:	bfd9                	j	800021b2 <wait+0xba>
    if(!havekids || p->killed){
    800021de:	c701                	beqz	a4,800021e6 <wait+0xee>
    800021e0:	02892783          	lw	a5,40(s2)
    800021e4:	c79d                	beqz	a5,80002212 <wait+0x11a>
      release(&wait_lock);
    800021e6:	0000f517          	auipc	a0,0xf
    800021ea:	0d250513          	addi	a0,a0,210 # 800112b8 <wait_lock>
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	aaa080e7          	jalr	-1366(ra) # 80000c98 <release>
      return -1;
    800021f6:	59fd                	li	s3,-1
}
    800021f8:	854e                	mv	a0,s3
    800021fa:	60a6                	ld	ra,72(sp)
    800021fc:	6406                	ld	s0,64(sp)
    800021fe:	74e2                	ld	s1,56(sp)
    80002200:	7942                	ld	s2,48(sp)
    80002202:	79a2                	ld	s3,40(sp)
    80002204:	7a02                	ld	s4,32(sp)
    80002206:	6ae2                	ld	s5,24(sp)
    80002208:	6b42                	ld	s6,16(sp)
    8000220a:	6ba2                	ld	s7,8(sp)
    8000220c:	6c02                	ld	s8,0(sp)
    8000220e:	6161                	addi	sp,sp,80
    80002210:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002212:	85e2                	mv	a1,s8
    80002214:	854a                	mv	a0,s2
    80002216:	00000097          	auipc	ra,0x0
    8000221a:	e7e080e7          	jalr	-386(ra) # 80002094 <sleep>
    havekids = 0;
    8000221e:	b715                	j	80002142 <wait+0x4a>

0000000080002220 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002220:	7139                	addi	sp,sp,-64
    80002222:	fc06                	sd	ra,56(sp)
    80002224:	f822                	sd	s0,48(sp)
    80002226:	f426                	sd	s1,40(sp)
    80002228:	f04a                	sd	s2,32(sp)
    8000222a:	ec4e                	sd	s3,24(sp)
    8000222c:	e852                	sd	s4,16(sp)
    8000222e:	e456                	sd	s5,8(sp)
    80002230:	0080                	addi	s0,sp,64
    80002232:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002234:	0000f497          	auipc	s1,0xf
    80002238:	49c48493          	addi	s1,s1,1180 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000223c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000223e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002240:	00015917          	auipc	s2,0x15
    80002244:	29090913          	addi	s2,s2,656 # 800174d0 <tickslock>
    80002248:	a821                	j	80002260 <wakeup+0x40>
        p->state = RUNNABLE;
    8000224a:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	a48080e7          	jalr	-1464(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002258:	17848493          	addi	s1,s1,376
    8000225c:	03248463          	beq	s1,s2,80002284 <wakeup+0x64>
    if(p != myproc()){
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	750080e7          	jalr	1872(ra) # 800019b0 <myproc>
    80002268:	fea488e3          	beq	s1,a0,80002258 <wakeup+0x38>
      acquire(&p->lock);
    8000226c:	8526                	mv	a0,s1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	976080e7          	jalr	-1674(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002276:	4c9c                	lw	a5,24(s1)
    80002278:	fd379be3          	bne	a5,s3,8000224e <wakeup+0x2e>
    8000227c:	709c                	ld	a5,32(s1)
    8000227e:	fd4798e3          	bne	a5,s4,8000224e <wakeup+0x2e>
    80002282:	b7e1                	j	8000224a <wakeup+0x2a>
    }
  }
}
    80002284:	70e2                	ld	ra,56(sp)
    80002286:	7442                	ld	s0,48(sp)
    80002288:	74a2                	ld	s1,40(sp)
    8000228a:	7902                	ld	s2,32(sp)
    8000228c:	69e2                	ld	s3,24(sp)
    8000228e:	6a42                	ld	s4,16(sp)
    80002290:	6aa2                	ld	s5,8(sp)
    80002292:	6121                	addi	sp,sp,64
    80002294:	8082                	ret

0000000080002296 <reparent>:
{
    80002296:	7179                	addi	sp,sp,-48
    80002298:	f406                	sd	ra,40(sp)
    8000229a:	f022                	sd	s0,32(sp)
    8000229c:	ec26                	sd	s1,24(sp)
    8000229e:	e84a                	sd	s2,16(sp)
    800022a0:	e44e                	sd	s3,8(sp)
    800022a2:	e052                	sd	s4,0(sp)
    800022a4:	1800                	addi	s0,sp,48
    800022a6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022a8:	0000f497          	auipc	s1,0xf
    800022ac:	42848493          	addi	s1,s1,1064 # 800116d0 <proc>
      pp->parent = initproc;
    800022b0:	00007a17          	auipc	s4,0x7
    800022b4:	d78a0a13          	addi	s4,s4,-648 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022b8:	00015997          	auipc	s3,0x15
    800022bc:	21898993          	addi	s3,s3,536 # 800174d0 <tickslock>
    800022c0:	a029                	j	800022ca <reparent+0x34>
    800022c2:	17848493          	addi	s1,s1,376
    800022c6:	01348d63          	beq	s1,s3,800022e0 <reparent+0x4a>
    if(pp->parent == p){
    800022ca:	7c9c                	ld	a5,56(s1)
    800022cc:	ff279be3          	bne	a5,s2,800022c2 <reparent+0x2c>
      pp->parent = initproc;
    800022d0:	000a3503          	ld	a0,0(s4)
    800022d4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022d6:	00000097          	auipc	ra,0x0
    800022da:	f4a080e7          	jalr	-182(ra) # 80002220 <wakeup>
    800022de:	b7d5                	j	800022c2 <reparent+0x2c>
}
    800022e0:	70a2                	ld	ra,40(sp)
    800022e2:	7402                	ld	s0,32(sp)
    800022e4:	64e2                	ld	s1,24(sp)
    800022e6:	6942                	ld	s2,16(sp)
    800022e8:	69a2                	ld	s3,8(sp)
    800022ea:	6a02                	ld	s4,0(sp)
    800022ec:	6145                	addi	sp,sp,48
    800022ee:	8082                	ret

00000000800022f0 <exit>:
{
    800022f0:	7179                	addi	sp,sp,-48
    800022f2:	f406                	sd	ra,40(sp)
    800022f4:	f022                	sd	s0,32(sp)
    800022f6:	ec26                	sd	s1,24(sp)
    800022f8:	e84a                	sd	s2,16(sp)
    800022fa:	e44e                	sd	s3,8(sp)
    800022fc:	e052                	sd	s4,0(sp)
    800022fe:	1800                	addi	s0,sp,48
    80002300:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	6ae080e7          	jalr	1710(ra) # 800019b0 <myproc>
  if(p == initproc)
    8000230a:	00007797          	auipc	a5,0x7
    8000230e:	d1e7b783          	ld	a5,-738(a5) # 80009028 <initproc>
    80002312:	00a78e63          	beq	a5,a0,8000232e <exit+0x3e>
    80002316:	89aa                	mv	s3,a0
  p->endTime = ticks;
    80002318:	00007797          	auipc	a5,0x7
    8000231c:	d187a783          	lw	a5,-744(a5) # 80009030 <ticks>
    80002320:	16f52623          	sw	a5,364(a0)
  for(int fd = 0; fd < NOFILE; fd++){
    80002324:	0d050493          	addi	s1,a0,208
    80002328:	15050913          	addi	s2,a0,336
    8000232c:	a015                	j	80002350 <exit+0x60>
    panic("init exiting");
    8000232e:	00006517          	auipc	a0,0x6
    80002332:	f3250513          	addi	a0,a0,-206 # 80008260 <digits+0x220>
    80002336:	ffffe097          	auipc	ra,0xffffe
    8000233a:	208080e7          	jalr	520(ra) # 8000053e <panic>
      fileclose(f);
    8000233e:	00002097          	auipc	ra,0x2
    80002342:	3da080e7          	jalr	986(ra) # 80004718 <fileclose>
      p->ofile[fd] = 0;
    80002346:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000234a:	04a1                	addi	s1,s1,8
    8000234c:	01248563          	beq	s1,s2,80002356 <exit+0x66>
    if(p->ofile[fd]){
    80002350:	6088                	ld	a0,0(s1)
    80002352:	f575                	bnez	a0,8000233e <exit+0x4e>
    80002354:	bfdd                	j	8000234a <exit+0x5a>
  begin_op();
    80002356:	00002097          	auipc	ra,0x2
    8000235a:	ef6080e7          	jalr	-266(ra) # 8000424c <begin_op>
  iput(p->cwd);
    8000235e:	1509b503          	ld	a0,336(s3)
    80002362:	00001097          	auipc	ra,0x1
    80002366:	6d2080e7          	jalr	1746(ra) # 80003a34 <iput>
  end_op();
    8000236a:	00002097          	auipc	ra,0x2
    8000236e:	f62080e7          	jalr	-158(ra) # 800042cc <end_op>
  p->cwd = 0;
    80002372:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002376:	0000f497          	auipc	s1,0xf
    8000237a:	f4248493          	addi	s1,s1,-190 # 800112b8 <wait_lock>
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	864080e7          	jalr	-1948(ra) # 80000be4 <acquire>
  reparent(p);
    80002388:	854e                	mv	a0,s3
    8000238a:	00000097          	auipc	ra,0x0
    8000238e:	f0c080e7          	jalr	-244(ra) # 80002296 <reparent>
  wakeup(p->parent);
    80002392:	0389b503          	ld	a0,56(s3)
    80002396:	00000097          	auipc	ra,0x0
    8000239a:	e8a080e7          	jalr	-374(ra) # 80002220 <wakeup>
  acquire(&p->lock);
    8000239e:	854e                	mv	a0,s3
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	844080e7          	jalr	-1980(ra) # 80000be4 <acquire>
  p->xstate = status;
    800023a8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023ac:	4795                	li	a5,5
    800023ae:	00f9ac23          	sw	a5,24(s3)
  p->endTime = ticks;
    800023b2:	00007797          	auipc	a5,0x7
    800023b6:	c7e7a783          	lw	a5,-898(a5) # 80009030 <ticks>
    800023ba:	16f9a623          	sw	a5,364(s3)
  release(&wait_lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8d8080e7          	jalr	-1832(ra) # 80000c98 <release>
  sched();
    800023c8:	00000097          	auipc	ra,0x0
    800023cc:	bba080e7          	jalr	-1094(ra) # 80001f82 <sched>
  panic("zombie exit");
    800023d0:	00006517          	auipc	a0,0x6
    800023d4:	ea050513          	addi	a0,a0,-352 # 80008270 <digits+0x230>
    800023d8:	ffffe097          	auipc	ra,0xffffe
    800023dc:	166080e7          	jalr	358(ra) # 8000053e <panic>

00000000800023e0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023e0:	7179                	addi	sp,sp,-48
    800023e2:	f406                	sd	ra,40(sp)
    800023e4:	f022                	sd	s0,32(sp)
    800023e6:	ec26                	sd	s1,24(sp)
    800023e8:	e84a                	sd	s2,16(sp)
    800023ea:	e44e                	sd	s3,8(sp)
    800023ec:	1800                	addi	s0,sp,48
    800023ee:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023f0:	0000f497          	auipc	s1,0xf
    800023f4:	2e048493          	addi	s1,s1,736 # 800116d0 <proc>
    800023f8:	00015997          	auipc	s3,0x15
    800023fc:	0d898993          	addi	s3,s3,216 # 800174d0 <tickslock>
    acquire(&p->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	7e2080e7          	jalr	2018(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000240a:	589c                	lw	a5,48(s1)
    8000240c:	01278d63          	beq	a5,s2,80002426 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002410:	8526                	mv	a0,s1
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	886080e7          	jalr	-1914(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000241a:	17848493          	addi	s1,s1,376
    8000241e:	ff3491e3          	bne	s1,s3,80002400 <kill+0x20>
  }
  return -1;
    80002422:	557d                	li	a0,-1
    80002424:	a829                	j	8000243e <kill+0x5e>
      p->killed = 1;
    80002426:	4785                	li	a5,1
    80002428:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000242a:	4c98                	lw	a4,24(s1)
    8000242c:	4789                	li	a5,2
    8000242e:	00f70f63          	beq	a4,a5,8000244c <kill+0x6c>
      release(&p->lock);
    80002432:	8526                	mv	a0,s1
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	864080e7          	jalr	-1948(ra) # 80000c98 <release>
      return 0;
    8000243c:	4501                	li	a0,0
}
    8000243e:	70a2                	ld	ra,40(sp)
    80002440:	7402                	ld	s0,32(sp)
    80002442:	64e2                	ld	s1,24(sp)
    80002444:	6942                	ld	s2,16(sp)
    80002446:	69a2                	ld	s3,8(sp)
    80002448:	6145                	addi	sp,sp,48
    8000244a:	8082                	ret
        p->state = RUNNABLE;
    8000244c:	478d                	li	a5,3
    8000244e:	cc9c                	sw	a5,24(s1)
    80002450:	b7cd                	j	80002432 <kill+0x52>

0000000080002452 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002452:	7179                	addi	sp,sp,-48
    80002454:	f406                	sd	ra,40(sp)
    80002456:	f022                	sd	s0,32(sp)
    80002458:	ec26                	sd	s1,24(sp)
    8000245a:	e84a                	sd	s2,16(sp)
    8000245c:	e44e                	sd	s3,8(sp)
    8000245e:	e052                	sd	s4,0(sp)
    80002460:	1800                	addi	s0,sp,48
    80002462:	84aa                	mv	s1,a0
    80002464:	892e                	mv	s2,a1
    80002466:	89b2                	mv	s3,a2
    80002468:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	546080e7          	jalr	1350(ra) # 800019b0 <myproc>
  if(user_dst){
    80002472:	c08d                	beqz	s1,80002494 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002474:	86d2                	mv	a3,s4
    80002476:	864e                	mv	a2,s3
    80002478:	85ca                	mv	a1,s2
    8000247a:	6928                	ld	a0,80(a0)
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	1f6080e7          	jalr	502(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002484:	70a2                	ld	ra,40(sp)
    80002486:	7402                	ld	s0,32(sp)
    80002488:	64e2                	ld	s1,24(sp)
    8000248a:	6942                	ld	s2,16(sp)
    8000248c:	69a2                	ld	s3,8(sp)
    8000248e:	6a02                	ld	s4,0(sp)
    80002490:	6145                	addi	sp,sp,48
    80002492:	8082                	ret
    memmove((char *)dst, src, len);
    80002494:	000a061b          	sext.w	a2,s4
    80002498:	85ce                	mv	a1,s3
    8000249a:	854a                	mv	a0,s2
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	8a4080e7          	jalr	-1884(ra) # 80000d40 <memmove>
    return 0;
    800024a4:	8526                	mv	a0,s1
    800024a6:	bff9                	j	80002484 <either_copyout+0x32>

00000000800024a8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024a8:	7179                	addi	sp,sp,-48
    800024aa:	f406                	sd	ra,40(sp)
    800024ac:	f022                	sd	s0,32(sp)
    800024ae:	ec26                	sd	s1,24(sp)
    800024b0:	e84a                	sd	s2,16(sp)
    800024b2:	e44e                	sd	s3,8(sp)
    800024b4:	e052                	sd	s4,0(sp)
    800024b6:	1800                	addi	s0,sp,48
    800024b8:	892a                	mv	s2,a0
    800024ba:	84ae                	mv	s1,a1
    800024bc:	89b2                	mv	s3,a2
    800024be:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	4f0080e7          	jalr	1264(ra) # 800019b0 <myproc>
  if(user_src){
    800024c8:	c08d                	beqz	s1,800024ea <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024ca:	86d2                	mv	a3,s4
    800024cc:	864e                	mv	a2,s3
    800024ce:	85ca                	mv	a1,s2
    800024d0:	6928                	ld	a0,80(a0)
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	22c080e7          	jalr	556(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024da:	70a2                	ld	ra,40(sp)
    800024dc:	7402                	ld	s0,32(sp)
    800024de:	64e2                	ld	s1,24(sp)
    800024e0:	6942                	ld	s2,16(sp)
    800024e2:	69a2                	ld	s3,8(sp)
    800024e4:	6a02                	ld	s4,0(sp)
    800024e6:	6145                	addi	sp,sp,48
    800024e8:	8082                	ret
    memmove(dst, (char*)src, len);
    800024ea:	000a061b          	sext.w	a2,s4
    800024ee:	85ce                	mv	a1,s3
    800024f0:	854a                	mv	a0,s2
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	84e080e7          	jalr	-1970(ra) # 80000d40 <memmove>
    return 0;
    800024fa:	8526                	mv	a0,s1
    800024fc:	bff9                	j	800024da <either_copyin+0x32>

00000000800024fe <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024fe:	715d                	addi	sp,sp,-80
    80002500:	e486                	sd	ra,72(sp)
    80002502:	e0a2                	sd	s0,64(sp)
    80002504:	fc26                	sd	s1,56(sp)
    80002506:	f84a                	sd	s2,48(sp)
    80002508:	f44e                	sd	s3,40(sp)
    8000250a:	f052                	sd	s4,32(sp)
    8000250c:	ec56                	sd	s5,24(sp)
    8000250e:	e85a                	sd	s6,16(sp)
    80002510:	e45e                	sd	s7,8(sp)
    80002512:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002514:	00006517          	auipc	a0,0x6
    80002518:	bb450513          	addi	a0,a0,-1100 # 800080c8 <digits+0x88>
    8000251c:	ffffe097          	auipc	ra,0xffffe
    80002520:	06c080e7          	jalr	108(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002524:	0000f497          	auipc	s1,0xf
    80002528:	30448493          	addi	s1,s1,772 # 80011828 <proc+0x158>
    8000252c:	00015917          	auipc	s2,0x15
    80002530:	0fc90913          	addi	s2,s2,252 # 80017628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002534:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002536:	00006997          	auipc	s3,0x6
    8000253a:	d4a98993          	addi	s3,s3,-694 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000253e:	00006a97          	auipc	s5,0x6
    80002542:	d4aa8a93          	addi	s5,s5,-694 # 80008288 <digits+0x248>
    printf("\n");
    80002546:	00006a17          	auipc	s4,0x6
    8000254a:	b82a0a13          	addi	s4,s4,-1150 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000254e:	00006b97          	auipc	s7,0x6
    80002552:	d72b8b93          	addi	s7,s7,-654 # 800082c0 <states.1718>
    80002556:	a00d                	j	80002578 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002558:	ed86a583          	lw	a1,-296(a3)
    8000255c:	8556                	mv	a0,s5
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	02a080e7          	jalr	42(ra) # 80000588 <printf>
    printf("\n");
    80002566:	8552                	mv	a0,s4
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	020080e7          	jalr	32(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002570:	17848493          	addi	s1,s1,376
    80002574:	03248163          	beq	s1,s2,80002596 <procdump+0x98>
    if(p->state == UNUSED)
    80002578:	86a6                	mv	a3,s1
    8000257a:	ec04a783          	lw	a5,-320(s1)
    8000257e:	dbed                	beqz	a5,80002570 <procdump+0x72>
      state = "???";
    80002580:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002582:	fcfb6be3          	bltu	s6,a5,80002558 <procdump+0x5a>
    80002586:	1782                	slli	a5,a5,0x20
    80002588:	9381                	srli	a5,a5,0x20
    8000258a:	078e                	slli	a5,a5,0x3
    8000258c:	97de                	add	a5,a5,s7
    8000258e:	6390                	ld	a2,0(a5)
    80002590:	f661                	bnez	a2,80002558 <procdump+0x5a>
      state = "???";
    80002592:	864e                	mv	a2,s3
    80002594:	b7d1                	j	80002558 <procdump+0x5a>
  }
}
    80002596:	60a6                	ld	ra,72(sp)
    80002598:	6406                	ld	s0,64(sp)
    8000259a:	74e2                	ld	s1,56(sp)
    8000259c:	7942                	ld	s2,48(sp)
    8000259e:	79a2                	ld	s3,40(sp)
    800025a0:	7a02                	ld	s4,32(sp)
    800025a2:	6ae2                	ld	s5,24(sp)
    800025a4:	6b42                	ld	s6,16(sp)
    800025a6:	6ba2                	ld	s7,8(sp)
    800025a8:	6161                	addi	sp,sp,80
    800025aa:	8082                	ret

00000000800025ac <waitx>:


int
waitx(uint64 addr, uint* rtime, uint* wtime)
{
    800025ac:	711d                	addi	sp,sp,-96
    800025ae:	ec86                	sd	ra,88(sp)
    800025b0:	e8a2                	sd	s0,80(sp)
    800025b2:	e4a6                	sd	s1,72(sp)
    800025b4:	e0ca                	sd	s2,64(sp)
    800025b6:	fc4e                	sd	s3,56(sp)
    800025b8:	f852                	sd	s4,48(sp)
    800025ba:	f456                	sd	s5,40(sp)
    800025bc:	f05a                	sd	s6,32(sp)
    800025be:	ec5e                	sd	s7,24(sp)
    800025c0:	e862                	sd	s8,16(sp)
    800025c2:	e466                	sd	s9,8(sp)
    800025c4:	e06a                	sd	s10,0(sp)
    800025c6:	1080                	addi	s0,sp,96
    800025c8:	8b2a                	mv	s6,a0
    800025ca:	8c2e                	mv	s8,a1
    800025cc:	8bb2                	mv	s7,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800025ce:	fffff097          	auipc	ra,0xfffff
    800025d2:	3e2080e7          	jalr	994(ra) # 800019b0 <myproc>
    800025d6:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800025d8:	0000f517          	auipc	a0,0xf
    800025dc:	ce050513          	addi	a0,a0,-800 # 800112b8 <wait_lock>
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	604080e7          	jalr	1540(ra) # 80000be4 <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    800025e8:	4c81                	li	s9,0
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
    800025ea:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800025ec:	00015997          	auipc	s3,0x15
    800025f0:	ee498993          	addi	s3,s3,-284 # 800174d0 <tickslock>
        havekids = 1;
    800025f4:	4a85                	li	s5,1
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025f6:	0000fd17          	auipc	s10,0xf
    800025fa:	cc2d0d13          	addi	s10,s10,-830 # 800112b8 <wait_lock>
    havekids = 0;
    800025fe:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    80002600:	0000f497          	auipc	s1,0xf
    80002604:	0d048493          	addi	s1,s1,208 # 800116d0 <proc>
    80002608:	a069                	j	80002692 <waitx+0xe6>
          pid = np->pid;
    8000260a:	0304a983          	lw	s3,48(s1)
          *rtime = np->runTime;
    8000260e:	1704a783          	lw	a5,368(s1)
    80002612:	00fc2023          	sw	a5,0(s8)
          *wtime = np->endTime - np->startTime - np->runTime;
    80002616:	16c4a783          	lw	a5,364(s1)
    8000261a:	1684a703          	lw	a4,360(s1)
    8000261e:	9f99                	subw	a5,a5,a4
    80002620:	1704a703          	lw	a4,368(s1)
    80002624:	9f99                	subw	a5,a5,a4
    80002626:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000262a:	000b0e63          	beqz	s6,80002646 <waitx+0x9a>
    8000262e:	4691                	li	a3,4
    80002630:	02c48613          	addi	a2,s1,44
    80002634:	85da                	mv	a1,s6
    80002636:	05093503          	ld	a0,80(s2)
    8000263a:	fffff097          	auipc	ra,0xfffff
    8000263e:	038080e7          	jalr	56(ra) # 80001672 <copyout>
    80002642:	02054563          	bltz	a0,8000266c <waitx+0xc0>
          freeproc(np);
    80002646:	8526                	mv	a0,s1
    80002648:	fffff097          	auipc	ra,0xfffff
    8000264c:	51a080e7          	jalr	1306(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002650:	8526                	mv	a0,s1
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	646080e7          	jalr	1606(ra) # 80000c98 <release>
          release(&wait_lock);
    8000265a:	0000f517          	auipc	a0,0xf
    8000265e:	c5e50513          	addi	a0,a0,-930 # 800112b8 <wait_lock>
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	636080e7          	jalr	1590(ra) # 80000c98 <release>
          return pid;
    8000266a:	a09d                	j	800026d0 <waitx+0x124>
            release(&np->lock);
    8000266c:	8526                	mv	a0,s1
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	62a080e7          	jalr	1578(ra) # 80000c98 <release>
            release(&wait_lock);
    80002676:	0000f517          	auipc	a0,0xf
    8000267a:	c4250513          	addi	a0,a0,-958 # 800112b8 <wait_lock>
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	61a080e7          	jalr	1562(ra) # 80000c98 <release>
            return -1;
    80002686:	59fd                	li	s3,-1
    80002688:	a0a1                	j	800026d0 <waitx+0x124>
    for(np = proc; np < &proc[NPROC]; np++){
    8000268a:	17848493          	addi	s1,s1,376
    8000268e:	03348463          	beq	s1,s3,800026b6 <waitx+0x10a>
      if(np->parent == p){
    80002692:	7c9c                	ld	a5,56(s1)
    80002694:	ff279be3          	bne	a5,s2,8000268a <waitx+0xde>
        acquire(&np->lock);
    80002698:	8526                	mv	a0,s1
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	54a080e7          	jalr	1354(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800026a2:	4c9c                	lw	a5,24(s1)
    800026a4:	f74783e3          	beq	a5,s4,8000260a <waitx+0x5e>
        release(&np->lock);
    800026a8:	8526                	mv	a0,s1
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	5ee080e7          	jalr	1518(ra) # 80000c98 <release>
        havekids = 1;
    800026b2:	8756                	mv	a4,s5
    800026b4:	bfd9                	j	8000268a <waitx+0xde>
    if(!havekids || p->killed){
    800026b6:	c701                	beqz	a4,800026be <waitx+0x112>
    800026b8:	02892783          	lw	a5,40(s2)
    800026bc:	cb8d                	beqz	a5,800026ee <waitx+0x142>
      release(&wait_lock);
    800026be:	0000f517          	auipc	a0,0xf
    800026c2:	bfa50513          	addi	a0,a0,-1030 # 800112b8 <wait_lock>
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	5d2080e7          	jalr	1490(ra) # 80000c98 <release>
      return -1;
    800026ce:	59fd                	li	s3,-1
  }
}
    800026d0:	854e                	mv	a0,s3
    800026d2:	60e6                	ld	ra,88(sp)
    800026d4:	6446                	ld	s0,80(sp)
    800026d6:	64a6                	ld	s1,72(sp)
    800026d8:	6906                	ld	s2,64(sp)
    800026da:	79e2                	ld	s3,56(sp)
    800026dc:	7a42                	ld	s4,48(sp)
    800026de:	7aa2                	ld	s5,40(sp)
    800026e0:	7b02                	ld	s6,32(sp)
    800026e2:	6be2                	ld	s7,24(sp)
    800026e4:	6c42                	ld	s8,16(sp)
    800026e6:	6ca2                	ld	s9,8(sp)
    800026e8:	6d02                	ld	s10,0(sp)
    800026ea:	6125                	addi	sp,sp,96
    800026ec:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026ee:	85ea                	mv	a1,s10
    800026f0:	854a                	mv	a0,s2
    800026f2:	00000097          	auipc	ra,0x0
    800026f6:	9a2080e7          	jalr	-1630(ra) # 80002094 <sleep>
    havekids = 0;
    800026fa:	b711                	j	800025fe <waitx+0x52>

00000000800026fc <increaseRuntime>:

// This function is executed after every CPU cycle with every ticks
// Iterates through each process & increases the run time of every running process.
void increaseRuntime() {
    800026fc:	7179                	addi	sp,sp,-48
    800026fe:	f406                	sd	ra,40(sp)
    80002700:	f022                	sd	s0,32(sp)
    80002702:	ec26                	sd	s1,24(sp)
    80002704:	e84a                	sd	s2,16(sp)
    80002706:	e44e                	sd	s3,8(sp)
    80002708:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p<&proc[NPROC]; p++) {
    8000270a:	0000f497          	auipc	s1,0xf
    8000270e:	fc648493          	addi	s1,s1,-58 # 800116d0 <proc>
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002712:	4991                	li	s3,4
  for (p = proc; p<&proc[NPROC]; p++) {
    80002714:	00015917          	auipc	s2,0x15
    80002718:	dbc90913          	addi	s2,s2,-580 # 800174d0 <tickslock>
    8000271c:	a811                	j	80002730 <increaseRuntime+0x34>
      p->runTime++;
    
    release(&p->lock);
    8000271e:	8526                	mv	a0,s1
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	578080e7          	jalr	1400(ra) # 80000c98 <release>
  for (p = proc; p<&proc[NPROC]; p++) {
    80002728:	17848493          	addi	s1,s1,376
    8000272c:	03248063          	beq	s1,s2,8000274c <increaseRuntime+0x50>
    acquire(&p->lock);
    80002730:	8526                	mv	a0,s1
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	4b2080e7          	jalr	1202(ra) # 80000be4 <acquire>
    if (p->state == RUNNING)
    8000273a:	4c9c                	lw	a5,24(s1)
    8000273c:	ff3791e3          	bne	a5,s3,8000271e <increaseRuntime+0x22>
      p->runTime++;
    80002740:	1704a783          	lw	a5,368(s1)
    80002744:	2785                	addiw	a5,a5,1
    80002746:	16f4a823          	sw	a5,368(s1)
    8000274a:	bfd1                	j	8000271e <increaseRuntime+0x22>
  }
}
    8000274c:	70a2                	ld	ra,40(sp)
    8000274e:	7402                	ld	s0,32(sp)
    80002750:	64e2                	ld	s1,24(sp)
    80002752:	6942                	ld	s2,16(sp)
    80002754:	69a2                	ld	s3,8(sp)
    80002756:	6145                	addi	sp,sp,48
    80002758:	8082                	ret

000000008000275a <swtch>:
    8000275a:	00153023          	sd	ra,0(a0)
    8000275e:	00253423          	sd	sp,8(a0)
    80002762:	e900                	sd	s0,16(a0)
    80002764:	ed04                	sd	s1,24(a0)
    80002766:	03253023          	sd	s2,32(a0)
    8000276a:	03353423          	sd	s3,40(a0)
    8000276e:	03453823          	sd	s4,48(a0)
    80002772:	03553c23          	sd	s5,56(a0)
    80002776:	05653023          	sd	s6,64(a0)
    8000277a:	05753423          	sd	s7,72(a0)
    8000277e:	05853823          	sd	s8,80(a0)
    80002782:	05953c23          	sd	s9,88(a0)
    80002786:	07a53023          	sd	s10,96(a0)
    8000278a:	07b53423          	sd	s11,104(a0)
    8000278e:	0005b083          	ld	ra,0(a1)
    80002792:	0085b103          	ld	sp,8(a1)
    80002796:	6980                	ld	s0,16(a1)
    80002798:	6d84                	ld	s1,24(a1)
    8000279a:	0205b903          	ld	s2,32(a1)
    8000279e:	0285b983          	ld	s3,40(a1)
    800027a2:	0305ba03          	ld	s4,48(a1)
    800027a6:	0385ba83          	ld	s5,56(a1)
    800027aa:	0405bb03          	ld	s6,64(a1)
    800027ae:	0485bb83          	ld	s7,72(a1)
    800027b2:	0505bc03          	ld	s8,80(a1)
    800027b6:	0585bc83          	ld	s9,88(a1)
    800027ba:	0605bd03          	ld	s10,96(a1)
    800027be:	0685bd83          	ld	s11,104(a1)
    800027c2:	8082                	ret

00000000800027c4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027c4:	1141                	addi	sp,sp,-16
    800027c6:	e406                	sd	ra,8(sp)
    800027c8:	e022                	sd	s0,0(sp)
    800027ca:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027cc:	00006597          	auipc	a1,0x6
    800027d0:	b2458593          	addi	a1,a1,-1244 # 800082f0 <states.1718+0x30>
    800027d4:	00015517          	auipc	a0,0x15
    800027d8:	cfc50513          	addi	a0,a0,-772 # 800174d0 <tickslock>
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	378080e7          	jalr	888(ra) # 80000b54 <initlock>
}
    800027e4:	60a2                	ld	ra,8(sp)
    800027e6:	6402                	ld	s0,0(sp)
    800027e8:	0141                	addi	sp,sp,16
    800027ea:	8082                	ret

00000000800027ec <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027ec:	1141                	addi	sp,sp,-16
    800027ee:	e422                	sd	s0,8(sp)
    800027f0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f2:	00003797          	auipc	a5,0x3
    800027f6:	53e78793          	addi	a5,a5,1342 # 80005d30 <kernelvec>
    800027fa:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027fe:	6422                	ld	s0,8(sp)
    80002800:	0141                	addi	sp,sp,16
    80002802:	8082                	ret

0000000080002804 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002804:	1141                	addi	sp,sp,-16
    80002806:	e406                	sd	ra,8(sp)
    80002808:	e022                	sd	s0,0(sp)
    8000280a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000280c:	fffff097          	auipc	ra,0xfffff
    80002810:	1a4080e7          	jalr	420(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002814:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002818:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000281a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000281e:	00004617          	auipc	a2,0x4
    80002822:	7e260613          	addi	a2,a2,2018 # 80007000 <_trampoline>
    80002826:	00004697          	auipc	a3,0x4
    8000282a:	7da68693          	addi	a3,a3,2010 # 80007000 <_trampoline>
    8000282e:	8e91                	sub	a3,a3,a2
    80002830:	040007b7          	lui	a5,0x4000
    80002834:	17fd                	addi	a5,a5,-1
    80002836:	07b2                	slli	a5,a5,0xc
    80002838:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000283a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000283e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002840:	180026f3          	csrr	a3,satp
    80002844:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002846:	6d38                	ld	a4,88(a0)
    80002848:	6134                	ld	a3,64(a0)
    8000284a:	6585                	lui	a1,0x1
    8000284c:	96ae                	add	a3,a3,a1
    8000284e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002850:	6d38                	ld	a4,88(a0)
    80002852:	00000697          	auipc	a3,0x0
    80002856:	14668693          	addi	a3,a3,326 # 80002998 <usertrap>
    8000285a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000285c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000285e:	8692                	mv	a3,tp
    80002860:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002862:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002866:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000286a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000286e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002872:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002874:	6f18                	ld	a4,24(a4)
    80002876:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000287a:	692c                	ld	a1,80(a0)
    8000287c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000287e:	00005717          	auipc	a4,0x5
    80002882:	81270713          	addi	a4,a4,-2030 # 80007090 <userret>
    80002886:	8f11                	sub	a4,a4,a2
    80002888:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000288a:	577d                	li	a4,-1
    8000288c:	177e                	slli	a4,a4,0x3f
    8000288e:	8dd9                	or	a1,a1,a4
    80002890:	02000537          	lui	a0,0x2000
    80002894:	157d                	addi	a0,a0,-1
    80002896:	0536                	slli	a0,a0,0xd
    80002898:	9782                	jalr	a5
}
    8000289a:	60a2                	ld	ra,8(sp)
    8000289c:	6402                	ld	s0,0(sp)
    8000289e:	0141                	addi	sp,sp,16
    800028a0:	8082                	ret

00000000800028a2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028a2:	1101                	addi	sp,sp,-32
    800028a4:	ec06                	sd	ra,24(sp)
    800028a6:	e822                	sd	s0,16(sp)
    800028a8:	e426                	sd	s1,8(sp)
    800028aa:	e04a                	sd	s2,0(sp)
    800028ac:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028ae:	00015917          	auipc	s2,0x15
    800028b2:	c2290913          	addi	s2,s2,-990 # 800174d0 <tickslock>
    800028b6:	854a                	mv	a0,s2
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	32c080e7          	jalr	812(ra) # 80000be4 <acquire>
  ticks++;
    800028c0:	00006497          	auipc	s1,0x6
    800028c4:	77048493          	addi	s1,s1,1904 # 80009030 <ticks>
    800028c8:	409c                	lw	a5,0(s1)
    800028ca:	2785                	addiw	a5,a5,1
    800028cc:	c09c                	sw	a5,0(s1)
  increaseRuntime();
    800028ce:	00000097          	auipc	ra,0x0
    800028d2:	e2e080e7          	jalr	-466(ra) # 800026fc <increaseRuntime>
  wakeup(&ticks);
    800028d6:	8526                	mv	a0,s1
    800028d8:	00000097          	auipc	ra,0x0
    800028dc:	948080e7          	jalr	-1720(ra) # 80002220 <wakeup>
  release(&tickslock);
    800028e0:	854a                	mv	a0,s2
    800028e2:	ffffe097          	auipc	ra,0xffffe
    800028e6:	3b6080e7          	jalr	950(ra) # 80000c98 <release>
}
    800028ea:	60e2                	ld	ra,24(sp)
    800028ec:	6442                	ld	s0,16(sp)
    800028ee:	64a2                	ld	s1,8(sp)
    800028f0:	6902                	ld	s2,0(sp)
    800028f2:	6105                	addi	sp,sp,32
    800028f4:	8082                	ret

00000000800028f6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028f6:	1101                	addi	sp,sp,-32
    800028f8:	ec06                	sd	ra,24(sp)
    800028fa:	e822                	sd	s0,16(sp)
    800028fc:	e426                	sd	s1,8(sp)
    800028fe:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002900:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002904:	00074d63          	bltz	a4,8000291e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002908:	57fd                	li	a5,-1
    8000290a:	17fe                	slli	a5,a5,0x3f
    8000290c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000290e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002910:	06f70363          	beq	a4,a5,80002976 <devintr+0x80>
  }
}
    80002914:	60e2                	ld	ra,24(sp)
    80002916:	6442                	ld	s0,16(sp)
    80002918:	64a2                	ld	s1,8(sp)
    8000291a:	6105                	addi	sp,sp,32
    8000291c:	8082                	ret
     (scause & 0xff) == 9){
    8000291e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002922:	46a5                	li	a3,9
    80002924:	fed792e3          	bne	a5,a3,80002908 <devintr+0x12>
    int irq = plic_claim();
    80002928:	00003097          	auipc	ra,0x3
    8000292c:	510080e7          	jalr	1296(ra) # 80005e38 <plic_claim>
    80002930:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002932:	47a9                	li	a5,10
    80002934:	02f50763          	beq	a0,a5,80002962 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002938:	4785                	li	a5,1
    8000293a:	02f50963          	beq	a0,a5,8000296c <devintr+0x76>
    return 1;
    8000293e:	4505                	li	a0,1
    } else if(irq){
    80002940:	d8f1                	beqz	s1,80002914 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002942:	85a6                	mv	a1,s1
    80002944:	00006517          	auipc	a0,0x6
    80002948:	9b450513          	addi	a0,a0,-1612 # 800082f8 <states.1718+0x38>
    8000294c:	ffffe097          	auipc	ra,0xffffe
    80002950:	c3c080e7          	jalr	-964(ra) # 80000588 <printf>
      plic_complete(irq);
    80002954:	8526                	mv	a0,s1
    80002956:	00003097          	auipc	ra,0x3
    8000295a:	506080e7          	jalr	1286(ra) # 80005e5c <plic_complete>
    return 1;
    8000295e:	4505                	li	a0,1
    80002960:	bf55                	j	80002914 <devintr+0x1e>
      uartintr();
    80002962:	ffffe097          	auipc	ra,0xffffe
    80002966:	046080e7          	jalr	70(ra) # 800009a8 <uartintr>
    8000296a:	b7ed                	j	80002954 <devintr+0x5e>
      virtio_disk_intr();
    8000296c:	00004097          	auipc	ra,0x4
    80002970:	9d0080e7          	jalr	-1584(ra) # 8000633c <virtio_disk_intr>
    80002974:	b7c5                	j	80002954 <devintr+0x5e>
    if(cpuid() == 0){
    80002976:	fffff097          	auipc	ra,0xfffff
    8000297a:	00e080e7          	jalr	14(ra) # 80001984 <cpuid>
    8000297e:	c901                	beqz	a0,8000298e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002980:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002984:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002986:	14479073          	csrw	sip,a5
    return 2;
    8000298a:	4509                	li	a0,2
    8000298c:	b761                	j	80002914 <devintr+0x1e>
      clockintr();
    8000298e:	00000097          	auipc	ra,0x0
    80002992:	f14080e7          	jalr	-236(ra) # 800028a2 <clockintr>
    80002996:	b7ed                	j	80002980 <devintr+0x8a>

0000000080002998 <usertrap>:
{
    80002998:	1101                	addi	sp,sp,-32
    8000299a:	ec06                	sd	ra,24(sp)
    8000299c:	e822                	sd	s0,16(sp)
    8000299e:	e426                	sd	s1,8(sp)
    800029a0:	e04a                	sd	s2,0(sp)
    800029a2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029a8:	1007f793          	andi	a5,a5,256
    800029ac:	e3ad                	bnez	a5,80002a0e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ae:	00003797          	auipc	a5,0x3
    800029b2:	38278793          	addi	a5,a5,898 # 80005d30 <kernelvec>
    800029b6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029ba:	fffff097          	auipc	ra,0xfffff
    800029be:	ff6080e7          	jalr	-10(ra) # 800019b0 <myproc>
    800029c2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029c4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c6:	14102773          	csrr	a4,sepc
    800029ca:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029cc:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029d0:	47a1                	li	a5,8
    800029d2:	04f71c63          	bne	a4,a5,80002a2a <usertrap+0x92>
    if(p->killed)
    800029d6:	551c                	lw	a5,40(a0)
    800029d8:	e3b9                	bnez	a5,80002a1e <usertrap+0x86>
    p->trapframe->epc += 4;
    800029da:	6cb8                	ld	a4,88(s1)
    800029dc:	6f1c                	ld	a5,24(a4)
    800029de:	0791                	addi	a5,a5,4
    800029e0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029e6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ea:	10079073          	csrw	sstatus,a5
    syscall();
    800029ee:	00000097          	auipc	ra,0x0
    800029f2:	2e0080e7          	jalr	736(ra) # 80002cce <syscall>
  if(p->killed)
    800029f6:	549c                	lw	a5,40(s1)
    800029f8:	ebc1                	bnez	a5,80002a88 <usertrap+0xf0>
  usertrapret();
    800029fa:	00000097          	auipc	ra,0x0
    800029fe:	e0a080e7          	jalr	-502(ra) # 80002804 <usertrapret>
}
    80002a02:	60e2                	ld	ra,24(sp)
    80002a04:	6442                	ld	s0,16(sp)
    80002a06:	64a2                	ld	s1,8(sp)
    80002a08:	6902                	ld	s2,0(sp)
    80002a0a:	6105                	addi	sp,sp,32
    80002a0c:	8082                	ret
    panic("usertrap: not from user mode");
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	90a50513          	addi	a0,a0,-1782 # 80008318 <states.1718+0x58>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b28080e7          	jalr	-1240(ra) # 8000053e <panic>
      exit(-1);
    80002a1e:	557d                	li	a0,-1
    80002a20:	00000097          	auipc	ra,0x0
    80002a24:	8d0080e7          	jalr	-1840(ra) # 800022f0 <exit>
    80002a28:	bf4d                	j	800029da <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a2a:	00000097          	auipc	ra,0x0
    80002a2e:	ecc080e7          	jalr	-308(ra) # 800028f6 <devintr>
    80002a32:	892a                	mv	s2,a0
    80002a34:	c501                	beqz	a0,80002a3c <usertrap+0xa4>
  if(p->killed)
    80002a36:	549c                	lw	a5,40(s1)
    80002a38:	c3a1                	beqz	a5,80002a78 <usertrap+0xe0>
    80002a3a:	a815                	j	80002a6e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a3c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a40:	5890                	lw	a2,48(s1)
    80002a42:	00006517          	auipc	a0,0x6
    80002a46:	8f650513          	addi	a0,a0,-1802 # 80008338 <states.1718+0x78>
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	b3e080e7          	jalr	-1218(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a52:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a56:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a5a:	00006517          	auipc	a0,0x6
    80002a5e:	90e50513          	addi	a0,a0,-1778 # 80008368 <states.1718+0xa8>
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	b26080e7          	jalr	-1242(ra) # 80000588 <printf>
    p->killed = 1;
    80002a6a:	4785                	li	a5,1
    80002a6c:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a6e:	557d                	li	a0,-1
    80002a70:	00000097          	auipc	ra,0x0
    80002a74:	880080e7          	jalr	-1920(ra) # 800022f0 <exit>
  if(which_dev == 2)
    80002a78:	4789                	li	a5,2
    80002a7a:	f8f910e3          	bne	s2,a5,800029fa <usertrap+0x62>
    yield();
    80002a7e:	fffff097          	auipc	ra,0xfffff
    80002a82:	5da080e7          	jalr	1498(ra) # 80002058 <yield>
    80002a86:	bf95                	j	800029fa <usertrap+0x62>
  int which_dev = 0;
    80002a88:	4901                	li	s2,0
    80002a8a:	b7d5                	j	80002a6e <usertrap+0xd6>

0000000080002a8c <kerneltrap>:
{
    80002a8c:	7179                	addi	sp,sp,-48
    80002a8e:	f406                	sd	ra,40(sp)
    80002a90:	f022                	sd	s0,32(sp)
    80002a92:	ec26                	sd	s1,24(sp)
    80002a94:	e84a                	sd	s2,16(sp)
    80002a96:	e44e                	sd	s3,8(sp)
    80002a98:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a9a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a9e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002aa6:	1004f793          	andi	a5,s1,256
    80002aaa:	cb85                	beqz	a5,80002ada <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ab0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ab2:	ef85                	bnez	a5,80002aea <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ab4:	00000097          	auipc	ra,0x0
    80002ab8:	e42080e7          	jalr	-446(ra) # 800028f6 <devintr>
    80002abc:	cd1d                	beqz	a0,80002afa <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002abe:	4789                	li	a5,2
    80002ac0:	06f50a63          	beq	a0,a5,80002b34 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ac4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ac8:	10049073          	csrw	sstatus,s1
}
    80002acc:	70a2                	ld	ra,40(sp)
    80002ace:	7402                	ld	s0,32(sp)
    80002ad0:	64e2                	ld	s1,24(sp)
    80002ad2:	6942                	ld	s2,16(sp)
    80002ad4:	69a2                	ld	s3,8(sp)
    80002ad6:	6145                	addi	sp,sp,48
    80002ad8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ada:	00006517          	auipc	a0,0x6
    80002ade:	8ae50513          	addi	a0,a0,-1874 # 80008388 <states.1718+0xc8>
    80002ae2:	ffffe097          	auipc	ra,0xffffe
    80002ae6:	a5c080e7          	jalr	-1444(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002aea:	00006517          	auipc	a0,0x6
    80002aee:	8c650513          	addi	a0,a0,-1850 # 800083b0 <states.1718+0xf0>
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	a4c080e7          	jalr	-1460(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002afa:	85ce                	mv	a1,s3
    80002afc:	00006517          	auipc	a0,0x6
    80002b00:	8d450513          	addi	a0,a0,-1836 # 800083d0 <states.1718+0x110>
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	a84080e7          	jalr	-1404(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b0c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b10:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b14:	00006517          	auipc	a0,0x6
    80002b18:	8cc50513          	addi	a0,a0,-1844 # 800083e0 <states.1718+0x120>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a6c080e7          	jalr	-1428(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b24:	00006517          	auipc	a0,0x6
    80002b28:	8d450513          	addi	a0,a0,-1836 # 800083f8 <states.1718+0x138>
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	a12080e7          	jalr	-1518(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	e7c080e7          	jalr	-388(ra) # 800019b0 <myproc>
    80002b3c:	d541                	beqz	a0,80002ac4 <kerneltrap+0x38>
    80002b3e:	fffff097          	auipc	ra,0xfffff
    80002b42:	e72080e7          	jalr	-398(ra) # 800019b0 <myproc>
    80002b46:	4d18                	lw	a4,24(a0)
    80002b48:	4791                	li	a5,4
    80002b4a:	f6f71de3          	bne	a4,a5,80002ac4 <kerneltrap+0x38>
    yield();
    80002b4e:	fffff097          	auipc	ra,0xfffff
    80002b52:	50a080e7          	jalr	1290(ra) # 80002058 <yield>
    80002b56:	b7bd                	j	80002ac4 <kerneltrap+0x38>

0000000080002b58 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b58:	1101                	addi	sp,sp,-32
    80002b5a:	ec06                	sd	ra,24(sp)
    80002b5c:	e822                	sd	s0,16(sp)
    80002b5e:	e426                	sd	s1,8(sp)
    80002b60:	1000                	addi	s0,sp,32
    80002b62:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b64:	fffff097          	auipc	ra,0xfffff
    80002b68:	e4c080e7          	jalr	-436(ra) # 800019b0 <myproc>
  switch (n) {
    80002b6c:	4795                	li	a5,5
    80002b6e:	0497e163          	bltu	a5,s1,80002bb0 <argraw+0x58>
    80002b72:	048a                	slli	s1,s1,0x2
    80002b74:	00006717          	auipc	a4,0x6
    80002b78:	8bc70713          	addi	a4,a4,-1860 # 80008430 <states.1718+0x170>
    80002b7c:	94ba                	add	s1,s1,a4
    80002b7e:	409c                	lw	a5,0(s1)
    80002b80:	97ba                	add	a5,a5,a4
    80002b82:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b84:	6d3c                	ld	a5,88(a0)
    80002b86:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b88:	60e2                	ld	ra,24(sp)
    80002b8a:	6442                	ld	s0,16(sp)
    80002b8c:	64a2                	ld	s1,8(sp)
    80002b8e:	6105                	addi	sp,sp,32
    80002b90:	8082                	ret
    return p->trapframe->a1;
    80002b92:	6d3c                	ld	a5,88(a0)
    80002b94:	7fa8                	ld	a0,120(a5)
    80002b96:	bfcd                	j	80002b88 <argraw+0x30>
    return p->trapframe->a2;
    80002b98:	6d3c                	ld	a5,88(a0)
    80002b9a:	63c8                	ld	a0,128(a5)
    80002b9c:	b7f5                	j	80002b88 <argraw+0x30>
    return p->trapframe->a3;
    80002b9e:	6d3c                	ld	a5,88(a0)
    80002ba0:	67c8                	ld	a0,136(a5)
    80002ba2:	b7dd                	j	80002b88 <argraw+0x30>
    return p->trapframe->a4;
    80002ba4:	6d3c                	ld	a5,88(a0)
    80002ba6:	6bc8                	ld	a0,144(a5)
    80002ba8:	b7c5                	j	80002b88 <argraw+0x30>
    return p->trapframe->a5;
    80002baa:	6d3c                	ld	a5,88(a0)
    80002bac:	6fc8                	ld	a0,152(a5)
    80002bae:	bfe9                	j	80002b88 <argraw+0x30>
  panic("argraw");
    80002bb0:	00006517          	auipc	a0,0x6
    80002bb4:	85850513          	addi	a0,a0,-1960 # 80008408 <states.1718+0x148>
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	986080e7          	jalr	-1658(ra) # 8000053e <panic>

0000000080002bc0 <fetchaddr>:
{
    80002bc0:	1101                	addi	sp,sp,-32
    80002bc2:	ec06                	sd	ra,24(sp)
    80002bc4:	e822                	sd	s0,16(sp)
    80002bc6:	e426                	sd	s1,8(sp)
    80002bc8:	e04a                	sd	s2,0(sp)
    80002bca:	1000                	addi	s0,sp,32
    80002bcc:	84aa                	mv	s1,a0
    80002bce:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bd0:	fffff097          	auipc	ra,0xfffff
    80002bd4:	de0080e7          	jalr	-544(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bd8:	653c                	ld	a5,72(a0)
    80002bda:	02f4f863          	bgeu	s1,a5,80002c0a <fetchaddr+0x4a>
    80002bde:	00848713          	addi	a4,s1,8
    80002be2:	02e7e663          	bltu	a5,a4,80002c0e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002be6:	46a1                	li	a3,8
    80002be8:	8626                	mv	a2,s1
    80002bea:	85ca                	mv	a1,s2
    80002bec:	6928                	ld	a0,80(a0)
    80002bee:	fffff097          	auipc	ra,0xfffff
    80002bf2:	b10080e7          	jalr	-1264(ra) # 800016fe <copyin>
    80002bf6:	00a03533          	snez	a0,a0
    80002bfa:	40a00533          	neg	a0,a0
}
    80002bfe:	60e2                	ld	ra,24(sp)
    80002c00:	6442                	ld	s0,16(sp)
    80002c02:	64a2                	ld	s1,8(sp)
    80002c04:	6902                	ld	s2,0(sp)
    80002c06:	6105                	addi	sp,sp,32
    80002c08:	8082                	ret
    return -1;
    80002c0a:	557d                	li	a0,-1
    80002c0c:	bfcd                	j	80002bfe <fetchaddr+0x3e>
    80002c0e:	557d                	li	a0,-1
    80002c10:	b7fd                	j	80002bfe <fetchaddr+0x3e>

0000000080002c12 <fetchstr>:
{
    80002c12:	7179                	addi	sp,sp,-48
    80002c14:	f406                	sd	ra,40(sp)
    80002c16:	f022                	sd	s0,32(sp)
    80002c18:	ec26                	sd	s1,24(sp)
    80002c1a:	e84a                	sd	s2,16(sp)
    80002c1c:	e44e                	sd	s3,8(sp)
    80002c1e:	1800                	addi	s0,sp,48
    80002c20:	892a                	mv	s2,a0
    80002c22:	84ae                	mv	s1,a1
    80002c24:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	d8a080e7          	jalr	-630(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c2e:	86ce                	mv	a3,s3
    80002c30:	864a                	mv	a2,s2
    80002c32:	85a6                	mv	a1,s1
    80002c34:	6928                	ld	a0,80(a0)
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	b54080e7          	jalr	-1196(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002c3e:	00054763          	bltz	a0,80002c4c <fetchstr+0x3a>
  return strlen(buf);
    80002c42:	8526                	mv	a0,s1
    80002c44:	ffffe097          	auipc	ra,0xffffe
    80002c48:	220080e7          	jalr	544(ra) # 80000e64 <strlen>
}
    80002c4c:	70a2                	ld	ra,40(sp)
    80002c4e:	7402                	ld	s0,32(sp)
    80002c50:	64e2                	ld	s1,24(sp)
    80002c52:	6942                	ld	s2,16(sp)
    80002c54:	69a2                	ld	s3,8(sp)
    80002c56:	6145                	addi	sp,sp,48
    80002c58:	8082                	ret

0000000080002c5a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c5a:	1101                	addi	sp,sp,-32
    80002c5c:	ec06                	sd	ra,24(sp)
    80002c5e:	e822                	sd	s0,16(sp)
    80002c60:	e426                	sd	s1,8(sp)
    80002c62:	1000                	addi	s0,sp,32
    80002c64:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c66:	00000097          	auipc	ra,0x0
    80002c6a:	ef2080e7          	jalr	-270(ra) # 80002b58 <argraw>
    80002c6e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c70:	4501                	li	a0,0
    80002c72:	60e2                	ld	ra,24(sp)
    80002c74:	6442                	ld	s0,16(sp)
    80002c76:	64a2                	ld	s1,8(sp)
    80002c78:	6105                	addi	sp,sp,32
    80002c7a:	8082                	ret

0000000080002c7c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c7c:	1101                	addi	sp,sp,-32
    80002c7e:	ec06                	sd	ra,24(sp)
    80002c80:	e822                	sd	s0,16(sp)
    80002c82:	e426                	sd	s1,8(sp)
    80002c84:	1000                	addi	s0,sp,32
    80002c86:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c88:	00000097          	auipc	ra,0x0
    80002c8c:	ed0080e7          	jalr	-304(ra) # 80002b58 <argraw>
    80002c90:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c92:	4501                	li	a0,0
    80002c94:	60e2                	ld	ra,24(sp)
    80002c96:	6442                	ld	s0,16(sp)
    80002c98:	64a2                	ld	s1,8(sp)
    80002c9a:	6105                	addi	sp,sp,32
    80002c9c:	8082                	ret

0000000080002c9e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c9e:	1101                	addi	sp,sp,-32
    80002ca0:	ec06                	sd	ra,24(sp)
    80002ca2:	e822                	sd	s0,16(sp)
    80002ca4:	e426                	sd	s1,8(sp)
    80002ca6:	e04a                	sd	s2,0(sp)
    80002ca8:	1000                	addi	s0,sp,32
    80002caa:	84ae                	mv	s1,a1
    80002cac:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cae:	00000097          	auipc	ra,0x0
    80002cb2:	eaa080e7          	jalr	-342(ra) # 80002b58 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cb6:	864a                	mv	a2,s2
    80002cb8:	85a6                	mv	a1,s1
    80002cba:	00000097          	auipc	ra,0x0
    80002cbe:	f58080e7          	jalr	-168(ra) # 80002c12 <fetchstr>
}
    80002cc2:	60e2                	ld	ra,24(sp)
    80002cc4:	6442                	ld	s0,16(sp)
    80002cc6:	64a2                	ld	s1,8(sp)
    80002cc8:	6902                	ld	s2,0(sp)
    80002cca:	6105                	addi	sp,sp,32
    80002ccc:	8082                	ret

0000000080002cce <syscall>:
[SYS_waitx]   sys_waitx,
};

void
syscall(void)
{
    80002cce:	1101                	addi	sp,sp,-32
    80002cd0:	ec06                	sd	ra,24(sp)
    80002cd2:	e822                	sd	s0,16(sp)
    80002cd4:	e426                	sd	s1,8(sp)
    80002cd6:	e04a                	sd	s2,0(sp)
    80002cd8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cda:	fffff097          	auipc	ra,0xfffff
    80002cde:	cd6080e7          	jalr	-810(ra) # 800019b0 <myproc>
    80002ce2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ce4:	05853903          	ld	s2,88(a0)
    80002ce8:	0a893783          	ld	a5,168(s2)
    80002cec:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cf0:	37fd                	addiw	a5,a5,-1
    80002cf2:	4755                	li	a4,21
    80002cf4:	00f76f63          	bltu	a4,a5,80002d12 <syscall+0x44>
    80002cf8:	00369713          	slli	a4,a3,0x3
    80002cfc:	00005797          	auipc	a5,0x5
    80002d00:	74c78793          	addi	a5,a5,1868 # 80008448 <syscalls>
    80002d04:	97ba                	add	a5,a5,a4
    80002d06:	639c                	ld	a5,0(a5)
    80002d08:	c789                	beqz	a5,80002d12 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d0a:	9782                	jalr	a5
    80002d0c:	06a93823          	sd	a0,112(s2)
    80002d10:	a839                	j	80002d2e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d12:	15848613          	addi	a2,s1,344
    80002d16:	588c                	lw	a1,48(s1)
    80002d18:	00005517          	auipc	a0,0x5
    80002d1c:	6f850513          	addi	a0,a0,1784 # 80008410 <states.1718+0x150>
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	868080e7          	jalr	-1944(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d28:	6cbc                	ld	a5,88(s1)
    80002d2a:	577d                	li	a4,-1
    80002d2c:	fbb8                	sd	a4,112(a5)
  }
}
    80002d2e:	60e2                	ld	ra,24(sp)
    80002d30:	6442                	ld	s0,16(sp)
    80002d32:	64a2                	ld	s1,8(sp)
    80002d34:	6902                	ld	s2,0(sp)
    80002d36:	6105                	addi	sp,sp,32
    80002d38:	8082                	ret

0000000080002d3a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d3a:	1101                	addi	sp,sp,-32
    80002d3c:	ec06                	sd	ra,24(sp)
    80002d3e:	e822                	sd	s0,16(sp)
    80002d40:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d42:	fec40593          	addi	a1,s0,-20
    80002d46:	4501                	li	a0,0
    80002d48:	00000097          	auipc	ra,0x0
    80002d4c:	f12080e7          	jalr	-238(ra) # 80002c5a <argint>
    return -1;
    80002d50:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d52:	00054963          	bltz	a0,80002d64 <sys_exit+0x2a>
  exit(n);
    80002d56:	fec42503          	lw	a0,-20(s0)
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	596080e7          	jalr	1430(ra) # 800022f0 <exit>
  return 0;  // not reached
    80002d62:	4781                	li	a5,0
}
    80002d64:	853e                	mv	a0,a5
    80002d66:	60e2                	ld	ra,24(sp)
    80002d68:	6442                	ld	s0,16(sp)
    80002d6a:	6105                	addi	sp,sp,32
    80002d6c:	8082                	ret

0000000080002d6e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d6e:	1141                	addi	sp,sp,-16
    80002d70:	e406                	sd	ra,8(sp)
    80002d72:	e022                	sd	s0,0(sp)
    80002d74:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	c3a080e7          	jalr	-966(ra) # 800019b0 <myproc>
}
    80002d7e:	5908                	lw	a0,48(a0)
    80002d80:	60a2                	ld	ra,8(sp)
    80002d82:	6402                	ld	s0,0(sp)
    80002d84:	0141                	addi	sp,sp,16
    80002d86:	8082                	ret

0000000080002d88 <sys_fork>:

uint64
sys_fork(void)
{
    80002d88:	1141                	addi	sp,sp,-16
    80002d8a:	e406                	sd	ra,8(sp)
    80002d8c:	e022                	sd	s0,0(sp)
    80002d8e:	0800                	addi	s0,sp,16
  return fork();
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	016080e7          	jalr	22(ra) # 80001da6 <fork>
}
    80002d98:	60a2                	ld	ra,8(sp)
    80002d9a:	6402                	ld	s0,0(sp)
    80002d9c:	0141                	addi	sp,sp,16
    80002d9e:	8082                	ret

0000000080002da0 <sys_wait>:

uint64
sys_wait(void)
{
    80002da0:	1101                	addi	sp,sp,-32
    80002da2:	ec06                	sd	ra,24(sp)
    80002da4:	e822                	sd	s0,16(sp)
    80002da6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002da8:	fe840593          	addi	a1,s0,-24
    80002dac:	4501                	li	a0,0
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	ece080e7          	jalr	-306(ra) # 80002c7c <argaddr>
    80002db6:	87aa                	mv	a5,a0
    return -1;
    80002db8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002dba:	0007c863          	bltz	a5,80002dca <sys_wait+0x2a>
  return wait(p);
    80002dbe:	fe843503          	ld	a0,-24(s0)
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	336080e7          	jalr	822(ra) # 800020f8 <wait>
}
    80002dca:	60e2                	ld	ra,24(sp)
    80002dcc:	6442                	ld	s0,16(sp)
    80002dce:	6105                	addi	sp,sp,32
    80002dd0:	8082                	ret

0000000080002dd2 <sys_waitx>:

uint64
sys_waitx(void)
{
    80002dd2:	7139                	addi	sp,sp,-64
    80002dd4:	fc06                	sd	ra,56(sp)
    80002dd6:	f822                	sd	s0,48(sp)
    80002dd8:	f426                	sd	s1,40(sp)
    80002dda:	f04a                	sd	s2,32(sp)
    80002ddc:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    80002dde:	fd840593          	addi	a1,s0,-40
    80002de2:	4501                	li	a0,0
    80002de4:	00000097          	auipc	ra,0x0
    80002de8:	e98080e7          	jalr	-360(ra) # 80002c7c <argaddr>
    return -1;
    80002dec:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    80002dee:	08054063          	bltz	a0,80002e6e <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80002df2:	fd040593          	addi	a1,s0,-48
    80002df6:	4505                	li	a0,1
    80002df8:	00000097          	auipc	ra,0x0
    80002dfc:	e84080e7          	jalr	-380(ra) # 80002c7c <argaddr>
    return -1;
    80002e00:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80002e02:	06054663          	bltz	a0,80002e6e <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    80002e06:	fc840593          	addi	a1,s0,-56
    80002e0a:	4509                	li	a0,2
    80002e0c:	00000097          	auipc	ra,0x0
    80002e10:	e70080e7          	jalr	-400(ra) # 80002c7c <argaddr>
    return -1;
    80002e14:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    80002e16:	04054c63          	bltz	a0,80002e6e <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    80002e1a:	fc040613          	addi	a2,s0,-64
    80002e1e:	fc440593          	addi	a1,s0,-60
    80002e22:	fd843503          	ld	a0,-40(s0)
    80002e26:	fffff097          	auipc	ra,0xfffff
    80002e2a:	786080e7          	jalr	1926(ra) # 800025ac <waitx>
    80002e2e:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80002e30:	fffff097          	auipc	ra,0xfffff
    80002e34:	b80080e7          	jalr	-1152(ra) # 800019b0 <myproc>
    80002e38:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002e3a:	4691                	li	a3,4
    80002e3c:	fc440613          	addi	a2,s0,-60
    80002e40:	fd043583          	ld	a1,-48(s0)
    80002e44:	6928                	ld	a0,80(a0)
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	82c080e7          	jalr	-2004(ra) # 80001672 <copyout>
    return -1;
    80002e4e:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002e50:	00054f63          	bltz	a0,80002e6e <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80002e54:	4691                	li	a3,4
    80002e56:	fc040613          	addi	a2,s0,-64
    80002e5a:	fc843583          	ld	a1,-56(s0)
    80002e5e:	68a8                	ld	a0,80(s1)
    80002e60:	fffff097          	auipc	ra,0xfffff
    80002e64:	812080e7          	jalr	-2030(ra) # 80001672 <copyout>
    80002e68:	00054a63          	bltz	a0,80002e7c <sys_waitx+0xaa>
    return -1;
  return ret;
    80002e6c:	87ca                	mv	a5,s2
}
    80002e6e:	853e                	mv	a0,a5
    80002e70:	70e2                	ld	ra,56(sp)
    80002e72:	7442                	ld	s0,48(sp)
    80002e74:	74a2                	ld	s1,40(sp)
    80002e76:	7902                	ld	s2,32(sp)
    80002e78:	6121                	addi	sp,sp,64
    80002e7a:	8082                	ret
    return -1;
    80002e7c:	57fd                	li	a5,-1
    80002e7e:	bfc5                	j	80002e6e <sys_waitx+0x9c>

0000000080002e80 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e80:	7179                	addi	sp,sp,-48
    80002e82:	f406                	sd	ra,40(sp)
    80002e84:	f022                	sd	s0,32(sp)
    80002e86:	ec26                	sd	s1,24(sp)
    80002e88:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e8a:	fdc40593          	addi	a1,s0,-36
    80002e8e:	4501                	li	a0,0
    80002e90:	00000097          	auipc	ra,0x0
    80002e94:	dca080e7          	jalr	-566(ra) # 80002c5a <argint>
    80002e98:	87aa                	mv	a5,a0
    return -1;
    80002e9a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e9c:	0207c063          	bltz	a5,80002ebc <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002ea0:	fffff097          	auipc	ra,0xfffff
    80002ea4:	b10080e7          	jalr	-1264(ra) # 800019b0 <myproc>
    80002ea8:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002eaa:	fdc42503          	lw	a0,-36(s0)
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	e84080e7          	jalr	-380(ra) # 80001d32 <growproc>
    80002eb6:	00054863          	bltz	a0,80002ec6 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002eba:	8526                	mv	a0,s1
}
    80002ebc:	70a2                	ld	ra,40(sp)
    80002ebe:	7402                	ld	s0,32(sp)
    80002ec0:	64e2                	ld	s1,24(sp)
    80002ec2:	6145                	addi	sp,sp,48
    80002ec4:	8082                	ret
    return -1;
    80002ec6:	557d                	li	a0,-1
    80002ec8:	bfd5                	j	80002ebc <sys_sbrk+0x3c>

0000000080002eca <sys_sleep>:

uint64
sys_sleep(void)
{
    80002eca:	7139                	addi	sp,sp,-64
    80002ecc:	fc06                	sd	ra,56(sp)
    80002ece:	f822                	sd	s0,48(sp)
    80002ed0:	f426                	sd	s1,40(sp)
    80002ed2:	f04a                	sd	s2,32(sp)
    80002ed4:	ec4e                	sd	s3,24(sp)
    80002ed6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ed8:	fcc40593          	addi	a1,s0,-52
    80002edc:	4501                	li	a0,0
    80002ede:	00000097          	auipc	ra,0x0
    80002ee2:	d7c080e7          	jalr	-644(ra) # 80002c5a <argint>
    return -1;
    80002ee6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ee8:	06054563          	bltz	a0,80002f52 <sys_sleep+0x88>
  acquire(&tickslock);
    80002eec:	00014517          	auipc	a0,0x14
    80002ef0:	5e450513          	addi	a0,a0,1508 # 800174d0 <tickslock>
    80002ef4:	ffffe097          	auipc	ra,0xffffe
    80002ef8:	cf0080e7          	jalr	-784(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002efc:	00006917          	auipc	s2,0x6
    80002f00:	13492903          	lw	s2,308(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002f04:	fcc42783          	lw	a5,-52(s0)
    80002f08:	cf85                	beqz	a5,80002f40 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f0a:	00014997          	auipc	s3,0x14
    80002f0e:	5c698993          	addi	s3,s3,1478 # 800174d0 <tickslock>
    80002f12:	00006497          	auipc	s1,0x6
    80002f16:	11e48493          	addi	s1,s1,286 # 80009030 <ticks>
    if(myproc()->killed){
    80002f1a:	fffff097          	auipc	ra,0xfffff
    80002f1e:	a96080e7          	jalr	-1386(ra) # 800019b0 <myproc>
    80002f22:	551c                	lw	a5,40(a0)
    80002f24:	ef9d                	bnez	a5,80002f62 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f26:	85ce                	mv	a1,s3
    80002f28:	8526                	mv	a0,s1
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	16a080e7          	jalr	362(ra) # 80002094 <sleep>
  while(ticks - ticks0 < n){
    80002f32:	409c                	lw	a5,0(s1)
    80002f34:	412787bb          	subw	a5,a5,s2
    80002f38:	fcc42703          	lw	a4,-52(s0)
    80002f3c:	fce7efe3          	bltu	a5,a4,80002f1a <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f40:	00014517          	auipc	a0,0x14
    80002f44:	59050513          	addi	a0,a0,1424 # 800174d0 <tickslock>
    80002f48:	ffffe097          	auipc	ra,0xffffe
    80002f4c:	d50080e7          	jalr	-688(ra) # 80000c98 <release>
  return 0;
    80002f50:	4781                	li	a5,0
}
    80002f52:	853e                	mv	a0,a5
    80002f54:	70e2                	ld	ra,56(sp)
    80002f56:	7442                	ld	s0,48(sp)
    80002f58:	74a2                	ld	s1,40(sp)
    80002f5a:	7902                	ld	s2,32(sp)
    80002f5c:	69e2                	ld	s3,24(sp)
    80002f5e:	6121                	addi	sp,sp,64
    80002f60:	8082                	ret
      release(&tickslock);
    80002f62:	00014517          	auipc	a0,0x14
    80002f66:	56e50513          	addi	a0,a0,1390 # 800174d0 <tickslock>
    80002f6a:	ffffe097          	auipc	ra,0xffffe
    80002f6e:	d2e080e7          	jalr	-722(ra) # 80000c98 <release>
      return -1;
    80002f72:	57fd                	li	a5,-1
    80002f74:	bff9                	j	80002f52 <sys_sleep+0x88>

0000000080002f76 <sys_kill>:

uint64
sys_kill(void)
{
    80002f76:	1101                	addi	sp,sp,-32
    80002f78:	ec06                	sd	ra,24(sp)
    80002f7a:	e822                	sd	s0,16(sp)
    80002f7c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f7e:	fec40593          	addi	a1,s0,-20
    80002f82:	4501                	li	a0,0
    80002f84:	00000097          	auipc	ra,0x0
    80002f88:	cd6080e7          	jalr	-810(ra) # 80002c5a <argint>
    80002f8c:	87aa                	mv	a5,a0
    return -1;
    80002f8e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f90:	0007c863          	bltz	a5,80002fa0 <sys_kill+0x2a>
  return kill(pid);
    80002f94:	fec42503          	lw	a0,-20(s0)
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	448080e7          	jalr	1096(ra) # 800023e0 <kill>
}
    80002fa0:	60e2                	ld	ra,24(sp)
    80002fa2:	6442                	ld	s0,16(sp)
    80002fa4:	6105                	addi	sp,sp,32
    80002fa6:	8082                	ret

0000000080002fa8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fa8:	1101                	addi	sp,sp,-32
    80002faa:	ec06                	sd	ra,24(sp)
    80002fac:	e822                	sd	s0,16(sp)
    80002fae:	e426                	sd	s1,8(sp)
    80002fb0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fb2:	00014517          	auipc	a0,0x14
    80002fb6:	51e50513          	addi	a0,a0,1310 # 800174d0 <tickslock>
    80002fba:	ffffe097          	auipc	ra,0xffffe
    80002fbe:	c2a080e7          	jalr	-982(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002fc2:	00006497          	auipc	s1,0x6
    80002fc6:	06e4a483          	lw	s1,110(s1) # 80009030 <ticks>
  release(&tickslock);
    80002fca:	00014517          	auipc	a0,0x14
    80002fce:	50650513          	addi	a0,a0,1286 # 800174d0 <tickslock>
    80002fd2:	ffffe097          	auipc	ra,0xffffe
    80002fd6:	cc6080e7          	jalr	-826(ra) # 80000c98 <release>
  return xticks;
}
    80002fda:	02049513          	slli	a0,s1,0x20
    80002fde:	9101                	srli	a0,a0,0x20
    80002fe0:	60e2                	ld	ra,24(sp)
    80002fe2:	6442                	ld	s0,16(sp)
    80002fe4:	64a2                	ld	s1,8(sp)
    80002fe6:	6105                	addi	sp,sp,32
    80002fe8:	8082                	ret

0000000080002fea <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fea:	7179                	addi	sp,sp,-48
    80002fec:	f406                	sd	ra,40(sp)
    80002fee:	f022                	sd	s0,32(sp)
    80002ff0:	ec26                	sd	s1,24(sp)
    80002ff2:	e84a                	sd	s2,16(sp)
    80002ff4:	e44e                	sd	s3,8(sp)
    80002ff6:	e052                	sd	s4,0(sp)
    80002ff8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ffa:	00005597          	auipc	a1,0x5
    80002ffe:	50658593          	addi	a1,a1,1286 # 80008500 <syscalls+0xb8>
    80003002:	00014517          	auipc	a0,0x14
    80003006:	4e650513          	addi	a0,a0,1254 # 800174e8 <bcache>
    8000300a:	ffffe097          	auipc	ra,0xffffe
    8000300e:	b4a080e7          	jalr	-1206(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003012:	0001c797          	auipc	a5,0x1c
    80003016:	4d678793          	addi	a5,a5,1238 # 8001f4e8 <bcache+0x8000>
    8000301a:	0001c717          	auipc	a4,0x1c
    8000301e:	73670713          	addi	a4,a4,1846 # 8001f750 <bcache+0x8268>
    80003022:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003026:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000302a:	00014497          	auipc	s1,0x14
    8000302e:	4d648493          	addi	s1,s1,1238 # 80017500 <bcache+0x18>
    b->next = bcache.head.next;
    80003032:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003034:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003036:	00005a17          	auipc	s4,0x5
    8000303a:	4d2a0a13          	addi	s4,s4,1234 # 80008508 <syscalls+0xc0>
    b->next = bcache.head.next;
    8000303e:	2b893783          	ld	a5,696(s2)
    80003042:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003044:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003048:	85d2                	mv	a1,s4
    8000304a:	01048513          	addi	a0,s1,16
    8000304e:	00001097          	auipc	ra,0x1
    80003052:	4bc080e7          	jalr	1212(ra) # 8000450a <initsleeplock>
    bcache.head.next->prev = b;
    80003056:	2b893783          	ld	a5,696(s2)
    8000305a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000305c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003060:	45848493          	addi	s1,s1,1112
    80003064:	fd349de3          	bne	s1,s3,8000303e <binit+0x54>
  }
}
    80003068:	70a2                	ld	ra,40(sp)
    8000306a:	7402                	ld	s0,32(sp)
    8000306c:	64e2                	ld	s1,24(sp)
    8000306e:	6942                	ld	s2,16(sp)
    80003070:	69a2                	ld	s3,8(sp)
    80003072:	6a02                	ld	s4,0(sp)
    80003074:	6145                	addi	sp,sp,48
    80003076:	8082                	ret

0000000080003078 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003078:	7179                	addi	sp,sp,-48
    8000307a:	f406                	sd	ra,40(sp)
    8000307c:	f022                	sd	s0,32(sp)
    8000307e:	ec26                	sd	s1,24(sp)
    80003080:	e84a                	sd	s2,16(sp)
    80003082:	e44e                	sd	s3,8(sp)
    80003084:	1800                	addi	s0,sp,48
    80003086:	89aa                	mv	s3,a0
    80003088:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000308a:	00014517          	auipc	a0,0x14
    8000308e:	45e50513          	addi	a0,a0,1118 # 800174e8 <bcache>
    80003092:	ffffe097          	auipc	ra,0xffffe
    80003096:	b52080e7          	jalr	-1198(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000309a:	0001c497          	auipc	s1,0x1c
    8000309e:	7064b483          	ld	s1,1798(s1) # 8001f7a0 <bcache+0x82b8>
    800030a2:	0001c797          	auipc	a5,0x1c
    800030a6:	6ae78793          	addi	a5,a5,1710 # 8001f750 <bcache+0x8268>
    800030aa:	02f48f63          	beq	s1,a5,800030e8 <bread+0x70>
    800030ae:	873e                	mv	a4,a5
    800030b0:	a021                	j	800030b8 <bread+0x40>
    800030b2:	68a4                	ld	s1,80(s1)
    800030b4:	02e48a63          	beq	s1,a4,800030e8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030b8:	449c                	lw	a5,8(s1)
    800030ba:	ff379ce3          	bne	a5,s3,800030b2 <bread+0x3a>
    800030be:	44dc                	lw	a5,12(s1)
    800030c0:	ff2799e3          	bne	a5,s2,800030b2 <bread+0x3a>
      b->refcnt++;
    800030c4:	40bc                	lw	a5,64(s1)
    800030c6:	2785                	addiw	a5,a5,1
    800030c8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030ca:	00014517          	auipc	a0,0x14
    800030ce:	41e50513          	addi	a0,a0,1054 # 800174e8 <bcache>
    800030d2:	ffffe097          	auipc	ra,0xffffe
    800030d6:	bc6080e7          	jalr	-1082(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800030da:	01048513          	addi	a0,s1,16
    800030de:	00001097          	auipc	ra,0x1
    800030e2:	466080e7          	jalr	1126(ra) # 80004544 <acquiresleep>
      return b;
    800030e6:	a8b9                	j	80003144 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030e8:	0001c497          	auipc	s1,0x1c
    800030ec:	6b04b483          	ld	s1,1712(s1) # 8001f798 <bcache+0x82b0>
    800030f0:	0001c797          	auipc	a5,0x1c
    800030f4:	66078793          	addi	a5,a5,1632 # 8001f750 <bcache+0x8268>
    800030f8:	00f48863          	beq	s1,a5,80003108 <bread+0x90>
    800030fc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030fe:	40bc                	lw	a5,64(s1)
    80003100:	cf81                	beqz	a5,80003118 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003102:	64a4                	ld	s1,72(s1)
    80003104:	fee49de3          	bne	s1,a4,800030fe <bread+0x86>
  panic("bget: no buffers");
    80003108:	00005517          	auipc	a0,0x5
    8000310c:	40850513          	addi	a0,a0,1032 # 80008510 <syscalls+0xc8>
    80003110:	ffffd097          	auipc	ra,0xffffd
    80003114:	42e080e7          	jalr	1070(ra) # 8000053e <panic>
      b->dev = dev;
    80003118:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000311c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003120:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003124:	4785                	li	a5,1
    80003126:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003128:	00014517          	auipc	a0,0x14
    8000312c:	3c050513          	addi	a0,a0,960 # 800174e8 <bcache>
    80003130:	ffffe097          	auipc	ra,0xffffe
    80003134:	b68080e7          	jalr	-1176(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003138:	01048513          	addi	a0,s1,16
    8000313c:	00001097          	auipc	ra,0x1
    80003140:	408080e7          	jalr	1032(ra) # 80004544 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003144:	409c                	lw	a5,0(s1)
    80003146:	cb89                	beqz	a5,80003158 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003148:	8526                	mv	a0,s1
    8000314a:	70a2                	ld	ra,40(sp)
    8000314c:	7402                	ld	s0,32(sp)
    8000314e:	64e2                	ld	s1,24(sp)
    80003150:	6942                	ld	s2,16(sp)
    80003152:	69a2                	ld	s3,8(sp)
    80003154:	6145                	addi	sp,sp,48
    80003156:	8082                	ret
    virtio_disk_rw(b, 0);
    80003158:	4581                	li	a1,0
    8000315a:	8526                	mv	a0,s1
    8000315c:	00003097          	auipc	ra,0x3
    80003160:	f0a080e7          	jalr	-246(ra) # 80006066 <virtio_disk_rw>
    b->valid = 1;
    80003164:	4785                	li	a5,1
    80003166:	c09c                	sw	a5,0(s1)
  return b;
    80003168:	b7c5                	j	80003148 <bread+0xd0>

000000008000316a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000316a:	1101                	addi	sp,sp,-32
    8000316c:	ec06                	sd	ra,24(sp)
    8000316e:	e822                	sd	s0,16(sp)
    80003170:	e426                	sd	s1,8(sp)
    80003172:	1000                	addi	s0,sp,32
    80003174:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003176:	0541                	addi	a0,a0,16
    80003178:	00001097          	auipc	ra,0x1
    8000317c:	466080e7          	jalr	1126(ra) # 800045de <holdingsleep>
    80003180:	cd01                	beqz	a0,80003198 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003182:	4585                	li	a1,1
    80003184:	8526                	mv	a0,s1
    80003186:	00003097          	auipc	ra,0x3
    8000318a:	ee0080e7          	jalr	-288(ra) # 80006066 <virtio_disk_rw>
}
    8000318e:	60e2                	ld	ra,24(sp)
    80003190:	6442                	ld	s0,16(sp)
    80003192:	64a2                	ld	s1,8(sp)
    80003194:	6105                	addi	sp,sp,32
    80003196:	8082                	ret
    panic("bwrite");
    80003198:	00005517          	auipc	a0,0x5
    8000319c:	39050513          	addi	a0,a0,912 # 80008528 <syscalls+0xe0>
    800031a0:	ffffd097          	auipc	ra,0xffffd
    800031a4:	39e080e7          	jalr	926(ra) # 8000053e <panic>

00000000800031a8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031a8:	1101                	addi	sp,sp,-32
    800031aa:	ec06                	sd	ra,24(sp)
    800031ac:	e822                	sd	s0,16(sp)
    800031ae:	e426                	sd	s1,8(sp)
    800031b0:	e04a                	sd	s2,0(sp)
    800031b2:	1000                	addi	s0,sp,32
    800031b4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031b6:	01050913          	addi	s2,a0,16
    800031ba:	854a                	mv	a0,s2
    800031bc:	00001097          	auipc	ra,0x1
    800031c0:	422080e7          	jalr	1058(ra) # 800045de <holdingsleep>
    800031c4:	c92d                	beqz	a0,80003236 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031c6:	854a                	mv	a0,s2
    800031c8:	00001097          	auipc	ra,0x1
    800031cc:	3d2080e7          	jalr	978(ra) # 8000459a <releasesleep>

  acquire(&bcache.lock);
    800031d0:	00014517          	auipc	a0,0x14
    800031d4:	31850513          	addi	a0,a0,792 # 800174e8 <bcache>
    800031d8:	ffffe097          	auipc	ra,0xffffe
    800031dc:	a0c080e7          	jalr	-1524(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031e0:	40bc                	lw	a5,64(s1)
    800031e2:	37fd                	addiw	a5,a5,-1
    800031e4:	0007871b          	sext.w	a4,a5
    800031e8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031ea:	eb05                	bnez	a4,8000321a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031ec:	68bc                	ld	a5,80(s1)
    800031ee:	64b8                	ld	a4,72(s1)
    800031f0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031f2:	64bc                	ld	a5,72(s1)
    800031f4:	68b8                	ld	a4,80(s1)
    800031f6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031f8:	0001c797          	auipc	a5,0x1c
    800031fc:	2f078793          	addi	a5,a5,752 # 8001f4e8 <bcache+0x8000>
    80003200:	2b87b703          	ld	a4,696(a5)
    80003204:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003206:	0001c717          	auipc	a4,0x1c
    8000320a:	54a70713          	addi	a4,a4,1354 # 8001f750 <bcache+0x8268>
    8000320e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003210:	2b87b703          	ld	a4,696(a5)
    80003214:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003216:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000321a:	00014517          	auipc	a0,0x14
    8000321e:	2ce50513          	addi	a0,a0,718 # 800174e8 <bcache>
    80003222:	ffffe097          	auipc	ra,0xffffe
    80003226:	a76080e7          	jalr	-1418(ra) # 80000c98 <release>
}
    8000322a:	60e2                	ld	ra,24(sp)
    8000322c:	6442                	ld	s0,16(sp)
    8000322e:	64a2                	ld	s1,8(sp)
    80003230:	6902                	ld	s2,0(sp)
    80003232:	6105                	addi	sp,sp,32
    80003234:	8082                	ret
    panic("brelse");
    80003236:	00005517          	auipc	a0,0x5
    8000323a:	2fa50513          	addi	a0,a0,762 # 80008530 <syscalls+0xe8>
    8000323e:	ffffd097          	auipc	ra,0xffffd
    80003242:	300080e7          	jalr	768(ra) # 8000053e <panic>

0000000080003246 <bpin>:

void
bpin(struct buf *b) {
    80003246:	1101                	addi	sp,sp,-32
    80003248:	ec06                	sd	ra,24(sp)
    8000324a:	e822                	sd	s0,16(sp)
    8000324c:	e426                	sd	s1,8(sp)
    8000324e:	1000                	addi	s0,sp,32
    80003250:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003252:	00014517          	auipc	a0,0x14
    80003256:	29650513          	addi	a0,a0,662 # 800174e8 <bcache>
    8000325a:	ffffe097          	auipc	ra,0xffffe
    8000325e:	98a080e7          	jalr	-1654(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003262:	40bc                	lw	a5,64(s1)
    80003264:	2785                	addiw	a5,a5,1
    80003266:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003268:	00014517          	auipc	a0,0x14
    8000326c:	28050513          	addi	a0,a0,640 # 800174e8 <bcache>
    80003270:	ffffe097          	auipc	ra,0xffffe
    80003274:	a28080e7          	jalr	-1496(ra) # 80000c98 <release>
}
    80003278:	60e2                	ld	ra,24(sp)
    8000327a:	6442                	ld	s0,16(sp)
    8000327c:	64a2                	ld	s1,8(sp)
    8000327e:	6105                	addi	sp,sp,32
    80003280:	8082                	ret

0000000080003282 <bunpin>:

void
bunpin(struct buf *b) {
    80003282:	1101                	addi	sp,sp,-32
    80003284:	ec06                	sd	ra,24(sp)
    80003286:	e822                	sd	s0,16(sp)
    80003288:	e426                	sd	s1,8(sp)
    8000328a:	1000                	addi	s0,sp,32
    8000328c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000328e:	00014517          	auipc	a0,0x14
    80003292:	25a50513          	addi	a0,a0,602 # 800174e8 <bcache>
    80003296:	ffffe097          	auipc	ra,0xffffe
    8000329a:	94e080e7          	jalr	-1714(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000329e:	40bc                	lw	a5,64(s1)
    800032a0:	37fd                	addiw	a5,a5,-1
    800032a2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032a4:	00014517          	auipc	a0,0x14
    800032a8:	24450513          	addi	a0,a0,580 # 800174e8 <bcache>
    800032ac:	ffffe097          	auipc	ra,0xffffe
    800032b0:	9ec080e7          	jalr	-1556(ra) # 80000c98 <release>
}
    800032b4:	60e2                	ld	ra,24(sp)
    800032b6:	6442                	ld	s0,16(sp)
    800032b8:	64a2                	ld	s1,8(sp)
    800032ba:	6105                	addi	sp,sp,32
    800032bc:	8082                	ret

00000000800032be <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032be:	1101                	addi	sp,sp,-32
    800032c0:	ec06                	sd	ra,24(sp)
    800032c2:	e822                	sd	s0,16(sp)
    800032c4:	e426                	sd	s1,8(sp)
    800032c6:	e04a                	sd	s2,0(sp)
    800032c8:	1000                	addi	s0,sp,32
    800032ca:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032cc:	00d5d59b          	srliw	a1,a1,0xd
    800032d0:	0001d797          	auipc	a5,0x1d
    800032d4:	8f47a783          	lw	a5,-1804(a5) # 8001fbc4 <sb+0x1c>
    800032d8:	9dbd                	addw	a1,a1,a5
    800032da:	00000097          	auipc	ra,0x0
    800032de:	d9e080e7          	jalr	-610(ra) # 80003078 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032e2:	0074f713          	andi	a4,s1,7
    800032e6:	4785                	li	a5,1
    800032e8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032ec:	14ce                	slli	s1,s1,0x33
    800032ee:	90d9                	srli	s1,s1,0x36
    800032f0:	00950733          	add	a4,a0,s1
    800032f4:	05874703          	lbu	a4,88(a4)
    800032f8:	00e7f6b3          	and	a3,a5,a4
    800032fc:	c69d                	beqz	a3,8000332a <bfree+0x6c>
    800032fe:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003300:	94aa                	add	s1,s1,a0
    80003302:	fff7c793          	not	a5,a5
    80003306:	8ff9                	and	a5,a5,a4
    80003308:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000330c:	00001097          	auipc	ra,0x1
    80003310:	118080e7          	jalr	280(ra) # 80004424 <log_write>
  brelse(bp);
    80003314:	854a                	mv	a0,s2
    80003316:	00000097          	auipc	ra,0x0
    8000331a:	e92080e7          	jalr	-366(ra) # 800031a8 <brelse>
}
    8000331e:	60e2                	ld	ra,24(sp)
    80003320:	6442                	ld	s0,16(sp)
    80003322:	64a2                	ld	s1,8(sp)
    80003324:	6902                	ld	s2,0(sp)
    80003326:	6105                	addi	sp,sp,32
    80003328:	8082                	ret
    panic("freeing free block");
    8000332a:	00005517          	auipc	a0,0x5
    8000332e:	20e50513          	addi	a0,a0,526 # 80008538 <syscalls+0xf0>
    80003332:	ffffd097          	auipc	ra,0xffffd
    80003336:	20c080e7          	jalr	524(ra) # 8000053e <panic>

000000008000333a <balloc>:
{
    8000333a:	711d                	addi	sp,sp,-96
    8000333c:	ec86                	sd	ra,88(sp)
    8000333e:	e8a2                	sd	s0,80(sp)
    80003340:	e4a6                	sd	s1,72(sp)
    80003342:	e0ca                	sd	s2,64(sp)
    80003344:	fc4e                	sd	s3,56(sp)
    80003346:	f852                	sd	s4,48(sp)
    80003348:	f456                	sd	s5,40(sp)
    8000334a:	f05a                	sd	s6,32(sp)
    8000334c:	ec5e                	sd	s7,24(sp)
    8000334e:	e862                	sd	s8,16(sp)
    80003350:	e466                	sd	s9,8(sp)
    80003352:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003354:	0001d797          	auipc	a5,0x1d
    80003358:	8587a783          	lw	a5,-1960(a5) # 8001fbac <sb+0x4>
    8000335c:	cbd1                	beqz	a5,800033f0 <balloc+0xb6>
    8000335e:	8baa                	mv	s7,a0
    80003360:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003362:	0001db17          	auipc	s6,0x1d
    80003366:	846b0b13          	addi	s6,s6,-1978 # 8001fba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000336a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000336c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000336e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003370:	6c89                	lui	s9,0x2
    80003372:	a831                	j	8000338e <balloc+0x54>
    brelse(bp);
    80003374:	854a                	mv	a0,s2
    80003376:	00000097          	auipc	ra,0x0
    8000337a:	e32080e7          	jalr	-462(ra) # 800031a8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000337e:	015c87bb          	addw	a5,s9,s5
    80003382:	00078a9b          	sext.w	s5,a5
    80003386:	004b2703          	lw	a4,4(s6)
    8000338a:	06eaf363          	bgeu	s5,a4,800033f0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000338e:	41fad79b          	sraiw	a5,s5,0x1f
    80003392:	0137d79b          	srliw	a5,a5,0x13
    80003396:	015787bb          	addw	a5,a5,s5
    8000339a:	40d7d79b          	sraiw	a5,a5,0xd
    8000339e:	01cb2583          	lw	a1,28(s6)
    800033a2:	9dbd                	addw	a1,a1,a5
    800033a4:	855e                	mv	a0,s7
    800033a6:	00000097          	auipc	ra,0x0
    800033aa:	cd2080e7          	jalr	-814(ra) # 80003078 <bread>
    800033ae:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033b0:	004b2503          	lw	a0,4(s6)
    800033b4:	000a849b          	sext.w	s1,s5
    800033b8:	8662                	mv	a2,s8
    800033ba:	faa4fde3          	bgeu	s1,a0,80003374 <balloc+0x3a>
      m = 1 << (bi % 8);
    800033be:	41f6579b          	sraiw	a5,a2,0x1f
    800033c2:	01d7d69b          	srliw	a3,a5,0x1d
    800033c6:	00c6873b          	addw	a4,a3,a2
    800033ca:	00777793          	andi	a5,a4,7
    800033ce:	9f95                	subw	a5,a5,a3
    800033d0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033d4:	4037571b          	sraiw	a4,a4,0x3
    800033d8:	00e906b3          	add	a3,s2,a4
    800033dc:	0586c683          	lbu	a3,88(a3)
    800033e0:	00d7f5b3          	and	a1,a5,a3
    800033e4:	cd91                	beqz	a1,80003400 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033e6:	2605                	addiw	a2,a2,1
    800033e8:	2485                	addiw	s1,s1,1
    800033ea:	fd4618e3          	bne	a2,s4,800033ba <balloc+0x80>
    800033ee:	b759                	j	80003374 <balloc+0x3a>
  panic("balloc: out of blocks");
    800033f0:	00005517          	auipc	a0,0x5
    800033f4:	16050513          	addi	a0,a0,352 # 80008550 <syscalls+0x108>
    800033f8:	ffffd097          	auipc	ra,0xffffd
    800033fc:	146080e7          	jalr	326(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003400:	974a                	add	a4,a4,s2
    80003402:	8fd5                	or	a5,a5,a3
    80003404:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003408:	854a                	mv	a0,s2
    8000340a:	00001097          	auipc	ra,0x1
    8000340e:	01a080e7          	jalr	26(ra) # 80004424 <log_write>
        brelse(bp);
    80003412:	854a                	mv	a0,s2
    80003414:	00000097          	auipc	ra,0x0
    80003418:	d94080e7          	jalr	-620(ra) # 800031a8 <brelse>
  bp = bread(dev, bno);
    8000341c:	85a6                	mv	a1,s1
    8000341e:	855e                	mv	a0,s7
    80003420:	00000097          	auipc	ra,0x0
    80003424:	c58080e7          	jalr	-936(ra) # 80003078 <bread>
    80003428:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000342a:	40000613          	li	a2,1024
    8000342e:	4581                	li	a1,0
    80003430:	05850513          	addi	a0,a0,88
    80003434:	ffffe097          	auipc	ra,0xffffe
    80003438:	8ac080e7          	jalr	-1876(ra) # 80000ce0 <memset>
  log_write(bp);
    8000343c:	854a                	mv	a0,s2
    8000343e:	00001097          	auipc	ra,0x1
    80003442:	fe6080e7          	jalr	-26(ra) # 80004424 <log_write>
  brelse(bp);
    80003446:	854a                	mv	a0,s2
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	d60080e7          	jalr	-672(ra) # 800031a8 <brelse>
}
    80003450:	8526                	mv	a0,s1
    80003452:	60e6                	ld	ra,88(sp)
    80003454:	6446                	ld	s0,80(sp)
    80003456:	64a6                	ld	s1,72(sp)
    80003458:	6906                	ld	s2,64(sp)
    8000345a:	79e2                	ld	s3,56(sp)
    8000345c:	7a42                	ld	s4,48(sp)
    8000345e:	7aa2                	ld	s5,40(sp)
    80003460:	7b02                	ld	s6,32(sp)
    80003462:	6be2                	ld	s7,24(sp)
    80003464:	6c42                	ld	s8,16(sp)
    80003466:	6ca2                	ld	s9,8(sp)
    80003468:	6125                	addi	sp,sp,96
    8000346a:	8082                	ret

000000008000346c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000346c:	7179                	addi	sp,sp,-48
    8000346e:	f406                	sd	ra,40(sp)
    80003470:	f022                	sd	s0,32(sp)
    80003472:	ec26                	sd	s1,24(sp)
    80003474:	e84a                	sd	s2,16(sp)
    80003476:	e44e                	sd	s3,8(sp)
    80003478:	e052                	sd	s4,0(sp)
    8000347a:	1800                	addi	s0,sp,48
    8000347c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000347e:	47ad                	li	a5,11
    80003480:	04b7fe63          	bgeu	a5,a1,800034dc <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003484:	ff45849b          	addiw	s1,a1,-12
    80003488:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000348c:	0ff00793          	li	a5,255
    80003490:	0ae7e363          	bltu	a5,a4,80003536 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003494:	08052583          	lw	a1,128(a0)
    80003498:	c5ad                	beqz	a1,80003502 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000349a:	00092503          	lw	a0,0(s2)
    8000349e:	00000097          	auipc	ra,0x0
    800034a2:	bda080e7          	jalr	-1062(ra) # 80003078 <bread>
    800034a6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034a8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034ac:	02049593          	slli	a1,s1,0x20
    800034b0:	9181                	srli	a1,a1,0x20
    800034b2:	058a                	slli	a1,a1,0x2
    800034b4:	00b784b3          	add	s1,a5,a1
    800034b8:	0004a983          	lw	s3,0(s1)
    800034bc:	04098d63          	beqz	s3,80003516 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034c0:	8552                	mv	a0,s4
    800034c2:	00000097          	auipc	ra,0x0
    800034c6:	ce6080e7          	jalr	-794(ra) # 800031a8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034ca:	854e                	mv	a0,s3
    800034cc:	70a2                	ld	ra,40(sp)
    800034ce:	7402                	ld	s0,32(sp)
    800034d0:	64e2                	ld	s1,24(sp)
    800034d2:	6942                	ld	s2,16(sp)
    800034d4:	69a2                	ld	s3,8(sp)
    800034d6:	6a02                	ld	s4,0(sp)
    800034d8:	6145                	addi	sp,sp,48
    800034da:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034dc:	02059493          	slli	s1,a1,0x20
    800034e0:	9081                	srli	s1,s1,0x20
    800034e2:	048a                	slli	s1,s1,0x2
    800034e4:	94aa                	add	s1,s1,a0
    800034e6:	0504a983          	lw	s3,80(s1)
    800034ea:	fe0990e3          	bnez	s3,800034ca <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034ee:	4108                	lw	a0,0(a0)
    800034f0:	00000097          	auipc	ra,0x0
    800034f4:	e4a080e7          	jalr	-438(ra) # 8000333a <balloc>
    800034f8:	0005099b          	sext.w	s3,a0
    800034fc:	0534a823          	sw	s3,80(s1)
    80003500:	b7e9                	j	800034ca <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003502:	4108                	lw	a0,0(a0)
    80003504:	00000097          	auipc	ra,0x0
    80003508:	e36080e7          	jalr	-458(ra) # 8000333a <balloc>
    8000350c:	0005059b          	sext.w	a1,a0
    80003510:	08b92023          	sw	a1,128(s2)
    80003514:	b759                	j	8000349a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003516:	00092503          	lw	a0,0(s2)
    8000351a:	00000097          	auipc	ra,0x0
    8000351e:	e20080e7          	jalr	-480(ra) # 8000333a <balloc>
    80003522:	0005099b          	sext.w	s3,a0
    80003526:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000352a:	8552                	mv	a0,s4
    8000352c:	00001097          	auipc	ra,0x1
    80003530:	ef8080e7          	jalr	-264(ra) # 80004424 <log_write>
    80003534:	b771                	j	800034c0 <bmap+0x54>
  panic("bmap: out of range");
    80003536:	00005517          	auipc	a0,0x5
    8000353a:	03250513          	addi	a0,a0,50 # 80008568 <syscalls+0x120>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	000080e7          	jalr	ra # 8000053e <panic>

0000000080003546 <iget>:
{
    80003546:	7179                	addi	sp,sp,-48
    80003548:	f406                	sd	ra,40(sp)
    8000354a:	f022                	sd	s0,32(sp)
    8000354c:	ec26                	sd	s1,24(sp)
    8000354e:	e84a                	sd	s2,16(sp)
    80003550:	e44e                	sd	s3,8(sp)
    80003552:	e052                	sd	s4,0(sp)
    80003554:	1800                	addi	s0,sp,48
    80003556:	89aa                	mv	s3,a0
    80003558:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000355a:	0001c517          	auipc	a0,0x1c
    8000355e:	66e50513          	addi	a0,a0,1646 # 8001fbc8 <itable>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	682080e7          	jalr	1666(ra) # 80000be4 <acquire>
  empty = 0;
    8000356a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000356c:	0001c497          	auipc	s1,0x1c
    80003570:	67448493          	addi	s1,s1,1652 # 8001fbe0 <itable+0x18>
    80003574:	0001e697          	auipc	a3,0x1e
    80003578:	0fc68693          	addi	a3,a3,252 # 80021670 <log>
    8000357c:	a039                	j	8000358a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000357e:	02090b63          	beqz	s2,800035b4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003582:	08848493          	addi	s1,s1,136
    80003586:	02d48a63          	beq	s1,a3,800035ba <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000358a:	449c                	lw	a5,8(s1)
    8000358c:	fef059e3          	blez	a5,8000357e <iget+0x38>
    80003590:	4098                	lw	a4,0(s1)
    80003592:	ff3716e3          	bne	a4,s3,8000357e <iget+0x38>
    80003596:	40d8                	lw	a4,4(s1)
    80003598:	ff4713e3          	bne	a4,s4,8000357e <iget+0x38>
      ip->ref++;
    8000359c:	2785                	addiw	a5,a5,1
    8000359e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035a0:	0001c517          	auipc	a0,0x1c
    800035a4:	62850513          	addi	a0,a0,1576 # 8001fbc8 <itable>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	6f0080e7          	jalr	1776(ra) # 80000c98 <release>
      return ip;
    800035b0:	8926                	mv	s2,s1
    800035b2:	a03d                	j	800035e0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035b4:	f7f9                	bnez	a5,80003582 <iget+0x3c>
    800035b6:	8926                	mv	s2,s1
    800035b8:	b7e9                	j	80003582 <iget+0x3c>
  if(empty == 0)
    800035ba:	02090c63          	beqz	s2,800035f2 <iget+0xac>
  ip->dev = dev;
    800035be:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035c2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035c6:	4785                	li	a5,1
    800035c8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035cc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035d0:	0001c517          	auipc	a0,0x1c
    800035d4:	5f850513          	addi	a0,a0,1528 # 8001fbc8 <itable>
    800035d8:	ffffd097          	auipc	ra,0xffffd
    800035dc:	6c0080e7          	jalr	1728(ra) # 80000c98 <release>
}
    800035e0:	854a                	mv	a0,s2
    800035e2:	70a2                	ld	ra,40(sp)
    800035e4:	7402                	ld	s0,32(sp)
    800035e6:	64e2                	ld	s1,24(sp)
    800035e8:	6942                	ld	s2,16(sp)
    800035ea:	69a2                	ld	s3,8(sp)
    800035ec:	6a02                	ld	s4,0(sp)
    800035ee:	6145                	addi	sp,sp,48
    800035f0:	8082                	ret
    panic("iget: no inodes");
    800035f2:	00005517          	auipc	a0,0x5
    800035f6:	f8e50513          	addi	a0,a0,-114 # 80008580 <syscalls+0x138>
    800035fa:	ffffd097          	auipc	ra,0xffffd
    800035fe:	f44080e7          	jalr	-188(ra) # 8000053e <panic>

0000000080003602 <fsinit>:
fsinit(int dev) {
    80003602:	7179                	addi	sp,sp,-48
    80003604:	f406                	sd	ra,40(sp)
    80003606:	f022                	sd	s0,32(sp)
    80003608:	ec26                	sd	s1,24(sp)
    8000360a:	e84a                	sd	s2,16(sp)
    8000360c:	e44e                	sd	s3,8(sp)
    8000360e:	1800                	addi	s0,sp,48
    80003610:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003612:	4585                	li	a1,1
    80003614:	00000097          	auipc	ra,0x0
    80003618:	a64080e7          	jalr	-1436(ra) # 80003078 <bread>
    8000361c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000361e:	0001c997          	auipc	s3,0x1c
    80003622:	58a98993          	addi	s3,s3,1418 # 8001fba8 <sb>
    80003626:	02000613          	li	a2,32
    8000362a:	05850593          	addi	a1,a0,88
    8000362e:	854e                	mv	a0,s3
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	710080e7          	jalr	1808(ra) # 80000d40 <memmove>
  brelse(bp);
    80003638:	8526                	mv	a0,s1
    8000363a:	00000097          	auipc	ra,0x0
    8000363e:	b6e080e7          	jalr	-1170(ra) # 800031a8 <brelse>
  if(sb.magic != FSMAGIC)
    80003642:	0009a703          	lw	a4,0(s3)
    80003646:	102037b7          	lui	a5,0x10203
    8000364a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000364e:	02f71263          	bne	a4,a5,80003672 <fsinit+0x70>
  initlog(dev, &sb);
    80003652:	0001c597          	auipc	a1,0x1c
    80003656:	55658593          	addi	a1,a1,1366 # 8001fba8 <sb>
    8000365a:	854a                	mv	a0,s2
    8000365c:	00001097          	auipc	ra,0x1
    80003660:	b4c080e7          	jalr	-1204(ra) # 800041a8 <initlog>
}
    80003664:	70a2                	ld	ra,40(sp)
    80003666:	7402                	ld	s0,32(sp)
    80003668:	64e2                	ld	s1,24(sp)
    8000366a:	6942                	ld	s2,16(sp)
    8000366c:	69a2                	ld	s3,8(sp)
    8000366e:	6145                	addi	sp,sp,48
    80003670:	8082                	ret
    panic("invalid file system");
    80003672:	00005517          	auipc	a0,0x5
    80003676:	f1e50513          	addi	a0,a0,-226 # 80008590 <syscalls+0x148>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	ec4080e7          	jalr	-316(ra) # 8000053e <panic>

0000000080003682 <iinit>:
{
    80003682:	7179                	addi	sp,sp,-48
    80003684:	f406                	sd	ra,40(sp)
    80003686:	f022                	sd	s0,32(sp)
    80003688:	ec26                	sd	s1,24(sp)
    8000368a:	e84a                	sd	s2,16(sp)
    8000368c:	e44e                	sd	s3,8(sp)
    8000368e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003690:	00005597          	auipc	a1,0x5
    80003694:	f1858593          	addi	a1,a1,-232 # 800085a8 <syscalls+0x160>
    80003698:	0001c517          	auipc	a0,0x1c
    8000369c:	53050513          	addi	a0,a0,1328 # 8001fbc8 <itable>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	4b4080e7          	jalr	1204(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036a8:	0001c497          	auipc	s1,0x1c
    800036ac:	54848493          	addi	s1,s1,1352 # 8001fbf0 <itable+0x28>
    800036b0:	0001e997          	auipc	s3,0x1e
    800036b4:	fd098993          	addi	s3,s3,-48 # 80021680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036b8:	00005917          	auipc	s2,0x5
    800036bc:	ef890913          	addi	s2,s2,-264 # 800085b0 <syscalls+0x168>
    800036c0:	85ca                	mv	a1,s2
    800036c2:	8526                	mv	a0,s1
    800036c4:	00001097          	auipc	ra,0x1
    800036c8:	e46080e7          	jalr	-442(ra) # 8000450a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036cc:	08848493          	addi	s1,s1,136
    800036d0:	ff3498e3          	bne	s1,s3,800036c0 <iinit+0x3e>
}
    800036d4:	70a2                	ld	ra,40(sp)
    800036d6:	7402                	ld	s0,32(sp)
    800036d8:	64e2                	ld	s1,24(sp)
    800036da:	6942                	ld	s2,16(sp)
    800036dc:	69a2                	ld	s3,8(sp)
    800036de:	6145                	addi	sp,sp,48
    800036e0:	8082                	ret

00000000800036e2 <ialloc>:
{
    800036e2:	715d                	addi	sp,sp,-80
    800036e4:	e486                	sd	ra,72(sp)
    800036e6:	e0a2                	sd	s0,64(sp)
    800036e8:	fc26                	sd	s1,56(sp)
    800036ea:	f84a                	sd	s2,48(sp)
    800036ec:	f44e                	sd	s3,40(sp)
    800036ee:	f052                	sd	s4,32(sp)
    800036f0:	ec56                	sd	s5,24(sp)
    800036f2:	e85a                	sd	s6,16(sp)
    800036f4:	e45e                	sd	s7,8(sp)
    800036f6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036f8:	0001c717          	auipc	a4,0x1c
    800036fc:	4bc72703          	lw	a4,1212(a4) # 8001fbb4 <sb+0xc>
    80003700:	4785                	li	a5,1
    80003702:	04e7fa63          	bgeu	a5,a4,80003756 <ialloc+0x74>
    80003706:	8aaa                	mv	s5,a0
    80003708:	8bae                	mv	s7,a1
    8000370a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000370c:	0001ca17          	auipc	s4,0x1c
    80003710:	49ca0a13          	addi	s4,s4,1180 # 8001fba8 <sb>
    80003714:	00048b1b          	sext.w	s6,s1
    80003718:	0044d593          	srli	a1,s1,0x4
    8000371c:	018a2783          	lw	a5,24(s4)
    80003720:	9dbd                	addw	a1,a1,a5
    80003722:	8556                	mv	a0,s5
    80003724:	00000097          	auipc	ra,0x0
    80003728:	954080e7          	jalr	-1708(ra) # 80003078 <bread>
    8000372c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000372e:	05850993          	addi	s3,a0,88
    80003732:	00f4f793          	andi	a5,s1,15
    80003736:	079a                	slli	a5,a5,0x6
    80003738:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000373a:	00099783          	lh	a5,0(s3)
    8000373e:	c785                	beqz	a5,80003766 <ialloc+0x84>
    brelse(bp);
    80003740:	00000097          	auipc	ra,0x0
    80003744:	a68080e7          	jalr	-1432(ra) # 800031a8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003748:	0485                	addi	s1,s1,1
    8000374a:	00ca2703          	lw	a4,12(s4)
    8000374e:	0004879b          	sext.w	a5,s1
    80003752:	fce7e1e3          	bltu	a5,a4,80003714 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003756:	00005517          	auipc	a0,0x5
    8000375a:	e6250513          	addi	a0,a0,-414 # 800085b8 <syscalls+0x170>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	de0080e7          	jalr	-544(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003766:	04000613          	li	a2,64
    8000376a:	4581                	li	a1,0
    8000376c:	854e                	mv	a0,s3
    8000376e:	ffffd097          	auipc	ra,0xffffd
    80003772:	572080e7          	jalr	1394(ra) # 80000ce0 <memset>
      dip->type = type;
    80003776:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000377a:	854a                	mv	a0,s2
    8000377c:	00001097          	auipc	ra,0x1
    80003780:	ca8080e7          	jalr	-856(ra) # 80004424 <log_write>
      brelse(bp);
    80003784:	854a                	mv	a0,s2
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	a22080e7          	jalr	-1502(ra) # 800031a8 <brelse>
      return iget(dev, inum);
    8000378e:	85da                	mv	a1,s6
    80003790:	8556                	mv	a0,s5
    80003792:	00000097          	auipc	ra,0x0
    80003796:	db4080e7          	jalr	-588(ra) # 80003546 <iget>
}
    8000379a:	60a6                	ld	ra,72(sp)
    8000379c:	6406                	ld	s0,64(sp)
    8000379e:	74e2                	ld	s1,56(sp)
    800037a0:	7942                	ld	s2,48(sp)
    800037a2:	79a2                	ld	s3,40(sp)
    800037a4:	7a02                	ld	s4,32(sp)
    800037a6:	6ae2                	ld	s5,24(sp)
    800037a8:	6b42                	ld	s6,16(sp)
    800037aa:	6ba2                	ld	s7,8(sp)
    800037ac:	6161                	addi	sp,sp,80
    800037ae:	8082                	ret

00000000800037b0 <iupdate>:
{
    800037b0:	1101                	addi	sp,sp,-32
    800037b2:	ec06                	sd	ra,24(sp)
    800037b4:	e822                	sd	s0,16(sp)
    800037b6:	e426                	sd	s1,8(sp)
    800037b8:	e04a                	sd	s2,0(sp)
    800037ba:	1000                	addi	s0,sp,32
    800037bc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037be:	415c                	lw	a5,4(a0)
    800037c0:	0047d79b          	srliw	a5,a5,0x4
    800037c4:	0001c597          	auipc	a1,0x1c
    800037c8:	3fc5a583          	lw	a1,1020(a1) # 8001fbc0 <sb+0x18>
    800037cc:	9dbd                	addw	a1,a1,a5
    800037ce:	4108                	lw	a0,0(a0)
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	8a8080e7          	jalr	-1880(ra) # 80003078 <bread>
    800037d8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037da:	05850793          	addi	a5,a0,88
    800037de:	40c8                	lw	a0,4(s1)
    800037e0:	893d                	andi	a0,a0,15
    800037e2:	051a                	slli	a0,a0,0x6
    800037e4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037e6:	04449703          	lh	a4,68(s1)
    800037ea:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037ee:	04649703          	lh	a4,70(s1)
    800037f2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037f6:	04849703          	lh	a4,72(s1)
    800037fa:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037fe:	04a49703          	lh	a4,74(s1)
    80003802:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003806:	44f8                	lw	a4,76(s1)
    80003808:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000380a:	03400613          	li	a2,52
    8000380e:	05048593          	addi	a1,s1,80
    80003812:	0531                	addi	a0,a0,12
    80003814:	ffffd097          	auipc	ra,0xffffd
    80003818:	52c080e7          	jalr	1324(ra) # 80000d40 <memmove>
  log_write(bp);
    8000381c:	854a                	mv	a0,s2
    8000381e:	00001097          	auipc	ra,0x1
    80003822:	c06080e7          	jalr	-1018(ra) # 80004424 <log_write>
  brelse(bp);
    80003826:	854a                	mv	a0,s2
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	980080e7          	jalr	-1664(ra) # 800031a8 <brelse>
}
    80003830:	60e2                	ld	ra,24(sp)
    80003832:	6442                	ld	s0,16(sp)
    80003834:	64a2                	ld	s1,8(sp)
    80003836:	6902                	ld	s2,0(sp)
    80003838:	6105                	addi	sp,sp,32
    8000383a:	8082                	ret

000000008000383c <idup>:
{
    8000383c:	1101                	addi	sp,sp,-32
    8000383e:	ec06                	sd	ra,24(sp)
    80003840:	e822                	sd	s0,16(sp)
    80003842:	e426                	sd	s1,8(sp)
    80003844:	1000                	addi	s0,sp,32
    80003846:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003848:	0001c517          	auipc	a0,0x1c
    8000384c:	38050513          	addi	a0,a0,896 # 8001fbc8 <itable>
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	394080e7          	jalr	916(ra) # 80000be4 <acquire>
  ip->ref++;
    80003858:	449c                	lw	a5,8(s1)
    8000385a:	2785                	addiw	a5,a5,1
    8000385c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000385e:	0001c517          	auipc	a0,0x1c
    80003862:	36a50513          	addi	a0,a0,874 # 8001fbc8 <itable>
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	432080e7          	jalr	1074(ra) # 80000c98 <release>
}
    8000386e:	8526                	mv	a0,s1
    80003870:	60e2                	ld	ra,24(sp)
    80003872:	6442                	ld	s0,16(sp)
    80003874:	64a2                	ld	s1,8(sp)
    80003876:	6105                	addi	sp,sp,32
    80003878:	8082                	ret

000000008000387a <ilock>:
{
    8000387a:	1101                	addi	sp,sp,-32
    8000387c:	ec06                	sd	ra,24(sp)
    8000387e:	e822                	sd	s0,16(sp)
    80003880:	e426                	sd	s1,8(sp)
    80003882:	e04a                	sd	s2,0(sp)
    80003884:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003886:	c115                	beqz	a0,800038aa <ilock+0x30>
    80003888:	84aa                	mv	s1,a0
    8000388a:	451c                	lw	a5,8(a0)
    8000388c:	00f05f63          	blez	a5,800038aa <ilock+0x30>
  acquiresleep(&ip->lock);
    80003890:	0541                	addi	a0,a0,16
    80003892:	00001097          	auipc	ra,0x1
    80003896:	cb2080e7          	jalr	-846(ra) # 80004544 <acquiresleep>
  if(ip->valid == 0){
    8000389a:	40bc                	lw	a5,64(s1)
    8000389c:	cf99                	beqz	a5,800038ba <ilock+0x40>
}
    8000389e:	60e2                	ld	ra,24(sp)
    800038a0:	6442                	ld	s0,16(sp)
    800038a2:	64a2                	ld	s1,8(sp)
    800038a4:	6902                	ld	s2,0(sp)
    800038a6:	6105                	addi	sp,sp,32
    800038a8:	8082                	ret
    panic("ilock");
    800038aa:	00005517          	auipc	a0,0x5
    800038ae:	d2650513          	addi	a0,a0,-730 # 800085d0 <syscalls+0x188>
    800038b2:	ffffd097          	auipc	ra,0xffffd
    800038b6:	c8c080e7          	jalr	-884(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038ba:	40dc                	lw	a5,4(s1)
    800038bc:	0047d79b          	srliw	a5,a5,0x4
    800038c0:	0001c597          	auipc	a1,0x1c
    800038c4:	3005a583          	lw	a1,768(a1) # 8001fbc0 <sb+0x18>
    800038c8:	9dbd                	addw	a1,a1,a5
    800038ca:	4088                	lw	a0,0(s1)
    800038cc:	fffff097          	auipc	ra,0xfffff
    800038d0:	7ac080e7          	jalr	1964(ra) # 80003078 <bread>
    800038d4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038d6:	05850593          	addi	a1,a0,88
    800038da:	40dc                	lw	a5,4(s1)
    800038dc:	8bbd                	andi	a5,a5,15
    800038de:	079a                	slli	a5,a5,0x6
    800038e0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038e2:	00059783          	lh	a5,0(a1)
    800038e6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038ea:	00259783          	lh	a5,2(a1)
    800038ee:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038f2:	00459783          	lh	a5,4(a1)
    800038f6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038fa:	00659783          	lh	a5,6(a1)
    800038fe:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003902:	459c                	lw	a5,8(a1)
    80003904:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003906:	03400613          	li	a2,52
    8000390a:	05b1                	addi	a1,a1,12
    8000390c:	05048513          	addi	a0,s1,80
    80003910:	ffffd097          	auipc	ra,0xffffd
    80003914:	430080e7          	jalr	1072(ra) # 80000d40 <memmove>
    brelse(bp);
    80003918:	854a                	mv	a0,s2
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	88e080e7          	jalr	-1906(ra) # 800031a8 <brelse>
    ip->valid = 1;
    80003922:	4785                	li	a5,1
    80003924:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003926:	04449783          	lh	a5,68(s1)
    8000392a:	fbb5                	bnez	a5,8000389e <ilock+0x24>
      panic("ilock: no type");
    8000392c:	00005517          	auipc	a0,0x5
    80003930:	cac50513          	addi	a0,a0,-852 # 800085d8 <syscalls+0x190>
    80003934:	ffffd097          	auipc	ra,0xffffd
    80003938:	c0a080e7          	jalr	-1014(ra) # 8000053e <panic>

000000008000393c <iunlock>:
{
    8000393c:	1101                	addi	sp,sp,-32
    8000393e:	ec06                	sd	ra,24(sp)
    80003940:	e822                	sd	s0,16(sp)
    80003942:	e426                	sd	s1,8(sp)
    80003944:	e04a                	sd	s2,0(sp)
    80003946:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003948:	c905                	beqz	a0,80003978 <iunlock+0x3c>
    8000394a:	84aa                	mv	s1,a0
    8000394c:	01050913          	addi	s2,a0,16
    80003950:	854a                	mv	a0,s2
    80003952:	00001097          	auipc	ra,0x1
    80003956:	c8c080e7          	jalr	-884(ra) # 800045de <holdingsleep>
    8000395a:	cd19                	beqz	a0,80003978 <iunlock+0x3c>
    8000395c:	449c                	lw	a5,8(s1)
    8000395e:	00f05d63          	blez	a5,80003978 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003962:	854a                	mv	a0,s2
    80003964:	00001097          	auipc	ra,0x1
    80003968:	c36080e7          	jalr	-970(ra) # 8000459a <releasesleep>
}
    8000396c:	60e2                	ld	ra,24(sp)
    8000396e:	6442                	ld	s0,16(sp)
    80003970:	64a2                	ld	s1,8(sp)
    80003972:	6902                	ld	s2,0(sp)
    80003974:	6105                	addi	sp,sp,32
    80003976:	8082                	ret
    panic("iunlock");
    80003978:	00005517          	auipc	a0,0x5
    8000397c:	c7050513          	addi	a0,a0,-912 # 800085e8 <syscalls+0x1a0>
    80003980:	ffffd097          	auipc	ra,0xffffd
    80003984:	bbe080e7          	jalr	-1090(ra) # 8000053e <panic>

0000000080003988 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003988:	7179                	addi	sp,sp,-48
    8000398a:	f406                	sd	ra,40(sp)
    8000398c:	f022                	sd	s0,32(sp)
    8000398e:	ec26                	sd	s1,24(sp)
    80003990:	e84a                	sd	s2,16(sp)
    80003992:	e44e                	sd	s3,8(sp)
    80003994:	e052                	sd	s4,0(sp)
    80003996:	1800                	addi	s0,sp,48
    80003998:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000399a:	05050493          	addi	s1,a0,80
    8000399e:	08050913          	addi	s2,a0,128
    800039a2:	a021                	j	800039aa <itrunc+0x22>
    800039a4:	0491                	addi	s1,s1,4
    800039a6:	01248d63          	beq	s1,s2,800039c0 <itrunc+0x38>
    if(ip->addrs[i]){
    800039aa:	408c                	lw	a1,0(s1)
    800039ac:	dde5                	beqz	a1,800039a4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039ae:	0009a503          	lw	a0,0(s3)
    800039b2:	00000097          	auipc	ra,0x0
    800039b6:	90c080e7          	jalr	-1780(ra) # 800032be <bfree>
      ip->addrs[i] = 0;
    800039ba:	0004a023          	sw	zero,0(s1)
    800039be:	b7dd                	j	800039a4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039c0:	0809a583          	lw	a1,128(s3)
    800039c4:	e185                	bnez	a1,800039e4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039c6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039ca:	854e                	mv	a0,s3
    800039cc:	00000097          	auipc	ra,0x0
    800039d0:	de4080e7          	jalr	-540(ra) # 800037b0 <iupdate>
}
    800039d4:	70a2                	ld	ra,40(sp)
    800039d6:	7402                	ld	s0,32(sp)
    800039d8:	64e2                	ld	s1,24(sp)
    800039da:	6942                	ld	s2,16(sp)
    800039dc:	69a2                	ld	s3,8(sp)
    800039de:	6a02                	ld	s4,0(sp)
    800039e0:	6145                	addi	sp,sp,48
    800039e2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039e4:	0009a503          	lw	a0,0(s3)
    800039e8:	fffff097          	auipc	ra,0xfffff
    800039ec:	690080e7          	jalr	1680(ra) # 80003078 <bread>
    800039f0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039f2:	05850493          	addi	s1,a0,88
    800039f6:	45850913          	addi	s2,a0,1112
    800039fa:	a811                	j	80003a0e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039fc:	0009a503          	lw	a0,0(s3)
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	8be080e7          	jalr	-1858(ra) # 800032be <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a08:	0491                	addi	s1,s1,4
    80003a0a:	01248563          	beq	s1,s2,80003a14 <itrunc+0x8c>
      if(a[j])
    80003a0e:	408c                	lw	a1,0(s1)
    80003a10:	dde5                	beqz	a1,80003a08 <itrunc+0x80>
    80003a12:	b7ed                	j	800039fc <itrunc+0x74>
    brelse(bp);
    80003a14:	8552                	mv	a0,s4
    80003a16:	fffff097          	auipc	ra,0xfffff
    80003a1a:	792080e7          	jalr	1938(ra) # 800031a8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a1e:	0809a583          	lw	a1,128(s3)
    80003a22:	0009a503          	lw	a0,0(s3)
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	898080e7          	jalr	-1896(ra) # 800032be <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a2e:	0809a023          	sw	zero,128(s3)
    80003a32:	bf51                	j	800039c6 <itrunc+0x3e>

0000000080003a34 <iput>:
{
    80003a34:	1101                	addi	sp,sp,-32
    80003a36:	ec06                	sd	ra,24(sp)
    80003a38:	e822                	sd	s0,16(sp)
    80003a3a:	e426                	sd	s1,8(sp)
    80003a3c:	e04a                	sd	s2,0(sp)
    80003a3e:	1000                	addi	s0,sp,32
    80003a40:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a42:	0001c517          	auipc	a0,0x1c
    80003a46:	18650513          	addi	a0,a0,390 # 8001fbc8 <itable>
    80003a4a:	ffffd097          	auipc	ra,0xffffd
    80003a4e:	19a080e7          	jalr	410(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a52:	4498                	lw	a4,8(s1)
    80003a54:	4785                	li	a5,1
    80003a56:	02f70363          	beq	a4,a5,80003a7c <iput+0x48>
  ip->ref--;
    80003a5a:	449c                	lw	a5,8(s1)
    80003a5c:	37fd                	addiw	a5,a5,-1
    80003a5e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a60:	0001c517          	auipc	a0,0x1c
    80003a64:	16850513          	addi	a0,a0,360 # 8001fbc8 <itable>
    80003a68:	ffffd097          	auipc	ra,0xffffd
    80003a6c:	230080e7          	jalr	560(ra) # 80000c98 <release>
}
    80003a70:	60e2                	ld	ra,24(sp)
    80003a72:	6442                	ld	s0,16(sp)
    80003a74:	64a2                	ld	s1,8(sp)
    80003a76:	6902                	ld	s2,0(sp)
    80003a78:	6105                	addi	sp,sp,32
    80003a7a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a7c:	40bc                	lw	a5,64(s1)
    80003a7e:	dff1                	beqz	a5,80003a5a <iput+0x26>
    80003a80:	04a49783          	lh	a5,74(s1)
    80003a84:	fbf9                	bnez	a5,80003a5a <iput+0x26>
    acquiresleep(&ip->lock);
    80003a86:	01048913          	addi	s2,s1,16
    80003a8a:	854a                	mv	a0,s2
    80003a8c:	00001097          	auipc	ra,0x1
    80003a90:	ab8080e7          	jalr	-1352(ra) # 80004544 <acquiresleep>
    release(&itable.lock);
    80003a94:	0001c517          	auipc	a0,0x1c
    80003a98:	13450513          	addi	a0,a0,308 # 8001fbc8 <itable>
    80003a9c:	ffffd097          	auipc	ra,0xffffd
    80003aa0:	1fc080e7          	jalr	508(ra) # 80000c98 <release>
    itrunc(ip);
    80003aa4:	8526                	mv	a0,s1
    80003aa6:	00000097          	auipc	ra,0x0
    80003aaa:	ee2080e7          	jalr	-286(ra) # 80003988 <itrunc>
    ip->type = 0;
    80003aae:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ab2:	8526                	mv	a0,s1
    80003ab4:	00000097          	auipc	ra,0x0
    80003ab8:	cfc080e7          	jalr	-772(ra) # 800037b0 <iupdate>
    ip->valid = 0;
    80003abc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ac0:	854a                	mv	a0,s2
    80003ac2:	00001097          	auipc	ra,0x1
    80003ac6:	ad8080e7          	jalr	-1320(ra) # 8000459a <releasesleep>
    acquire(&itable.lock);
    80003aca:	0001c517          	auipc	a0,0x1c
    80003ace:	0fe50513          	addi	a0,a0,254 # 8001fbc8 <itable>
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	112080e7          	jalr	274(ra) # 80000be4 <acquire>
    80003ada:	b741                	j	80003a5a <iput+0x26>

0000000080003adc <iunlockput>:
{
    80003adc:	1101                	addi	sp,sp,-32
    80003ade:	ec06                	sd	ra,24(sp)
    80003ae0:	e822                	sd	s0,16(sp)
    80003ae2:	e426                	sd	s1,8(sp)
    80003ae4:	1000                	addi	s0,sp,32
    80003ae6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	e54080e7          	jalr	-428(ra) # 8000393c <iunlock>
  iput(ip);
    80003af0:	8526                	mv	a0,s1
    80003af2:	00000097          	auipc	ra,0x0
    80003af6:	f42080e7          	jalr	-190(ra) # 80003a34 <iput>
}
    80003afa:	60e2                	ld	ra,24(sp)
    80003afc:	6442                	ld	s0,16(sp)
    80003afe:	64a2                	ld	s1,8(sp)
    80003b00:	6105                	addi	sp,sp,32
    80003b02:	8082                	ret

0000000080003b04 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b04:	1141                	addi	sp,sp,-16
    80003b06:	e422                	sd	s0,8(sp)
    80003b08:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b0a:	411c                	lw	a5,0(a0)
    80003b0c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b0e:	415c                	lw	a5,4(a0)
    80003b10:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b12:	04451783          	lh	a5,68(a0)
    80003b16:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b1a:	04a51783          	lh	a5,74(a0)
    80003b1e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b22:	04c56783          	lwu	a5,76(a0)
    80003b26:	e99c                	sd	a5,16(a1)
}
    80003b28:	6422                	ld	s0,8(sp)
    80003b2a:	0141                	addi	sp,sp,16
    80003b2c:	8082                	ret

0000000080003b2e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b2e:	457c                	lw	a5,76(a0)
    80003b30:	0ed7e963          	bltu	a5,a3,80003c22 <readi+0xf4>
{
    80003b34:	7159                	addi	sp,sp,-112
    80003b36:	f486                	sd	ra,104(sp)
    80003b38:	f0a2                	sd	s0,96(sp)
    80003b3a:	eca6                	sd	s1,88(sp)
    80003b3c:	e8ca                	sd	s2,80(sp)
    80003b3e:	e4ce                	sd	s3,72(sp)
    80003b40:	e0d2                	sd	s4,64(sp)
    80003b42:	fc56                	sd	s5,56(sp)
    80003b44:	f85a                	sd	s6,48(sp)
    80003b46:	f45e                	sd	s7,40(sp)
    80003b48:	f062                	sd	s8,32(sp)
    80003b4a:	ec66                	sd	s9,24(sp)
    80003b4c:	e86a                	sd	s10,16(sp)
    80003b4e:	e46e                	sd	s11,8(sp)
    80003b50:	1880                	addi	s0,sp,112
    80003b52:	8baa                	mv	s7,a0
    80003b54:	8c2e                	mv	s8,a1
    80003b56:	8ab2                	mv	s5,a2
    80003b58:	84b6                	mv	s1,a3
    80003b5a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b5c:	9f35                	addw	a4,a4,a3
    return 0;
    80003b5e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b60:	0ad76063          	bltu	a4,a3,80003c00 <readi+0xd2>
  if(off + n > ip->size)
    80003b64:	00e7f463          	bgeu	a5,a4,80003b6c <readi+0x3e>
    n = ip->size - off;
    80003b68:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b6c:	0a0b0963          	beqz	s6,80003c1e <readi+0xf0>
    80003b70:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b72:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b76:	5cfd                	li	s9,-1
    80003b78:	a82d                	j	80003bb2 <readi+0x84>
    80003b7a:	020a1d93          	slli	s11,s4,0x20
    80003b7e:	020ddd93          	srli	s11,s11,0x20
    80003b82:	05890613          	addi	a2,s2,88
    80003b86:	86ee                	mv	a3,s11
    80003b88:	963a                	add	a2,a2,a4
    80003b8a:	85d6                	mv	a1,s5
    80003b8c:	8562                	mv	a0,s8
    80003b8e:	fffff097          	auipc	ra,0xfffff
    80003b92:	8c4080e7          	jalr	-1852(ra) # 80002452 <either_copyout>
    80003b96:	05950d63          	beq	a0,s9,80003bf0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b9a:	854a                	mv	a0,s2
    80003b9c:	fffff097          	auipc	ra,0xfffff
    80003ba0:	60c080e7          	jalr	1548(ra) # 800031a8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ba4:	013a09bb          	addw	s3,s4,s3
    80003ba8:	009a04bb          	addw	s1,s4,s1
    80003bac:	9aee                	add	s5,s5,s11
    80003bae:	0569f763          	bgeu	s3,s6,80003bfc <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bb2:	000ba903          	lw	s2,0(s7)
    80003bb6:	00a4d59b          	srliw	a1,s1,0xa
    80003bba:	855e                	mv	a0,s7
    80003bbc:	00000097          	auipc	ra,0x0
    80003bc0:	8b0080e7          	jalr	-1872(ra) # 8000346c <bmap>
    80003bc4:	0005059b          	sext.w	a1,a0
    80003bc8:	854a                	mv	a0,s2
    80003bca:	fffff097          	auipc	ra,0xfffff
    80003bce:	4ae080e7          	jalr	1198(ra) # 80003078 <bread>
    80003bd2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd4:	3ff4f713          	andi	a4,s1,1023
    80003bd8:	40ed07bb          	subw	a5,s10,a4
    80003bdc:	413b06bb          	subw	a3,s6,s3
    80003be0:	8a3e                	mv	s4,a5
    80003be2:	2781                	sext.w	a5,a5
    80003be4:	0006861b          	sext.w	a2,a3
    80003be8:	f8f679e3          	bgeu	a2,a5,80003b7a <readi+0x4c>
    80003bec:	8a36                	mv	s4,a3
    80003bee:	b771                	j	80003b7a <readi+0x4c>
      brelse(bp);
    80003bf0:	854a                	mv	a0,s2
    80003bf2:	fffff097          	auipc	ra,0xfffff
    80003bf6:	5b6080e7          	jalr	1462(ra) # 800031a8 <brelse>
      tot = -1;
    80003bfa:	59fd                	li	s3,-1
  }
  return tot;
    80003bfc:	0009851b          	sext.w	a0,s3
}
    80003c00:	70a6                	ld	ra,104(sp)
    80003c02:	7406                	ld	s0,96(sp)
    80003c04:	64e6                	ld	s1,88(sp)
    80003c06:	6946                	ld	s2,80(sp)
    80003c08:	69a6                	ld	s3,72(sp)
    80003c0a:	6a06                	ld	s4,64(sp)
    80003c0c:	7ae2                	ld	s5,56(sp)
    80003c0e:	7b42                	ld	s6,48(sp)
    80003c10:	7ba2                	ld	s7,40(sp)
    80003c12:	7c02                	ld	s8,32(sp)
    80003c14:	6ce2                	ld	s9,24(sp)
    80003c16:	6d42                	ld	s10,16(sp)
    80003c18:	6da2                	ld	s11,8(sp)
    80003c1a:	6165                	addi	sp,sp,112
    80003c1c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c1e:	89da                	mv	s3,s6
    80003c20:	bff1                	j	80003bfc <readi+0xce>
    return 0;
    80003c22:	4501                	li	a0,0
}
    80003c24:	8082                	ret

0000000080003c26 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c26:	457c                	lw	a5,76(a0)
    80003c28:	10d7e863          	bltu	a5,a3,80003d38 <writei+0x112>
{
    80003c2c:	7159                	addi	sp,sp,-112
    80003c2e:	f486                	sd	ra,104(sp)
    80003c30:	f0a2                	sd	s0,96(sp)
    80003c32:	eca6                	sd	s1,88(sp)
    80003c34:	e8ca                	sd	s2,80(sp)
    80003c36:	e4ce                	sd	s3,72(sp)
    80003c38:	e0d2                	sd	s4,64(sp)
    80003c3a:	fc56                	sd	s5,56(sp)
    80003c3c:	f85a                	sd	s6,48(sp)
    80003c3e:	f45e                	sd	s7,40(sp)
    80003c40:	f062                	sd	s8,32(sp)
    80003c42:	ec66                	sd	s9,24(sp)
    80003c44:	e86a                	sd	s10,16(sp)
    80003c46:	e46e                	sd	s11,8(sp)
    80003c48:	1880                	addi	s0,sp,112
    80003c4a:	8b2a                	mv	s6,a0
    80003c4c:	8c2e                	mv	s8,a1
    80003c4e:	8ab2                	mv	s5,a2
    80003c50:	8936                	mv	s2,a3
    80003c52:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c54:	00e687bb          	addw	a5,a3,a4
    80003c58:	0ed7e263          	bltu	a5,a3,80003d3c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c5c:	00043737          	lui	a4,0x43
    80003c60:	0ef76063          	bltu	a4,a5,80003d40 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c64:	0c0b8863          	beqz	s7,80003d34 <writei+0x10e>
    80003c68:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c6a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c6e:	5cfd                	li	s9,-1
    80003c70:	a091                	j	80003cb4 <writei+0x8e>
    80003c72:	02099d93          	slli	s11,s3,0x20
    80003c76:	020ddd93          	srli	s11,s11,0x20
    80003c7a:	05848513          	addi	a0,s1,88
    80003c7e:	86ee                	mv	a3,s11
    80003c80:	8656                	mv	a2,s5
    80003c82:	85e2                	mv	a1,s8
    80003c84:	953a                	add	a0,a0,a4
    80003c86:	fffff097          	auipc	ra,0xfffff
    80003c8a:	822080e7          	jalr	-2014(ra) # 800024a8 <either_copyin>
    80003c8e:	07950263          	beq	a0,s9,80003cf2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c92:	8526                	mv	a0,s1
    80003c94:	00000097          	auipc	ra,0x0
    80003c98:	790080e7          	jalr	1936(ra) # 80004424 <log_write>
    brelse(bp);
    80003c9c:	8526                	mv	a0,s1
    80003c9e:	fffff097          	auipc	ra,0xfffff
    80003ca2:	50a080e7          	jalr	1290(ra) # 800031a8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ca6:	01498a3b          	addw	s4,s3,s4
    80003caa:	0129893b          	addw	s2,s3,s2
    80003cae:	9aee                	add	s5,s5,s11
    80003cb0:	057a7663          	bgeu	s4,s7,80003cfc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cb4:	000b2483          	lw	s1,0(s6)
    80003cb8:	00a9559b          	srliw	a1,s2,0xa
    80003cbc:	855a                	mv	a0,s6
    80003cbe:	fffff097          	auipc	ra,0xfffff
    80003cc2:	7ae080e7          	jalr	1966(ra) # 8000346c <bmap>
    80003cc6:	0005059b          	sext.w	a1,a0
    80003cca:	8526                	mv	a0,s1
    80003ccc:	fffff097          	auipc	ra,0xfffff
    80003cd0:	3ac080e7          	jalr	940(ra) # 80003078 <bread>
    80003cd4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cd6:	3ff97713          	andi	a4,s2,1023
    80003cda:	40ed07bb          	subw	a5,s10,a4
    80003cde:	414b86bb          	subw	a3,s7,s4
    80003ce2:	89be                	mv	s3,a5
    80003ce4:	2781                	sext.w	a5,a5
    80003ce6:	0006861b          	sext.w	a2,a3
    80003cea:	f8f674e3          	bgeu	a2,a5,80003c72 <writei+0x4c>
    80003cee:	89b6                	mv	s3,a3
    80003cf0:	b749                	j	80003c72 <writei+0x4c>
      brelse(bp);
    80003cf2:	8526                	mv	a0,s1
    80003cf4:	fffff097          	auipc	ra,0xfffff
    80003cf8:	4b4080e7          	jalr	1204(ra) # 800031a8 <brelse>
  }

  if(off > ip->size)
    80003cfc:	04cb2783          	lw	a5,76(s6)
    80003d00:	0127f463          	bgeu	a5,s2,80003d08 <writei+0xe2>
    ip->size = off;
    80003d04:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d08:	855a                	mv	a0,s6
    80003d0a:	00000097          	auipc	ra,0x0
    80003d0e:	aa6080e7          	jalr	-1370(ra) # 800037b0 <iupdate>

  return tot;
    80003d12:	000a051b          	sext.w	a0,s4
}
    80003d16:	70a6                	ld	ra,104(sp)
    80003d18:	7406                	ld	s0,96(sp)
    80003d1a:	64e6                	ld	s1,88(sp)
    80003d1c:	6946                	ld	s2,80(sp)
    80003d1e:	69a6                	ld	s3,72(sp)
    80003d20:	6a06                	ld	s4,64(sp)
    80003d22:	7ae2                	ld	s5,56(sp)
    80003d24:	7b42                	ld	s6,48(sp)
    80003d26:	7ba2                	ld	s7,40(sp)
    80003d28:	7c02                	ld	s8,32(sp)
    80003d2a:	6ce2                	ld	s9,24(sp)
    80003d2c:	6d42                	ld	s10,16(sp)
    80003d2e:	6da2                	ld	s11,8(sp)
    80003d30:	6165                	addi	sp,sp,112
    80003d32:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d34:	8a5e                	mv	s4,s7
    80003d36:	bfc9                	j	80003d08 <writei+0xe2>
    return -1;
    80003d38:	557d                	li	a0,-1
}
    80003d3a:	8082                	ret
    return -1;
    80003d3c:	557d                	li	a0,-1
    80003d3e:	bfe1                	j	80003d16 <writei+0xf0>
    return -1;
    80003d40:	557d                	li	a0,-1
    80003d42:	bfd1                	j	80003d16 <writei+0xf0>

0000000080003d44 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d44:	1141                	addi	sp,sp,-16
    80003d46:	e406                	sd	ra,8(sp)
    80003d48:	e022                	sd	s0,0(sp)
    80003d4a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d4c:	4639                	li	a2,14
    80003d4e:	ffffd097          	auipc	ra,0xffffd
    80003d52:	06a080e7          	jalr	106(ra) # 80000db8 <strncmp>
}
    80003d56:	60a2                	ld	ra,8(sp)
    80003d58:	6402                	ld	s0,0(sp)
    80003d5a:	0141                	addi	sp,sp,16
    80003d5c:	8082                	ret

0000000080003d5e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d5e:	7139                	addi	sp,sp,-64
    80003d60:	fc06                	sd	ra,56(sp)
    80003d62:	f822                	sd	s0,48(sp)
    80003d64:	f426                	sd	s1,40(sp)
    80003d66:	f04a                	sd	s2,32(sp)
    80003d68:	ec4e                	sd	s3,24(sp)
    80003d6a:	e852                	sd	s4,16(sp)
    80003d6c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d6e:	04451703          	lh	a4,68(a0)
    80003d72:	4785                	li	a5,1
    80003d74:	00f71a63          	bne	a4,a5,80003d88 <dirlookup+0x2a>
    80003d78:	892a                	mv	s2,a0
    80003d7a:	89ae                	mv	s3,a1
    80003d7c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d7e:	457c                	lw	a5,76(a0)
    80003d80:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d82:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d84:	e79d                	bnez	a5,80003db2 <dirlookup+0x54>
    80003d86:	a8a5                	j	80003dfe <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d88:	00005517          	auipc	a0,0x5
    80003d8c:	86850513          	addi	a0,a0,-1944 # 800085f0 <syscalls+0x1a8>
    80003d90:	ffffc097          	auipc	ra,0xffffc
    80003d94:	7ae080e7          	jalr	1966(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003d98:	00005517          	auipc	a0,0x5
    80003d9c:	87050513          	addi	a0,a0,-1936 # 80008608 <syscalls+0x1c0>
    80003da0:	ffffc097          	auipc	ra,0xffffc
    80003da4:	79e080e7          	jalr	1950(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003da8:	24c1                	addiw	s1,s1,16
    80003daa:	04c92783          	lw	a5,76(s2)
    80003dae:	04f4f763          	bgeu	s1,a5,80003dfc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003db2:	4741                	li	a4,16
    80003db4:	86a6                	mv	a3,s1
    80003db6:	fc040613          	addi	a2,s0,-64
    80003dba:	4581                	li	a1,0
    80003dbc:	854a                	mv	a0,s2
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	d70080e7          	jalr	-656(ra) # 80003b2e <readi>
    80003dc6:	47c1                	li	a5,16
    80003dc8:	fcf518e3          	bne	a0,a5,80003d98 <dirlookup+0x3a>
    if(de.inum == 0)
    80003dcc:	fc045783          	lhu	a5,-64(s0)
    80003dd0:	dfe1                	beqz	a5,80003da8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dd2:	fc240593          	addi	a1,s0,-62
    80003dd6:	854e                	mv	a0,s3
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	f6c080e7          	jalr	-148(ra) # 80003d44 <namecmp>
    80003de0:	f561                	bnez	a0,80003da8 <dirlookup+0x4a>
      if(poff)
    80003de2:	000a0463          	beqz	s4,80003dea <dirlookup+0x8c>
        *poff = off;
    80003de6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003dea:	fc045583          	lhu	a1,-64(s0)
    80003dee:	00092503          	lw	a0,0(s2)
    80003df2:	fffff097          	auipc	ra,0xfffff
    80003df6:	754080e7          	jalr	1876(ra) # 80003546 <iget>
    80003dfa:	a011                	j	80003dfe <dirlookup+0xa0>
  return 0;
    80003dfc:	4501                	li	a0,0
}
    80003dfe:	70e2                	ld	ra,56(sp)
    80003e00:	7442                	ld	s0,48(sp)
    80003e02:	74a2                	ld	s1,40(sp)
    80003e04:	7902                	ld	s2,32(sp)
    80003e06:	69e2                	ld	s3,24(sp)
    80003e08:	6a42                	ld	s4,16(sp)
    80003e0a:	6121                	addi	sp,sp,64
    80003e0c:	8082                	ret

0000000080003e0e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e0e:	711d                	addi	sp,sp,-96
    80003e10:	ec86                	sd	ra,88(sp)
    80003e12:	e8a2                	sd	s0,80(sp)
    80003e14:	e4a6                	sd	s1,72(sp)
    80003e16:	e0ca                	sd	s2,64(sp)
    80003e18:	fc4e                	sd	s3,56(sp)
    80003e1a:	f852                	sd	s4,48(sp)
    80003e1c:	f456                	sd	s5,40(sp)
    80003e1e:	f05a                	sd	s6,32(sp)
    80003e20:	ec5e                	sd	s7,24(sp)
    80003e22:	e862                	sd	s8,16(sp)
    80003e24:	e466                	sd	s9,8(sp)
    80003e26:	1080                	addi	s0,sp,96
    80003e28:	84aa                	mv	s1,a0
    80003e2a:	8b2e                	mv	s6,a1
    80003e2c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e2e:	00054703          	lbu	a4,0(a0)
    80003e32:	02f00793          	li	a5,47
    80003e36:	02f70363          	beq	a4,a5,80003e5c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e3a:	ffffe097          	auipc	ra,0xffffe
    80003e3e:	b76080e7          	jalr	-1162(ra) # 800019b0 <myproc>
    80003e42:	15053503          	ld	a0,336(a0)
    80003e46:	00000097          	auipc	ra,0x0
    80003e4a:	9f6080e7          	jalr	-1546(ra) # 8000383c <idup>
    80003e4e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e50:	02f00913          	li	s2,47
  len = path - s;
    80003e54:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e56:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e58:	4c05                	li	s8,1
    80003e5a:	a865                	j	80003f12 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e5c:	4585                	li	a1,1
    80003e5e:	4505                	li	a0,1
    80003e60:	fffff097          	auipc	ra,0xfffff
    80003e64:	6e6080e7          	jalr	1766(ra) # 80003546 <iget>
    80003e68:	89aa                	mv	s3,a0
    80003e6a:	b7dd                	j	80003e50 <namex+0x42>
      iunlockput(ip);
    80003e6c:	854e                	mv	a0,s3
    80003e6e:	00000097          	auipc	ra,0x0
    80003e72:	c6e080e7          	jalr	-914(ra) # 80003adc <iunlockput>
      return 0;
    80003e76:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e78:	854e                	mv	a0,s3
    80003e7a:	60e6                	ld	ra,88(sp)
    80003e7c:	6446                	ld	s0,80(sp)
    80003e7e:	64a6                	ld	s1,72(sp)
    80003e80:	6906                	ld	s2,64(sp)
    80003e82:	79e2                	ld	s3,56(sp)
    80003e84:	7a42                	ld	s4,48(sp)
    80003e86:	7aa2                	ld	s5,40(sp)
    80003e88:	7b02                	ld	s6,32(sp)
    80003e8a:	6be2                	ld	s7,24(sp)
    80003e8c:	6c42                	ld	s8,16(sp)
    80003e8e:	6ca2                	ld	s9,8(sp)
    80003e90:	6125                	addi	sp,sp,96
    80003e92:	8082                	ret
      iunlock(ip);
    80003e94:	854e                	mv	a0,s3
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	aa6080e7          	jalr	-1370(ra) # 8000393c <iunlock>
      return ip;
    80003e9e:	bfe9                	j	80003e78 <namex+0x6a>
      iunlockput(ip);
    80003ea0:	854e                	mv	a0,s3
    80003ea2:	00000097          	auipc	ra,0x0
    80003ea6:	c3a080e7          	jalr	-966(ra) # 80003adc <iunlockput>
      return 0;
    80003eaa:	89d2                	mv	s3,s4
    80003eac:	b7f1                	j	80003e78 <namex+0x6a>
  len = path - s;
    80003eae:	40b48633          	sub	a2,s1,a1
    80003eb2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003eb6:	094cd463          	bge	s9,s4,80003f3e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003eba:	4639                	li	a2,14
    80003ebc:	8556                	mv	a0,s5
    80003ebe:	ffffd097          	auipc	ra,0xffffd
    80003ec2:	e82080e7          	jalr	-382(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003ec6:	0004c783          	lbu	a5,0(s1)
    80003eca:	01279763          	bne	a5,s2,80003ed8 <namex+0xca>
    path++;
    80003ece:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ed0:	0004c783          	lbu	a5,0(s1)
    80003ed4:	ff278de3          	beq	a5,s2,80003ece <namex+0xc0>
    ilock(ip);
    80003ed8:	854e                	mv	a0,s3
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	9a0080e7          	jalr	-1632(ra) # 8000387a <ilock>
    if(ip->type != T_DIR){
    80003ee2:	04499783          	lh	a5,68(s3)
    80003ee6:	f98793e3          	bne	a5,s8,80003e6c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003eea:	000b0563          	beqz	s6,80003ef4 <namex+0xe6>
    80003eee:	0004c783          	lbu	a5,0(s1)
    80003ef2:	d3cd                	beqz	a5,80003e94 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ef4:	865e                	mv	a2,s7
    80003ef6:	85d6                	mv	a1,s5
    80003ef8:	854e                	mv	a0,s3
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	e64080e7          	jalr	-412(ra) # 80003d5e <dirlookup>
    80003f02:	8a2a                	mv	s4,a0
    80003f04:	dd51                	beqz	a0,80003ea0 <namex+0x92>
    iunlockput(ip);
    80003f06:	854e                	mv	a0,s3
    80003f08:	00000097          	auipc	ra,0x0
    80003f0c:	bd4080e7          	jalr	-1068(ra) # 80003adc <iunlockput>
    ip = next;
    80003f10:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f12:	0004c783          	lbu	a5,0(s1)
    80003f16:	05279763          	bne	a5,s2,80003f64 <namex+0x156>
    path++;
    80003f1a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f1c:	0004c783          	lbu	a5,0(s1)
    80003f20:	ff278de3          	beq	a5,s2,80003f1a <namex+0x10c>
  if(*path == 0)
    80003f24:	c79d                	beqz	a5,80003f52 <namex+0x144>
    path++;
    80003f26:	85a6                	mv	a1,s1
  len = path - s;
    80003f28:	8a5e                	mv	s4,s7
    80003f2a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f2c:	01278963          	beq	a5,s2,80003f3e <namex+0x130>
    80003f30:	dfbd                	beqz	a5,80003eae <namex+0xa0>
    path++;
    80003f32:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f34:	0004c783          	lbu	a5,0(s1)
    80003f38:	ff279ce3          	bne	a5,s2,80003f30 <namex+0x122>
    80003f3c:	bf8d                	j	80003eae <namex+0xa0>
    memmove(name, s, len);
    80003f3e:	2601                	sext.w	a2,a2
    80003f40:	8556                	mv	a0,s5
    80003f42:	ffffd097          	auipc	ra,0xffffd
    80003f46:	dfe080e7          	jalr	-514(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f4a:	9a56                	add	s4,s4,s5
    80003f4c:	000a0023          	sb	zero,0(s4)
    80003f50:	bf9d                	j	80003ec6 <namex+0xb8>
  if(nameiparent){
    80003f52:	f20b03e3          	beqz	s6,80003e78 <namex+0x6a>
    iput(ip);
    80003f56:	854e                	mv	a0,s3
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	adc080e7          	jalr	-1316(ra) # 80003a34 <iput>
    return 0;
    80003f60:	4981                	li	s3,0
    80003f62:	bf19                	j	80003e78 <namex+0x6a>
  if(*path == 0)
    80003f64:	d7fd                	beqz	a5,80003f52 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f66:	0004c783          	lbu	a5,0(s1)
    80003f6a:	85a6                	mv	a1,s1
    80003f6c:	b7d1                	j	80003f30 <namex+0x122>

0000000080003f6e <dirlink>:
{
    80003f6e:	7139                	addi	sp,sp,-64
    80003f70:	fc06                	sd	ra,56(sp)
    80003f72:	f822                	sd	s0,48(sp)
    80003f74:	f426                	sd	s1,40(sp)
    80003f76:	f04a                	sd	s2,32(sp)
    80003f78:	ec4e                	sd	s3,24(sp)
    80003f7a:	e852                	sd	s4,16(sp)
    80003f7c:	0080                	addi	s0,sp,64
    80003f7e:	892a                	mv	s2,a0
    80003f80:	8a2e                	mv	s4,a1
    80003f82:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f84:	4601                	li	a2,0
    80003f86:	00000097          	auipc	ra,0x0
    80003f8a:	dd8080e7          	jalr	-552(ra) # 80003d5e <dirlookup>
    80003f8e:	e93d                	bnez	a0,80004004 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f90:	04c92483          	lw	s1,76(s2)
    80003f94:	c49d                	beqz	s1,80003fc2 <dirlink+0x54>
    80003f96:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f98:	4741                	li	a4,16
    80003f9a:	86a6                	mv	a3,s1
    80003f9c:	fc040613          	addi	a2,s0,-64
    80003fa0:	4581                	li	a1,0
    80003fa2:	854a                	mv	a0,s2
    80003fa4:	00000097          	auipc	ra,0x0
    80003fa8:	b8a080e7          	jalr	-1142(ra) # 80003b2e <readi>
    80003fac:	47c1                	li	a5,16
    80003fae:	06f51163          	bne	a0,a5,80004010 <dirlink+0xa2>
    if(de.inum == 0)
    80003fb2:	fc045783          	lhu	a5,-64(s0)
    80003fb6:	c791                	beqz	a5,80003fc2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fb8:	24c1                	addiw	s1,s1,16
    80003fba:	04c92783          	lw	a5,76(s2)
    80003fbe:	fcf4ede3          	bltu	s1,a5,80003f98 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fc2:	4639                	li	a2,14
    80003fc4:	85d2                	mv	a1,s4
    80003fc6:	fc240513          	addi	a0,s0,-62
    80003fca:	ffffd097          	auipc	ra,0xffffd
    80003fce:	e2a080e7          	jalr	-470(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003fd2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fd6:	4741                	li	a4,16
    80003fd8:	86a6                	mv	a3,s1
    80003fda:	fc040613          	addi	a2,s0,-64
    80003fde:	4581                	li	a1,0
    80003fe0:	854a                	mv	a0,s2
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	c44080e7          	jalr	-956(ra) # 80003c26 <writei>
    80003fea:	872a                	mv	a4,a0
    80003fec:	47c1                	li	a5,16
  return 0;
    80003fee:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ff0:	02f71863          	bne	a4,a5,80004020 <dirlink+0xb2>
}
    80003ff4:	70e2                	ld	ra,56(sp)
    80003ff6:	7442                	ld	s0,48(sp)
    80003ff8:	74a2                	ld	s1,40(sp)
    80003ffa:	7902                	ld	s2,32(sp)
    80003ffc:	69e2                	ld	s3,24(sp)
    80003ffe:	6a42                	ld	s4,16(sp)
    80004000:	6121                	addi	sp,sp,64
    80004002:	8082                	ret
    iput(ip);
    80004004:	00000097          	auipc	ra,0x0
    80004008:	a30080e7          	jalr	-1488(ra) # 80003a34 <iput>
    return -1;
    8000400c:	557d                	li	a0,-1
    8000400e:	b7dd                	j	80003ff4 <dirlink+0x86>
      panic("dirlink read");
    80004010:	00004517          	auipc	a0,0x4
    80004014:	60850513          	addi	a0,a0,1544 # 80008618 <syscalls+0x1d0>
    80004018:	ffffc097          	auipc	ra,0xffffc
    8000401c:	526080e7          	jalr	1318(ra) # 8000053e <panic>
    panic("dirlink");
    80004020:	00004517          	auipc	a0,0x4
    80004024:	70850513          	addi	a0,a0,1800 # 80008728 <syscalls+0x2e0>
    80004028:	ffffc097          	auipc	ra,0xffffc
    8000402c:	516080e7          	jalr	1302(ra) # 8000053e <panic>

0000000080004030 <namei>:

struct inode*
namei(char *path)
{
    80004030:	1101                	addi	sp,sp,-32
    80004032:	ec06                	sd	ra,24(sp)
    80004034:	e822                	sd	s0,16(sp)
    80004036:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004038:	fe040613          	addi	a2,s0,-32
    8000403c:	4581                	li	a1,0
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	dd0080e7          	jalr	-560(ra) # 80003e0e <namex>
}
    80004046:	60e2                	ld	ra,24(sp)
    80004048:	6442                	ld	s0,16(sp)
    8000404a:	6105                	addi	sp,sp,32
    8000404c:	8082                	ret

000000008000404e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000404e:	1141                	addi	sp,sp,-16
    80004050:	e406                	sd	ra,8(sp)
    80004052:	e022                	sd	s0,0(sp)
    80004054:	0800                	addi	s0,sp,16
    80004056:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004058:	4585                	li	a1,1
    8000405a:	00000097          	auipc	ra,0x0
    8000405e:	db4080e7          	jalr	-588(ra) # 80003e0e <namex>
}
    80004062:	60a2                	ld	ra,8(sp)
    80004064:	6402                	ld	s0,0(sp)
    80004066:	0141                	addi	sp,sp,16
    80004068:	8082                	ret

000000008000406a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000406a:	1101                	addi	sp,sp,-32
    8000406c:	ec06                	sd	ra,24(sp)
    8000406e:	e822                	sd	s0,16(sp)
    80004070:	e426                	sd	s1,8(sp)
    80004072:	e04a                	sd	s2,0(sp)
    80004074:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004076:	0001d917          	auipc	s2,0x1d
    8000407a:	5fa90913          	addi	s2,s2,1530 # 80021670 <log>
    8000407e:	01892583          	lw	a1,24(s2)
    80004082:	02892503          	lw	a0,40(s2)
    80004086:	fffff097          	auipc	ra,0xfffff
    8000408a:	ff2080e7          	jalr	-14(ra) # 80003078 <bread>
    8000408e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004090:	02c92683          	lw	a3,44(s2)
    80004094:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004096:	02d05763          	blez	a3,800040c4 <write_head+0x5a>
    8000409a:	0001d797          	auipc	a5,0x1d
    8000409e:	60678793          	addi	a5,a5,1542 # 800216a0 <log+0x30>
    800040a2:	05c50713          	addi	a4,a0,92
    800040a6:	36fd                	addiw	a3,a3,-1
    800040a8:	1682                	slli	a3,a3,0x20
    800040aa:	9281                	srli	a3,a3,0x20
    800040ac:	068a                	slli	a3,a3,0x2
    800040ae:	0001d617          	auipc	a2,0x1d
    800040b2:	5f660613          	addi	a2,a2,1526 # 800216a4 <log+0x34>
    800040b6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040b8:	4390                	lw	a2,0(a5)
    800040ba:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040bc:	0791                	addi	a5,a5,4
    800040be:	0711                	addi	a4,a4,4
    800040c0:	fed79ce3          	bne	a5,a3,800040b8 <write_head+0x4e>
  }
  bwrite(buf);
    800040c4:	8526                	mv	a0,s1
    800040c6:	fffff097          	auipc	ra,0xfffff
    800040ca:	0a4080e7          	jalr	164(ra) # 8000316a <bwrite>
  brelse(buf);
    800040ce:	8526                	mv	a0,s1
    800040d0:	fffff097          	auipc	ra,0xfffff
    800040d4:	0d8080e7          	jalr	216(ra) # 800031a8 <brelse>
}
    800040d8:	60e2                	ld	ra,24(sp)
    800040da:	6442                	ld	s0,16(sp)
    800040dc:	64a2                	ld	s1,8(sp)
    800040de:	6902                	ld	s2,0(sp)
    800040e0:	6105                	addi	sp,sp,32
    800040e2:	8082                	ret

00000000800040e4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040e4:	0001d797          	auipc	a5,0x1d
    800040e8:	5b87a783          	lw	a5,1464(a5) # 8002169c <log+0x2c>
    800040ec:	0af05d63          	blez	a5,800041a6 <install_trans+0xc2>
{
    800040f0:	7139                	addi	sp,sp,-64
    800040f2:	fc06                	sd	ra,56(sp)
    800040f4:	f822                	sd	s0,48(sp)
    800040f6:	f426                	sd	s1,40(sp)
    800040f8:	f04a                	sd	s2,32(sp)
    800040fa:	ec4e                	sd	s3,24(sp)
    800040fc:	e852                	sd	s4,16(sp)
    800040fe:	e456                	sd	s5,8(sp)
    80004100:	e05a                	sd	s6,0(sp)
    80004102:	0080                	addi	s0,sp,64
    80004104:	8b2a                	mv	s6,a0
    80004106:	0001da97          	auipc	s5,0x1d
    8000410a:	59aa8a93          	addi	s5,s5,1434 # 800216a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000410e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004110:	0001d997          	auipc	s3,0x1d
    80004114:	56098993          	addi	s3,s3,1376 # 80021670 <log>
    80004118:	a035                	j	80004144 <install_trans+0x60>
      bunpin(dbuf);
    8000411a:	8526                	mv	a0,s1
    8000411c:	fffff097          	auipc	ra,0xfffff
    80004120:	166080e7          	jalr	358(ra) # 80003282 <bunpin>
    brelse(lbuf);
    80004124:	854a                	mv	a0,s2
    80004126:	fffff097          	auipc	ra,0xfffff
    8000412a:	082080e7          	jalr	130(ra) # 800031a8 <brelse>
    brelse(dbuf);
    8000412e:	8526                	mv	a0,s1
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	078080e7          	jalr	120(ra) # 800031a8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004138:	2a05                	addiw	s4,s4,1
    8000413a:	0a91                	addi	s5,s5,4
    8000413c:	02c9a783          	lw	a5,44(s3)
    80004140:	04fa5963          	bge	s4,a5,80004192 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004144:	0189a583          	lw	a1,24(s3)
    80004148:	014585bb          	addw	a1,a1,s4
    8000414c:	2585                	addiw	a1,a1,1
    8000414e:	0289a503          	lw	a0,40(s3)
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	f26080e7          	jalr	-218(ra) # 80003078 <bread>
    8000415a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000415c:	000aa583          	lw	a1,0(s5)
    80004160:	0289a503          	lw	a0,40(s3)
    80004164:	fffff097          	auipc	ra,0xfffff
    80004168:	f14080e7          	jalr	-236(ra) # 80003078 <bread>
    8000416c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000416e:	40000613          	li	a2,1024
    80004172:	05890593          	addi	a1,s2,88
    80004176:	05850513          	addi	a0,a0,88
    8000417a:	ffffd097          	auipc	ra,0xffffd
    8000417e:	bc6080e7          	jalr	-1082(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004182:	8526                	mv	a0,s1
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	fe6080e7          	jalr	-26(ra) # 8000316a <bwrite>
    if(recovering == 0)
    8000418c:	f80b1ce3          	bnez	s6,80004124 <install_trans+0x40>
    80004190:	b769                	j	8000411a <install_trans+0x36>
}
    80004192:	70e2                	ld	ra,56(sp)
    80004194:	7442                	ld	s0,48(sp)
    80004196:	74a2                	ld	s1,40(sp)
    80004198:	7902                	ld	s2,32(sp)
    8000419a:	69e2                	ld	s3,24(sp)
    8000419c:	6a42                	ld	s4,16(sp)
    8000419e:	6aa2                	ld	s5,8(sp)
    800041a0:	6b02                	ld	s6,0(sp)
    800041a2:	6121                	addi	sp,sp,64
    800041a4:	8082                	ret
    800041a6:	8082                	ret

00000000800041a8 <initlog>:
{
    800041a8:	7179                	addi	sp,sp,-48
    800041aa:	f406                	sd	ra,40(sp)
    800041ac:	f022                	sd	s0,32(sp)
    800041ae:	ec26                	sd	s1,24(sp)
    800041b0:	e84a                	sd	s2,16(sp)
    800041b2:	e44e                	sd	s3,8(sp)
    800041b4:	1800                	addi	s0,sp,48
    800041b6:	892a                	mv	s2,a0
    800041b8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041ba:	0001d497          	auipc	s1,0x1d
    800041be:	4b648493          	addi	s1,s1,1206 # 80021670 <log>
    800041c2:	00004597          	auipc	a1,0x4
    800041c6:	46658593          	addi	a1,a1,1126 # 80008628 <syscalls+0x1e0>
    800041ca:	8526                	mv	a0,s1
    800041cc:	ffffd097          	auipc	ra,0xffffd
    800041d0:	988080e7          	jalr	-1656(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800041d4:	0149a583          	lw	a1,20(s3)
    800041d8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041da:	0109a783          	lw	a5,16(s3)
    800041de:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041e0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041e4:	854a                	mv	a0,s2
    800041e6:	fffff097          	auipc	ra,0xfffff
    800041ea:	e92080e7          	jalr	-366(ra) # 80003078 <bread>
  log.lh.n = lh->n;
    800041ee:	4d3c                	lw	a5,88(a0)
    800041f0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041f2:	02f05563          	blez	a5,8000421c <initlog+0x74>
    800041f6:	05c50713          	addi	a4,a0,92
    800041fa:	0001d697          	auipc	a3,0x1d
    800041fe:	4a668693          	addi	a3,a3,1190 # 800216a0 <log+0x30>
    80004202:	37fd                	addiw	a5,a5,-1
    80004204:	1782                	slli	a5,a5,0x20
    80004206:	9381                	srli	a5,a5,0x20
    80004208:	078a                	slli	a5,a5,0x2
    8000420a:	06050613          	addi	a2,a0,96
    8000420e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004210:	4310                	lw	a2,0(a4)
    80004212:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004214:	0711                	addi	a4,a4,4
    80004216:	0691                	addi	a3,a3,4
    80004218:	fef71ce3          	bne	a4,a5,80004210 <initlog+0x68>
  brelse(buf);
    8000421c:	fffff097          	auipc	ra,0xfffff
    80004220:	f8c080e7          	jalr	-116(ra) # 800031a8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004224:	4505                	li	a0,1
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	ebe080e7          	jalr	-322(ra) # 800040e4 <install_trans>
  log.lh.n = 0;
    8000422e:	0001d797          	auipc	a5,0x1d
    80004232:	4607a723          	sw	zero,1134(a5) # 8002169c <log+0x2c>
  write_head(); // clear the log
    80004236:	00000097          	auipc	ra,0x0
    8000423a:	e34080e7          	jalr	-460(ra) # 8000406a <write_head>
}
    8000423e:	70a2                	ld	ra,40(sp)
    80004240:	7402                	ld	s0,32(sp)
    80004242:	64e2                	ld	s1,24(sp)
    80004244:	6942                	ld	s2,16(sp)
    80004246:	69a2                	ld	s3,8(sp)
    80004248:	6145                	addi	sp,sp,48
    8000424a:	8082                	ret

000000008000424c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000424c:	1101                	addi	sp,sp,-32
    8000424e:	ec06                	sd	ra,24(sp)
    80004250:	e822                	sd	s0,16(sp)
    80004252:	e426                	sd	s1,8(sp)
    80004254:	e04a                	sd	s2,0(sp)
    80004256:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004258:	0001d517          	auipc	a0,0x1d
    8000425c:	41850513          	addi	a0,a0,1048 # 80021670 <log>
    80004260:	ffffd097          	auipc	ra,0xffffd
    80004264:	984080e7          	jalr	-1660(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004268:	0001d497          	auipc	s1,0x1d
    8000426c:	40848493          	addi	s1,s1,1032 # 80021670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004270:	4979                	li	s2,30
    80004272:	a039                	j	80004280 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004274:	85a6                	mv	a1,s1
    80004276:	8526                	mv	a0,s1
    80004278:	ffffe097          	auipc	ra,0xffffe
    8000427c:	e1c080e7          	jalr	-484(ra) # 80002094 <sleep>
    if(log.committing){
    80004280:	50dc                	lw	a5,36(s1)
    80004282:	fbed                	bnez	a5,80004274 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004284:	509c                	lw	a5,32(s1)
    80004286:	0017871b          	addiw	a4,a5,1
    8000428a:	0007069b          	sext.w	a3,a4
    8000428e:	0027179b          	slliw	a5,a4,0x2
    80004292:	9fb9                	addw	a5,a5,a4
    80004294:	0017979b          	slliw	a5,a5,0x1
    80004298:	54d8                	lw	a4,44(s1)
    8000429a:	9fb9                	addw	a5,a5,a4
    8000429c:	00f95963          	bge	s2,a5,800042ae <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042a0:	85a6                	mv	a1,s1
    800042a2:	8526                	mv	a0,s1
    800042a4:	ffffe097          	auipc	ra,0xffffe
    800042a8:	df0080e7          	jalr	-528(ra) # 80002094 <sleep>
    800042ac:	bfd1                	j	80004280 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042ae:	0001d517          	auipc	a0,0x1d
    800042b2:	3c250513          	addi	a0,a0,962 # 80021670 <log>
    800042b6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042b8:	ffffd097          	auipc	ra,0xffffd
    800042bc:	9e0080e7          	jalr	-1568(ra) # 80000c98 <release>
      break;
    }
  }
}
    800042c0:	60e2                	ld	ra,24(sp)
    800042c2:	6442                	ld	s0,16(sp)
    800042c4:	64a2                	ld	s1,8(sp)
    800042c6:	6902                	ld	s2,0(sp)
    800042c8:	6105                	addi	sp,sp,32
    800042ca:	8082                	ret

00000000800042cc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042cc:	7139                	addi	sp,sp,-64
    800042ce:	fc06                	sd	ra,56(sp)
    800042d0:	f822                	sd	s0,48(sp)
    800042d2:	f426                	sd	s1,40(sp)
    800042d4:	f04a                	sd	s2,32(sp)
    800042d6:	ec4e                	sd	s3,24(sp)
    800042d8:	e852                	sd	s4,16(sp)
    800042da:	e456                	sd	s5,8(sp)
    800042dc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042de:	0001d497          	auipc	s1,0x1d
    800042e2:	39248493          	addi	s1,s1,914 # 80021670 <log>
    800042e6:	8526                	mv	a0,s1
    800042e8:	ffffd097          	auipc	ra,0xffffd
    800042ec:	8fc080e7          	jalr	-1796(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800042f0:	509c                	lw	a5,32(s1)
    800042f2:	37fd                	addiw	a5,a5,-1
    800042f4:	0007891b          	sext.w	s2,a5
    800042f8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042fa:	50dc                	lw	a5,36(s1)
    800042fc:	efb9                	bnez	a5,8000435a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042fe:	06091663          	bnez	s2,8000436a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004302:	0001d497          	auipc	s1,0x1d
    80004306:	36e48493          	addi	s1,s1,878 # 80021670 <log>
    8000430a:	4785                	li	a5,1
    8000430c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000430e:	8526                	mv	a0,s1
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	988080e7          	jalr	-1656(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004318:	54dc                	lw	a5,44(s1)
    8000431a:	06f04763          	bgtz	a5,80004388 <end_op+0xbc>
    acquire(&log.lock);
    8000431e:	0001d497          	auipc	s1,0x1d
    80004322:	35248493          	addi	s1,s1,850 # 80021670 <log>
    80004326:	8526                	mv	a0,s1
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	8bc080e7          	jalr	-1860(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004330:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004334:	8526                	mv	a0,s1
    80004336:	ffffe097          	auipc	ra,0xffffe
    8000433a:	eea080e7          	jalr	-278(ra) # 80002220 <wakeup>
    release(&log.lock);
    8000433e:	8526                	mv	a0,s1
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	958080e7          	jalr	-1704(ra) # 80000c98 <release>
}
    80004348:	70e2                	ld	ra,56(sp)
    8000434a:	7442                	ld	s0,48(sp)
    8000434c:	74a2                	ld	s1,40(sp)
    8000434e:	7902                	ld	s2,32(sp)
    80004350:	69e2                	ld	s3,24(sp)
    80004352:	6a42                	ld	s4,16(sp)
    80004354:	6aa2                	ld	s5,8(sp)
    80004356:	6121                	addi	sp,sp,64
    80004358:	8082                	ret
    panic("log.committing");
    8000435a:	00004517          	auipc	a0,0x4
    8000435e:	2d650513          	addi	a0,a0,726 # 80008630 <syscalls+0x1e8>
    80004362:	ffffc097          	auipc	ra,0xffffc
    80004366:	1dc080e7          	jalr	476(ra) # 8000053e <panic>
    wakeup(&log);
    8000436a:	0001d497          	auipc	s1,0x1d
    8000436e:	30648493          	addi	s1,s1,774 # 80021670 <log>
    80004372:	8526                	mv	a0,s1
    80004374:	ffffe097          	auipc	ra,0xffffe
    80004378:	eac080e7          	jalr	-340(ra) # 80002220 <wakeup>
  release(&log.lock);
    8000437c:	8526                	mv	a0,s1
    8000437e:	ffffd097          	auipc	ra,0xffffd
    80004382:	91a080e7          	jalr	-1766(ra) # 80000c98 <release>
  if(do_commit){
    80004386:	b7c9                	j	80004348 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004388:	0001da97          	auipc	s5,0x1d
    8000438c:	318a8a93          	addi	s5,s5,792 # 800216a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004390:	0001da17          	auipc	s4,0x1d
    80004394:	2e0a0a13          	addi	s4,s4,736 # 80021670 <log>
    80004398:	018a2583          	lw	a1,24(s4)
    8000439c:	012585bb          	addw	a1,a1,s2
    800043a0:	2585                	addiw	a1,a1,1
    800043a2:	028a2503          	lw	a0,40(s4)
    800043a6:	fffff097          	auipc	ra,0xfffff
    800043aa:	cd2080e7          	jalr	-814(ra) # 80003078 <bread>
    800043ae:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043b0:	000aa583          	lw	a1,0(s5)
    800043b4:	028a2503          	lw	a0,40(s4)
    800043b8:	fffff097          	auipc	ra,0xfffff
    800043bc:	cc0080e7          	jalr	-832(ra) # 80003078 <bread>
    800043c0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043c2:	40000613          	li	a2,1024
    800043c6:	05850593          	addi	a1,a0,88
    800043ca:	05848513          	addi	a0,s1,88
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	972080e7          	jalr	-1678(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800043d6:	8526                	mv	a0,s1
    800043d8:	fffff097          	auipc	ra,0xfffff
    800043dc:	d92080e7          	jalr	-622(ra) # 8000316a <bwrite>
    brelse(from);
    800043e0:	854e                	mv	a0,s3
    800043e2:	fffff097          	auipc	ra,0xfffff
    800043e6:	dc6080e7          	jalr	-570(ra) # 800031a8 <brelse>
    brelse(to);
    800043ea:	8526                	mv	a0,s1
    800043ec:	fffff097          	auipc	ra,0xfffff
    800043f0:	dbc080e7          	jalr	-580(ra) # 800031a8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043f4:	2905                	addiw	s2,s2,1
    800043f6:	0a91                	addi	s5,s5,4
    800043f8:	02ca2783          	lw	a5,44(s4)
    800043fc:	f8f94ee3          	blt	s2,a5,80004398 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004400:	00000097          	auipc	ra,0x0
    80004404:	c6a080e7          	jalr	-918(ra) # 8000406a <write_head>
    install_trans(0); // Now install writes to home locations
    80004408:	4501                	li	a0,0
    8000440a:	00000097          	auipc	ra,0x0
    8000440e:	cda080e7          	jalr	-806(ra) # 800040e4 <install_trans>
    log.lh.n = 0;
    80004412:	0001d797          	auipc	a5,0x1d
    80004416:	2807a523          	sw	zero,650(a5) # 8002169c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000441a:	00000097          	auipc	ra,0x0
    8000441e:	c50080e7          	jalr	-944(ra) # 8000406a <write_head>
    80004422:	bdf5                	j	8000431e <end_op+0x52>

0000000080004424 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004424:	1101                	addi	sp,sp,-32
    80004426:	ec06                	sd	ra,24(sp)
    80004428:	e822                	sd	s0,16(sp)
    8000442a:	e426                	sd	s1,8(sp)
    8000442c:	e04a                	sd	s2,0(sp)
    8000442e:	1000                	addi	s0,sp,32
    80004430:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004432:	0001d917          	auipc	s2,0x1d
    80004436:	23e90913          	addi	s2,s2,574 # 80021670 <log>
    8000443a:	854a                	mv	a0,s2
    8000443c:	ffffc097          	auipc	ra,0xffffc
    80004440:	7a8080e7          	jalr	1960(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004444:	02c92603          	lw	a2,44(s2)
    80004448:	47f5                	li	a5,29
    8000444a:	06c7c563          	blt	a5,a2,800044b4 <log_write+0x90>
    8000444e:	0001d797          	auipc	a5,0x1d
    80004452:	23e7a783          	lw	a5,574(a5) # 8002168c <log+0x1c>
    80004456:	37fd                	addiw	a5,a5,-1
    80004458:	04f65e63          	bge	a2,a5,800044b4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000445c:	0001d797          	auipc	a5,0x1d
    80004460:	2347a783          	lw	a5,564(a5) # 80021690 <log+0x20>
    80004464:	06f05063          	blez	a5,800044c4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004468:	4781                	li	a5,0
    8000446a:	06c05563          	blez	a2,800044d4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000446e:	44cc                	lw	a1,12(s1)
    80004470:	0001d717          	auipc	a4,0x1d
    80004474:	23070713          	addi	a4,a4,560 # 800216a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004478:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000447a:	4314                	lw	a3,0(a4)
    8000447c:	04b68c63          	beq	a3,a1,800044d4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004480:	2785                	addiw	a5,a5,1
    80004482:	0711                	addi	a4,a4,4
    80004484:	fef61be3          	bne	a2,a5,8000447a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004488:	0621                	addi	a2,a2,8
    8000448a:	060a                	slli	a2,a2,0x2
    8000448c:	0001d797          	auipc	a5,0x1d
    80004490:	1e478793          	addi	a5,a5,484 # 80021670 <log>
    80004494:	963e                	add	a2,a2,a5
    80004496:	44dc                	lw	a5,12(s1)
    80004498:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000449a:	8526                	mv	a0,s1
    8000449c:	fffff097          	auipc	ra,0xfffff
    800044a0:	daa080e7          	jalr	-598(ra) # 80003246 <bpin>
    log.lh.n++;
    800044a4:	0001d717          	auipc	a4,0x1d
    800044a8:	1cc70713          	addi	a4,a4,460 # 80021670 <log>
    800044ac:	575c                	lw	a5,44(a4)
    800044ae:	2785                	addiw	a5,a5,1
    800044b0:	d75c                	sw	a5,44(a4)
    800044b2:	a835                	j	800044ee <log_write+0xca>
    panic("too big a transaction");
    800044b4:	00004517          	auipc	a0,0x4
    800044b8:	18c50513          	addi	a0,a0,396 # 80008640 <syscalls+0x1f8>
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	082080e7          	jalr	130(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800044c4:	00004517          	auipc	a0,0x4
    800044c8:	19450513          	addi	a0,a0,404 # 80008658 <syscalls+0x210>
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	072080e7          	jalr	114(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800044d4:	00878713          	addi	a4,a5,8
    800044d8:	00271693          	slli	a3,a4,0x2
    800044dc:	0001d717          	auipc	a4,0x1d
    800044e0:	19470713          	addi	a4,a4,404 # 80021670 <log>
    800044e4:	9736                	add	a4,a4,a3
    800044e6:	44d4                	lw	a3,12(s1)
    800044e8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044ea:	faf608e3          	beq	a2,a5,8000449a <log_write+0x76>
  }
  release(&log.lock);
    800044ee:	0001d517          	auipc	a0,0x1d
    800044f2:	18250513          	addi	a0,a0,386 # 80021670 <log>
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	7a2080e7          	jalr	1954(ra) # 80000c98 <release>
}
    800044fe:	60e2                	ld	ra,24(sp)
    80004500:	6442                	ld	s0,16(sp)
    80004502:	64a2                	ld	s1,8(sp)
    80004504:	6902                	ld	s2,0(sp)
    80004506:	6105                	addi	sp,sp,32
    80004508:	8082                	ret

000000008000450a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000450a:	1101                	addi	sp,sp,-32
    8000450c:	ec06                	sd	ra,24(sp)
    8000450e:	e822                	sd	s0,16(sp)
    80004510:	e426                	sd	s1,8(sp)
    80004512:	e04a                	sd	s2,0(sp)
    80004514:	1000                	addi	s0,sp,32
    80004516:	84aa                	mv	s1,a0
    80004518:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000451a:	00004597          	auipc	a1,0x4
    8000451e:	15e58593          	addi	a1,a1,350 # 80008678 <syscalls+0x230>
    80004522:	0521                	addi	a0,a0,8
    80004524:	ffffc097          	auipc	ra,0xffffc
    80004528:	630080e7          	jalr	1584(ra) # 80000b54 <initlock>
  lk->name = name;
    8000452c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004530:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004534:	0204a423          	sw	zero,40(s1)
}
    80004538:	60e2                	ld	ra,24(sp)
    8000453a:	6442                	ld	s0,16(sp)
    8000453c:	64a2                	ld	s1,8(sp)
    8000453e:	6902                	ld	s2,0(sp)
    80004540:	6105                	addi	sp,sp,32
    80004542:	8082                	ret

0000000080004544 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004544:	1101                	addi	sp,sp,-32
    80004546:	ec06                	sd	ra,24(sp)
    80004548:	e822                	sd	s0,16(sp)
    8000454a:	e426                	sd	s1,8(sp)
    8000454c:	e04a                	sd	s2,0(sp)
    8000454e:	1000                	addi	s0,sp,32
    80004550:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004552:	00850913          	addi	s2,a0,8
    80004556:	854a                	mv	a0,s2
    80004558:	ffffc097          	auipc	ra,0xffffc
    8000455c:	68c080e7          	jalr	1676(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004560:	409c                	lw	a5,0(s1)
    80004562:	cb89                	beqz	a5,80004574 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004564:	85ca                	mv	a1,s2
    80004566:	8526                	mv	a0,s1
    80004568:	ffffe097          	auipc	ra,0xffffe
    8000456c:	b2c080e7          	jalr	-1236(ra) # 80002094 <sleep>
  while (lk->locked) {
    80004570:	409c                	lw	a5,0(s1)
    80004572:	fbed                	bnez	a5,80004564 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004574:	4785                	li	a5,1
    80004576:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004578:	ffffd097          	auipc	ra,0xffffd
    8000457c:	438080e7          	jalr	1080(ra) # 800019b0 <myproc>
    80004580:	591c                	lw	a5,48(a0)
    80004582:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004584:	854a                	mv	a0,s2
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	712080e7          	jalr	1810(ra) # 80000c98 <release>
}
    8000458e:	60e2                	ld	ra,24(sp)
    80004590:	6442                	ld	s0,16(sp)
    80004592:	64a2                	ld	s1,8(sp)
    80004594:	6902                	ld	s2,0(sp)
    80004596:	6105                	addi	sp,sp,32
    80004598:	8082                	ret

000000008000459a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000459a:	1101                	addi	sp,sp,-32
    8000459c:	ec06                	sd	ra,24(sp)
    8000459e:	e822                	sd	s0,16(sp)
    800045a0:	e426                	sd	s1,8(sp)
    800045a2:	e04a                	sd	s2,0(sp)
    800045a4:	1000                	addi	s0,sp,32
    800045a6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045a8:	00850913          	addi	s2,a0,8
    800045ac:	854a                	mv	a0,s2
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	636080e7          	jalr	1590(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800045b6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045ba:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045be:	8526                	mv	a0,s1
    800045c0:	ffffe097          	auipc	ra,0xffffe
    800045c4:	c60080e7          	jalr	-928(ra) # 80002220 <wakeup>
  release(&lk->lk);
    800045c8:	854a                	mv	a0,s2
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	6ce080e7          	jalr	1742(ra) # 80000c98 <release>
}
    800045d2:	60e2                	ld	ra,24(sp)
    800045d4:	6442                	ld	s0,16(sp)
    800045d6:	64a2                	ld	s1,8(sp)
    800045d8:	6902                	ld	s2,0(sp)
    800045da:	6105                	addi	sp,sp,32
    800045dc:	8082                	ret

00000000800045de <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045de:	7179                	addi	sp,sp,-48
    800045e0:	f406                	sd	ra,40(sp)
    800045e2:	f022                	sd	s0,32(sp)
    800045e4:	ec26                	sd	s1,24(sp)
    800045e6:	e84a                	sd	s2,16(sp)
    800045e8:	e44e                	sd	s3,8(sp)
    800045ea:	1800                	addi	s0,sp,48
    800045ec:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045ee:	00850913          	addi	s2,a0,8
    800045f2:	854a                	mv	a0,s2
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	5f0080e7          	jalr	1520(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045fc:	409c                	lw	a5,0(s1)
    800045fe:	ef99                	bnez	a5,8000461c <holdingsleep+0x3e>
    80004600:	4481                	li	s1,0
  release(&lk->lk);
    80004602:	854a                	mv	a0,s2
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	694080e7          	jalr	1684(ra) # 80000c98 <release>
  return r;
}
    8000460c:	8526                	mv	a0,s1
    8000460e:	70a2                	ld	ra,40(sp)
    80004610:	7402                	ld	s0,32(sp)
    80004612:	64e2                	ld	s1,24(sp)
    80004614:	6942                	ld	s2,16(sp)
    80004616:	69a2                	ld	s3,8(sp)
    80004618:	6145                	addi	sp,sp,48
    8000461a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000461c:	0284a983          	lw	s3,40(s1)
    80004620:	ffffd097          	auipc	ra,0xffffd
    80004624:	390080e7          	jalr	912(ra) # 800019b0 <myproc>
    80004628:	5904                	lw	s1,48(a0)
    8000462a:	413484b3          	sub	s1,s1,s3
    8000462e:	0014b493          	seqz	s1,s1
    80004632:	bfc1                	j	80004602 <holdingsleep+0x24>

0000000080004634 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004634:	1141                	addi	sp,sp,-16
    80004636:	e406                	sd	ra,8(sp)
    80004638:	e022                	sd	s0,0(sp)
    8000463a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000463c:	00004597          	auipc	a1,0x4
    80004640:	04c58593          	addi	a1,a1,76 # 80008688 <syscalls+0x240>
    80004644:	0001d517          	auipc	a0,0x1d
    80004648:	17450513          	addi	a0,a0,372 # 800217b8 <ftable>
    8000464c:	ffffc097          	auipc	ra,0xffffc
    80004650:	508080e7          	jalr	1288(ra) # 80000b54 <initlock>
}
    80004654:	60a2                	ld	ra,8(sp)
    80004656:	6402                	ld	s0,0(sp)
    80004658:	0141                	addi	sp,sp,16
    8000465a:	8082                	ret

000000008000465c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000465c:	1101                	addi	sp,sp,-32
    8000465e:	ec06                	sd	ra,24(sp)
    80004660:	e822                	sd	s0,16(sp)
    80004662:	e426                	sd	s1,8(sp)
    80004664:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004666:	0001d517          	auipc	a0,0x1d
    8000466a:	15250513          	addi	a0,a0,338 # 800217b8 <ftable>
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	576080e7          	jalr	1398(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004676:	0001d497          	auipc	s1,0x1d
    8000467a:	15a48493          	addi	s1,s1,346 # 800217d0 <ftable+0x18>
    8000467e:	0001e717          	auipc	a4,0x1e
    80004682:	0f270713          	addi	a4,a4,242 # 80022770 <ftable+0xfb8>
    if(f->ref == 0){
    80004686:	40dc                	lw	a5,4(s1)
    80004688:	cf99                	beqz	a5,800046a6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000468a:	02848493          	addi	s1,s1,40
    8000468e:	fee49ce3          	bne	s1,a4,80004686 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004692:	0001d517          	auipc	a0,0x1d
    80004696:	12650513          	addi	a0,a0,294 # 800217b8 <ftable>
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	5fe080e7          	jalr	1534(ra) # 80000c98 <release>
  return 0;
    800046a2:	4481                	li	s1,0
    800046a4:	a819                	j	800046ba <filealloc+0x5e>
      f->ref = 1;
    800046a6:	4785                	li	a5,1
    800046a8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046aa:	0001d517          	auipc	a0,0x1d
    800046ae:	10e50513          	addi	a0,a0,270 # 800217b8 <ftable>
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	5e6080e7          	jalr	1510(ra) # 80000c98 <release>
}
    800046ba:	8526                	mv	a0,s1
    800046bc:	60e2                	ld	ra,24(sp)
    800046be:	6442                	ld	s0,16(sp)
    800046c0:	64a2                	ld	s1,8(sp)
    800046c2:	6105                	addi	sp,sp,32
    800046c4:	8082                	ret

00000000800046c6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046c6:	1101                	addi	sp,sp,-32
    800046c8:	ec06                	sd	ra,24(sp)
    800046ca:	e822                	sd	s0,16(sp)
    800046cc:	e426                	sd	s1,8(sp)
    800046ce:	1000                	addi	s0,sp,32
    800046d0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046d2:	0001d517          	auipc	a0,0x1d
    800046d6:	0e650513          	addi	a0,a0,230 # 800217b8 <ftable>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	50a080e7          	jalr	1290(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800046e2:	40dc                	lw	a5,4(s1)
    800046e4:	02f05263          	blez	a5,80004708 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046e8:	2785                	addiw	a5,a5,1
    800046ea:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046ec:	0001d517          	auipc	a0,0x1d
    800046f0:	0cc50513          	addi	a0,a0,204 # 800217b8 <ftable>
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	5a4080e7          	jalr	1444(ra) # 80000c98 <release>
  return f;
}
    800046fc:	8526                	mv	a0,s1
    800046fe:	60e2                	ld	ra,24(sp)
    80004700:	6442                	ld	s0,16(sp)
    80004702:	64a2                	ld	s1,8(sp)
    80004704:	6105                	addi	sp,sp,32
    80004706:	8082                	ret
    panic("filedup");
    80004708:	00004517          	auipc	a0,0x4
    8000470c:	f8850513          	addi	a0,a0,-120 # 80008690 <syscalls+0x248>
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	e2e080e7          	jalr	-466(ra) # 8000053e <panic>

0000000080004718 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004718:	7139                	addi	sp,sp,-64
    8000471a:	fc06                	sd	ra,56(sp)
    8000471c:	f822                	sd	s0,48(sp)
    8000471e:	f426                	sd	s1,40(sp)
    80004720:	f04a                	sd	s2,32(sp)
    80004722:	ec4e                	sd	s3,24(sp)
    80004724:	e852                	sd	s4,16(sp)
    80004726:	e456                	sd	s5,8(sp)
    80004728:	0080                	addi	s0,sp,64
    8000472a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000472c:	0001d517          	auipc	a0,0x1d
    80004730:	08c50513          	addi	a0,a0,140 # 800217b8 <ftable>
    80004734:	ffffc097          	auipc	ra,0xffffc
    80004738:	4b0080e7          	jalr	1200(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000473c:	40dc                	lw	a5,4(s1)
    8000473e:	06f05163          	blez	a5,800047a0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004742:	37fd                	addiw	a5,a5,-1
    80004744:	0007871b          	sext.w	a4,a5
    80004748:	c0dc                	sw	a5,4(s1)
    8000474a:	06e04363          	bgtz	a4,800047b0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000474e:	0004a903          	lw	s2,0(s1)
    80004752:	0094ca83          	lbu	s5,9(s1)
    80004756:	0104ba03          	ld	s4,16(s1)
    8000475a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000475e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004762:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004766:	0001d517          	auipc	a0,0x1d
    8000476a:	05250513          	addi	a0,a0,82 # 800217b8 <ftable>
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	52a080e7          	jalr	1322(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004776:	4785                	li	a5,1
    80004778:	04f90d63          	beq	s2,a5,800047d2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000477c:	3979                	addiw	s2,s2,-2
    8000477e:	4785                	li	a5,1
    80004780:	0527e063          	bltu	a5,s2,800047c0 <fileclose+0xa8>
    begin_op();
    80004784:	00000097          	auipc	ra,0x0
    80004788:	ac8080e7          	jalr	-1336(ra) # 8000424c <begin_op>
    iput(ff.ip);
    8000478c:	854e                	mv	a0,s3
    8000478e:	fffff097          	auipc	ra,0xfffff
    80004792:	2a6080e7          	jalr	678(ra) # 80003a34 <iput>
    end_op();
    80004796:	00000097          	auipc	ra,0x0
    8000479a:	b36080e7          	jalr	-1226(ra) # 800042cc <end_op>
    8000479e:	a00d                	j	800047c0 <fileclose+0xa8>
    panic("fileclose");
    800047a0:	00004517          	auipc	a0,0x4
    800047a4:	ef850513          	addi	a0,a0,-264 # 80008698 <syscalls+0x250>
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	d96080e7          	jalr	-618(ra) # 8000053e <panic>
    release(&ftable.lock);
    800047b0:	0001d517          	auipc	a0,0x1d
    800047b4:	00850513          	addi	a0,a0,8 # 800217b8 <ftable>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	4e0080e7          	jalr	1248(ra) # 80000c98 <release>
  }
}
    800047c0:	70e2                	ld	ra,56(sp)
    800047c2:	7442                	ld	s0,48(sp)
    800047c4:	74a2                	ld	s1,40(sp)
    800047c6:	7902                	ld	s2,32(sp)
    800047c8:	69e2                	ld	s3,24(sp)
    800047ca:	6a42                	ld	s4,16(sp)
    800047cc:	6aa2                	ld	s5,8(sp)
    800047ce:	6121                	addi	sp,sp,64
    800047d0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047d2:	85d6                	mv	a1,s5
    800047d4:	8552                	mv	a0,s4
    800047d6:	00000097          	auipc	ra,0x0
    800047da:	34c080e7          	jalr	844(ra) # 80004b22 <pipeclose>
    800047de:	b7cd                	j	800047c0 <fileclose+0xa8>

00000000800047e0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047e0:	715d                	addi	sp,sp,-80
    800047e2:	e486                	sd	ra,72(sp)
    800047e4:	e0a2                	sd	s0,64(sp)
    800047e6:	fc26                	sd	s1,56(sp)
    800047e8:	f84a                	sd	s2,48(sp)
    800047ea:	f44e                	sd	s3,40(sp)
    800047ec:	0880                	addi	s0,sp,80
    800047ee:	84aa                	mv	s1,a0
    800047f0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047f2:	ffffd097          	auipc	ra,0xffffd
    800047f6:	1be080e7          	jalr	446(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047fa:	409c                	lw	a5,0(s1)
    800047fc:	37f9                	addiw	a5,a5,-2
    800047fe:	4705                	li	a4,1
    80004800:	04f76763          	bltu	a4,a5,8000484e <filestat+0x6e>
    80004804:	892a                	mv	s2,a0
    ilock(f->ip);
    80004806:	6c88                	ld	a0,24(s1)
    80004808:	fffff097          	auipc	ra,0xfffff
    8000480c:	072080e7          	jalr	114(ra) # 8000387a <ilock>
    stati(f->ip, &st);
    80004810:	fb840593          	addi	a1,s0,-72
    80004814:	6c88                	ld	a0,24(s1)
    80004816:	fffff097          	auipc	ra,0xfffff
    8000481a:	2ee080e7          	jalr	750(ra) # 80003b04 <stati>
    iunlock(f->ip);
    8000481e:	6c88                	ld	a0,24(s1)
    80004820:	fffff097          	auipc	ra,0xfffff
    80004824:	11c080e7          	jalr	284(ra) # 8000393c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004828:	46e1                	li	a3,24
    8000482a:	fb840613          	addi	a2,s0,-72
    8000482e:	85ce                	mv	a1,s3
    80004830:	05093503          	ld	a0,80(s2)
    80004834:	ffffd097          	auipc	ra,0xffffd
    80004838:	e3e080e7          	jalr	-450(ra) # 80001672 <copyout>
    8000483c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004840:	60a6                	ld	ra,72(sp)
    80004842:	6406                	ld	s0,64(sp)
    80004844:	74e2                	ld	s1,56(sp)
    80004846:	7942                	ld	s2,48(sp)
    80004848:	79a2                	ld	s3,40(sp)
    8000484a:	6161                	addi	sp,sp,80
    8000484c:	8082                	ret
  return -1;
    8000484e:	557d                	li	a0,-1
    80004850:	bfc5                	j	80004840 <filestat+0x60>

0000000080004852 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004852:	7179                	addi	sp,sp,-48
    80004854:	f406                	sd	ra,40(sp)
    80004856:	f022                	sd	s0,32(sp)
    80004858:	ec26                	sd	s1,24(sp)
    8000485a:	e84a                	sd	s2,16(sp)
    8000485c:	e44e                	sd	s3,8(sp)
    8000485e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004860:	00854783          	lbu	a5,8(a0)
    80004864:	c3d5                	beqz	a5,80004908 <fileread+0xb6>
    80004866:	84aa                	mv	s1,a0
    80004868:	89ae                	mv	s3,a1
    8000486a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000486c:	411c                	lw	a5,0(a0)
    8000486e:	4705                	li	a4,1
    80004870:	04e78963          	beq	a5,a4,800048c2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004874:	470d                	li	a4,3
    80004876:	04e78d63          	beq	a5,a4,800048d0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000487a:	4709                	li	a4,2
    8000487c:	06e79e63          	bne	a5,a4,800048f8 <fileread+0xa6>
    ilock(f->ip);
    80004880:	6d08                	ld	a0,24(a0)
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	ff8080e7          	jalr	-8(ra) # 8000387a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000488a:	874a                	mv	a4,s2
    8000488c:	5094                	lw	a3,32(s1)
    8000488e:	864e                	mv	a2,s3
    80004890:	4585                	li	a1,1
    80004892:	6c88                	ld	a0,24(s1)
    80004894:	fffff097          	auipc	ra,0xfffff
    80004898:	29a080e7          	jalr	666(ra) # 80003b2e <readi>
    8000489c:	892a                	mv	s2,a0
    8000489e:	00a05563          	blez	a0,800048a8 <fileread+0x56>
      f->off += r;
    800048a2:	509c                	lw	a5,32(s1)
    800048a4:	9fa9                	addw	a5,a5,a0
    800048a6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048a8:	6c88                	ld	a0,24(s1)
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	092080e7          	jalr	146(ra) # 8000393c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048b2:	854a                	mv	a0,s2
    800048b4:	70a2                	ld	ra,40(sp)
    800048b6:	7402                	ld	s0,32(sp)
    800048b8:	64e2                	ld	s1,24(sp)
    800048ba:	6942                	ld	s2,16(sp)
    800048bc:	69a2                	ld	s3,8(sp)
    800048be:	6145                	addi	sp,sp,48
    800048c0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048c2:	6908                	ld	a0,16(a0)
    800048c4:	00000097          	auipc	ra,0x0
    800048c8:	3c8080e7          	jalr	968(ra) # 80004c8c <piperead>
    800048cc:	892a                	mv	s2,a0
    800048ce:	b7d5                	j	800048b2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048d0:	02451783          	lh	a5,36(a0)
    800048d4:	03079693          	slli	a3,a5,0x30
    800048d8:	92c1                	srli	a3,a3,0x30
    800048da:	4725                	li	a4,9
    800048dc:	02d76863          	bltu	a4,a3,8000490c <fileread+0xba>
    800048e0:	0792                	slli	a5,a5,0x4
    800048e2:	0001d717          	auipc	a4,0x1d
    800048e6:	e3670713          	addi	a4,a4,-458 # 80021718 <devsw>
    800048ea:	97ba                	add	a5,a5,a4
    800048ec:	639c                	ld	a5,0(a5)
    800048ee:	c38d                	beqz	a5,80004910 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048f0:	4505                	li	a0,1
    800048f2:	9782                	jalr	a5
    800048f4:	892a                	mv	s2,a0
    800048f6:	bf75                	j	800048b2 <fileread+0x60>
    panic("fileread");
    800048f8:	00004517          	auipc	a0,0x4
    800048fc:	db050513          	addi	a0,a0,-592 # 800086a8 <syscalls+0x260>
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	c3e080e7          	jalr	-962(ra) # 8000053e <panic>
    return -1;
    80004908:	597d                	li	s2,-1
    8000490a:	b765                	j	800048b2 <fileread+0x60>
      return -1;
    8000490c:	597d                	li	s2,-1
    8000490e:	b755                	j	800048b2 <fileread+0x60>
    80004910:	597d                	li	s2,-1
    80004912:	b745                	j	800048b2 <fileread+0x60>

0000000080004914 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004914:	715d                	addi	sp,sp,-80
    80004916:	e486                	sd	ra,72(sp)
    80004918:	e0a2                	sd	s0,64(sp)
    8000491a:	fc26                	sd	s1,56(sp)
    8000491c:	f84a                	sd	s2,48(sp)
    8000491e:	f44e                	sd	s3,40(sp)
    80004920:	f052                	sd	s4,32(sp)
    80004922:	ec56                	sd	s5,24(sp)
    80004924:	e85a                	sd	s6,16(sp)
    80004926:	e45e                	sd	s7,8(sp)
    80004928:	e062                	sd	s8,0(sp)
    8000492a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000492c:	00954783          	lbu	a5,9(a0)
    80004930:	10078663          	beqz	a5,80004a3c <filewrite+0x128>
    80004934:	892a                	mv	s2,a0
    80004936:	8aae                	mv	s5,a1
    80004938:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000493a:	411c                	lw	a5,0(a0)
    8000493c:	4705                	li	a4,1
    8000493e:	02e78263          	beq	a5,a4,80004962 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004942:	470d                	li	a4,3
    80004944:	02e78663          	beq	a5,a4,80004970 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004948:	4709                	li	a4,2
    8000494a:	0ee79163          	bne	a5,a4,80004a2c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000494e:	0ac05d63          	blez	a2,80004a08 <filewrite+0xf4>
    int i = 0;
    80004952:	4981                	li	s3,0
    80004954:	6b05                	lui	s6,0x1
    80004956:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000495a:	6b85                	lui	s7,0x1
    8000495c:	c00b8b9b          	addiw	s7,s7,-1024
    80004960:	a861                	j	800049f8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004962:	6908                	ld	a0,16(a0)
    80004964:	00000097          	auipc	ra,0x0
    80004968:	22e080e7          	jalr	558(ra) # 80004b92 <pipewrite>
    8000496c:	8a2a                	mv	s4,a0
    8000496e:	a045                	j	80004a0e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004970:	02451783          	lh	a5,36(a0)
    80004974:	03079693          	slli	a3,a5,0x30
    80004978:	92c1                	srli	a3,a3,0x30
    8000497a:	4725                	li	a4,9
    8000497c:	0cd76263          	bltu	a4,a3,80004a40 <filewrite+0x12c>
    80004980:	0792                	slli	a5,a5,0x4
    80004982:	0001d717          	auipc	a4,0x1d
    80004986:	d9670713          	addi	a4,a4,-618 # 80021718 <devsw>
    8000498a:	97ba                	add	a5,a5,a4
    8000498c:	679c                	ld	a5,8(a5)
    8000498e:	cbdd                	beqz	a5,80004a44 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004990:	4505                	li	a0,1
    80004992:	9782                	jalr	a5
    80004994:	8a2a                	mv	s4,a0
    80004996:	a8a5                	j	80004a0e <filewrite+0xfa>
    80004998:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000499c:	00000097          	auipc	ra,0x0
    800049a0:	8b0080e7          	jalr	-1872(ra) # 8000424c <begin_op>
      ilock(f->ip);
    800049a4:	01893503          	ld	a0,24(s2)
    800049a8:	fffff097          	auipc	ra,0xfffff
    800049ac:	ed2080e7          	jalr	-302(ra) # 8000387a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049b0:	8762                	mv	a4,s8
    800049b2:	02092683          	lw	a3,32(s2)
    800049b6:	01598633          	add	a2,s3,s5
    800049ba:	4585                	li	a1,1
    800049bc:	01893503          	ld	a0,24(s2)
    800049c0:	fffff097          	auipc	ra,0xfffff
    800049c4:	266080e7          	jalr	614(ra) # 80003c26 <writei>
    800049c8:	84aa                	mv	s1,a0
    800049ca:	00a05763          	blez	a0,800049d8 <filewrite+0xc4>
        f->off += r;
    800049ce:	02092783          	lw	a5,32(s2)
    800049d2:	9fa9                	addw	a5,a5,a0
    800049d4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049d8:	01893503          	ld	a0,24(s2)
    800049dc:	fffff097          	auipc	ra,0xfffff
    800049e0:	f60080e7          	jalr	-160(ra) # 8000393c <iunlock>
      end_op();
    800049e4:	00000097          	auipc	ra,0x0
    800049e8:	8e8080e7          	jalr	-1816(ra) # 800042cc <end_op>

      if(r != n1){
    800049ec:	009c1f63          	bne	s8,s1,80004a0a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049f0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049f4:	0149db63          	bge	s3,s4,80004a0a <filewrite+0xf6>
      int n1 = n - i;
    800049f8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049fc:	84be                	mv	s1,a5
    800049fe:	2781                	sext.w	a5,a5
    80004a00:	f8fb5ce3          	bge	s6,a5,80004998 <filewrite+0x84>
    80004a04:	84de                	mv	s1,s7
    80004a06:	bf49                	j	80004998 <filewrite+0x84>
    int i = 0;
    80004a08:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a0a:	013a1f63          	bne	s4,s3,80004a28 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a0e:	8552                	mv	a0,s4
    80004a10:	60a6                	ld	ra,72(sp)
    80004a12:	6406                	ld	s0,64(sp)
    80004a14:	74e2                	ld	s1,56(sp)
    80004a16:	7942                	ld	s2,48(sp)
    80004a18:	79a2                	ld	s3,40(sp)
    80004a1a:	7a02                	ld	s4,32(sp)
    80004a1c:	6ae2                	ld	s5,24(sp)
    80004a1e:	6b42                	ld	s6,16(sp)
    80004a20:	6ba2                	ld	s7,8(sp)
    80004a22:	6c02                	ld	s8,0(sp)
    80004a24:	6161                	addi	sp,sp,80
    80004a26:	8082                	ret
    ret = (i == n ? n : -1);
    80004a28:	5a7d                	li	s4,-1
    80004a2a:	b7d5                	j	80004a0e <filewrite+0xfa>
    panic("filewrite");
    80004a2c:	00004517          	auipc	a0,0x4
    80004a30:	c8c50513          	addi	a0,a0,-884 # 800086b8 <syscalls+0x270>
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	b0a080e7          	jalr	-1270(ra) # 8000053e <panic>
    return -1;
    80004a3c:	5a7d                	li	s4,-1
    80004a3e:	bfc1                	j	80004a0e <filewrite+0xfa>
      return -1;
    80004a40:	5a7d                	li	s4,-1
    80004a42:	b7f1                	j	80004a0e <filewrite+0xfa>
    80004a44:	5a7d                	li	s4,-1
    80004a46:	b7e1                	j	80004a0e <filewrite+0xfa>

0000000080004a48 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a48:	7179                	addi	sp,sp,-48
    80004a4a:	f406                	sd	ra,40(sp)
    80004a4c:	f022                	sd	s0,32(sp)
    80004a4e:	ec26                	sd	s1,24(sp)
    80004a50:	e84a                	sd	s2,16(sp)
    80004a52:	e44e                	sd	s3,8(sp)
    80004a54:	e052                	sd	s4,0(sp)
    80004a56:	1800                	addi	s0,sp,48
    80004a58:	84aa                	mv	s1,a0
    80004a5a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a5c:	0005b023          	sd	zero,0(a1)
    80004a60:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a64:	00000097          	auipc	ra,0x0
    80004a68:	bf8080e7          	jalr	-1032(ra) # 8000465c <filealloc>
    80004a6c:	e088                	sd	a0,0(s1)
    80004a6e:	c551                	beqz	a0,80004afa <pipealloc+0xb2>
    80004a70:	00000097          	auipc	ra,0x0
    80004a74:	bec080e7          	jalr	-1044(ra) # 8000465c <filealloc>
    80004a78:	00aa3023          	sd	a0,0(s4)
    80004a7c:	c92d                	beqz	a0,80004aee <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	076080e7          	jalr	118(ra) # 80000af4 <kalloc>
    80004a86:	892a                	mv	s2,a0
    80004a88:	c125                	beqz	a0,80004ae8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a8a:	4985                	li	s3,1
    80004a8c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a90:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a94:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a98:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a9c:	00004597          	auipc	a1,0x4
    80004aa0:	c2c58593          	addi	a1,a1,-980 # 800086c8 <syscalls+0x280>
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	0b0080e7          	jalr	176(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004aac:	609c                	ld	a5,0(s1)
    80004aae:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ab2:	609c                	ld	a5,0(s1)
    80004ab4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ab8:	609c                	ld	a5,0(s1)
    80004aba:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004abe:	609c                	ld	a5,0(s1)
    80004ac0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ac4:	000a3783          	ld	a5,0(s4)
    80004ac8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004acc:	000a3783          	ld	a5,0(s4)
    80004ad0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ad4:	000a3783          	ld	a5,0(s4)
    80004ad8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004adc:	000a3783          	ld	a5,0(s4)
    80004ae0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ae4:	4501                	li	a0,0
    80004ae6:	a025                	j	80004b0e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ae8:	6088                	ld	a0,0(s1)
    80004aea:	e501                	bnez	a0,80004af2 <pipealloc+0xaa>
    80004aec:	a039                	j	80004afa <pipealloc+0xb2>
    80004aee:	6088                	ld	a0,0(s1)
    80004af0:	c51d                	beqz	a0,80004b1e <pipealloc+0xd6>
    fileclose(*f0);
    80004af2:	00000097          	auipc	ra,0x0
    80004af6:	c26080e7          	jalr	-986(ra) # 80004718 <fileclose>
  if(*f1)
    80004afa:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004afe:	557d                	li	a0,-1
  if(*f1)
    80004b00:	c799                	beqz	a5,80004b0e <pipealloc+0xc6>
    fileclose(*f1);
    80004b02:	853e                	mv	a0,a5
    80004b04:	00000097          	auipc	ra,0x0
    80004b08:	c14080e7          	jalr	-1004(ra) # 80004718 <fileclose>
  return -1;
    80004b0c:	557d                	li	a0,-1
}
    80004b0e:	70a2                	ld	ra,40(sp)
    80004b10:	7402                	ld	s0,32(sp)
    80004b12:	64e2                	ld	s1,24(sp)
    80004b14:	6942                	ld	s2,16(sp)
    80004b16:	69a2                	ld	s3,8(sp)
    80004b18:	6a02                	ld	s4,0(sp)
    80004b1a:	6145                	addi	sp,sp,48
    80004b1c:	8082                	ret
  return -1;
    80004b1e:	557d                	li	a0,-1
    80004b20:	b7fd                	j	80004b0e <pipealloc+0xc6>

0000000080004b22 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b22:	1101                	addi	sp,sp,-32
    80004b24:	ec06                	sd	ra,24(sp)
    80004b26:	e822                	sd	s0,16(sp)
    80004b28:	e426                	sd	s1,8(sp)
    80004b2a:	e04a                	sd	s2,0(sp)
    80004b2c:	1000                	addi	s0,sp,32
    80004b2e:	84aa                	mv	s1,a0
    80004b30:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	0b2080e7          	jalr	178(ra) # 80000be4 <acquire>
  if(writable){
    80004b3a:	02090d63          	beqz	s2,80004b74 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b3e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b42:	21848513          	addi	a0,s1,536
    80004b46:	ffffd097          	auipc	ra,0xffffd
    80004b4a:	6da080e7          	jalr	1754(ra) # 80002220 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b4e:	2204b783          	ld	a5,544(s1)
    80004b52:	eb95                	bnez	a5,80004b86 <pipeclose+0x64>
    release(&pi->lock);
    80004b54:	8526                	mv	a0,s1
    80004b56:	ffffc097          	auipc	ra,0xffffc
    80004b5a:	142080e7          	jalr	322(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b5e:	8526                	mv	a0,s1
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	e98080e7          	jalr	-360(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004b68:	60e2                	ld	ra,24(sp)
    80004b6a:	6442                	ld	s0,16(sp)
    80004b6c:	64a2                	ld	s1,8(sp)
    80004b6e:	6902                	ld	s2,0(sp)
    80004b70:	6105                	addi	sp,sp,32
    80004b72:	8082                	ret
    pi->readopen = 0;
    80004b74:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b78:	21c48513          	addi	a0,s1,540
    80004b7c:	ffffd097          	auipc	ra,0xffffd
    80004b80:	6a4080e7          	jalr	1700(ra) # 80002220 <wakeup>
    80004b84:	b7e9                	j	80004b4e <pipeclose+0x2c>
    release(&pi->lock);
    80004b86:	8526                	mv	a0,s1
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	110080e7          	jalr	272(ra) # 80000c98 <release>
}
    80004b90:	bfe1                	j	80004b68 <pipeclose+0x46>

0000000080004b92 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b92:	7159                	addi	sp,sp,-112
    80004b94:	f486                	sd	ra,104(sp)
    80004b96:	f0a2                	sd	s0,96(sp)
    80004b98:	eca6                	sd	s1,88(sp)
    80004b9a:	e8ca                	sd	s2,80(sp)
    80004b9c:	e4ce                	sd	s3,72(sp)
    80004b9e:	e0d2                	sd	s4,64(sp)
    80004ba0:	fc56                	sd	s5,56(sp)
    80004ba2:	f85a                	sd	s6,48(sp)
    80004ba4:	f45e                	sd	s7,40(sp)
    80004ba6:	f062                	sd	s8,32(sp)
    80004ba8:	ec66                	sd	s9,24(sp)
    80004baa:	1880                	addi	s0,sp,112
    80004bac:	84aa                	mv	s1,a0
    80004bae:	8aae                	mv	s5,a1
    80004bb0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bb2:	ffffd097          	auipc	ra,0xffffd
    80004bb6:	dfe080e7          	jalr	-514(ra) # 800019b0 <myproc>
    80004bba:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bbc:	8526                	mv	a0,s1
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	026080e7          	jalr	38(ra) # 80000be4 <acquire>
  while(i < n){
    80004bc6:	0d405163          	blez	s4,80004c88 <pipewrite+0xf6>
    80004bca:	8ba6                	mv	s7,s1
  int i = 0;
    80004bcc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bce:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bd0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bd4:	21c48c13          	addi	s8,s1,540
    80004bd8:	a08d                	j	80004c3a <pipewrite+0xa8>
      release(&pi->lock);
    80004bda:	8526                	mv	a0,s1
    80004bdc:	ffffc097          	auipc	ra,0xffffc
    80004be0:	0bc080e7          	jalr	188(ra) # 80000c98 <release>
      return -1;
    80004be4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004be6:	854a                	mv	a0,s2
    80004be8:	70a6                	ld	ra,104(sp)
    80004bea:	7406                	ld	s0,96(sp)
    80004bec:	64e6                	ld	s1,88(sp)
    80004bee:	6946                	ld	s2,80(sp)
    80004bf0:	69a6                	ld	s3,72(sp)
    80004bf2:	6a06                	ld	s4,64(sp)
    80004bf4:	7ae2                	ld	s5,56(sp)
    80004bf6:	7b42                	ld	s6,48(sp)
    80004bf8:	7ba2                	ld	s7,40(sp)
    80004bfa:	7c02                	ld	s8,32(sp)
    80004bfc:	6ce2                	ld	s9,24(sp)
    80004bfe:	6165                	addi	sp,sp,112
    80004c00:	8082                	ret
      wakeup(&pi->nread);
    80004c02:	8566                	mv	a0,s9
    80004c04:	ffffd097          	auipc	ra,0xffffd
    80004c08:	61c080e7          	jalr	1564(ra) # 80002220 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c0c:	85de                	mv	a1,s7
    80004c0e:	8562                	mv	a0,s8
    80004c10:	ffffd097          	auipc	ra,0xffffd
    80004c14:	484080e7          	jalr	1156(ra) # 80002094 <sleep>
    80004c18:	a839                	j	80004c36 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c1a:	21c4a783          	lw	a5,540(s1)
    80004c1e:	0017871b          	addiw	a4,a5,1
    80004c22:	20e4ae23          	sw	a4,540(s1)
    80004c26:	1ff7f793          	andi	a5,a5,511
    80004c2a:	97a6                	add	a5,a5,s1
    80004c2c:	f9f44703          	lbu	a4,-97(s0)
    80004c30:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c34:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c36:	03495d63          	bge	s2,s4,80004c70 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c3a:	2204a783          	lw	a5,544(s1)
    80004c3e:	dfd1                	beqz	a5,80004bda <pipewrite+0x48>
    80004c40:	0289a783          	lw	a5,40(s3)
    80004c44:	fbd9                	bnez	a5,80004bda <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c46:	2184a783          	lw	a5,536(s1)
    80004c4a:	21c4a703          	lw	a4,540(s1)
    80004c4e:	2007879b          	addiw	a5,a5,512
    80004c52:	faf708e3          	beq	a4,a5,80004c02 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c56:	4685                	li	a3,1
    80004c58:	01590633          	add	a2,s2,s5
    80004c5c:	f9f40593          	addi	a1,s0,-97
    80004c60:	0509b503          	ld	a0,80(s3)
    80004c64:	ffffd097          	auipc	ra,0xffffd
    80004c68:	a9a080e7          	jalr	-1382(ra) # 800016fe <copyin>
    80004c6c:	fb6517e3          	bne	a0,s6,80004c1a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c70:	21848513          	addi	a0,s1,536
    80004c74:	ffffd097          	auipc	ra,0xffffd
    80004c78:	5ac080e7          	jalr	1452(ra) # 80002220 <wakeup>
  release(&pi->lock);
    80004c7c:	8526                	mv	a0,s1
    80004c7e:	ffffc097          	auipc	ra,0xffffc
    80004c82:	01a080e7          	jalr	26(ra) # 80000c98 <release>
  return i;
    80004c86:	b785                	j	80004be6 <pipewrite+0x54>
  int i = 0;
    80004c88:	4901                	li	s2,0
    80004c8a:	b7dd                	j	80004c70 <pipewrite+0xde>

0000000080004c8c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c8c:	715d                	addi	sp,sp,-80
    80004c8e:	e486                	sd	ra,72(sp)
    80004c90:	e0a2                	sd	s0,64(sp)
    80004c92:	fc26                	sd	s1,56(sp)
    80004c94:	f84a                	sd	s2,48(sp)
    80004c96:	f44e                	sd	s3,40(sp)
    80004c98:	f052                	sd	s4,32(sp)
    80004c9a:	ec56                	sd	s5,24(sp)
    80004c9c:	e85a                	sd	s6,16(sp)
    80004c9e:	0880                	addi	s0,sp,80
    80004ca0:	84aa                	mv	s1,a0
    80004ca2:	892e                	mv	s2,a1
    80004ca4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ca6:	ffffd097          	auipc	ra,0xffffd
    80004caa:	d0a080e7          	jalr	-758(ra) # 800019b0 <myproc>
    80004cae:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cb0:	8b26                	mv	s6,s1
    80004cb2:	8526                	mv	a0,s1
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	f30080e7          	jalr	-208(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cbc:	2184a703          	lw	a4,536(s1)
    80004cc0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cc4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cc8:	02f71463          	bne	a4,a5,80004cf0 <piperead+0x64>
    80004ccc:	2244a783          	lw	a5,548(s1)
    80004cd0:	c385                	beqz	a5,80004cf0 <piperead+0x64>
    if(pr->killed){
    80004cd2:	028a2783          	lw	a5,40(s4)
    80004cd6:	ebc1                	bnez	a5,80004d66 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cd8:	85da                	mv	a1,s6
    80004cda:	854e                	mv	a0,s3
    80004cdc:	ffffd097          	auipc	ra,0xffffd
    80004ce0:	3b8080e7          	jalr	952(ra) # 80002094 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ce4:	2184a703          	lw	a4,536(s1)
    80004ce8:	21c4a783          	lw	a5,540(s1)
    80004cec:	fef700e3          	beq	a4,a5,80004ccc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cf0:	09505263          	blez	s5,80004d74 <piperead+0xe8>
    80004cf4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cf6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004cf8:	2184a783          	lw	a5,536(s1)
    80004cfc:	21c4a703          	lw	a4,540(s1)
    80004d00:	02f70d63          	beq	a4,a5,80004d3a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d04:	0017871b          	addiw	a4,a5,1
    80004d08:	20e4ac23          	sw	a4,536(s1)
    80004d0c:	1ff7f793          	andi	a5,a5,511
    80004d10:	97a6                	add	a5,a5,s1
    80004d12:	0187c783          	lbu	a5,24(a5)
    80004d16:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d1a:	4685                	li	a3,1
    80004d1c:	fbf40613          	addi	a2,s0,-65
    80004d20:	85ca                	mv	a1,s2
    80004d22:	050a3503          	ld	a0,80(s4)
    80004d26:	ffffd097          	auipc	ra,0xffffd
    80004d2a:	94c080e7          	jalr	-1716(ra) # 80001672 <copyout>
    80004d2e:	01650663          	beq	a0,s6,80004d3a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d32:	2985                	addiw	s3,s3,1
    80004d34:	0905                	addi	s2,s2,1
    80004d36:	fd3a91e3          	bne	s5,s3,80004cf8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d3a:	21c48513          	addi	a0,s1,540
    80004d3e:	ffffd097          	auipc	ra,0xffffd
    80004d42:	4e2080e7          	jalr	1250(ra) # 80002220 <wakeup>
  release(&pi->lock);
    80004d46:	8526                	mv	a0,s1
    80004d48:	ffffc097          	auipc	ra,0xffffc
    80004d4c:	f50080e7          	jalr	-176(ra) # 80000c98 <release>
  return i;
}
    80004d50:	854e                	mv	a0,s3
    80004d52:	60a6                	ld	ra,72(sp)
    80004d54:	6406                	ld	s0,64(sp)
    80004d56:	74e2                	ld	s1,56(sp)
    80004d58:	7942                	ld	s2,48(sp)
    80004d5a:	79a2                	ld	s3,40(sp)
    80004d5c:	7a02                	ld	s4,32(sp)
    80004d5e:	6ae2                	ld	s5,24(sp)
    80004d60:	6b42                	ld	s6,16(sp)
    80004d62:	6161                	addi	sp,sp,80
    80004d64:	8082                	ret
      release(&pi->lock);
    80004d66:	8526                	mv	a0,s1
    80004d68:	ffffc097          	auipc	ra,0xffffc
    80004d6c:	f30080e7          	jalr	-208(ra) # 80000c98 <release>
      return -1;
    80004d70:	59fd                	li	s3,-1
    80004d72:	bff9                	j	80004d50 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d74:	4981                	li	s3,0
    80004d76:	b7d1                	j	80004d3a <piperead+0xae>

0000000080004d78 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d78:	df010113          	addi	sp,sp,-528
    80004d7c:	20113423          	sd	ra,520(sp)
    80004d80:	20813023          	sd	s0,512(sp)
    80004d84:	ffa6                	sd	s1,504(sp)
    80004d86:	fbca                	sd	s2,496(sp)
    80004d88:	f7ce                	sd	s3,488(sp)
    80004d8a:	f3d2                	sd	s4,480(sp)
    80004d8c:	efd6                	sd	s5,472(sp)
    80004d8e:	ebda                	sd	s6,464(sp)
    80004d90:	e7de                	sd	s7,456(sp)
    80004d92:	e3e2                	sd	s8,448(sp)
    80004d94:	ff66                	sd	s9,440(sp)
    80004d96:	fb6a                	sd	s10,432(sp)
    80004d98:	f76e                	sd	s11,424(sp)
    80004d9a:	0c00                	addi	s0,sp,528
    80004d9c:	84aa                	mv	s1,a0
    80004d9e:	dea43c23          	sd	a0,-520(s0)
    80004da2:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004da6:	ffffd097          	auipc	ra,0xffffd
    80004daa:	c0a080e7          	jalr	-1014(ra) # 800019b0 <myproc>
    80004dae:	892a                	mv	s2,a0

  begin_op();
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	49c080e7          	jalr	1180(ra) # 8000424c <begin_op>

  if((ip = namei(path)) == 0){
    80004db8:	8526                	mv	a0,s1
    80004dba:	fffff097          	auipc	ra,0xfffff
    80004dbe:	276080e7          	jalr	630(ra) # 80004030 <namei>
    80004dc2:	c92d                	beqz	a0,80004e34 <exec+0xbc>
    80004dc4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004dc6:	fffff097          	auipc	ra,0xfffff
    80004dca:	ab4080e7          	jalr	-1356(ra) # 8000387a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dce:	04000713          	li	a4,64
    80004dd2:	4681                	li	a3,0
    80004dd4:	e5040613          	addi	a2,s0,-432
    80004dd8:	4581                	li	a1,0
    80004dda:	8526                	mv	a0,s1
    80004ddc:	fffff097          	auipc	ra,0xfffff
    80004de0:	d52080e7          	jalr	-686(ra) # 80003b2e <readi>
    80004de4:	04000793          	li	a5,64
    80004de8:	00f51a63          	bne	a0,a5,80004dfc <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004dec:	e5042703          	lw	a4,-432(s0)
    80004df0:	464c47b7          	lui	a5,0x464c4
    80004df4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004df8:	04f70463          	beq	a4,a5,80004e40 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dfc:	8526                	mv	a0,s1
    80004dfe:	fffff097          	auipc	ra,0xfffff
    80004e02:	cde080e7          	jalr	-802(ra) # 80003adc <iunlockput>
    end_op();
    80004e06:	fffff097          	auipc	ra,0xfffff
    80004e0a:	4c6080e7          	jalr	1222(ra) # 800042cc <end_op>
  }
  return -1;
    80004e0e:	557d                	li	a0,-1
}
    80004e10:	20813083          	ld	ra,520(sp)
    80004e14:	20013403          	ld	s0,512(sp)
    80004e18:	74fe                	ld	s1,504(sp)
    80004e1a:	795e                	ld	s2,496(sp)
    80004e1c:	79be                	ld	s3,488(sp)
    80004e1e:	7a1e                	ld	s4,480(sp)
    80004e20:	6afe                	ld	s5,472(sp)
    80004e22:	6b5e                	ld	s6,464(sp)
    80004e24:	6bbe                	ld	s7,456(sp)
    80004e26:	6c1e                	ld	s8,448(sp)
    80004e28:	7cfa                	ld	s9,440(sp)
    80004e2a:	7d5a                	ld	s10,432(sp)
    80004e2c:	7dba                	ld	s11,424(sp)
    80004e2e:	21010113          	addi	sp,sp,528
    80004e32:	8082                	ret
    end_op();
    80004e34:	fffff097          	auipc	ra,0xfffff
    80004e38:	498080e7          	jalr	1176(ra) # 800042cc <end_op>
    return -1;
    80004e3c:	557d                	li	a0,-1
    80004e3e:	bfc9                	j	80004e10 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e40:	854a                	mv	a0,s2
    80004e42:	ffffd097          	auipc	ra,0xffffd
    80004e46:	c32080e7          	jalr	-974(ra) # 80001a74 <proc_pagetable>
    80004e4a:	8baa                	mv	s7,a0
    80004e4c:	d945                	beqz	a0,80004dfc <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e4e:	e7042983          	lw	s3,-400(s0)
    80004e52:	e8845783          	lhu	a5,-376(s0)
    80004e56:	c7ad                	beqz	a5,80004ec0 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e58:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e5a:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e5c:	6c85                	lui	s9,0x1
    80004e5e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e62:	def43823          	sd	a5,-528(s0)
    80004e66:	a42d                	j	80005090 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e68:	00004517          	auipc	a0,0x4
    80004e6c:	86850513          	addi	a0,a0,-1944 # 800086d0 <syscalls+0x288>
    80004e70:	ffffb097          	auipc	ra,0xffffb
    80004e74:	6ce080e7          	jalr	1742(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e78:	8756                	mv	a4,s5
    80004e7a:	012d86bb          	addw	a3,s11,s2
    80004e7e:	4581                	li	a1,0
    80004e80:	8526                	mv	a0,s1
    80004e82:	fffff097          	auipc	ra,0xfffff
    80004e86:	cac080e7          	jalr	-852(ra) # 80003b2e <readi>
    80004e8a:	2501                	sext.w	a0,a0
    80004e8c:	1aaa9963          	bne	s5,a0,8000503e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e90:	6785                	lui	a5,0x1
    80004e92:	0127893b          	addw	s2,a5,s2
    80004e96:	77fd                	lui	a5,0xfffff
    80004e98:	01478a3b          	addw	s4,a5,s4
    80004e9c:	1f897163          	bgeu	s2,s8,8000507e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004ea0:	02091593          	slli	a1,s2,0x20
    80004ea4:	9181                	srli	a1,a1,0x20
    80004ea6:	95ea                	add	a1,a1,s10
    80004ea8:	855e                	mv	a0,s7
    80004eaa:	ffffc097          	auipc	ra,0xffffc
    80004eae:	1c4080e7          	jalr	452(ra) # 8000106e <walkaddr>
    80004eb2:	862a                	mv	a2,a0
    if(pa == 0)
    80004eb4:	d955                	beqz	a0,80004e68 <exec+0xf0>
      n = PGSIZE;
    80004eb6:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004eb8:	fd9a70e3          	bgeu	s4,s9,80004e78 <exec+0x100>
      n = sz - i;
    80004ebc:	8ad2                	mv	s5,s4
    80004ebe:	bf6d                	j	80004e78 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ec0:	4901                	li	s2,0
  iunlockput(ip);
    80004ec2:	8526                	mv	a0,s1
    80004ec4:	fffff097          	auipc	ra,0xfffff
    80004ec8:	c18080e7          	jalr	-1000(ra) # 80003adc <iunlockput>
  end_op();
    80004ecc:	fffff097          	auipc	ra,0xfffff
    80004ed0:	400080e7          	jalr	1024(ra) # 800042cc <end_op>
  p = myproc();
    80004ed4:	ffffd097          	auipc	ra,0xffffd
    80004ed8:	adc080e7          	jalr	-1316(ra) # 800019b0 <myproc>
    80004edc:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004ede:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ee2:	6785                	lui	a5,0x1
    80004ee4:	17fd                	addi	a5,a5,-1
    80004ee6:	993e                	add	s2,s2,a5
    80004ee8:	757d                	lui	a0,0xfffff
    80004eea:	00a977b3          	and	a5,s2,a0
    80004eee:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ef2:	6609                	lui	a2,0x2
    80004ef4:	963e                	add	a2,a2,a5
    80004ef6:	85be                	mv	a1,a5
    80004ef8:	855e                	mv	a0,s7
    80004efa:	ffffc097          	auipc	ra,0xffffc
    80004efe:	528080e7          	jalr	1320(ra) # 80001422 <uvmalloc>
    80004f02:	8b2a                	mv	s6,a0
  ip = 0;
    80004f04:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f06:	12050c63          	beqz	a0,8000503e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f0a:	75f9                	lui	a1,0xffffe
    80004f0c:	95aa                	add	a1,a1,a0
    80004f0e:	855e                	mv	a0,s7
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	730080e7          	jalr	1840(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f18:	7c7d                	lui	s8,0xfffff
    80004f1a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f1c:	e0043783          	ld	a5,-512(s0)
    80004f20:	6388                	ld	a0,0(a5)
    80004f22:	c535                	beqz	a0,80004f8e <exec+0x216>
    80004f24:	e9040993          	addi	s3,s0,-368
    80004f28:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f2c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f2e:	ffffc097          	auipc	ra,0xffffc
    80004f32:	f36080e7          	jalr	-202(ra) # 80000e64 <strlen>
    80004f36:	2505                	addiw	a0,a0,1
    80004f38:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f3c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f40:	13896363          	bltu	s2,s8,80005066 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f44:	e0043d83          	ld	s11,-512(s0)
    80004f48:	000dba03          	ld	s4,0(s11)
    80004f4c:	8552                	mv	a0,s4
    80004f4e:	ffffc097          	auipc	ra,0xffffc
    80004f52:	f16080e7          	jalr	-234(ra) # 80000e64 <strlen>
    80004f56:	0015069b          	addiw	a3,a0,1
    80004f5a:	8652                	mv	a2,s4
    80004f5c:	85ca                	mv	a1,s2
    80004f5e:	855e                	mv	a0,s7
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	712080e7          	jalr	1810(ra) # 80001672 <copyout>
    80004f68:	10054363          	bltz	a0,8000506e <exec+0x2f6>
    ustack[argc] = sp;
    80004f6c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f70:	0485                	addi	s1,s1,1
    80004f72:	008d8793          	addi	a5,s11,8
    80004f76:	e0f43023          	sd	a5,-512(s0)
    80004f7a:	008db503          	ld	a0,8(s11)
    80004f7e:	c911                	beqz	a0,80004f92 <exec+0x21a>
    if(argc >= MAXARG)
    80004f80:	09a1                	addi	s3,s3,8
    80004f82:	fb3c96e3          	bne	s9,s3,80004f2e <exec+0x1b6>
  sz = sz1;
    80004f86:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f8a:	4481                	li	s1,0
    80004f8c:	a84d                	j	8000503e <exec+0x2c6>
  sp = sz;
    80004f8e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f90:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f92:	00349793          	slli	a5,s1,0x3
    80004f96:	f9040713          	addi	a4,s0,-112
    80004f9a:	97ba                	add	a5,a5,a4
    80004f9c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004fa0:	00148693          	addi	a3,s1,1
    80004fa4:	068e                	slli	a3,a3,0x3
    80004fa6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004faa:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fae:	01897663          	bgeu	s2,s8,80004fba <exec+0x242>
  sz = sz1;
    80004fb2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fb6:	4481                	li	s1,0
    80004fb8:	a059                	j	8000503e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fba:	e9040613          	addi	a2,s0,-368
    80004fbe:	85ca                	mv	a1,s2
    80004fc0:	855e                	mv	a0,s7
    80004fc2:	ffffc097          	auipc	ra,0xffffc
    80004fc6:	6b0080e7          	jalr	1712(ra) # 80001672 <copyout>
    80004fca:	0a054663          	bltz	a0,80005076 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004fce:	058ab783          	ld	a5,88(s5)
    80004fd2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fd6:	df843783          	ld	a5,-520(s0)
    80004fda:	0007c703          	lbu	a4,0(a5)
    80004fde:	cf11                	beqz	a4,80004ffa <exec+0x282>
    80004fe0:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fe2:	02f00693          	li	a3,47
    80004fe6:	a039                	j	80004ff4 <exec+0x27c>
      last = s+1;
    80004fe8:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004fec:	0785                	addi	a5,a5,1
    80004fee:	fff7c703          	lbu	a4,-1(a5)
    80004ff2:	c701                	beqz	a4,80004ffa <exec+0x282>
    if(*s == '/')
    80004ff4:	fed71ce3          	bne	a4,a3,80004fec <exec+0x274>
    80004ff8:	bfc5                	j	80004fe8 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ffa:	4641                	li	a2,16
    80004ffc:	df843583          	ld	a1,-520(s0)
    80005000:	158a8513          	addi	a0,s5,344
    80005004:	ffffc097          	auipc	ra,0xffffc
    80005008:	e2e080e7          	jalr	-466(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000500c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005010:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005014:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005018:	058ab783          	ld	a5,88(s5)
    8000501c:	e6843703          	ld	a4,-408(s0)
    80005020:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005022:	058ab783          	ld	a5,88(s5)
    80005026:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000502a:	85ea                	mv	a1,s10
    8000502c:	ffffd097          	auipc	ra,0xffffd
    80005030:	ae4080e7          	jalr	-1308(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005034:	0004851b          	sext.w	a0,s1
    80005038:	bbe1                	j	80004e10 <exec+0x98>
    8000503a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000503e:	e0843583          	ld	a1,-504(s0)
    80005042:	855e                	mv	a0,s7
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	acc080e7          	jalr	-1332(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    8000504c:	da0498e3          	bnez	s1,80004dfc <exec+0x84>
  return -1;
    80005050:	557d                	li	a0,-1
    80005052:	bb7d                	j	80004e10 <exec+0x98>
    80005054:	e1243423          	sd	s2,-504(s0)
    80005058:	b7dd                	j	8000503e <exec+0x2c6>
    8000505a:	e1243423          	sd	s2,-504(s0)
    8000505e:	b7c5                	j	8000503e <exec+0x2c6>
    80005060:	e1243423          	sd	s2,-504(s0)
    80005064:	bfe9                	j	8000503e <exec+0x2c6>
  sz = sz1;
    80005066:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000506a:	4481                	li	s1,0
    8000506c:	bfc9                	j	8000503e <exec+0x2c6>
  sz = sz1;
    8000506e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005072:	4481                	li	s1,0
    80005074:	b7e9                	j	8000503e <exec+0x2c6>
  sz = sz1;
    80005076:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000507a:	4481                	li	s1,0
    8000507c:	b7c9                	j	8000503e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000507e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005082:	2b05                	addiw	s6,s6,1
    80005084:	0389899b          	addiw	s3,s3,56
    80005088:	e8845783          	lhu	a5,-376(s0)
    8000508c:	e2fb5be3          	bge	s6,a5,80004ec2 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005090:	2981                	sext.w	s3,s3
    80005092:	03800713          	li	a4,56
    80005096:	86ce                	mv	a3,s3
    80005098:	e1840613          	addi	a2,s0,-488
    8000509c:	4581                	li	a1,0
    8000509e:	8526                	mv	a0,s1
    800050a0:	fffff097          	auipc	ra,0xfffff
    800050a4:	a8e080e7          	jalr	-1394(ra) # 80003b2e <readi>
    800050a8:	03800793          	li	a5,56
    800050ac:	f8f517e3          	bne	a0,a5,8000503a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800050b0:	e1842783          	lw	a5,-488(s0)
    800050b4:	4705                	li	a4,1
    800050b6:	fce796e3          	bne	a5,a4,80005082 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800050ba:	e4043603          	ld	a2,-448(s0)
    800050be:	e3843783          	ld	a5,-456(s0)
    800050c2:	f8f669e3          	bltu	a2,a5,80005054 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050c6:	e2843783          	ld	a5,-472(s0)
    800050ca:	963e                	add	a2,a2,a5
    800050cc:	f8f667e3          	bltu	a2,a5,8000505a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050d0:	85ca                	mv	a1,s2
    800050d2:	855e                	mv	a0,s7
    800050d4:	ffffc097          	auipc	ra,0xffffc
    800050d8:	34e080e7          	jalr	846(ra) # 80001422 <uvmalloc>
    800050dc:	e0a43423          	sd	a0,-504(s0)
    800050e0:	d141                	beqz	a0,80005060 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800050e2:	e2843d03          	ld	s10,-472(s0)
    800050e6:	df043783          	ld	a5,-528(s0)
    800050ea:	00fd77b3          	and	a5,s10,a5
    800050ee:	fba1                	bnez	a5,8000503e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050f0:	e2042d83          	lw	s11,-480(s0)
    800050f4:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050f8:	f80c03e3          	beqz	s8,8000507e <exec+0x306>
    800050fc:	8a62                	mv	s4,s8
    800050fe:	4901                	li	s2,0
    80005100:	b345                	j	80004ea0 <exec+0x128>

0000000080005102 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005102:	7179                	addi	sp,sp,-48
    80005104:	f406                	sd	ra,40(sp)
    80005106:	f022                	sd	s0,32(sp)
    80005108:	ec26                	sd	s1,24(sp)
    8000510a:	e84a                	sd	s2,16(sp)
    8000510c:	1800                	addi	s0,sp,48
    8000510e:	892e                	mv	s2,a1
    80005110:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005112:	fdc40593          	addi	a1,s0,-36
    80005116:	ffffe097          	auipc	ra,0xffffe
    8000511a:	b44080e7          	jalr	-1212(ra) # 80002c5a <argint>
    8000511e:	04054063          	bltz	a0,8000515e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005122:	fdc42703          	lw	a4,-36(s0)
    80005126:	47bd                	li	a5,15
    80005128:	02e7ed63          	bltu	a5,a4,80005162 <argfd+0x60>
    8000512c:	ffffd097          	auipc	ra,0xffffd
    80005130:	884080e7          	jalr	-1916(ra) # 800019b0 <myproc>
    80005134:	fdc42703          	lw	a4,-36(s0)
    80005138:	01a70793          	addi	a5,a4,26
    8000513c:	078e                	slli	a5,a5,0x3
    8000513e:	953e                	add	a0,a0,a5
    80005140:	611c                	ld	a5,0(a0)
    80005142:	c395                	beqz	a5,80005166 <argfd+0x64>
    return -1;
  if(pfd)
    80005144:	00090463          	beqz	s2,8000514c <argfd+0x4a>
    *pfd = fd;
    80005148:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000514c:	4501                	li	a0,0
  if(pf)
    8000514e:	c091                	beqz	s1,80005152 <argfd+0x50>
    *pf = f;
    80005150:	e09c                	sd	a5,0(s1)
}
    80005152:	70a2                	ld	ra,40(sp)
    80005154:	7402                	ld	s0,32(sp)
    80005156:	64e2                	ld	s1,24(sp)
    80005158:	6942                	ld	s2,16(sp)
    8000515a:	6145                	addi	sp,sp,48
    8000515c:	8082                	ret
    return -1;
    8000515e:	557d                	li	a0,-1
    80005160:	bfcd                	j	80005152 <argfd+0x50>
    return -1;
    80005162:	557d                	li	a0,-1
    80005164:	b7fd                	j	80005152 <argfd+0x50>
    80005166:	557d                	li	a0,-1
    80005168:	b7ed                	j	80005152 <argfd+0x50>

000000008000516a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000516a:	1101                	addi	sp,sp,-32
    8000516c:	ec06                	sd	ra,24(sp)
    8000516e:	e822                	sd	s0,16(sp)
    80005170:	e426                	sd	s1,8(sp)
    80005172:	1000                	addi	s0,sp,32
    80005174:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005176:	ffffd097          	auipc	ra,0xffffd
    8000517a:	83a080e7          	jalr	-1990(ra) # 800019b0 <myproc>
    8000517e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005180:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005184:	4501                	li	a0,0
    80005186:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005188:	6398                	ld	a4,0(a5)
    8000518a:	cb19                	beqz	a4,800051a0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000518c:	2505                	addiw	a0,a0,1
    8000518e:	07a1                	addi	a5,a5,8
    80005190:	fed51ce3          	bne	a0,a3,80005188 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005194:	557d                	li	a0,-1
}
    80005196:	60e2                	ld	ra,24(sp)
    80005198:	6442                	ld	s0,16(sp)
    8000519a:	64a2                	ld	s1,8(sp)
    8000519c:	6105                	addi	sp,sp,32
    8000519e:	8082                	ret
      p->ofile[fd] = f;
    800051a0:	01a50793          	addi	a5,a0,26
    800051a4:	078e                	slli	a5,a5,0x3
    800051a6:	963e                	add	a2,a2,a5
    800051a8:	e204                	sd	s1,0(a2)
      return fd;
    800051aa:	b7f5                	j	80005196 <fdalloc+0x2c>

00000000800051ac <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051ac:	715d                	addi	sp,sp,-80
    800051ae:	e486                	sd	ra,72(sp)
    800051b0:	e0a2                	sd	s0,64(sp)
    800051b2:	fc26                	sd	s1,56(sp)
    800051b4:	f84a                	sd	s2,48(sp)
    800051b6:	f44e                	sd	s3,40(sp)
    800051b8:	f052                	sd	s4,32(sp)
    800051ba:	ec56                	sd	s5,24(sp)
    800051bc:	0880                	addi	s0,sp,80
    800051be:	89ae                	mv	s3,a1
    800051c0:	8ab2                	mv	s5,a2
    800051c2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051c4:	fb040593          	addi	a1,s0,-80
    800051c8:	fffff097          	auipc	ra,0xfffff
    800051cc:	e86080e7          	jalr	-378(ra) # 8000404e <nameiparent>
    800051d0:	892a                	mv	s2,a0
    800051d2:	12050f63          	beqz	a0,80005310 <create+0x164>
    return 0;

  ilock(dp);
    800051d6:	ffffe097          	auipc	ra,0xffffe
    800051da:	6a4080e7          	jalr	1700(ra) # 8000387a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051de:	4601                	li	a2,0
    800051e0:	fb040593          	addi	a1,s0,-80
    800051e4:	854a                	mv	a0,s2
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	b78080e7          	jalr	-1160(ra) # 80003d5e <dirlookup>
    800051ee:	84aa                	mv	s1,a0
    800051f0:	c921                	beqz	a0,80005240 <create+0x94>
    iunlockput(dp);
    800051f2:	854a                	mv	a0,s2
    800051f4:	fffff097          	auipc	ra,0xfffff
    800051f8:	8e8080e7          	jalr	-1816(ra) # 80003adc <iunlockput>
    ilock(ip);
    800051fc:	8526                	mv	a0,s1
    800051fe:	ffffe097          	auipc	ra,0xffffe
    80005202:	67c080e7          	jalr	1660(ra) # 8000387a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005206:	2981                	sext.w	s3,s3
    80005208:	4789                	li	a5,2
    8000520a:	02f99463          	bne	s3,a5,80005232 <create+0x86>
    8000520e:	0444d783          	lhu	a5,68(s1)
    80005212:	37f9                	addiw	a5,a5,-2
    80005214:	17c2                	slli	a5,a5,0x30
    80005216:	93c1                	srli	a5,a5,0x30
    80005218:	4705                	li	a4,1
    8000521a:	00f76c63          	bltu	a4,a5,80005232 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000521e:	8526                	mv	a0,s1
    80005220:	60a6                	ld	ra,72(sp)
    80005222:	6406                	ld	s0,64(sp)
    80005224:	74e2                	ld	s1,56(sp)
    80005226:	7942                	ld	s2,48(sp)
    80005228:	79a2                	ld	s3,40(sp)
    8000522a:	7a02                	ld	s4,32(sp)
    8000522c:	6ae2                	ld	s5,24(sp)
    8000522e:	6161                	addi	sp,sp,80
    80005230:	8082                	ret
    iunlockput(ip);
    80005232:	8526                	mv	a0,s1
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	8a8080e7          	jalr	-1880(ra) # 80003adc <iunlockput>
    return 0;
    8000523c:	4481                	li	s1,0
    8000523e:	b7c5                	j	8000521e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005240:	85ce                	mv	a1,s3
    80005242:	00092503          	lw	a0,0(s2)
    80005246:	ffffe097          	auipc	ra,0xffffe
    8000524a:	49c080e7          	jalr	1180(ra) # 800036e2 <ialloc>
    8000524e:	84aa                	mv	s1,a0
    80005250:	c529                	beqz	a0,8000529a <create+0xee>
  ilock(ip);
    80005252:	ffffe097          	auipc	ra,0xffffe
    80005256:	628080e7          	jalr	1576(ra) # 8000387a <ilock>
  ip->major = major;
    8000525a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000525e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005262:	4785                	li	a5,1
    80005264:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005268:	8526                	mv	a0,s1
    8000526a:	ffffe097          	auipc	ra,0xffffe
    8000526e:	546080e7          	jalr	1350(ra) # 800037b0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005272:	2981                	sext.w	s3,s3
    80005274:	4785                	li	a5,1
    80005276:	02f98a63          	beq	s3,a5,800052aa <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000527a:	40d0                	lw	a2,4(s1)
    8000527c:	fb040593          	addi	a1,s0,-80
    80005280:	854a                	mv	a0,s2
    80005282:	fffff097          	auipc	ra,0xfffff
    80005286:	cec080e7          	jalr	-788(ra) # 80003f6e <dirlink>
    8000528a:	06054b63          	bltz	a0,80005300 <create+0x154>
  iunlockput(dp);
    8000528e:	854a                	mv	a0,s2
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	84c080e7          	jalr	-1972(ra) # 80003adc <iunlockput>
  return ip;
    80005298:	b759                	j	8000521e <create+0x72>
    panic("create: ialloc");
    8000529a:	00003517          	auipc	a0,0x3
    8000529e:	45650513          	addi	a0,a0,1110 # 800086f0 <syscalls+0x2a8>
    800052a2:	ffffb097          	auipc	ra,0xffffb
    800052a6:	29c080e7          	jalr	668(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800052aa:	04a95783          	lhu	a5,74(s2)
    800052ae:	2785                	addiw	a5,a5,1
    800052b0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052b4:	854a                	mv	a0,s2
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	4fa080e7          	jalr	1274(ra) # 800037b0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052be:	40d0                	lw	a2,4(s1)
    800052c0:	00003597          	auipc	a1,0x3
    800052c4:	44058593          	addi	a1,a1,1088 # 80008700 <syscalls+0x2b8>
    800052c8:	8526                	mv	a0,s1
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	ca4080e7          	jalr	-860(ra) # 80003f6e <dirlink>
    800052d2:	00054f63          	bltz	a0,800052f0 <create+0x144>
    800052d6:	00492603          	lw	a2,4(s2)
    800052da:	00003597          	auipc	a1,0x3
    800052de:	42e58593          	addi	a1,a1,1070 # 80008708 <syscalls+0x2c0>
    800052e2:	8526                	mv	a0,s1
    800052e4:	fffff097          	auipc	ra,0xfffff
    800052e8:	c8a080e7          	jalr	-886(ra) # 80003f6e <dirlink>
    800052ec:	f80557e3          	bgez	a0,8000527a <create+0xce>
      panic("create dots");
    800052f0:	00003517          	auipc	a0,0x3
    800052f4:	42050513          	addi	a0,a0,1056 # 80008710 <syscalls+0x2c8>
    800052f8:	ffffb097          	auipc	ra,0xffffb
    800052fc:	246080e7          	jalr	582(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005300:	00003517          	auipc	a0,0x3
    80005304:	42050513          	addi	a0,a0,1056 # 80008720 <syscalls+0x2d8>
    80005308:	ffffb097          	auipc	ra,0xffffb
    8000530c:	236080e7          	jalr	566(ra) # 8000053e <panic>
    return 0;
    80005310:	84aa                	mv	s1,a0
    80005312:	b731                	j	8000521e <create+0x72>

0000000080005314 <sys_dup>:
{
    80005314:	7179                	addi	sp,sp,-48
    80005316:	f406                	sd	ra,40(sp)
    80005318:	f022                	sd	s0,32(sp)
    8000531a:	ec26                	sd	s1,24(sp)
    8000531c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000531e:	fd840613          	addi	a2,s0,-40
    80005322:	4581                	li	a1,0
    80005324:	4501                	li	a0,0
    80005326:	00000097          	auipc	ra,0x0
    8000532a:	ddc080e7          	jalr	-548(ra) # 80005102 <argfd>
    return -1;
    8000532e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005330:	02054363          	bltz	a0,80005356 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005334:	fd843503          	ld	a0,-40(s0)
    80005338:	00000097          	auipc	ra,0x0
    8000533c:	e32080e7          	jalr	-462(ra) # 8000516a <fdalloc>
    80005340:	84aa                	mv	s1,a0
    return -1;
    80005342:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005344:	00054963          	bltz	a0,80005356 <sys_dup+0x42>
  filedup(f);
    80005348:	fd843503          	ld	a0,-40(s0)
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	37a080e7          	jalr	890(ra) # 800046c6 <filedup>
  return fd;
    80005354:	87a6                	mv	a5,s1
}
    80005356:	853e                	mv	a0,a5
    80005358:	70a2                	ld	ra,40(sp)
    8000535a:	7402                	ld	s0,32(sp)
    8000535c:	64e2                	ld	s1,24(sp)
    8000535e:	6145                	addi	sp,sp,48
    80005360:	8082                	ret

0000000080005362 <sys_read>:
{
    80005362:	7179                	addi	sp,sp,-48
    80005364:	f406                	sd	ra,40(sp)
    80005366:	f022                	sd	s0,32(sp)
    80005368:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000536a:	fe840613          	addi	a2,s0,-24
    8000536e:	4581                	li	a1,0
    80005370:	4501                	li	a0,0
    80005372:	00000097          	auipc	ra,0x0
    80005376:	d90080e7          	jalr	-624(ra) # 80005102 <argfd>
    return -1;
    8000537a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000537c:	04054163          	bltz	a0,800053be <sys_read+0x5c>
    80005380:	fe440593          	addi	a1,s0,-28
    80005384:	4509                	li	a0,2
    80005386:	ffffe097          	auipc	ra,0xffffe
    8000538a:	8d4080e7          	jalr	-1836(ra) # 80002c5a <argint>
    return -1;
    8000538e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005390:	02054763          	bltz	a0,800053be <sys_read+0x5c>
    80005394:	fd840593          	addi	a1,s0,-40
    80005398:	4505                	li	a0,1
    8000539a:	ffffe097          	auipc	ra,0xffffe
    8000539e:	8e2080e7          	jalr	-1822(ra) # 80002c7c <argaddr>
    return -1;
    800053a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a4:	00054d63          	bltz	a0,800053be <sys_read+0x5c>
  return fileread(f, p, n);
    800053a8:	fe442603          	lw	a2,-28(s0)
    800053ac:	fd843583          	ld	a1,-40(s0)
    800053b0:	fe843503          	ld	a0,-24(s0)
    800053b4:	fffff097          	auipc	ra,0xfffff
    800053b8:	49e080e7          	jalr	1182(ra) # 80004852 <fileread>
    800053bc:	87aa                	mv	a5,a0
}
    800053be:	853e                	mv	a0,a5
    800053c0:	70a2                	ld	ra,40(sp)
    800053c2:	7402                	ld	s0,32(sp)
    800053c4:	6145                	addi	sp,sp,48
    800053c6:	8082                	ret

00000000800053c8 <sys_write>:
{
    800053c8:	7179                	addi	sp,sp,-48
    800053ca:	f406                	sd	ra,40(sp)
    800053cc:	f022                	sd	s0,32(sp)
    800053ce:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d0:	fe840613          	addi	a2,s0,-24
    800053d4:	4581                	li	a1,0
    800053d6:	4501                	li	a0,0
    800053d8:	00000097          	auipc	ra,0x0
    800053dc:	d2a080e7          	jalr	-726(ra) # 80005102 <argfd>
    return -1;
    800053e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e2:	04054163          	bltz	a0,80005424 <sys_write+0x5c>
    800053e6:	fe440593          	addi	a1,s0,-28
    800053ea:	4509                	li	a0,2
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	86e080e7          	jalr	-1938(ra) # 80002c5a <argint>
    return -1;
    800053f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f6:	02054763          	bltz	a0,80005424 <sys_write+0x5c>
    800053fa:	fd840593          	addi	a1,s0,-40
    800053fe:	4505                	li	a0,1
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	87c080e7          	jalr	-1924(ra) # 80002c7c <argaddr>
    return -1;
    80005408:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000540a:	00054d63          	bltz	a0,80005424 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000540e:	fe442603          	lw	a2,-28(s0)
    80005412:	fd843583          	ld	a1,-40(s0)
    80005416:	fe843503          	ld	a0,-24(s0)
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	4fa080e7          	jalr	1274(ra) # 80004914 <filewrite>
    80005422:	87aa                	mv	a5,a0
}
    80005424:	853e                	mv	a0,a5
    80005426:	70a2                	ld	ra,40(sp)
    80005428:	7402                	ld	s0,32(sp)
    8000542a:	6145                	addi	sp,sp,48
    8000542c:	8082                	ret

000000008000542e <sys_close>:
{
    8000542e:	1101                	addi	sp,sp,-32
    80005430:	ec06                	sd	ra,24(sp)
    80005432:	e822                	sd	s0,16(sp)
    80005434:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005436:	fe040613          	addi	a2,s0,-32
    8000543a:	fec40593          	addi	a1,s0,-20
    8000543e:	4501                	li	a0,0
    80005440:	00000097          	auipc	ra,0x0
    80005444:	cc2080e7          	jalr	-830(ra) # 80005102 <argfd>
    return -1;
    80005448:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000544a:	02054463          	bltz	a0,80005472 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000544e:	ffffc097          	auipc	ra,0xffffc
    80005452:	562080e7          	jalr	1378(ra) # 800019b0 <myproc>
    80005456:	fec42783          	lw	a5,-20(s0)
    8000545a:	07e9                	addi	a5,a5,26
    8000545c:	078e                	slli	a5,a5,0x3
    8000545e:	97aa                	add	a5,a5,a0
    80005460:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005464:	fe043503          	ld	a0,-32(s0)
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	2b0080e7          	jalr	688(ra) # 80004718 <fileclose>
  return 0;
    80005470:	4781                	li	a5,0
}
    80005472:	853e                	mv	a0,a5
    80005474:	60e2                	ld	ra,24(sp)
    80005476:	6442                	ld	s0,16(sp)
    80005478:	6105                	addi	sp,sp,32
    8000547a:	8082                	ret

000000008000547c <sys_fstat>:
{
    8000547c:	1101                	addi	sp,sp,-32
    8000547e:	ec06                	sd	ra,24(sp)
    80005480:	e822                	sd	s0,16(sp)
    80005482:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005484:	fe840613          	addi	a2,s0,-24
    80005488:	4581                	li	a1,0
    8000548a:	4501                	li	a0,0
    8000548c:	00000097          	auipc	ra,0x0
    80005490:	c76080e7          	jalr	-906(ra) # 80005102 <argfd>
    return -1;
    80005494:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005496:	02054563          	bltz	a0,800054c0 <sys_fstat+0x44>
    8000549a:	fe040593          	addi	a1,s0,-32
    8000549e:	4505                	li	a0,1
    800054a0:	ffffd097          	auipc	ra,0xffffd
    800054a4:	7dc080e7          	jalr	2012(ra) # 80002c7c <argaddr>
    return -1;
    800054a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054aa:	00054b63          	bltz	a0,800054c0 <sys_fstat+0x44>
  return filestat(f, st);
    800054ae:	fe043583          	ld	a1,-32(s0)
    800054b2:	fe843503          	ld	a0,-24(s0)
    800054b6:	fffff097          	auipc	ra,0xfffff
    800054ba:	32a080e7          	jalr	810(ra) # 800047e0 <filestat>
    800054be:	87aa                	mv	a5,a0
}
    800054c0:	853e                	mv	a0,a5
    800054c2:	60e2                	ld	ra,24(sp)
    800054c4:	6442                	ld	s0,16(sp)
    800054c6:	6105                	addi	sp,sp,32
    800054c8:	8082                	ret

00000000800054ca <sys_link>:
{
    800054ca:	7169                	addi	sp,sp,-304
    800054cc:	f606                	sd	ra,296(sp)
    800054ce:	f222                	sd	s0,288(sp)
    800054d0:	ee26                	sd	s1,280(sp)
    800054d2:	ea4a                	sd	s2,272(sp)
    800054d4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054d6:	08000613          	li	a2,128
    800054da:	ed040593          	addi	a1,s0,-304
    800054de:	4501                	li	a0,0
    800054e0:	ffffd097          	auipc	ra,0xffffd
    800054e4:	7be080e7          	jalr	1982(ra) # 80002c9e <argstr>
    return -1;
    800054e8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ea:	10054e63          	bltz	a0,80005606 <sys_link+0x13c>
    800054ee:	08000613          	li	a2,128
    800054f2:	f5040593          	addi	a1,s0,-176
    800054f6:	4505                	li	a0,1
    800054f8:	ffffd097          	auipc	ra,0xffffd
    800054fc:	7a6080e7          	jalr	1958(ra) # 80002c9e <argstr>
    return -1;
    80005500:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005502:	10054263          	bltz	a0,80005606 <sys_link+0x13c>
  begin_op();
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	d46080e7          	jalr	-698(ra) # 8000424c <begin_op>
  if((ip = namei(old)) == 0){
    8000550e:	ed040513          	addi	a0,s0,-304
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	b1e080e7          	jalr	-1250(ra) # 80004030 <namei>
    8000551a:	84aa                	mv	s1,a0
    8000551c:	c551                	beqz	a0,800055a8 <sys_link+0xde>
  ilock(ip);
    8000551e:	ffffe097          	auipc	ra,0xffffe
    80005522:	35c080e7          	jalr	860(ra) # 8000387a <ilock>
  if(ip->type == T_DIR){
    80005526:	04449703          	lh	a4,68(s1)
    8000552a:	4785                	li	a5,1
    8000552c:	08f70463          	beq	a4,a5,800055b4 <sys_link+0xea>
  ip->nlink++;
    80005530:	04a4d783          	lhu	a5,74(s1)
    80005534:	2785                	addiw	a5,a5,1
    80005536:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000553a:	8526                	mv	a0,s1
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	274080e7          	jalr	628(ra) # 800037b0 <iupdate>
  iunlock(ip);
    80005544:	8526                	mv	a0,s1
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	3f6080e7          	jalr	1014(ra) # 8000393c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000554e:	fd040593          	addi	a1,s0,-48
    80005552:	f5040513          	addi	a0,s0,-176
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	af8080e7          	jalr	-1288(ra) # 8000404e <nameiparent>
    8000555e:	892a                	mv	s2,a0
    80005560:	c935                	beqz	a0,800055d4 <sys_link+0x10a>
  ilock(dp);
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	318080e7          	jalr	792(ra) # 8000387a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000556a:	00092703          	lw	a4,0(s2)
    8000556e:	409c                	lw	a5,0(s1)
    80005570:	04f71d63          	bne	a4,a5,800055ca <sys_link+0x100>
    80005574:	40d0                	lw	a2,4(s1)
    80005576:	fd040593          	addi	a1,s0,-48
    8000557a:	854a                	mv	a0,s2
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	9f2080e7          	jalr	-1550(ra) # 80003f6e <dirlink>
    80005584:	04054363          	bltz	a0,800055ca <sys_link+0x100>
  iunlockput(dp);
    80005588:	854a                	mv	a0,s2
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	552080e7          	jalr	1362(ra) # 80003adc <iunlockput>
  iput(ip);
    80005592:	8526                	mv	a0,s1
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	4a0080e7          	jalr	1184(ra) # 80003a34 <iput>
  end_op();
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	d30080e7          	jalr	-720(ra) # 800042cc <end_op>
  return 0;
    800055a4:	4781                	li	a5,0
    800055a6:	a085                	j	80005606 <sys_link+0x13c>
    end_op();
    800055a8:	fffff097          	auipc	ra,0xfffff
    800055ac:	d24080e7          	jalr	-732(ra) # 800042cc <end_op>
    return -1;
    800055b0:	57fd                	li	a5,-1
    800055b2:	a891                	j	80005606 <sys_link+0x13c>
    iunlockput(ip);
    800055b4:	8526                	mv	a0,s1
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	526080e7          	jalr	1318(ra) # 80003adc <iunlockput>
    end_op();
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	d0e080e7          	jalr	-754(ra) # 800042cc <end_op>
    return -1;
    800055c6:	57fd                	li	a5,-1
    800055c8:	a83d                	j	80005606 <sys_link+0x13c>
    iunlockput(dp);
    800055ca:	854a                	mv	a0,s2
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	510080e7          	jalr	1296(ra) # 80003adc <iunlockput>
  ilock(ip);
    800055d4:	8526                	mv	a0,s1
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	2a4080e7          	jalr	676(ra) # 8000387a <ilock>
  ip->nlink--;
    800055de:	04a4d783          	lhu	a5,74(s1)
    800055e2:	37fd                	addiw	a5,a5,-1
    800055e4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	1c6080e7          	jalr	454(ra) # 800037b0 <iupdate>
  iunlockput(ip);
    800055f2:	8526                	mv	a0,s1
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	4e8080e7          	jalr	1256(ra) # 80003adc <iunlockput>
  end_op();
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	cd0080e7          	jalr	-816(ra) # 800042cc <end_op>
  return -1;
    80005604:	57fd                	li	a5,-1
}
    80005606:	853e                	mv	a0,a5
    80005608:	70b2                	ld	ra,296(sp)
    8000560a:	7412                	ld	s0,288(sp)
    8000560c:	64f2                	ld	s1,280(sp)
    8000560e:	6952                	ld	s2,272(sp)
    80005610:	6155                	addi	sp,sp,304
    80005612:	8082                	ret

0000000080005614 <sys_unlink>:
{
    80005614:	7151                	addi	sp,sp,-240
    80005616:	f586                	sd	ra,232(sp)
    80005618:	f1a2                	sd	s0,224(sp)
    8000561a:	eda6                	sd	s1,216(sp)
    8000561c:	e9ca                	sd	s2,208(sp)
    8000561e:	e5ce                	sd	s3,200(sp)
    80005620:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005622:	08000613          	li	a2,128
    80005626:	f3040593          	addi	a1,s0,-208
    8000562a:	4501                	li	a0,0
    8000562c:	ffffd097          	auipc	ra,0xffffd
    80005630:	672080e7          	jalr	1650(ra) # 80002c9e <argstr>
    80005634:	18054163          	bltz	a0,800057b6 <sys_unlink+0x1a2>
  begin_op();
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	c14080e7          	jalr	-1004(ra) # 8000424c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005640:	fb040593          	addi	a1,s0,-80
    80005644:	f3040513          	addi	a0,s0,-208
    80005648:	fffff097          	auipc	ra,0xfffff
    8000564c:	a06080e7          	jalr	-1530(ra) # 8000404e <nameiparent>
    80005650:	84aa                	mv	s1,a0
    80005652:	c979                	beqz	a0,80005728 <sys_unlink+0x114>
  ilock(dp);
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	226080e7          	jalr	550(ra) # 8000387a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000565c:	00003597          	auipc	a1,0x3
    80005660:	0a458593          	addi	a1,a1,164 # 80008700 <syscalls+0x2b8>
    80005664:	fb040513          	addi	a0,s0,-80
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	6dc080e7          	jalr	1756(ra) # 80003d44 <namecmp>
    80005670:	14050a63          	beqz	a0,800057c4 <sys_unlink+0x1b0>
    80005674:	00003597          	auipc	a1,0x3
    80005678:	09458593          	addi	a1,a1,148 # 80008708 <syscalls+0x2c0>
    8000567c:	fb040513          	addi	a0,s0,-80
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	6c4080e7          	jalr	1732(ra) # 80003d44 <namecmp>
    80005688:	12050e63          	beqz	a0,800057c4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000568c:	f2c40613          	addi	a2,s0,-212
    80005690:	fb040593          	addi	a1,s0,-80
    80005694:	8526                	mv	a0,s1
    80005696:	ffffe097          	auipc	ra,0xffffe
    8000569a:	6c8080e7          	jalr	1736(ra) # 80003d5e <dirlookup>
    8000569e:	892a                	mv	s2,a0
    800056a0:	12050263          	beqz	a0,800057c4 <sys_unlink+0x1b0>
  ilock(ip);
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	1d6080e7          	jalr	470(ra) # 8000387a <ilock>
  if(ip->nlink < 1)
    800056ac:	04a91783          	lh	a5,74(s2)
    800056b0:	08f05263          	blez	a5,80005734 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056b4:	04491703          	lh	a4,68(s2)
    800056b8:	4785                	li	a5,1
    800056ba:	08f70563          	beq	a4,a5,80005744 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056be:	4641                	li	a2,16
    800056c0:	4581                	li	a1,0
    800056c2:	fc040513          	addi	a0,s0,-64
    800056c6:	ffffb097          	auipc	ra,0xffffb
    800056ca:	61a080e7          	jalr	1562(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056ce:	4741                	li	a4,16
    800056d0:	f2c42683          	lw	a3,-212(s0)
    800056d4:	fc040613          	addi	a2,s0,-64
    800056d8:	4581                	li	a1,0
    800056da:	8526                	mv	a0,s1
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	54a080e7          	jalr	1354(ra) # 80003c26 <writei>
    800056e4:	47c1                	li	a5,16
    800056e6:	0af51563          	bne	a0,a5,80005790 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056ea:	04491703          	lh	a4,68(s2)
    800056ee:	4785                	li	a5,1
    800056f0:	0af70863          	beq	a4,a5,800057a0 <sys_unlink+0x18c>
  iunlockput(dp);
    800056f4:	8526                	mv	a0,s1
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	3e6080e7          	jalr	998(ra) # 80003adc <iunlockput>
  ip->nlink--;
    800056fe:	04a95783          	lhu	a5,74(s2)
    80005702:	37fd                	addiw	a5,a5,-1
    80005704:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005708:	854a                	mv	a0,s2
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	0a6080e7          	jalr	166(ra) # 800037b0 <iupdate>
  iunlockput(ip);
    80005712:	854a                	mv	a0,s2
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	3c8080e7          	jalr	968(ra) # 80003adc <iunlockput>
  end_op();
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	bb0080e7          	jalr	-1104(ra) # 800042cc <end_op>
  return 0;
    80005724:	4501                	li	a0,0
    80005726:	a84d                	j	800057d8 <sys_unlink+0x1c4>
    end_op();
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	ba4080e7          	jalr	-1116(ra) # 800042cc <end_op>
    return -1;
    80005730:	557d                	li	a0,-1
    80005732:	a05d                	j	800057d8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005734:	00003517          	auipc	a0,0x3
    80005738:	ffc50513          	addi	a0,a0,-4 # 80008730 <syscalls+0x2e8>
    8000573c:	ffffb097          	auipc	ra,0xffffb
    80005740:	e02080e7          	jalr	-510(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005744:	04c92703          	lw	a4,76(s2)
    80005748:	02000793          	li	a5,32
    8000574c:	f6e7f9e3          	bgeu	a5,a4,800056be <sys_unlink+0xaa>
    80005750:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005754:	4741                	li	a4,16
    80005756:	86ce                	mv	a3,s3
    80005758:	f1840613          	addi	a2,s0,-232
    8000575c:	4581                	li	a1,0
    8000575e:	854a                	mv	a0,s2
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	3ce080e7          	jalr	974(ra) # 80003b2e <readi>
    80005768:	47c1                	li	a5,16
    8000576a:	00f51b63          	bne	a0,a5,80005780 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000576e:	f1845783          	lhu	a5,-232(s0)
    80005772:	e7a1                	bnez	a5,800057ba <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005774:	29c1                	addiw	s3,s3,16
    80005776:	04c92783          	lw	a5,76(s2)
    8000577a:	fcf9ede3          	bltu	s3,a5,80005754 <sys_unlink+0x140>
    8000577e:	b781                	j	800056be <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005780:	00003517          	auipc	a0,0x3
    80005784:	fc850513          	addi	a0,a0,-56 # 80008748 <syscalls+0x300>
    80005788:	ffffb097          	auipc	ra,0xffffb
    8000578c:	db6080e7          	jalr	-586(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005790:	00003517          	auipc	a0,0x3
    80005794:	fd050513          	addi	a0,a0,-48 # 80008760 <syscalls+0x318>
    80005798:	ffffb097          	auipc	ra,0xffffb
    8000579c:	da6080e7          	jalr	-602(ra) # 8000053e <panic>
    dp->nlink--;
    800057a0:	04a4d783          	lhu	a5,74(s1)
    800057a4:	37fd                	addiw	a5,a5,-1
    800057a6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057aa:	8526                	mv	a0,s1
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	004080e7          	jalr	4(ra) # 800037b0 <iupdate>
    800057b4:	b781                	j	800056f4 <sys_unlink+0xe0>
    return -1;
    800057b6:	557d                	li	a0,-1
    800057b8:	a005                	j	800057d8 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057ba:	854a                	mv	a0,s2
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	320080e7          	jalr	800(ra) # 80003adc <iunlockput>
  iunlockput(dp);
    800057c4:	8526                	mv	a0,s1
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	316080e7          	jalr	790(ra) # 80003adc <iunlockput>
  end_op();
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	afe080e7          	jalr	-1282(ra) # 800042cc <end_op>
  return -1;
    800057d6:	557d                	li	a0,-1
}
    800057d8:	70ae                	ld	ra,232(sp)
    800057da:	740e                	ld	s0,224(sp)
    800057dc:	64ee                	ld	s1,216(sp)
    800057de:	694e                	ld	s2,208(sp)
    800057e0:	69ae                	ld	s3,200(sp)
    800057e2:	616d                	addi	sp,sp,240
    800057e4:	8082                	ret

00000000800057e6 <sys_open>:

uint64
sys_open(void)
{
    800057e6:	7131                	addi	sp,sp,-192
    800057e8:	fd06                	sd	ra,184(sp)
    800057ea:	f922                	sd	s0,176(sp)
    800057ec:	f526                	sd	s1,168(sp)
    800057ee:	f14a                	sd	s2,160(sp)
    800057f0:	ed4e                	sd	s3,152(sp)
    800057f2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057f4:	08000613          	li	a2,128
    800057f8:	f5040593          	addi	a1,s0,-176
    800057fc:	4501                	li	a0,0
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	4a0080e7          	jalr	1184(ra) # 80002c9e <argstr>
    return -1;
    80005806:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005808:	0c054163          	bltz	a0,800058ca <sys_open+0xe4>
    8000580c:	f4c40593          	addi	a1,s0,-180
    80005810:	4505                	li	a0,1
    80005812:	ffffd097          	auipc	ra,0xffffd
    80005816:	448080e7          	jalr	1096(ra) # 80002c5a <argint>
    8000581a:	0a054863          	bltz	a0,800058ca <sys_open+0xe4>

  begin_op();
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	a2e080e7          	jalr	-1490(ra) # 8000424c <begin_op>

  if(omode & O_CREATE){
    80005826:	f4c42783          	lw	a5,-180(s0)
    8000582a:	2007f793          	andi	a5,a5,512
    8000582e:	cbdd                	beqz	a5,800058e4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005830:	4681                	li	a3,0
    80005832:	4601                	li	a2,0
    80005834:	4589                	li	a1,2
    80005836:	f5040513          	addi	a0,s0,-176
    8000583a:	00000097          	auipc	ra,0x0
    8000583e:	972080e7          	jalr	-1678(ra) # 800051ac <create>
    80005842:	892a                	mv	s2,a0
    if(ip == 0){
    80005844:	c959                	beqz	a0,800058da <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005846:	04491703          	lh	a4,68(s2)
    8000584a:	478d                	li	a5,3
    8000584c:	00f71763          	bne	a4,a5,8000585a <sys_open+0x74>
    80005850:	04695703          	lhu	a4,70(s2)
    80005854:	47a5                	li	a5,9
    80005856:	0ce7ec63          	bltu	a5,a4,8000592e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	e02080e7          	jalr	-510(ra) # 8000465c <filealloc>
    80005862:	89aa                	mv	s3,a0
    80005864:	10050263          	beqz	a0,80005968 <sys_open+0x182>
    80005868:	00000097          	auipc	ra,0x0
    8000586c:	902080e7          	jalr	-1790(ra) # 8000516a <fdalloc>
    80005870:	84aa                	mv	s1,a0
    80005872:	0e054663          	bltz	a0,8000595e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005876:	04491703          	lh	a4,68(s2)
    8000587a:	478d                	li	a5,3
    8000587c:	0cf70463          	beq	a4,a5,80005944 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005880:	4789                	li	a5,2
    80005882:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005886:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000588a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000588e:	f4c42783          	lw	a5,-180(s0)
    80005892:	0017c713          	xori	a4,a5,1
    80005896:	8b05                	andi	a4,a4,1
    80005898:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000589c:	0037f713          	andi	a4,a5,3
    800058a0:	00e03733          	snez	a4,a4
    800058a4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058a8:	4007f793          	andi	a5,a5,1024
    800058ac:	c791                	beqz	a5,800058b8 <sys_open+0xd2>
    800058ae:	04491703          	lh	a4,68(s2)
    800058b2:	4789                	li	a5,2
    800058b4:	08f70f63          	beq	a4,a5,80005952 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058b8:	854a                	mv	a0,s2
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	082080e7          	jalr	130(ra) # 8000393c <iunlock>
  end_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	a0a080e7          	jalr	-1526(ra) # 800042cc <end_op>

  return fd;
}
    800058ca:	8526                	mv	a0,s1
    800058cc:	70ea                	ld	ra,184(sp)
    800058ce:	744a                	ld	s0,176(sp)
    800058d0:	74aa                	ld	s1,168(sp)
    800058d2:	790a                	ld	s2,160(sp)
    800058d4:	69ea                	ld	s3,152(sp)
    800058d6:	6129                	addi	sp,sp,192
    800058d8:	8082                	ret
      end_op();
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	9f2080e7          	jalr	-1550(ra) # 800042cc <end_op>
      return -1;
    800058e2:	b7e5                	j	800058ca <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058e4:	f5040513          	addi	a0,s0,-176
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	748080e7          	jalr	1864(ra) # 80004030 <namei>
    800058f0:	892a                	mv	s2,a0
    800058f2:	c905                	beqz	a0,80005922 <sys_open+0x13c>
    ilock(ip);
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	f86080e7          	jalr	-122(ra) # 8000387a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058fc:	04491703          	lh	a4,68(s2)
    80005900:	4785                	li	a5,1
    80005902:	f4f712e3          	bne	a4,a5,80005846 <sys_open+0x60>
    80005906:	f4c42783          	lw	a5,-180(s0)
    8000590a:	dba1                	beqz	a5,8000585a <sys_open+0x74>
      iunlockput(ip);
    8000590c:	854a                	mv	a0,s2
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	1ce080e7          	jalr	462(ra) # 80003adc <iunlockput>
      end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	9b6080e7          	jalr	-1610(ra) # 800042cc <end_op>
      return -1;
    8000591e:	54fd                	li	s1,-1
    80005920:	b76d                	j	800058ca <sys_open+0xe4>
      end_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	9aa080e7          	jalr	-1622(ra) # 800042cc <end_op>
      return -1;
    8000592a:	54fd                	li	s1,-1
    8000592c:	bf79                	j	800058ca <sys_open+0xe4>
    iunlockput(ip);
    8000592e:	854a                	mv	a0,s2
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	1ac080e7          	jalr	428(ra) # 80003adc <iunlockput>
    end_op();
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	994080e7          	jalr	-1644(ra) # 800042cc <end_op>
    return -1;
    80005940:	54fd                	li	s1,-1
    80005942:	b761                	j	800058ca <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005944:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005948:	04691783          	lh	a5,70(s2)
    8000594c:	02f99223          	sh	a5,36(s3)
    80005950:	bf2d                	j	8000588a <sys_open+0xa4>
    itrunc(ip);
    80005952:	854a                	mv	a0,s2
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	034080e7          	jalr	52(ra) # 80003988 <itrunc>
    8000595c:	bfb1                	j	800058b8 <sys_open+0xd2>
      fileclose(f);
    8000595e:	854e                	mv	a0,s3
    80005960:	fffff097          	auipc	ra,0xfffff
    80005964:	db8080e7          	jalr	-584(ra) # 80004718 <fileclose>
    iunlockput(ip);
    80005968:	854a                	mv	a0,s2
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	172080e7          	jalr	370(ra) # 80003adc <iunlockput>
    end_op();
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	95a080e7          	jalr	-1702(ra) # 800042cc <end_op>
    return -1;
    8000597a:	54fd                	li	s1,-1
    8000597c:	b7b9                	j	800058ca <sys_open+0xe4>

000000008000597e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000597e:	7175                	addi	sp,sp,-144
    80005980:	e506                	sd	ra,136(sp)
    80005982:	e122                	sd	s0,128(sp)
    80005984:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	8c6080e7          	jalr	-1850(ra) # 8000424c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000598e:	08000613          	li	a2,128
    80005992:	f7040593          	addi	a1,s0,-144
    80005996:	4501                	li	a0,0
    80005998:	ffffd097          	auipc	ra,0xffffd
    8000599c:	306080e7          	jalr	774(ra) # 80002c9e <argstr>
    800059a0:	02054963          	bltz	a0,800059d2 <sys_mkdir+0x54>
    800059a4:	4681                	li	a3,0
    800059a6:	4601                	li	a2,0
    800059a8:	4585                	li	a1,1
    800059aa:	f7040513          	addi	a0,s0,-144
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	7fe080e7          	jalr	2046(ra) # 800051ac <create>
    800059b6:	cd11                	beqz	a0,800059d2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	124080e7          	jalr	292(ra) # 80003adc <iunlockput>
  end_op();
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	90c080e7          	jalr	-1780(ra) # 800042cc <end_op>
  return 0;
    800059c8:	4501                	li	a0,0
}
    800059ca:	60aa                	ld	ra,136(sp)
    800059cc:	640a                	ld	s0,128(sp)
    800059ce:	6149                	addi	sp,sp,144
    800059d0:	8082                	ret
    end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	8fa080e7          	jalr	-1798(ra) # 800042cc <end_op>
    return -1;
    800059da:	557d                	li	a0,-1
    800059dc:	b7fd                	j	800059ca <sys_mkdir+0x4c>

00000000800059de <sys_mknod>:

uint64
sys_mknod(void)
{
    800059de:	7135                	addi	sp,sp,-160
    800059e0:	ed06                	sd	ra,152(sp)
    800059e2:	e922                	sd	s0,144(sp)
    800059e4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	866080e7          	jalr	-1946(ra) # 8000424c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059ee:	08000613          	li	a2,128
    800059f2:	f7040593          	addi	a1,s0,-144
    800059f6:	4501                	li	a0,0
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	2a6080e7          	jalr	678(ra) # 80002c9e <argstr>
    80005a00:	04054a63          	bltz	a0,80005a54 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a04:	f6c40593          	addi	a1,s0,-148
    80005a08:	4505                	li	a0,1
    80005a0a:	ffffd097          	auipc	ra,0xffffd
    80005a0e:	250080e7          	jalr	592(ra) # 80002c5a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a12:	04054163          	bltz	a0,80005a54 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a16:	f6840593          	addi	a1,s0,-152
    80005a1a:	4509                	li	a0,2
    80005a1c:	ffffd097          	auipc	ra,0xffffd
    80005a20:	23e080e7          	jalr	574(ra) # 80002c5a <argint>
     argint(1, &major) < 0 ||
    80005a24:	02054863          	bltz	a0,80005a54 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a28:	f6841683          	lh	a3,-152(s0)
    80005a2c:	f6c41603          	lh	a2,-148(s0)
    80005a30:	458d                	li	a1,3
    80005a32:	f7040513          	addi	a0,s0,-144
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	776080e7          	jalr	1910(ra) # 800051ac <create>
     argint(2, &minor) < 0 ||
    80005a3e:	c919                	beqz	a0,80005a54 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	09c080e7          	jalr	156(ra) # 80003adc <iunlockput>
  end_op();
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	884080e7          	jalr	-1916(ra) # 800042cc <end_op>
  return 0;
    80005a50:	4501                	li	a0,0
    80005a52:	a031                	j	80005a5e <sys_mknod+0x80>
    end_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	878080e7          	jalr	-1928(ra) # 800042cc <end_op>
    return -1;
    80005a5c:	557d                	li	a0,-1
}
    80005a5e:	60ea                	ld	ra,152(sp)
    80005a60:	644a                	ld	s0,144(sp)
    80005a62:	610d                	addi	sp,sp,160
    80005a64:	8082                	ret

0000000080005a66 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a66:	7135                	addi	sp,sp,-160
    80005a68:	ed06                	sd	ra,152(sp)
    80005a6a:	e922                	sd	s0,144(sp)
    80005a6c:	e526                	sd	s1,136(sp)
    80005a6e:	e14a                	sd	s2,128(sp)
    80005a70:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a72:	ffffc097          	auipc	ra,0xffffc
    80005a76:	f3e080e7          	jalr	-194(ra) # 800019b0 <myproc>
    80005a7a:	892a                	mv	s2,a0
  
  begin_op();
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	7d0080e7          	jalr	2000(ra) # 8000424c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a84:	08000613          	li	a2,128
    80005a88:	f6040593          	addi	a1,s0,-160
    80005a8c:	4501                	li	a0,0
    80005a8e:	ffffd097          	auipc	ra,0xffffd
    80005a92:	210080e7          	jalr	528(ra) # 80002c9e <argstr>
    80005a96:	04054b63          	bltz	a0,80005aec <sys_chdir+0x86>
    80005a9a:	f6040513          	addi	a0,s0,-160
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	592080e7          	jalr	1426(ra) # 80004030 <namei>
    80005aa6:	84aa                	mv	s1,a0
    80005aa8:	c131                	beqz	a0,80005aec <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	dd0080e7          	jalr	-560(ra) # 8000387a <ilock>
  if(ip->type != T_DIR){
    80005ab2:	04449703          	lh	a4,68(s1)
    80005ab6:	4785                	li	a5,1
    80005ab8:	04f71063          	bne	a4,a5,80005af8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005abc:	8526                	mv	a0,s1
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	e7e080e7          	jalr	-386(ra) # 8000393c <iunlock>
  iput(p->cwd);
    80005ac6:	15093503          	ld	a0,336(s2)
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	f6a080e7          	jalr	-150(ra) # 80003a34 <iput>
  end_op();
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	7fa080e7          	jalr	2042(ra) # 800042cc <end_op>
  p->cwd = ip;
    80005ada:	14993823          	sd	s1,336(s2)
  return 0;
    80005ade:	4501                	li	a0,0
}
    80005ae0:	60ea                	ld	ra,152(sp)
    80005ae2:	644a                	ld	s0,144(sp)
    80005ae4:	64aa                	ld	s1,136(sp)
    80005ae6:	690a                	ld	s2,128(sp)
    80005ae8:	610d                	addi	sp,sp,160
    80005aea:	8082                	ret
    end_op();
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	7e0080e7          	jalr	2016(ra) # 800042cc <end_op>
    return -1;
    80005af4:	557d                	li	a0,-1
    80005af6:	b7ed                	j	80005ae0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005af8:	8526                	mv	a0,s1
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	fe2080e7          	jalr	-30(ra) # 80003adc <iunlockput>
    end_op();
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	7ca080e7          	jalr	1994(ra) # 800042cc <end_op>
    return -1;
    80005b0a:	557d                	li	a0,-1
    80005b0c:	bfd1                	j	80005ae0 <sys_chdir+0x7a>

0000000080005b0e <sys_exec>:

uint64
sys_exec(void)
{
    80005b0e:	7145                	addi	sp,sp,-464
    80005b10:	e786                	sd	ra,456(sp)
    80005b12:	e3a2                	sd	s0,448(sp)
    80005b14:	ff26                	sd	s1,440(sp)
    80005b16:	fb4a                	sd	s2,432(sp)
    80005b18:	f74e                	sd	s3,424(sp)
    80005b1a:	f352                	sd	s4,416(sp)
    80005b1c:	ef56                	sd	s5,408(sp)
    80005b1e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b20:	08000613          	li	a2,128
    80005b24:	f4040593          	addi	a1,s0,-192
    80005b28:	4501                	li	a0,0
    80005b2a:	ffffd097          	auipc	ra,0xffffd
    80005b2e:	174080e7          	jalr	372(ra) # 80002c9e <argstr>
    return -1;
    80005b32:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b34:	0c054a63          	bltz	a0,80005c08 <sys_exec+0xfa>
    80005b38:	e3840593          	addi	a1,s0,-456
    80005b3c:	4505                	li	a0,1
    80005b3e:	ffffd097          	auipc	ra,0xffffd
    80005b42:	13e080e7          	jalr	318(ra) # 80002c7c <argaddr>
    80005b46:	0c054163          	bltz	a0,80005c08 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b4a:	10000613          	li	a2,256
    80005b4e:	4581                	li	a1,0
    80005b50:	e4040513          	addi	a0,s0,-448
    80005b54:	ffffb097          	auipc	ra,0xffffb
    80005b58:	18c080e7          	jalr	396(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b5c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b60:	89a6                	mv	s3,s1
    80005b62:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b64:	02000a13          	li	s4,32
    80005b68:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b6c:	00391513          	slli	a0,s2,0x3
    80005b70:	e3040593          	addi	a1,s0,-464
    80005b74:	e3843783          	ld	a5,-456(s0)
    80005b78:	953e                	add	a0,a0,a5
    80005b7a:	ffffd097          	auipc	ra,0xffffd
    80005b7e:	046080e7          	jalr	70(ra) # 80002bc0 <fetchaddr>
    80005b82:	02054a63          	bltz	a0,80005bb6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b86:	e3043783          	ld	a5,-464(s0)
    80005b8a:	c3b9                	beqz	a5,80005bd0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b8c:	ffffb097          	auipc	ra,0xffffb
    80005b90:	f68080e7          	jalr	-152(ra) # 80000af4 <kalloc>
    80005b94:	85aa                	mv	a1,a0
    80005b96:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b9a:	cd11                	beqz	a0,80005bb6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b9c:	6605                	lui	a2,0x1
    80005b9e:	e3043503          	ld	a0,-464(s0)
    80005ba2:	ffffd097          	auipc	ra,0xffffd
    80005ba6:	070080e7          	jalr	112(ra) # 80002c12 <fetchstr>
    80005baa:	00054663          	bltz	a0,80005bb6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005bae:	0905                	addi	s2,s2,1
    80005bb0:	09a1                	addi	s3,s3,8
    80005bb2:	fb491be3          	bne	s2,s4,80005b68 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bb6:	10048913          	addi	s2,s1,256
    80005bba:	6088                	ld	a0,0(s1)
    80005bbc:	c529                	beqz	a0,80005c06 <sys_exec+0xf8>
    kfree(argv[i]);
    80005bbe:	ffffb097          	auipc	ra,0xffffb
    80005bc2:	e3a080e7          	jalr	-454(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bc6:	04a1                	addi	s1,s1,8
    80005bc8:	ff2499e3          	bne	s1,s2,80005bba <sys_exec+0xac>
  return -1;
    80005bcc:	597d                	li	s2,-1
    80005bce:	a82d                	j	80005c08 <sys_exec+0xfa>
      argv[i] = 0;
    80005bd0:	0a8e                	slli	s5,s5,0x3
    80005bd2:	fc040793          	addi	a5,s0,-64
    80005bd6:	9abe                	add	s5,s5,a5
    80005bd8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bdc:	e4040593          	addi	a1,s0,-448
    80005be0:	f4040513          	addi	a0,s0,-192
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	194080e7          	jalr	404(ra) # 80004d78 <exec>
    80005bec:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bee:	10048993          	addi	s3,s1,256
    80005bf2:	6088                	ld	a0,0(s1)
    80005bf4:	c911                	beqz	a0,80005c08 <sys_exec+0xfa>
    kfree(argv[i]);
    80005bf6:	ffffb097          	auipc	ra,0xffffb
    80005bfa:	e02080e7          	jalr	-510(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bfe:	04a1                	addi	s1,s1,8
    80005c00:	ff3499e3          	bne	s1,s3,80005bf2 <sys_exec+0xe4>
    80005c04:	a011                	j	80005c08 <sys_exec+0xfa>
  return -1;
    80005c06:	597d                	li	s2,-1
}
    80005c08:	854a                	mv	a0,s2
    80005c0a:	60be                	ld	ra,456(sp)
    80005c0c:	641e                	ld	s0,448(sp)
    80005c0e:	74fa                	ld	s1,440(sp)
    80005c10:	795a                	ld	s2,432(sp)
    80005c12:	79ba                	ld	s3,424(sp)
    80005c14:	7a1a                	ld	s4,416(sp)
    80005c16:	6afa                	ld	s5,408(sp)
    80005c18:	6179                	addi	sp,sp,464
    80005c1a:	8082                	ret

0000000080005c1c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c1c:	7139                	addi	sp,sp,-64
    80005c1e:	fc06                	sd	ra,56(sp)
    80005c20:	f822                	sd	s0,48(sp)
    80005c22:	f426                	sd	s1,40(sp)
    80005c24:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c26:	ffffc097          	auipc	ra,0xffffc
    80005c2a:	d8a080e7          	jalr	-630(ra) # 800019b0 <myproc>
    80005c2e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c30:	fd840593          	addi	a1,s0,-40
    80005c34:	4501                	li	a0,0
    80005c36:	ffffd097          	auipc	ra,0xffffd
    80005c3a:	046080e7          	jalr	70(ra) # 80002c7c <argaddr>
    return -1;
    80005c3e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c40:	0e054063          	bltz	a0,80005d20 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c44:	fc840593          	addi	a1,s0,-56
    80005c48:	fd040513          	addi	a0,s0,-48
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	dfc080e7          	jalr	-516(ra) # 80004a48 <pipealloc>
    return -1;
    80005c54:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c56:	0c054563          	bltz	a0,80005d20 <sys_pipe+0x104>
  fd0 = -1;
    80005c5a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c5e:	fd043503          	ld	a0,-48(s0)
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	508080e7          	jalr	1288(ra) # 8000516a <fdalloc>
    80005c6a:	fca42223          	sw	a0,-60(s0)
    80005c6e:	08054c63          	bltz	a0,80005d06 <sys_pipe+0xea>
    80005c72:	fc843503          	ld	a0,-56(s0)
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	4f4080e7          	jalr	1268(ra) # 8000516a <fdalloc>
    80005c7e:	fca42023          	sw	a0,-64(s0)
    80005c82:	06054863          	bltz	a0,80005cf2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c86:	4691                	li	a3,4
    80005c88:	fc440613          	addi	a2,s0,-60
    80005c8c:	fd843583          	ld	a1,-40(s0)
    80005c90:	68a8                	ld	a0,80(s1)
    80005c92:	ffffc097          	auipc	ra,0xffffc
    80005c96:	9e0080e7          	jalr	-1568(ra) # 80001672 <copyout>
    80005c9a:	02054063          	bltz	a0,80005cba <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c9e:	4691                	li	a3,4
    80005ca0:	fc040613          	addi	a2,s0,-64
    80005ca4:	fd843583          	ld	a1,-40(s0)
    80005ca8:	0591                	addi	a1,a1,4
    80005caa:	68a8                	ld	a0,80(s1)
    80005cac:	ffffc097          	auipc	ra,0xffffc
    80005cb0:	9c6080e7          	jalr	-1594(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cb4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cb6:	06055563          	bgez	a0,80005d20 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005cba:	fc442783          	lw	a5,-60(s0)
    80005cbe:	07e9                	addi	a5,a5,26
    80005cc0:	078e                	slli	a5,a5,0x3
    80005cc2:	97a6                	add	a5,a5,s1
    80005cc4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cc8:	fc042503          	lw	a0,-64(s0)
    80005ccc:	0569                	addi	a0,a0,26
    80005cce:	050e                	slli	a0,a0,0x3
    80005cd0:	9526                	add	a0,a0,s1
    80005cd2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cd6:	fd043503          	ld	a0,-48(s0)
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	a3e080e7          	jalr	-1474(ra) # 80004718 <fileclose>
    fileclose(wf);
    80005ce2:	fc843503          	ld	a0,-56(s0)
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	a32080e7          	jalr	-1486(ra) # 80004718 <fileclose>
    return -1;
    80005cee:	57fd                	li	a5,-1
    80005cf0:	a805                	j	80005d20 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cf2:	fc442783          	lw	a5,-60(s0)
    80005cf6:	0007c863          	bltz	a5,80005d06 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cfa:	01a78513          	addi	a0,a5,26
    80005cfe:	050e                	slli	a0,a0,0x3
    80005d00:	9526                	add	a0,a0,s1
    80005d02:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d06:	fd043503          	ld	a0,-48(s0)
    80005d0a:	fffff097          	auipc	ra,0xfffff
    80005d0e:	a0e080e7          	jalr	-1522(ra) # 80004718 <fileclose>
    fileclose(wf);
    80005d12:	fc843503          	ld	a0,-56(s0)
    80005d16:	fffff097          	auipc	ra,0xfffff
    80005d1a:	a02080e7          	jalr	-1534(ra) # 80004718 <fileclose>
    return -1;
    80005d1e:	57fd                	li	a5,-1
}
    80005d20:	853e                	mv	a0,a5
    80005d22:	70e2                	ld	ra,56(sp)
    80005d24:	7442                	ld	s0,48(sp)
    80005d26:	74a2                	ld	s1,40(sp)
    80005d28:	6121                	addi	sp,sp,64
    80005d2a:	8082                	ret
    80005d2c:	0000                	unimp
	...

0000000080005d30 <kernelvec>:
    80005d30:	7111                	addi	sp,sp,-256
    80005d32:	e006                	sd	ra,0(sp)
    80005d34:	e40a                	sd	sp,8(sp)
    80005d36:	e80e                	sd	gp,16(sp)
    80005d38:	ec12                	sd	tp,24(sp)
    80005d3a:	f016                	sd	t0,32(sp)
    80005d3c:	f41a                	sd	t1,40(sp)
    80005d3e:	f81e                	sd	t2,48(sp)
    80005d40:	fc22                	sd	s0,56(sp)
    80005d42:	e0a6                	sd	s1,64(sp)
    80005d44:	e4aa                	sd	a0,72(sp)
    80005d46:	e8ae                	sd	a1,80(sp)
    80005d48:	ecb2                	sd	a2,88(sp)
    80005d4a:	f0b6                	sd	a3,96(sp)
    80005d4c:	f4ba                	sd	a4,104(sp)
    80005d4e:	f8be                	sd	a5,112(sp)
    80005d50:	fcc2                	sd	a6,120(sp)
    80005d52:	e146                	sd	a7,128(sp)
    80005d54:	e54a                	sd	s2,136(sp)
    80005d56:	e94e                	sd	s3,144(sp)
    80005d58:	ed52                	sd	s4,152(sp)
    80005d5a:	f156                	sd	s5,160(sp)
    80005d5c:	f55a                	sd	s6,168(sp)
    80005d5e:	f95e                	sd	s7,176(sp)
    80005d60:	fd62                	sd	s8,184(sp)
    80005d62:	e1e6                	sd	s9,192(sp)
    80005d64:	e5ea                	sd	s10,200(sp)
    80005d66:	e9ee                	sd	s11,208(sp)
    80005d68:	edf2                	sd	t3,216(sp)
    80005d6a:	f1f6                	sd	t4,224(sp)
    80005d6c:	f5fa                	sd	t5,232(sp)
    80005d6e:	f9fe                	sd	t6,240(sp)
    80005d70:	d1dfc0ef          	jal	ra,80002a8c <kerneltrap>
    80005d74:	6082                	ld	ra,0(sp)
    80005d76:	6122                	ld	sp,8(sp)
    80005d78:	61c2                	ld	gp,16(sp)
    80005d7a:	7282                	ld	t0,32(sp)
    80005d7c:	7322                	ld	t1,40(sp)
    80005d7e:	73c2                	ld	t2,48(sp)
    80005d80:	7462                	ld	s0,56(sp)
    80005d82:	6486                	ld	s1,64(sp)
    80005d84:	6526                	ld	a0,72(sp)
    80005d86:	65c6                	ld	a1,80(sp)
    80005d88:	6666                	ld	a2,88(sp)
    80005d8a:	7686                	ld	a3,96(sp)
    80005d8c:	7726                	ld	a4,104(sp)
    80005d8e:	77c6                	ld	a5,112(sp)
    80005d90:	7866                	ld	a6,120(sp)
    80005d92:	688a                	ld	a7,128(sp)
    80005d94:	692a                	ld	s2,136(sp)
    80005d96:	69ca                	ld	s3,144(sp)
    80005d98:	6a6a                	ld	s4,152(sp)
    80005d9a:	7a8a                	ld	s5,160(sp)
    80005d9c:	7b2a                	ld	s6,168(sp)
    80005d9e:	7bca                	ld	s7,176(sp)
    80005da0:	7c6a                	ld	s8,184(sp)
    80005da2:	6c8e                	ld	s9,192(sp)
    80005da4:	6d2e                	ld	s10,200(sp)
    80005da6:	6dce                	ld	s11,208(sp)
    80005da8:	6e6e                	ld	t3,216(sp)
    80005daa:	7e8e                	ld	t4,224(sp)
    80005dac:	7f2e                	ld	t5,232(sp)
    80005dae:	7fce                	ld	t6,240(sp)
    80005db0:	6111                	addi	sp,sp,256
    80005db2:	10200073          	sret
    80005db6:	00000013          	nop
    80005dba:	00000013          	nop
    80005dbe:	0001                	nop

0000000080005dc0 <timervec>:
    80005dc0:	34051573          	csrrw	a0,mscratch,a0
    80005dc4:	e10c                	sd	a1,0(a0)
    80005dc6:	e510                	sd	a2,8(a0)
    80005dc8:	e914                	sd	a3,16(a0)
    80005dca:	6d0c                	ld	a1,24(a0)
    80005dcc:	7110                	ld	a2,32(a0)
    80005dce:	6194                	ld	a3,0(a1)
    80005dd0:	96b2                	add	a3,a3,a2
    80005dd2:	e194                	sd	a3,0(a1)
    80005dd4:	4589                	li	a1,2
    80005dd6:	14459073          	csrw	sip,a1
    80005dda:	6914                	ld	a3,16(a0)
    80005ddc:	6510                	ld	a2,8(a0)
    80005dde:	610c                	ld	a1,0(a0)
    80005de0:	34051573          	csrrw	a0,mscratch,a0
    80005de4:	30200073          	mret
	...

0000000080005dea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dea:	1141                	addi	sp,sp,-16
    80005dec:	e422                	sd	s0,8(sp)
    80005dee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005df0:	0c0007b7          	lui	a5,0xc000
    80005df4:	4705                	li	a4,1
    80005df6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005df8:	c3d8                	sw	a4,4(a5)
}
    80005dfa:	6422                	ld	s0,8(sp)
    80005dfc:	0141                	addi	sp,sp,16
    80005dfe:	8082                	ret

0000000080005e00 <plicinithart>:

void
plicinithart(void)
{
    80005e00:	1141                	addi	sp,sp,-16
    80005e02:	e406                	sd	ra,8(sp)
    80005e04:	e022                	sd	s0,0(sp)
    80005e06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e08:	ffffc097          	auipc	ra,0xffffc
    80005e0c:	b7c080e7          	jalr	-1156(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e10:	0085171b          	slliw	a4,a0,0x8
    80005e14:	0c0027b7          	lui	a5,0xc002
    80005e18:	97ba                	add	a5,a5,a4
    80005e1a:	40200713          	li	a4,1026
    80005e1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e22:	00d5151b          	slliw	a0,a0,0xd
    80005e26:	0c2017b7          	lui	a5,0xc201
    80005e2a:	953e                	add	a0,a0,a5
    80005e2c:	00052023          	sw	zero,0(a0)
}
    80005e30:	60a2                	ld	ra,8(sp)
    80005e32:	6402                	ld	s0,0(sp)
    80005e34:	0141                	addi	sp,sp,16
    80005e36:	8082                	ret

0000000080005e38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e38:	1141                	addi	sp,sp,-16
    80005e3a:	e406                	sd	ra,8(sp)
    80005e3c:	e022                	sd	s0,0(sp)
    80005e3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e40:	ffffc097          	auipc	ra,0xffffc
    80005e44:	b44080e7          	jalr	-1212(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e48:	00d5179b          	slliw	a5,a0,0xd
    80005e4c:	0c201537          	lui	a0,0xc201
    80005e50:	953e                	add	a0,a0,a5
  return irq;
}
    80005e52:	4148                	lw	a0,4(a0)
    80005e54:	60a2                	ld	ra,8(sp)
    80005e56:	6402                	ld	s0,0(sp)
    80005e58:	0141                	addi	sp,sp,16
    80005e5a:	8082                	ret

0000000080005e5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e5c:	1101                	addi	sp,sp,-32
    80005e5e:	ec06                	sd	ra,24(sp)
    80005e60:	e822                	sd	s0,16(sp)
    80005e62:	e426                	sd	s1,8(sp)
    80005e64:	1000                	addi	s0,sp,32
    80005e66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	b1c080e7          	jalr	-1252(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e70:	00d5151b          	slliw	a0,a0,0xd
    80005e74:	0c2017b7          	lui	a5,0xc201
    80005e78:	97aa                	add	a5,a5,a0
    80005e7a:	c3c4                	sw	s1,4(a5)
}
    80005e7c:	60e2                	ld	ra,24(sp)
    80005e7e:	6442                	ld	s0,16(sp)
    80005e80:	64a2                	ld	s1,8(sp)
    80005e82:	6105                	addi	sp,sp,32
    80005e84:	8082                	ret

0000000080005e86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e86:	1141                	addi	sp,sp,-16
    80005e88:	e406                	sd	ra,8(sp)
    80005e8a:	e022                	sd	s0,0(sp)
    80005e8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e8e:	479d                	li	a5,7
    80005e90:	06a7c963          	blt	a5,a0,80005f02 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e94:	0001d797          	auipc	a5,0x1d
    80005e98:	16c78793          	addi	a5,a5,364 # 80023000 <disk>
    80005e9c:	00a78733          	add	a4,a5,a0
    80005ea0:	6789                	lui	a5,0x2
    80005ea2:	97ba                	add	a5,a5,a4
    80005ea4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ea8:	e7ad                	bnez	a5,80005f12 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005eaa:	00451793          	slli	a5,a0,0x4
    80005eae:	0001f717          	auipc	a4,0x1f
    80005eb2:	15270713          	addi	a4,a4,338 # 80025000 <disk+0x2000>
    80005eb6:	6314                	ld	a3,0(a4)
    80005eb8:	96be                	add	a3,a3,a5
    80005eba:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005ebe:	6314                	ld	a3,0(a4)
    80005ec0:	96be                	add	a3,a3,a5
    80005ec2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ec6:	6314                	ld	a3,0(a4)
    80005ec8:	96be                	add	a3,a3,a5
    80005eca:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005ece:	6318                	ld	a4,0(a4)
    80005ed0:	97ba                	add	a5,a5,a4
    80005ed2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ed6:	0001d797          	auipc	a5,0x1d
    80005eda:	12a78793          	addi	a5,a5,298 # 80023000 <disk>
    80005ede:	97aa                	add	a5,a5,a0
    80005ee0:	6509                	lui	a0,0x2
    80005ee2:	953e                	add	a0,a0,a5
    80005ee4:	4785                	li	a5,1
    80005ee6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005eea:	0001f517          	auipc	a0,0x1f
    80005eee:	12e50513          	addi	a0,a0,302 # 80025018 <disk+0x2018>
    80005ef2:	ffffc097          	auipc	ra,0xffffc
    80005ef6:	32e080e7          	jalr	814(ra) # 80002220 <wakeup>
}
    80005efa:	60a2                	ld	ra,8(sp)
    80005efc:	6402                	ld	s0,0(sp)
    80005efe:	0141                	addi	sp,sp,16
    80005f00:	8082                	ret
    panic("free_desc 1");
    80005f02:	00003517          	auipc	a0,0x3
    80005f06:	86e50513          	addi	a0,a0,-1938 # 80008770 <syscalls+0x328>
    80005f0a:	ffffa097          	auipc	ra,0xffffa
    80005f0e:	634080e7          	jalr	1588(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f12:	00003517          	auipc	a0,0x3
    80005f16:	86e50513          	addi	a0,a0,-1938 # 80008780 <syscalls+0x338>
    80005f1a:	ffffa097          	auipc	ra,0xffffa
    80005f1e:	624080e7          	jalr	1572(ra) # 8000053e <panic>

0000000080005f22 <virtio_disk_init>:
{
    80005f22:	1101                	addi	sp,sp,-32
    80005f24:	ec06                	sd	ra,24(sp)
    80005f26:	e822                	sd	s0,16(sp)
    80005f28:	e426                	sd	s1,8(sp)
    80005f2a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f2c:	00003597          	auipc	a1,0x3
    80005f30:	86458593          	addi	a1,a1,-1948 # 80008790 <syscalls+0x348>
    80005f34:	0001f517          	auipc	a0,0x1f
    80005f38:	1f450513          	addi	a0,a0,500 # 80025128 <disk+0x2128>
    80005f3c:	ffffb097          	auipc	ra,0xffffb
    80005f40:	c18080e7          	jalr	-1000(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f44:	100017b7          	lui	a5,0x10001
    80005f48:	4398                	lw	a4,0(a5)
    80005f4a:	2701                	sext.w	a4,a4
    80005f4c:	747277b7          	lui	a5,0x74727
    80005f50:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f54:	0ef71163          	bne	a4,a5,80006036 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f58:	100017b7          	lui	a5,0x10001
    80005f5c:	43dc                	lw	a5,4(a5)
    80005f5e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f60:	4705                	li	a4,1
    80005f62:	0ce79a63          	bne	a5,a4,80006036 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f66:	100017b7          	lui	a5,0x10001
    80005f6a:	479c                	lw	a5,8(a5)
    80005f6c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f6e:	4709                	li	a4,2
    80005f70:	0ce79363          	bne	a5,a4,80006036 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f74:	100017b7          	lui	a5,0x10001
    80005f78:	47d8                	lw	a4,12(a5)
    80005f7a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f7c:	554d47b7          	lui	a5,0x554d4
    80005f80:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f84:	0af71963          	bne	a4,a5,80006036 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f88:	100017b7          	lui	a5,0x10001
    80005f8c:	4705                	li	a4,1
    80005f8e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f90:	470d                	li	a4,3
    80005f92:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f94:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f96:	c7ffe737          	lui	a4,0xc7ffe
    80005f9a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f9e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fa0:	2701                	sext.w	a4,a4
    80005fa2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fa4:	472d                	li	a4,11
    80005fa6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fa8:	473d                	li	a4,15
    80005faa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005fac:	6705                	lui	a4,0x1
    80005fae:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fb0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fb4:	5bdc                	lw	a5,52(a5)
    80005fb6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fb8:	c7d9                	beqz	a5,80006046 <virtio_disk_init+0x124>
  if(max < NUM)
    80005fba:	471d                	li	a4,7
    80005fbc:	08f77d63          	bgeu	a4,a5,80006056 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fc0:	100014b7          	lui	s1,0x10001
    80005fc4:	47a1                	li	a5,8
    80005fc6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fc8:	6609                	lui	a2,0x2
    80005fca:	4581                	li	a1,0
    80005fcc:	0001d517          	auipc	a0,0x1d
    80005fd0:	03450513          	addi	a0,a0,52 # 80023000 <disk>
    80005fd4:	ffffb097          	auipc	ra,0xffffb
    80005fd8:	d0c080e7          	jalr	-756(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fdc:	0001d717          	auipc	a4,0x1d
    80005fe0:	02470713          	addi	a4,a4,36 # 80023000 <disk>
    80005fe4:	00c75793          	srli	a5,a4,0xc
    80005fe8:	2781                	sext.w	a5,a5
    80005fea:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005fec:	0001f797          	auipc	a5,0x1f
    80005ff0:	01478793          	addi	a5,a5,20 # 80025000 <disk+0x2000>
    80005ff4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005ff6:	0001d717          	auipc	a4,0x1d
    80005ffa:	08a70713          	addi	a4,a4,138 # 80023080 <disk+0x80>
    80005ffe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006000:	0001e717          	auipc	a4,0x1e
    80006004:	00070713          	mv	a4,a4
    80006008:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000600a:	4705                	li	a4,1
    8000600c:	00e78c23          	sb	a4,24(a5)
    80006010:	00e78ca3          	sb	a4,25(a5)
    80006014:	00e78d23          	sb	a4,26(a5)
    80006018:	00e78da3          	sb	a4,27(a5)
    8000601c:	00e78e23          	sb	a4,28(a5)
    80006020:	00e78ea3          	sb	a4,29(a5)
    80006024:	00e78f23          	sb	a4,30(a5)
    80006028:	00e78fa3          	sb	a4,31(a5)
}
    8000602c:	60e2                	ld	ra,24(sp)
    8000602e:	6442                	ld	s0,16(sp)
    80006030:	64a2                	ld	s1,8(sp)
    80006032:	6105                	addi	sp,sp,32
    80006034:	8082                	ret
    panic("could not find virtio disk");
    80006036:	00002517          	auipc	a0,0x2
    8000603a:	76a50513          	addi	a0,a0,1898 # 800087a0 <syscalls+0x358>
    8000603e:	ffffa097          	auipc	ra,0xffffa
    80006042:	500080e7          	jalr	1280(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006046:	00002517          	auipc	a0,0x2
    8000604a:	77a50513          	addi	a0,a0,1914 # 800087c0 <syscalls+0x378>
    8000604e:	ffffa097          	auipc	ra,0xffffa
    80006052:	4f0080e7          	jalr	1264(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006056:	00002517          	auipc	a0,0x2
    8000605a:	78a50513          	addi	a0,a0,1930 # 800087e0 <syscalls+0x398>
    8000605e:	ffffa097          	auipc	ra,0xffffa
    80006062:	4e0080e7          	jalr	1248(ra) # 8000053e <panic>

0000000080006066 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006066:	7159                	addi	sp,sp,-112
    80006068:	f486                	sd	ra,104(sp)
    8000606a:	f0a2                	sd	s0,96(sp)
    8000606c:	eca6                	sd	s1,88(sp)
    8000606e:	e8ca                	sd	s2,80(sp)
    80006070:	e4ce                	sd	s3,72(sp)
    80006072:	e0d2                	sd	s4,64(sp)
    80006074:	fc56                	sd	s5,56(sp)
    80006076:	f85a                	sd	s6,48(sp)
    80006078:	f45e                	sd	s7,40(sp)
    8000607a:	f062                	sd	s8,32(sp)
    8000607c:	ec66                	sd	s9,24(sp)
    8000607e:	e86a                	sd	s10,16(sp)
    80006080:	1880                	addi	s0,sp,112
    80006082:	892a                	mv	s2,a0
    80006084:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006086:	00c52c83          	lw	s9,12(a0)
    8000608a:	001c9c9b          	slliw	s9,s9,0x1
    8000608e:	1c82                	slli	s9,s9,0x20
    80006090:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006094:	0001f517          	auipc	a0,0x1f
    80006098:	09450513          	addi	a0,a0,148 # 80025128 <disk+0x2128>
    8000609c:	ffffb097          	auipc	ra,0xffffb
    800060a0:	b48080e7          	jalr	-1208(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800060a4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060a6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060a8:	0001db97          	auipc	s7,0x1d
    800060ac:	f58b8b93          	addi	s7,s7,-168 # 80023000 <disk>
    800060b0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800060b2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060b4:	8a4e                	mv	s4,s3
    800060b6:	a051                	j	8000613a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800060b8:	00fb86b3          	add	a3,s7,a5
    800060bc:	96da                	add	a3,a3,s6
    800060be:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060c2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060c4:	0207c563          	bltz	a5,800060ee <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060c8:	2485                	addiw	s1,s1,1
    800060ca:	0711                	addi	a4,a4,4
    800060cc:	25548063          	beq	s1,s5,8000630c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800060d0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060d2:	0001f697          	auipc	a3,0x1f
    800060d6:	f4668693          	addi	a3,a3,-186 # 80025018 <disk+0x2018>
    800060da:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060dc:	0006c583          	lbu	a1,0(a3)
    800060e0:	fde1                	bnez	a1,800060b8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060e2:	2785                	addiw	a5,a5,1
    800060e4:	0685                	addi	a3,a3,1
    800060e6:	ff879be3          	bne	a5,s8,800060dc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060ea:	57fd                	li	a5,-1
    800060ec:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060ee:	02905a63          	blez	s1,80006122 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060f2:	f9042503          	lw	a0,-112(s0)
    800060f6:	00000097          	auipc	ra,0x0
    800060fa:	d90080e7          	jalr	-624(ra) # 80005e86 <free_desc>
      for(int j = 0; j < i; j++)
    800060fe:	4785                	li	a5,1
    80006100:	0297d163          	bge	a5,s1,80006122 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006104:	f9442503          	lw	a0,-108(s0)
    80006108:	00000097          	auipc	ra,0x0
    8000610c:	d7e080e7          	jalr	-642(ra) # 80005e86 <free_desc>
      for(int j = 0; j < i; j++)
    80006110:	4789                	li	a5,2
    80006112:	0097d863          	bge	a5,s1,80006122 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006116:	f9842503          	lw	a0,-104(s0)
    8000611a:	00000097          	auipc	ra,0x0
    8000611e:	d6c080e7          	jalr	-660(ra) # 80005e86 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006122:	0001f597          	auipc	a1,0x1f
    80006126:	00658593          	addi	a1,a1,6 # 80025128 <disk+0x2128>
    8000612a:	0001f517          	auipc	a0,0x1f
    8000612e:	eee50513          	addi	a0,a0,-274 # 80025018 <disk+0x2018>
    80006132:	ffffc097          	auipc	ra,0xffffc
    80006136:	f62080e7          	jalr	-158(ra) # 80002094 <sleep>
  for(int i = 0; i < 3; i++){
    8000613a:	f9040713          	addi	a4,s0,-112
    8000613e:	84ce                	mv	s1,s3
    80006140:	bf41                	j	800060d0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006142:	20058713          	addi	a4,a1,512
    80006146:	00471693          	slli	a3,a4,0x4
    8000614a:	0001d717          	auipc	a4,0x1d
    8000614e:	eb670713          	addi	a4,a4,-330 # 80023000 <disk>
    80006152:	9736                	add	a4,a4,a3
    80006154:	4685                	li	a3,1
    80006156:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000615a:	20058713          	addi	a4,a1,512
    8000615e:	00471693          	slli	a3,a4,0x4
    80006162:	0001d717          	auipc	a4,0x1d
    80006166:	e9e70713          	addi	a4,a4,-354 # 80023000 <disk>
    8000616a:	9736                	add	a4,a4,a3
    8000616c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006170:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006174:	7679                	lui	a2,0xffffe
    80006176:	963e                	add	a2,a2,a5
    80006178:	0001f697          	auipc	a3,0x1f
    8000617c:	e8868693          	addi	a3,a3,-376 # 80025000 <disk+0x2000>
    80006180:	6298                	ld	a4,0(a3)
    80006182:	9732                	add	a4,a4,a2
    80006184:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006186:	6298                	ld	a4,0(a3)
    80006188:	9732                	add	a4,a4,a2
    8000618a:	4541                	li	a0,16
    8000618c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000618e:	6298                	ld	a4,0(a3)
    80006190:	9732                	add	a4,a4,a2
    80006192:	4505                	li	a0,1
    80006194:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006198:	f9442703          	lw	a4,-108(s0)
    8000619c:	6288                	ld	a0,0(a3)
    8000619e:	962a                	add	a2,a2,a0
    800061a0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061a4:	0712                	slli	a4,a4,0x4
    800061a6:	6290                	ld	a2,0(a3)
    800061a8:	963a                	add	a2,a2,a4
    800061aa:	05890513          	addi	a0,s2,88
    800061ae:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800061b0:	6294                	ld	a3,0(a3)
    800061b2:	96ba                	add	a3,a3,a4
    800061b4:	40000613          	li	a2,1024
    800061b8:	c690                	sw	a2,8(a3)
  if(write)
    800061ba:	140d0063          	beqz	s10,800062fa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061be:	0001f697          	auipc	a3,0x1f
    800061c2:	e426b683          	ld	a3,-446(a3) # 80025000 <disk+0x2000>
    800061c6:	96ba                	add	a3,a3,a4
    800061c8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061cc:	0001d817          	auipc	a6,0x1d
    800061d0:	e3480813          	addi	a6,a6,-460 # 80023000 <disk>
    800061d4:	0001f517          	auipc	a0,0x1f
    800061d8:	e2c50513          	addi	a0,a0,-468 # 80025000 <disk+0x2000>
    800061dc:	6114                	ld	a3,0(a0)
    800061de:	96ba                	add	a3,a3,a4
    800061e0:	00c6d603          	lhu	a2,12(a3)
    800061e4:	00166613          	ori	a2,a2,1
    800061e8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061ec:	f9842683          	lw	a3,-104(s0)
    800061f0:	6110                	ld	a2,0(a0)
    800061f2:	9732                	add	a4,a4,a2
    800061f4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061f8:	20058613          	addi	a2,a1,512
    800061fc:	0612                	slli	a2,a2,0x4
    800061fe:	9642                	add	a2,a2,a6
    80006200:	577d                	li	a4,-1
    80006202:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006206:	00469713          	slli	a4,a3,0x4
    8000620a:	6114                	ld	a3,0(a0)
    8000620c:	96ba                	add	a3,a3,a4
    8000620e:	03078793          	addi	a5,a5,48
    80006212:	97c2                	add	a5,a5,a6
    80006214:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006216:	611c                	ld	a5,0(a0)
    80006218:	97ba                	add	a5,a5,a4
    8000621a:	4685                	li	a3,1
    8000621c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000621e:	611c                	ld	a5,0(a0)
    80006220:	97ba                	add	a5,a5,a4
    80006222:	4809                	li	a6,2
    80006224:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006228:	611c                	ld	a5,0(a0)
    8000622a:	973e                	add	a4,a4,a5
    8000622c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006230:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006234:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006238:	6518                	ld	a4,8(a0)
    8000623a:	00275783          	lhu	a5,2(a4)
    8000623e:	8b9d                	andi	a5,a5,7
    80006240:	0786                	slli	a5,a5,0x1
    80006242:	97ba                	add	a5,a5,a4
    80006244:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006248:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000624c:	6518                	ld	a4,8(a0)
    8000624e:	00275783          	lhu	a5,2(a4)
    80006252:	2785                	addiw	a5,a5,1
    80006254:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006258:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000625c:	100017b7          	lui	a5,0x10001
    80006260:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006264:	00492703          	lw	a4,4(s2)
    80006268:	4785                	li	a5,1
    8000626a:	02f71163          	bne	a4,a5,8000628c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000626e:	0001f997          	auipc	s3,0x1f
    80006272:	eba98993          	addi	s3,s3,-326 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006276:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006278:	85ce                	mv	a1,s3
    8000627a:	854a                	mv	a0,s2
    8000627c:	ffffc097          	auipc	ra,0xffffc
    80006280:	e18080e7          	jalr	-488(ra) # 80002094 <sleep>
  while(b->disk == 1) {
    80006284:	00492783          	lw	a5,4(s2)
    80006288:	fe9788e3          	beq	a5,s1,80006278 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000628c:	f9042903          	lw	s2,-112(s0)
    80006290:	20090793          	addi	a5,s2,512
    80006294:	00479713          	slli	a4,a5,0x4
    80006298:	0001d797          	auipc	a5,0x1d
    8000629c:	d6878793          	addi	a5,a5,-664 # 80023000 <disk>
    800062a0:	97ba                	add	a5,a5,a4
    800062a2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800062a6:	0001f997          	auipc	s3,0x1f
    800062aa:	d5a98993          	addi	s3,s3,-678 # 80025000 <disk+0x2000>
    800062ae:	00491713          	slli	a4,s2,0x4
    800062b2:	0009b783          	ld	a5,0(s3)
    800062b6:	97ba                	add	a5,a5,a4
    800062b8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062bc:	854a                	mv	a0,s2
    800062be:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062c2:	00000097          	auipc	ra,0x0
    800062c6:	bc4080e7          	jalr	-1084(ra) # 80005e86 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062ca:	8885                	andi	s1,s1,1
    800062cc:	f0ed                	bnez	s1,800062ae <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062ce:	0001f517          	auipc	a0,0x1f
    800062d2:	e5a50513          	addi	a0,a0,-422 # 80025128 <disk+0x2128>
    800062d6:	ffffb097          	auipc	ra,0xffffb
    800062da:	9c2080e7          	jalr	-1598(ra) # 80000c98 <release>
}
    800062de:	70a6                	ld	ra,104(sp)
    800062e0:	7406                	ld	s0,96(sp)
    800062e2:	64e6                	ld	s1,88(sp)
    800062e4:	6946                	ld	s2,80(sp)
    800062e6:	69a6                	ld	s3,72(sp)
    800062e8:	6a06                	ld	s4,64(sp)
    800062ea:	7ae2                	ld	s5,56(sp)
    800062ec:	7b42                	ld	s6,48(sp)
    800062ee:	7ba2                	ld	s7,40(sp)
    800062f0:	7c02                	ld	s8,32(sp)
    800062f2:	6ce2                	ld	s9,24(sp)
    800062f4:	6d42                	ld	s10,16(sp)
    800062f6:	6165                	addi	sp,sp,112
    800062f8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062fa:	0001f697          	auipc	a3,0x1f
    800062fe:	d066b683          	ld	a3,-762(a3) # 80025000 <disk+0x2000>
    80006302:	96ba                	add	a3,a3,a4
    80006304:	4609                	li	a2,2
    80006306:	00c69623          	sh	a2,12(a3)
    8000630a:	b5c9                	j	800061cc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000630c:	f9042583          	lw	a1,-112(s0)
    80006310:	20058793          	addi	a5,a1,512
    80006314:	0792                	slli	a5,a5,0x4
    80006316:	0001d517          	auipc	a0,0x1d
    8000631a:	d9250513          	addi	a0,a0,-622 # 800230a8 <disk+0xa8>
    8000631e:	953e                	add	a0,a0,a5
  if(write)
    80006320:	e20d11e3          	bnez	s10,80006142 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006324:	20058713          	addi	a4,a1,512
    80006328:	00471693          	slli	a3,a4,0x4
    8000632c:	0001d717          	auipc	a4,0x1d
    80006330:	cd470713          	addi	a4,a4,-812 # 80023000 <disk>
    80006334:	9736                	add	a4,a4,a3
    80006336:	0a072423          	sw	zero,168(a4)
    8000633a:	b505                	j	8000615a <virtio_disk_rw+0xf4>

000000008000633c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000633c:	1101                	addi	sp,sp,-32
    8000633e:	ec06                	sd	ra,24(sp)
    80006340:	e822                	sd	s0,16(sp)
    80006342:	e426                	sd	s1,8(sp)
    80006344:	e04a                	sd	s2,0(sp)
    80006346:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006348:	0001f517          	auipc	a0,0x1f
    8000634c:	de050513          	addi	a0,a0,-544 # 80025128 <disk+0x2128>
    80006350:	ffffb097          	auipc	ra,0xffffb
    80006354:	894080e7          	jalr	-1900(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006358:	10001737          	lui	a4,0x10001
    8000635c:	533c                	lw	a5,96(a4)
    8000635e:	8b8d                	andi	a5,a5,3
    80006360:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006362:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006366:	0001f797          	auipc	a5,0x1f
    8000636a:	c9a78793          	addi	a5,a5,-870 # 80025000 <disk+0x2000>
    8000636e:	6b94                	ld	a3,16(a5)
    80006370:	0207d703          	lhu	a4,32(a5)
    80006374:	0026d783          	lhu	a5,2(a3)
    80006378:	06f70163          	beq	a4,a5,800063da <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000637c:	0001d917          	auipc	s2,0x1d
    80006380:	c8490913          	addi	s2,s2,-892 # 80023000 <disk>
    80006384:	0001f497          	auipc	s1,0x1f
    80006388:	c7c48493          	addi	s1,s1,-900 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000638c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006390:	6898                	ld	a4,16(s1)
    80006392:	0204d783          	lhu	a5,32(s1)
    80006396:	8b9d                	andi	a5,a5,7
    80006398:	078e                	slli	a5,a5,0x3
    8000639a:	97ba                	add	a5,a5,a4
    8000639c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000639e:	20078713          	addi	a4,a5,512
    800063a2:	0712                	slli	a4,a4,0x4
    800063a4:	974a                	add	a4,a4,s2
    800063a6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800063aa:	e731                	bnez	a4,800063f6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063ac:	20078793          	addi	a5,a5,512
    800063b0:	0792                	slli	a5,a5,0x4
    800063b2:	97ca                	add	a5,a5,s2
    800063b4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800063b6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063ba:	ffffc097          	auipc	ra,0xffffc
    800063be:	e66080e7          	jalr	-410(ra) # 80002220 <wakeup>

    disk.used_idx += 1;
    800063c2:	0204d783          	lhu	a5,32(s1)
    800063c6:	2785                	addiw	a5,a5,1
    800063c8:	17c2                	slli	a5,a5,0x30
    800063ca:	93c1                	srli	a5,a5,0x30
    800063cc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063d0:	6898                	ld	a4,16(s1)
    800063d2:	00275703          	lhu	a4,2(a4)
    800063d6:	faf71be3          	bne	a4,a5,8000638c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800063da:	0001f517          	auipc	a0,0x1f
    800063de:	d4e50513          	addi	a0,a0,-690 # 80025128 <disk+0x2128>
    800063e2:	ffffb097          	auipc	ra,0xffffb
    800063e6:	8b6080e7          	jalr	-1866(ra) # 80000c98 <release>
}
    800063ea:	60e2                	ld	ra,24(sp)
    800063ec:	6442                	ld	s0,16(sp)
    800063ee:	64a2                	ld	s1,8(sp)
    800063f0:	6902                	ld	s2,0(sp)
    800063f2:	6105                	addi	sp,sp,32
    800063f4:	8082                	ret
      panic("virtio_disk_intr status");
    800063f6:	00002517          	auipc	a0,0x2
    800063fa:	40a50513          	addi	a0,a0,1034 # 80008800 <syscalls+0x3b8>
    800063fe:	ffffa097          	auipc	ra,0xffffa
    80006402:	140080e7          	jalr	320(ra) # 8000053e <panic>
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
