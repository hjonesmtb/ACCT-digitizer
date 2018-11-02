#
TARGET = led_demo

TARGET_IP = 142.90.101.226

QUARTUS_ROOTDIR ?= /opt/intelFPGA/18.0/quartus #Path to Quartus install
SOPC_FILE = ../../soc_system.sopcinfo #Path to SOPC File
HPS_MODULE = hps_0 #Name of HPS module in soc system
HPS_FILE = hps_0.h #Name of HPS incude file

#
#
ALT_DEVICE_FAMILY = soc_cv_av
HWLIBS_ROOT = ../hwlib


CFLAGS = $(MAKEFLAGS) -g -Wall -I$(HWLIBS_ROOT)/include \
	-I$(HWLIBS_ROOT)/include/$(ALT_DEVICE_FAMILY) -D$(ALT_DEVICE_FAMILY)

LDFLAGS = -g -Wall -static

CROSS_COMPILE = arm-linux-gnu-
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)gcc
ARCH = arm

SOURCES = $(wildcard *.c)
OBJECTS = $(patsubst %.c,%.o,${SOURCES})

.PHONY: build
build: $(TARGET)

$(TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS)   $^ -o $@

$(TARGET)_TEST:
	make $(TARGET) MAKEFLAGS=-DTEST
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@

%.o : %.c $(HPS_FILE)
	$(CC) $(CFLAGS) -c $< -o $@

$(HPS_FILE) : $(SOPC_FILE)
	$(QUARTUS_ROOTDIR)/sopc_builder/bin/sopc-create-header-files $(SOPC_FILE) \
			--single $(HPS_FILE) --module $(HPS_MODULE)

.PHONEY: test
test: $(TARGET)_TEST
	qemu-arm $(TARGET)_TEST

.PHONEY: send
send: $(TARGET)
	scp $(TARGET) root@$(TARGET_IP):/home/root

.PHONEY: run
run: send
	ssh root@$(TARGET_IP) "/home/root/$(TARGET)"

.PHONY: clean
clean:
	rm -f $(TARGET) *.a *.o *~  $(TARGET)_TEST

.PHONEY: clean_all
clean_all: clean
	rm -f $(HPS_FILE)

