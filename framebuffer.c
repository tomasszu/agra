#include <stdio.h>
#include <stdlib.h>
#include "agra.h"

#define FrameWidth 40
#define FrameHeight 20

pixcolor_t * buffer = 0x00000000;

int FrameBufferGetWidth()
{
	return FrameWidth;
}

int FrameBufferGetHeight()
{
	return FrameHeight;
}

pixcolor_t * FrameBufferGetAddress()
{
	if(buffer != 0x00000000) return buffer;
	else
	{
		buffer = (pixcolor_t*) malloc( FrameHeight * FrameWidth * sizeof(pixcolor_t));
		return buffer;
	};

}

int FrameShow()
{
	for(int i = 0; i < FrameHeight; i++)
	  {
	  	for(int j = 0; j < FrameWidth; j++)
	  	{
	  		int r = buffer[i*FrameWidth+j].r;
	  		int g = buffer[i*FrameWidth+j].g;
	  		int b = buffer[i*FrameWidth+j].b;
	  		if(r > g)
	  		{
	  			if(r > b) printf("R");
	  			else printf("M");
	  		}
	  		else if(b > g)
	  		{
	  			if(b > r) printf("B");
	  		}
	  		else if(r == g && g == b)
	  		{
	  			if(r == 0x0000) printf(" ");
	  			else printf("*");
	  		} 
	  		else
	  		{
	  			if(g > b && r > b) printf("Y");
	  			else if( b > r) printf("C");
	  			else printf("G");

	  		};
	  	}
	  	printf("\n");
	  }
	  //printf("%d\n", buffer[2*40+25].r);
	  //printf("%d\n", buffer[2*40+25].g);
	  //printf("%d\n", buffer[2*40+25].b);
	  //printf("%d\n", buffer[2*40+25].op);
	return 0;
}
