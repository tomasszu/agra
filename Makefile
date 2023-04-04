# Sample Makefile

TARGET := agra

OBJ := $(TARGET)_main.o $(TARGET).o framebuffer.o

ASFLAGS = -mcpu=xscale -alh=$*.lis -L
CFLAGS = -mcpu=xscale -O0 -Wall
LDFLAGS =

CC := arm-linux-gnueabi-gcc
AS := arm-linux-gnueabi-as

.PHONY: test all clean distclean	# Veids kā izvairīies no kļūdiņām, iekļauti visi mērķi

test:	all
	qemu-arm -L /usr/arm-linux-gnueabi $(TARGET)

all:	$(TARGET)       # Mērķis visiem Makefailiem - ko taisīt

clean:
	$(RM) $(TARGET) *.o

distclean:	clean
	$(RM) *.lis *~
								# allhfiles - failu virkne, simbolisks mainīgais
allhfiles := $(wildcard *.h)	# Salasa visus tos failus, kam galā ir .h ar f-ju wildcard

$(TARGET):	$(OBJ)			# Mūsu mērķim vajadzēs object failus
	$(CC) $(LDFLAGS) -o $@ $^

%.o:	%.s                 # Veidos objektus no assambler failiem
	$(AS) -g $(ASFLAGS) -o $@ $<    # AS kompilators

%.o:	%.c $(allhfiles)                 # Veidos objektus no C failiem
	$(CC) -g $(CFLAGS) -o $@ -c $<    # C kompilators

%.s:	%.c $(allhfiles)				# Veidos assambler no C failiem
	$(CC) $(CFLAGS) -fomit-frame-pointer -o $@ -S $<    # C kompilators
