#include <stdio.h>
#include <stdlib.h>
#include "agra.h"

int main ()
{
	pixcolor_t color_op;
	pixop_t pixop;
	pixop = PIXEL_COPY;

	color_op.r = 0x03ff;
	color_op.g = 0x03ff;
	color_op.b = 0x03ff;
	color_op.op = pixop;
	setPixColor(&color_op);
	pixel(25, 2, &color_op);
	
	color_op.r = 0x0000;
	color_op.g = 0x0000;
	color_op.b = 0x03ff;
	line(0, 0, 39, 19);

	color_op.r = 0x03ff;
	color_op.g = 0x0000;
	color_op.b = 0x0000;
	circle(20, 10, 7);

	color_op.r = 0x0000;
	color_op.g = 0x03ff;
	color_op.b = 0x0000;
	triangleFill(20,13,28,19,38,6);

	FrameShow();
	return 0;
}