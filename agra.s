	.text
	.align	2
	.global	setPixColor
	.type	setPixColor, %function
setPixColor:
	ldr r1, color_addr  // ielade atminas lauku datu sekcijaa
	str r0, [r1]		//saglabaa adresi uz color_op atminas laukaa
	bx lr
	.size	setPixColor, .-setPixColor


	.global	pixel
	.type	pixel, %function
pixel:
	stmfd sp!, {r4,r5,fp,lr}
	add fp, sp, #12	// aizbidam fp, 3 vietas uz augsu no sp
	sub sp, sp, #16	//atbrivojam vel 4 vietas uz leju stekaa

	str r0, [sp]	// saglabajam r0 (x) stekaa
	str r1, [sp, #4]	// saglabajam r1 (y) stekaa
	str r2, [sp, #8]	// saglabajam r2 (color_op) stekaa
	buffer_clear:
		ldr r3, clean_addr
		ldrb r0, [r3, #0]
		cmp r0, #0x01
		beq pixel_main
		stmfd sp!, {r0,r3,fp,lr}
		bl clear
		ldmfd sp!, {r0,r3,fp,lr}
		mov r0, #0x01
		strb r0, [r3, #0]
	pixel_main:
	bl FrameBufferGetWidth
	str r0, [sp, #12]	// saglabajam r0 (FrameWidth) stekaa
	bl FrameBufferGetHeight
	// ignorejam pikselus arpus kadra
	yRangeCheck:
	ldr r1, [sp, #4]	// r1 = y
	cmp r0, r1			// ja FrameHeight < y
	ble end 			// break
	cmp r1, #0			// ja y < 0
	blt end 			// break
	xRangeCheck:
	ldr r0, [sp, #12]	// r0 = FrameWidth
	ldr r1, [sp]		// r1 = x
	cmp r0, r1			// ja FrameWidth < x
	ble end 			// break
	cmp r1, #0			// ja x < 0
	blt end 			// break

	bl FrameBufferGetAddress
	mov r4, r0			// r4 = buff addr
	ldr r3, [sp, #4]	// ielade y no steka
	mov r3, r3, lsl #2
	ldr r1, [sp, #12]	// ielade FrameWidth no steka
	mul r3, r1, r3		//y*FrameWidth
	ldr r2, [sp]		// ielade x no steka
	mov r2, r2, lsl #2
	add r5, r3, r2		// +x
	ldr r2, [sp, #8]	// ielade color_op
	ldr r0, [r2, #0]	// !!!! cancel vnk JO VERTIB VAIG IZLOBIT
	//gatavojamies pixelOp funkcijai
	ldr r1, [r4, r5]	// r1 = buffer[y*FrameWidth+x]
	mov r2, #0
	mov r3, #0

	stmfd sp!, {r1,r4,r5}
	bl pixelOp
	ldmfd sp!, {r1,r4,r5}

	str r0, [r4, r5]	// buffer[y*FrameWidth+x] = r5

	end:
	sub sp, fp, #12	// aizbidam sp, 3 vietu uz leju no fp
	ldmfd sp!, {r4,r5,fp,lr}
	bx lr
	.size	pixel, .-pixel

	.global	pixelOp
	.type	pixelOp, %function
pixelOp:
	stmfd sp!, {r4,fp,lr}
	add fp, sp, #8	// aizbidam fp, 2 vietu uz augsu no sp
	// iegustam op bitus
	and r2, r0, #0xC0000000
	cmp r2, #0x00
	beq endOp 		// ja 0, tad rakstam paari
	// iegustam krasas izveli bez op bitiem
	and r3, r0, #0x3FFFFFFF
	ldr r4, =0x40000000
	cmp r2, r4	// vai veicama AND operacija
	bne orCheck
	// iegustam buffer pikseli bez op bitiem
	and r1, r1, #0x3FFFFFFF
	and r3, r3, r1	//pixcolor AND buffer pix
	add r0, r4, r3  //pieliekam krasai klat AND op izveli
	b endOp
	orCheck:
	ldr r4, =0x80000000
	cmp r2, r4 // vai veicama OR operacija
	bne xorCheck
	// iegustam buffer pikseli bez op bitiem
	and r1, r1, #0x3FFFFFFF
	orr r3, r3, r1	//pixcolor OR buffer pix
	add r0, r4, r3  //pieliekam krasai klat OR op izveli
	b endOp
	xorCheck:
	ldr r4, =0xC0000000
	cmp r2, r4 // vai veicama OR operacija
	bne endOp
	// iegustam buffer pikseli bez op bitiem
	and r1, r1, #0x3FFFFFFF
	eor r3, r3, r1	//pixcolor XOR buffer pix
	add r0, r4, r3  //pieliekam krasai klat XOR op izveli

	endOp:
	ldmfd sp!, {r4,fp,lr}
	bx lr
	.size	pixelOp, .-pixelOp

	.global	line
	.type	line, %function
line:
	stmfd sp!, {r4,fp,lr}
	add	fp, sp, #8		// aizbidam fp, 2 vietas uz augsu no sp
	sub	sp, sp, #40		//atbrivojam vel 10 vietas uz leju stekaa
	str	r0, [sp, #12]	// x1 stekaa
	str	r1, [sp, #8]	// y1 stekaa
	str	r2, [sp, #4]	// x2 stekaa
	str	r3, [sp]		// y2 stekaa

	cmp	r2, r0			//(x2>x1)
	ble	x2Smaller
		sub	r4, r2, r0	//dx = x2-x1
		str	r4, [sp, #16]	// dx stekaa
		b	yCheck
	x2Smaller:
		sub	r4, r0, r2		//dx = x1-x2
		str	r4, [sp, #16]	//dx stekaa
	yCheck:
		cmp	r3, r1			//(y2>y1)
		ble	y2Smaller
			sub	r4, r3, r1		//dy = y2-y1
			str	r4, [sp, #20]	//dy stekaa
			b	dAssign
		y2Smaller:
			sub	r4, r1, r3		//dy = y1-y2
			str	r4, [sp, #20]	//dy stekaa
	dAssign:
		rsb	r4, r4, #0		//dy = dy*(-1)
		str	r4, [sp, #20]
		cmp	r0, r2			//if(x1>=x2)
		bge	x1Larger_2
			mov	r4, #1
			str	r4, [sp, #24]	//sx = 1
			b	yCheck_2
		x1Larger_2:
			mvn	r4, #0
			str	r4, [sp, #24]	//sx = 0
	yCheck_2:
		cmp	r1, r3			//if(y1>=y2)
		bge	y1Larger
			mov	r4, #1
			str	r4, [sp, #28]	//sy = 1
			b	errAssign
		y1Larger:
			mvn	r4, #0
			str	r4, [sp, #28]	//sy = 0
	errAssign:
		ldr	r2, [sp, #16]	//dx
		ldr	r3, [sp, #20]	//dy
		add	r3, r2, r3		// err = dx + dy
		str	r3, [sp, #32]	//err
	lineLoop:
		ldr r4, color_addr // ielade adresi uz .data lauku
		ldr r2, [r4, #0]   // panem color_op adresi no .data lauka
		ldr	r1, [sp, #8]	//y1
		ldr	r0, [sp, #12]	//x1
		bl	pixel
		ldr	r2, [sp, #12]	//x1
		ldr	r3, [sp, #4]	//x2
		cmp	r2, r3			// if (x1 == x2
		bne	continue
			ldr	r2, [sp, #8]	//y1
			ldr	r3, [sp]		//y2
			cmp	r2, r3			// && y1 == y2)
			beq	EndLine			// break
	continue:
		ldr	r3, [sp, #32]	//err
		lsl	r4, r3, #1		//e2 = 2 * err;
		str	r4, [sp, #36]	//e2
		ldr	r2, [sp, #20]	//dy
		cmp	r4, r2			// if (e2 >= dy)
		blt	check2 
			add	r3, r2, r3		//err += dy
			str	r3, [sp, #32]
			ldr	r2, [sp, #12]	//x1
			ldr	r3, [sp, #24]	//sx
			add	r3, r2, r3		//x1 += sx
			str	r3, [sp, #12]
		check2:
			ldr	r3, [sp, #16]	//dx
			cmp	r4, r3			// if (e2 <= dx)
			bgt	lineLoop
				ldr	r2, [sp, #32]	//err
				add	r3, r2, r3		//err += dx
				str	r3, [sp, #32]
				ldr	r2, [sp, #8]	//y1
				ldr	r3, [sp, #28]	//sy
				add	r3, r2, r3		//y0 += sy
				str	r3, [sp, #8]
				b	lineLoop

	EndLine:
		sub	sp, fp, #8
		ldmfd sp!, {r4,fp,lr}
		bx lr
	.size	line, .-line

	.global	circle
	.type	circle, %function
circle:
	stmfd sp!, {r4,r5,fp,lr}
	add fp, sp, #12	// aizbidam fp, 3 vietu uz augsu no sp
	sub sp, sp, #8	//atbrivojam vel 2 vietas uz leju stekaa

	str r2, [sp]	// saglabajam r2 (r) stekaa

	mov r2, #0		// int P = 0
	ldr r3, [sp]	// int Q = r
	mov r4, r3
	mov r4, r4, lsl #1	//(2*r)
	rsb r4, r4, #3 // D = 3-(2*r);
	str r4, [sp, #4]	// saglabajam r4 (D) stekaa

	stmfd sp!, {r0,r1,r2,r3}
	bl Do8Ways
	ldmfd sp!, {r0,r1,r2,r3}

	loop_4:
		ldr r4, [sp, #4] // D
		cmp r4, #0	//(D < 0)
		bge dHigher_3 //if(D >= 0)
			mov r5, r2, lsl #2	//4*P
			add r5, r5, #6		//(4*P + 6)
			add r4, r4, r5		// D += (4*P + 6);
			str r4, [sp, #4]
			add r2, r2, #1		//++P
			b print_4
			dHigher_3:
			sub r5, r2, r3		//(P-Q)
			mov r5, r5, lsl #2	//4*(P-Q)
			add r5, r5, #10		//(4*(P-Q) + 10)
			add r4, r4, r5		//D += (4*(P-Q) + 10);
			str r4, [sp, #4]
			add r2, r2, #1		//++P
			sub r3, r3, #1		//--Q
		print_4:
				stmfd sp!, {r0,r1,r2,r3}
				bl Do8Ways
				ldmfd sp!, {r0,r1,r2,r3}
	while_4:
		cmp r2, r3
		ble loop_4

	sub sp, fp, #12	// aizbidam sp, 3 vietas uz leju no fp
	ldmfd sp!, {r4,r5,fp,lr}
	bx lr
	.size	circle, .-circle

	.global	Do8Ways
	.type	Do8Ways, %function
Do8Ways:
	stmfd sp!, {fp,lr}
	add fp, sp, #4	// aizbidam fp, 1 vietu uz augsu no sp
	sub sp, sp, #32	//atbrivojam vel 8 vietas uz leju stekaa

	add r4, r0, r2 //x+P
	str r4, [sp]
	sub r4, r0, r2 //x-P
	str r4, [sp, #4]
	add r4, r0, r3 //x+Q
	str r4, [sp, #8]
	sub r4, r0, r3 //x-Q
	str r4, [sp, #12]
	add r4, r1, r2 //y+P
	str r4, [sp, #16]
	sub r4, r1, r2 //y-P
	str r4, [sp, #20]
	add r4, r1, r3 //y+Q
	str r4, [sp, #24]
	sub r4, r1, r3 //y-Q
	str r4, [sp, #28]

	ldr r3, color_addr // ielade adresi uz .data lauku
	ldr r2, [r3, #0]   // panem color_op adresi no .data lauka

	ldr r0, [sp]
	ldr r1, [sp, #24]
	stmfd sp!, {r2}
	bl pixel			//pixel(x+p, y+q, buffer);
	ldmfd sp!, {r2}

	ldr r0, [sp, #4]
	ldr r1, [sp, #24]
	stmfd sp!, {r2}
	bl pixel			//pixel(x-p, y+q, buffer);
	ldmfd sp!, {r2}

	ldr r0, [sp]
	ldr r1, [sp, #28]
	stmfd sp!, {r2}
	bl pixel			//pixel(x+p, y-q, buffer);
	ldmfd sp!, {r2}

	ldr r0, [sp, #4]
	ldr r1, [sp, #28]
	stmfd sp!, {r2}
	bl pixel			//pixel(x-p, y-q, buffer);
	ldmfd sp!, {r2}

	ldr r0, [sp, #8]
	ldr r1, [sp, #16]
	stmfd sp!, {r2}
	bl pixel			//pixel(x+q, y+p, buffer);
	ldmfd sp!, {r2}

	ldr r0, [sp, #12]
	ldr r1, [sp, #16]
	stmfd sp!, {r2}
	bl pixel			//pixel(x-q, y+p, buffer);
	ldmfd sp!, {r2}

	ldr r0, [sp, #8]
	ldr r1, [sp, #20]
	stmfd sp!, {r2}
	bl pixel			//pixel(x+q, y-p, buffer);
	ldmfd sp!, {r2}

	ldr r0, [sp, #12]
	ldr r1, [sp, #20]
	stmfd sp!, {r2}
	bl pixel			//pixel(x-q, y-p, buffer);
	ldmfd sp!, {r2}


	sub sp, fp, #4	// aizbidam sp, 1 vietu uz leju no fp
	ldmfd sp!, {fp,lr}
	bx lr
	.size	Do8Ways, .-Do8Ways


	.global	SWAP
	.type	SWAP, %function
SWAP:
	stmfd sp!, {fp,lr}
	add fp, sp, #4	// aizbidam fp, 1 vietu uz augsu no sp
	sub	sp, sp, #12 // rezervejam 3 vietas stekaa

	str	r0, [sp]		//x stekaa
	str	r1, [sp, #4]	//y stekaa

	ldr	r3, [sp]		//x adrese
	ldr	r3, [r3]		//*x
	str	r3, [sp, #8]	//*x stekaa

	ldr	r3, [sp, #4]	//y adrese
	ldr	r2, [r3]		//*y

	ldr	r3, [sp]		//x adrese;
	str	r2, [r3]		//*x = *y

	ldr	r3, [sp, #4]	//y adrese
	ldr	r2, [sp, #8]	//*x
	str	r2, [r3]		//*y = *x

	sub sp, fp, #4	// aizbidam sp, 1 vietu uz leju no fp
	ldmfd sp!, {fp,lr}
	bx lr
	.size	SWAP, .-SWAP


	.global	triangleFill
	.type	triangleFill, %function
triangleFill:
	stmfd sp!, {fp,lr}
	add	fp, sp, #4
	sub	sp, sp, #96
	str	r0, [sp, #12]	//x1
	str	r1, [sp, #8]	//y1
	str	r2, [sp, #4]	//x2
	str	r3, [sp]		//y2

	mov	r3, #0
	str	r3, [fp, #-40]	//changed1 = 0
	mov	r3, #0
	str	r3, [fp, #-36]	//changed2 = 0

	ldr	r2, [sp, #8]	//y1
	ldr	r3, [sp]		//y2
	cmp	r2, r3			//if (y1 > y2)
	ble	y1smaller
		sub	r1, fp, #100	//adress of y2
		sub	r0, fp, #92		//adress of y1
		bl	SWAP
		sub	r1, fp, #96		//adress of x2
		sub	r0, fp, #88		//adress of x1
		bl	SWAP
	y1smaller:
		ldr	r2, [sp, #8]	//y1
		ldr	r3, [fp, #8]	//y3
		cmp	r2, r3			//if(y1 > y3)
		ble	y1smaller2
			add	r1, fp, #8		//adress of y3
			sub	r0, fp, #92		//adress of y1
			bl	SWAP
			sub	r0, fp, #88		//adress of x1
			add	r1, fp, #4		//adress of x3
			bl	SWAP
		y1smaller2:
			ldr	r2, [sp]		//y2
			ldr	r3, [fp, #8]	//y3
			cmp	r2, r3			//if(y2 > y3)
			ble	y2smaller2
				add	r1, fp, #8		//adress of y3
				sub	r0, fp, #100	//adress of y2
				bl	SWAP
				sub	r0, fp, #96		//adress of x2
				add	r1, fp, #4		//adress of x3
				bl	SWAP
	y2smaller2:
		ldr	r3, [sp, #12]		//x1
		str	r3, [fp, #-64]		//t2x = x1
		str	r3, [fp, #-68]		//t1x = t2x = x1
		ldr	r3, [sp, #8]		//y1
		str	r3, [fp, #-60]		//y = y1

		ldr	r2, [sp, #4]		//x2
		ldr	r3, [sp, #12]		//x1
		sub	r3, r2, r3			//dx1 = (x2 - x1)
		str	r3, [fp, #-84]		//dx1 stekaa
		cmp	r3, #0				//if(dx1<0)
		bge	dxPos
			rsb	r3, r3, #0			//dx1=-dx1;
			str	r3, [fp, #-84]
			mvn	r3, #0				//signx1=0
			str	r3, [fp, #-32]		//signx1
			b	dx2Check
		dxPos:
			mov	r3, #1
			str	r3, [fp, #-32]			//signx1=1
dx2Check:
	ldr	r2, [sp]		//y2
	ldr	r3, [sp, #8]			//y1
	sub	r3, r2, r3		//dy1 = (y2 - y1)
	str	r3, [fp, #-80]	//dy1

	ldr	r2, [fp, #4]	//x3
	ldr	r3, [sp, #12]	//x1
	sub	r3, r2, r3		//dx2 = (x3 - x1)
	str	r3, [fp, #-76]	//dx2

	cmp	r3, #0		//if(dx2<0)
	bge	dx2Pos
	rsb	r3, r3, #0		//dx2=-dx2
	str	r3, [fp, #-76]
	mvn	r3, #0
	str	r3, [fp, #-28]	//signx2=-1
	b	valueSwap1
dx2Pos:
	mov	r3, #1
	str	r3, [fp, #-28]	//signx2=1;
valueSwap1:
	ldr	r2, [fp, #8]		//y3
	ldr	r3, [sp, #8]		//y1
	sub	r3, r2, r3			//dy2 = (y3 - y1)
	str	r3, [fp, #-72]		//dy2

	ldr	r2, [fp, #-80]		//dy1
	ldr	r3, [fp, #-84]		//dx1
	cmp	r2, r3
	ble	dy1S
	sub	r1, fp, #80		// dy1 addr
	sub	r0, fp, #84		// dx1 addr
	bl	SWAP
	mov	r3, #1
	str	r3, [fp, #-40]		//changed1=1
dy1S:
	ldr	r2, [fp, #-72]		//dy2
	ldr	r3, [fp, #-76]		//dx2
	cmp	r2, r3				//if (dy2 > dx2)
	ble	dy2S
	sub	r1, fp, #76		//dx2 addr
	sub	r0, fp, #72		//dy2 addr
	bl	SWAP
	mov	r3, #1
	str	r3, [fp, #-36]	//changed2 = 1
dy2S:
	ldr	r3, [fp, #-76]	//dx2
	asr	r3, r3, #1		//e2 = (dx2>>1)
	str	r3, [fp, #-20]	//e2

	ldr	r2, [sp, #8] 	//y1
	ldr	r3, [sp]		//y2
	cmp	r2, r3			//if(y1==y2)
	beq	next
	ldr	r3, [fp, #-84]	//dx1
	asr	r3, r3, #1		//e1 = (dx1>>1)
	str	r3, [fp, #-24]	//e1
for:
	mov	r3, #0		//int i=0
	str	r3, [fp, #-16]	//i
	b	forTest
triLoop1:
	mov	r2, #0
	str	r2, [fp, #-48]		//t1xp=0
	mov	r3, #0
	str	r3, [fp, #-44]		//t2xp=0
	ldr	r2, [fp, #-68]		//t1x
	ldr	r3, [fp, #-64]		//t2x
	cmp	r2, r3				//if(t1x<t2x)
	bge	t2xB
	//minx=t1x; maxx=t2x;
	ldr	r3, [fp, #-68]
	str	r3, [fp, #-56]
	ldr	r3, [fp, #-64]
	str	r3, [fp, #-52]
	b	triWhile1
t2xB:
	//maxx=t1x; minx=t2x;
	ldr	r3, [fp, #-64]
	str	r3, [fp, #-56]
	ldr	r3, [fp, #-68]
	str	r3, [fp, #-52]
	b	triWhile1
iSmaller1:
	ldr	r3, [fp, #-16]	//i
	add	r3, r3, #1		//i++
	str	r3, [fp, #-16]
	//e1 += dy1;
	ldr	r3, [fp, #-80] //dy1
	ldr	r2, [fp, #-24]
	add	r3, r2, r3
	str	r3, [fp, #-24]
	b	triWhile2
e1G:
	//e1 -= dx1;
	ldr	r3, [fp, #-84] //dx1
	ldr	r2, [fp, #-24] //e1
	sub	r3, r2, r3
	str	r3, [fp, #-24]
	//if (changed1)
	ldr	r3, [fp, #-40] //changed1
	cmp	r3, #0
	beq	next1
	//t1xp=signx1
	ldr	r3, [fp, #-32]
	str	r3, [fp, #-48]
triWhile2:
	//(e1 >= dx1)
	ldr	r3, [fp, #-84] //dx1
	ldr	r2, [fp, #-24] //e1
	cmp	r2, r3
	bge	e1G
	//if (changed1) break;
	ldr	r3, [fp, #-40] //changed1
	cmp	r3, #0
	bne	next1
	//else t1x += signx1;
	ldr	r2, [fp, #-68] //signx1
	ldr	r3, [fp, #-32] //t1x
	add	r3, r2, r3
	str	r3, [fp, #-68]
triWhile1:
	ldr	r3, [fp, #-84]		//dx1
	ldr	r2, [fp, #-16]		//i
	cmp	r2, r3				//i<dx1
	blt	iSmaller1
next1:
	//e2 += dy2;
	ldr	r3, [fp, #-72] //dy2
	ldr	r2, [fp, #-20] //e2
	add	r3, r2, r3
	str	r3, [fp, #-20]
	b	triWhile3Cond
triWhile3:
	//e2 -= dx2;
	ldr	r3, [fp, #-76]
	ldr	r2, [fp, #-20]
	sub	r3, r2, r3
	str	r3, [fp, #-20]
	//if (changed2)
	ldr	r3, [fp, #-36]
	cmp	r3, #0
	beq	next2
	//t2xp=signx2
	ldr	r3, [fp, #-28]
	str	r3, [fp, #-44]
triWhile3Cond:
	//while (e2 >= dx2)
	ldr	r3, [fp, #-76] //dx2
	ldr	r2, [fp, #-20] //e2
	cmp	r2, r3
	bge	triWhile3
	//if (changed2)
	ldr	r3, [fp, #-36]
	cmp	r3, #0
	bne	next2
	//t2x += signx2;
	ldr	r2, [fp, #-64] //t2x
	ldr	r3, [fp, #-28] //signx2
	add	r3, r2, r3
	str	r3, [fp, #-64]
	b	next1
next2:
	//if(minx>t1x)
	ldr	r2, [fp, #-56]
	ldr	r3, [fp, #-68]
	cmp	r2, r3
	ble	minxS
	str	r3, [fp, #-56] //minx=t1x
minxS:
	//if(minx>t2x)
	ldr	r2, [fp, #-56]
	ldr	r3, [fp, #-64]
	cmp	r2, r3
	ble	minxS2
	str	r3, [fp, #-56] //minx=t2x
minxS2:
	//maxx<t1x
	ldr	r2, [fp, #-52]
	ldr	r3, [fp, #-68]
	cmp	r2, r3
	bge	maxxL
	//maxx=t1x
	str	r3, [fp, #-52]
maxxL:
	//if(maxx<t2x)
	ldr	r2, [fp, #-52]
	ldr	r3, [fp, #-64]
	cmp	r2, r3
	bge	maxxL2
	str	r3, [fp, #-52] //maxx=t2x
maxxL2:
	//line(minx, y, maxx, y)
	ldr	r3, [fp, #-60] //y
	ldr	r2, [fp, #-52] //maxx
	ldr	r1, [fp, #-60]
	ldr	r0, [fp, #-56] //minx
	bl	line
	//if(!changed1)
	ldr	r3, [fp, #-40]
	cmp	r3, #0
	bne	changed3
	ldr	r2, [fp, #-68]
	ldr	r3, [fp, #-32]
	add	r3, r2, r3		//t1x += signx1
	str	r3, [fp, #-68]
changed3:
	//t1x+=t1xp;
	ldr	r2, [fp, #-68]
	ldr	r3, [fp, #-48]
	add	r3, r2, r3
	str	r3, [fp, #-68]
	//if(!changed2)
	ldr	r3, [fp, #-36]
	cmp	r3, #0
	bne	changed4
	ldr	r2, [fp, #-64]
	ldr	r3, [fp, #-28]
	add	r3, r2, r3		//t2x += signx2
	str	r3, [fp, #-64]
changed4:
	//t2x+=t2xp
	ldr	r2, [fp, #-64]
	ldr	r3, [fp, #-44]
	add	r3, r2, r3
	str	r3, [fp, #-64]
	//y += 1;
	ldr	r3, [fp, #-60] //y
	add	r3, r3, #1
	str	r3, [fp, #-60]
	//if(y==y2) break
	ldr	r3, [sp]		//y2
	ldr	r2, [fp, #-60]	//y
	cmp	r2, r3
	beq	next
forTest:
	ldr	r3, [fp, #-84]	//dx1
	ldr	r2, [fp, #-16]	//i
	cmp	r2, r3			//i<dx1
	blt	triLoop1
next:
	//dx1 = (x3 - x2)
	ldr	r2, [fp, #4]
	ldr	r3, [sp, #4]
	sub	r3, r2, r3
	str	r3, [fp, #-84]
	//if(dx1<0)
	cmp	r3, #0
	bge	dx1G
	//dx1=-dx1; signx1=-1
	ldr	r3, [fp, #-84]
	rsb	r3, r3, #0
	str	r3, [fp, #-84]
	mvn	r3, #0
	str	r3, [fp, #-32]
	b	dy1Check
dx1G:
	//signx1=1
	mov	r3, #1
	str	r3, [fp, #-32]
dy1Check:
	//dy1 = (y3 - y2)
	ldr	r2, [fp, #8]
	ldr	r3, [sp]
	sub	r3, r2, r3
	str	r3, [fp, #-80]
	//t1x=x2
	ldr	r3, [sp, #4]
	str	r3, [fp, #-68]
	//if (dy1 > dx1)
	ldr	r2, [fp, #-80]
	ldr	r3, [fp, #-84]
	cmp	r2, r3
	ble	dy1S_2
	//SWAP(&dy1,&dx1)
	sub	r1, fp, #84
	sub	r0, fp, #80
	bl	SWAP
	//changed1 = 1
	mov	r3, #1
	str	r3, [fp, #-40]
	b	for2
dy1S_2:
	//changed1 = 0
	mov	r3, #0
	str	r3, [fp, #-40]
for2:
	//e1 = (dx1>>1)
	ldr	r3, [fp, #-84]
	asr	r3, r3, #1
	str	r3, [fp, #-24]
	//int i = 0
	mov	r3, #0
	str	r3, [fp, #-12]
	b	iCheck
triFor:
	//t1xp=0; t2xp=0;
	mov	r3, #0
	str	r3, [fp, #-48]
	mov	r3, #0
	str	r3, [fp, #-44]
	//if(t1x<t2x)
	ldr	r2, [fp, #-68]
	ldr	r3, [fp, #-64]
	cmp	r2, r3
	bge	t1xL
	//minx=t1x; maxx=t2x;
	ldr	r3, [fp, #-68]
	str	r3, [fp, #-56]
	ldr	r3, [fp, #-64]
	str	r3, [fp, #-52]
	b	triWhileCond4
t1xL:
	//minx=t2x; maxx=t1x;
	ldr	r3, [fp, #-64]
	str	r3, [fp, #-56]
	ldr	r3, [fp, #-68]
	str	r3, [fp, #-52]
	b	triWhileCond4
triWhile4:
	//e1 += dy1
	ldr	r3, [fp, #-80]
	ldr	r2, [fp, #-24]
	add	r3, r2, r3
	str	r3, [fp, #-24]
	//e1 >= dx1
	ldr	r3, [fp, #-84]
	ldr	r2, [fp, #-24]
	cmp	r2, r3
	blt	triWhile5exit
	//e1 -= dx1;
	ldr	r3, [fp, #-84]
	ldr	r2, [fp, #-24]
	sub	r3, r2, r3
	str	r3, [fp, #-24]
	//if (changed1)
	ldr	r3, [fp, #-40]
	cmp	r3, #0
	beq	next3
	//t1xp=signx1
	ldr	r3, [fp, #-32]
	str	r3, [fp, #-48]
triWhile5exit:
	//if (changed1)
	ldr	r3, [fp, #-40]
	cmp	r3, #0
	bne	next3
	//t1x += signx1
	ldr	r2, [fp, #-68]
	ldr	r3, [fp, #-32]
	add	r3, r2, r3
	str	r3, [fp, #-68]
	//if(i<dx1)
	ldr	r3, [fp, #-84]
	ldr	r2, [fp, #-12]
	cmp	r2, r3
	bge	triWhileCond4
	//i++
	ldr	r3, [fp, #-12]
	add	r3, r3, #1
	str	r3, [fp, #-12]
triWhileCond4:
	//while(i<dx1)
	ldr	r3, [fp, #-84]
	ldr	r2, [fp, #-12]
	cmp	r2, r3
	blt	triWhile4
	b	next3
next3:
	b	triWhile5Cond
triWhile5:
	//e2 += dy2;
	ldr	r3, [fp, #-72]
	ldr	r2, [fp, #-20]
	add	r3, r2, r3
	str	r3, [fp, #-20]
	b	triWhile6Cond
triWhile6:
	//e2 -= dx2
	ldr	r3, [fp, #-76]
	ldr	r2, [fp, #-20]
	sub	r3, r2, r3
	str	r3, [fp, #-20]
	//if(changed2)
	ldr	r3, [fp, #-36]
	cmp	r3, #0
	beq	next4
	//t2xp=signx2
	ldr	r3, [fp, #-28]
	str	r3, [fp, #-44]
triWhile6Cond:
	//(e2 >= dx2)
	ldr	r3, [fp, #-76]
	ldr	r2, [fp, #-20]
	cmp	r2, r3
	bge	triWhile6
	//if (changed2)
	ldr	r3, [fp, #-36]
	cmp	r3, #0
	bne	next4
	//t2x += signx2
	ldr	r2, [fp, #-64]
	ldr	r3, [fp, #-28]
	add	r3, r2, r3
	str	r3, [fp, #-64]
triWhile5Cond:
	//while (t2x!=x3)
	ldr	r3, [fp, #4]
	ldr	r2, [fp, #-64]
	cmp	r2, r3
	bne	triWhile5
	b	next4
next4:
	//if(minx>t1x)
	ldr	r2, [fp, #-56]
	ldr	r3, [fp, #-68]
	cmp	r2, r3
	ble	minxS3
	//minx=t1x
	ldr	r3, [fp, #-68]
	str	r3, [fp, #-56]
minxS3:
	//if(minx>t2x)
	ldr	r2, [fp, #-56]
	ldr	r3, [fp, #-64]
	cmp	r2, r3
	ble	minxS4
	//minx=t2x
	ldr	r3, [fp, #-64]
	str	r3, [fp, #-56]
minxS4:
	//if(maxx<t1x)
	ldr	r2, [fp, #-52]
	ldr	r3, [fp, #-68]
	cmp	r2, r3
	bge	maxxL3
	//maxx=t1x
	ldr	r3, [fp, #-68]
	str	r3, [fp, #-52]
maxxL3:
	//if(maxx<t2x)
	ldr	r2, [fp, #-52]
	ldr	r3, [fp, #-64]
	cmp	r2, r3
	bge	maxxL4
	//maxx=t2x
	ldr	r3, [fp, #-64]
	str	r3, [fp, #-52]
maxxL4:
	//line(minx, y, maxx, y);
	ldr	r3, [fp, #-60]
	ldr	r2, [fp, #-52]
	ldr	r1, [fp, #-60]
	ldr	r0, [fp, #-56]
	bl	line
	//if(!changed1)
	ldr	r3, [fp, #-40]
	cmp	r3, #0
	bne	notChanged
	//t1x += signx1;
	ldr	r2, [fp, #-68]
	ldr	r3, [fp, #-32]
	add	r3, r2, r3
	str	r3, [fp, #-68]
notChanged:
	// t1x+=t1xp;
	ldr	r2, [fp, #-68]
	ldr	r3, [fp, #-48]
	add	r3, r2, r3
	str	r3, [fp, #-68]
	// if(!changed2)
	ldr	r3, [fp, #-36]
	cmp	r3, #0
	bne	notChanged2
	//t2x += signx2
	ldr	r2, [fp, #-64]
	ldr	r3, [fp, #-28]
	add	r3, r2, r3
	str	r3, [fp, #-64]
notChanged2:
	//t2x+=t2xp
	ldr	r2, [fp, #-64]
	ldr	r3, [fp, #-44]
	add	r3, r2, r3
	str	r3, [fp, #-64]
	//y += 1
	ldr	r3, [fp, #-60]
	add	r3, r3, #1
	str	r3, [fp, #-60]
	//if(y>y3)
	ldr	r3, [fp, #8]
	ldr	r2, [fp, #-60]
	cmp	r2, r3
	bgt	return
	ldr	r3, [fp, #-12]
	add	r3, r3, #1
	str	r3, [fp, #-12]
iCheck:
	//i<=dx1
	ldr	r3, [fp, #-84]
	ldr	r2, [fp, #-12]
	cmp	r2, r3
	ble	triFor

return:
	sub	sp, fp, #4
	ldmfd sp!, {fp,lr}
	bx lr
	.size	triangleFill, .-triangleFill


	.global	clear
	.type	clear, %function
clear:
	stmfd sp!, {fp,lr}
	add fp, sp, #4	// aizbidam fp, 1 vietu uz augsu no sp
	sub sp, sp, #8	//atbrivojam vel 2 vietas uz leju stekaa
	bl FrameBufferGetWidth
	str r0, [sp]	// saglabajam r0 (FrameWidth) stekaa
	bl FrameBufferGetHeight
	str r0, [sp, #4]	// saglabajam r0 (FrameHeight) stekaa

	bl FrameBufferGetAddress
	mov r1, #0		//counter i (height)
	mov r2, #0		//counter j (width)
	mov r4, #0x00000000 //notirisanai
	loop1:
		mov r2, #0
	loop2:
		ldr r3, [sp]	// ielade FrameWidth no steka
		mul r3, r1, r3		//i*FrameWidth
		add r3, r2, r3		// +j
		str r4, [r0, r3]	//r4 = buffer[i*FrameWidth+j]
	test2:
		add r2, #4 // counter j + 4
		ldr r3, [sp]	// ielade FrameWidth
		cmp r3, r2, lsr #2 // vai count < counter/4
		bhi loop2
	test1:
		add r1, #4 // counter i + 4
		ldr r3, [sp, #4]	// ielade FrameHeight
		cmp r3, r1, lsr #2 // vai count < counter/4
		bhi loop1

	sub sp, fp, #4	// aizbidam sp, 1 vietu uz leju no fp
	ldmfd sp!, {fp,lr}
	mov r0, #0
	bx lr
	.size	clear, .-clear


color_addr: .word color_op
clean_addr: .word clean_flag

	.data
color_op:
	.word 0x00000000
clean_flag:
	.byte 0x00