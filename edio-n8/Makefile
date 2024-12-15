#MAKEFLAGS= -j8

CC65_HOME = E:/devtools/cc65
SYS	= nes

croper = $(CC65_HOME)/bin/croper
CL   = $(CC65_HOME)/bin/cl65
CC   = $(CC65_HOME)/bin/cc65
AS   = $(CC65_HOME)/bin/ca65
LD   = $(CC65_HOME)/bin/ld65

INC = $(CC65_HOME)/include
ASMINC = $(CC65_HOME)/asminc
# This one comes with VICE

# --static-locals
CFLAGS		:= -O 
AFLAGS		:= -t $(SYS)
BDIR		:=build

vpath %.o $(BDIR)/


SRC_S := crt0.s everdrive_asm.s
SRC_C :=  $(wildcard *.c)
#SRC_C := $(filter-out app-%.c, $(SRC_C))

OBJ = $(SRC_S:.s=.o)
OBJ += $(SRC_C:.c=.o)
OFILES = $(OBJ:%.o=$(BDIR)/%.o)
	
# --------------------------------------------------------------------------
all: $(OBJ) 
	$(LD) -C nes.cfg -o edio-n8.nes $(OFILES) nes.lib -m $(BDIR)/mem.map
	

%.o: %.s
	$(AS) $(AFLAGS) -o $(basename $(BDIR)/$<).o $<

%.o: %.c
	$(CC) $(CFLAGS) -o $(basename $(BDIR)/$<).s $<
	$(AS) $(AFLAGS) $(basename $(BDIR)/$<).s



clean:
	$(RM) $(BDIR)/*.o
	$(RM) $(BDIR)/*.s
	$(RM) $(APDIR)/*.o
