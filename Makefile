platform=$(shell uname)

PROJECT		:= test

SRCDIR 		:= src
OUTPUTDIR 	:= bin
OBJDIR 		:= obj

CPU = cortex-m4

OBJECTS	+= main.o \
	       sysinit.o \
	       crt0.o

TOOLPATH = /usr
TEENSY3X_BASEPATH = teensy_basepath
TEENSYDIR = ~/opt/arduino-1.8.1/hardware/

TARGETTYPE = arm-none-eabi
TEENSY3X_INC     = $(TEENSY3X_BASEPATH)/include
GCC_INC          = $(TOOLPATH)/$(TARGETTYPE)/include

VPATH = $(TEENSY3X_BASEPATH)/common
VPATH += :./src
				
INCDIRS  = -I$(GCC_INC)
INCDIRS += -I$(TEENSY3X_INC)
INCDIRS += -I./include
INCDIRS += -I.

LSCRIPT = $(TEENSY3X_BASEPATH)/common/Teensy31_flash.ld

OPTIMIZATION = 0
DEBUG = -g

LIBDIRS  = -L"$(TOOLPATH)\$(TARGETTYPE)\lib"
LIBS =

GCFLAGS = -Wall -Wextra -Werror -fno-common -mcpu=$(CPU) -mthumb -O$(OPTIMIZATION) $(DEBUG)
GCFLAGS += $(INCDIRS)
ASFLAGS = -mcpu=$(CPU)
LDFLAGS  = -nostdlib -nostartfiles -Map=$(OUTPUTDIR)/$(PROJECT).map -T$(LSCRIPT)
LDFLAGS += --cref
LDFLAGS += $(LIBDIRS)
LDFLAGS += $(LIBS)

BINDIR = $(TOOLPATH)/bin

CC = $(BINDIR)/arm-none-eabi-gcc
AS = $(BINDIR)/arm-none-eabi-as
AR = $(BINDIR)/arm-none-eabi-ar
LD = $(BINDIR)/arm-none-eabi-ld
OBJCOPY = $(BINDIR)/arm-none-eabi-objcopy
SIZE = $(BINDIR)/arm-none-eabi-size
OBJDUMP = $(BINDIR)/arm-none-eabi-objdump
REMOVE = rm -f


#########################################################################

all:: $(PROJECT).hex $(PROJECT).bin stats dump

$(PROJECT).bin: $(PROJECT).elf
	$(OBJCOPY) -O binary -j .text -j .data $(OUTPUTDIR)/$(PROJECT).elf $(OUTPUTDIR)/$(PROJECT).bin

$(PROJECT).hex: $(PROJECT).elf
	$(OBJCOPY) -R .stack -O ihex $(OUTPUTDIR)/$(PROJECT).elf $(OUTPUTDIR)/$(PROJECT).hex

$(PROJECT).elf: $(OBJECTS)
	$(LD) $(OBJDIR)/*.o $(LDFLAGS) -o $(OUTPUTDIR)/$(PROJECT).elf


stats: $(PROJECT).elf
	$(SIZE) $(OUTPUTDIR)/$(PROJECT).elf
	
dump: $(PROJECT).elf
	$(OBJDUMP) -h $(OUTPUTDIR)/$(PROJECT).elf	

program:: $(PROJECT).hex $(PROJECT).bin stats dump load

load: $(PROJECT).elf
	$(OBJCOPY) -O ihex -R .eeprom $(OUTPUTDIR)/$(PROJECT).elf $(OUTPUTDIR)/$(PROJECT).hex
	tools/teensy_loader_cli --mcu=mk20dx256 -w $(OUTPUTDIR)/$(PROJECT).hex

clean:
	$(REMOVE) $(OBJDIR)/*.o
	$(REMOVE) $(OUTPUTDIR)/$(PROJECT).hex
	$(REMOVE) $(OUTPUTDIR)/$(PROJECT).elf
	$(REMOVE) $(OUTPUTDIR)/$(PROJECT).map
	$(REMOVE) $(OUTPUTDIR)/$(PROJECT).bin
	$(REMOVE) *.lst

#  The toolvers target provides a sanity check, so you can determine
#  exactly which version of each tool will be used when you build.
#  If you use this target, make will display the first line of each
#  tool invocation.
#  To use this feature, enter from the command-line:
#    make -f $(PROJECT).mak toolvers
toolvers:
	$(CC) --version | sed q
	$(AS) --version | sed q
	$(LD) --version | sed q
	$(AR) --version | sed q
	$(OBJCOPY) --version | sed q
	$(SIZE) --version | sed q
	$(OBJDUMP) --version | sed q
	
.c.o :
	@echo Compiling $<, writing to $@...
	$(CC) $(GCFLAGS) -c $< -o $(OBJDIR)/$@ 2>&1 | sed -e 's/\(\w\+\):\([0-9]\+\):/\1(\2):/'
    
.cpp.o :
	@echo Compiling $<, writing to $@...
	$(CC) $(GCFLAGS) -c $<

.s.o :
	@echo Assembling $<, writing to $@...
	$(AS) $(ASFLAGS) -o $(OBJDIR)/$@ $<  2>&1 | sed -e 's/\(\w\+\):\([0-9]\+\):/\1(\2):/'

