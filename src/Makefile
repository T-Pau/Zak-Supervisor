DEPDIR := .deps

CC = cl65
CFLAGS = -t c64
LD = cl65
LDFLAGS_64 = -t c64


DISK = zak-supervisor.d64
PROGRAMS = \
	zak-supervisor.prg \
	zak-supervisor-run.prg

all: ${DISK}

SOURCES = \
	expand.s \
	graphics.s \
	input.s \
	output.s \
	zak-supervisor.s

OBJECTS = ${SOURCES:%.s=%-64.o}

${DISK}: ${PROGRAMS} mkd64 filelist
	perl mkd64 ${DISK} "zak supervisor,21" filelist


%-64.o : %.s ${DEPDIR}/%-64.o.d | ${DEPDIR}
	${CC} -o $@ ${CFLAGS_64} --create-dep ${DEPDIR}/$@.d -c $<

${DEPDIR}: ; @mkdir -p $@

DEPFILES := ${OBJECTS:%=${DEPDIR}/%.d}
${DEPFILES}:

include $(wildcard ${DEPFILES})

zak-supervisor.prg: ${OBJECTS} c64-asm-3000.cfg
	${LD} ${LDFLAGS} -Ln zak-supervisor.sym -C c64-asm-3000.cfg -o zak-supervisor.prg ${OBJECTS}

zak-supervisor-run.prg: zak-supervisor.prg
	pucrunch -ffast -c64 -x12800 zak-supervisor.prg zak-supervisor-run.prg

help.bin: help.scr
	perl screen.pl -c help.scr > help.bin || (rm help.bin; exit 1)

init.bin: init.scr
	perl screen.pl -c init.scr > init.bin || (rm init.bin; exit 1)

monitor.bin: monitor.scr
	perl screen.pl -c monitor.scr > monitor.bin || (rm monitor.bin; exit 1)

graphics-64.o: help.bin init.bin monitor.bin
