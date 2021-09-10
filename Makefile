all: zak-supervisor.prg

zak-supervisor.prg: zak-supervisor.s expand.s init.bin monitor.bin defines.inc c64-asm-3000.cfg
	cl65 -C c64-asm-3000.cfg -t c64 -o zak-supervisor.prg zak-supervisor.s expand.s

init.bin: init.scr
	perl screen.pl -c init.scr > init.bin || (rm init.bin; exit 1)

monitor.bin: monitor.scr
	perl screen.pl -c monitor.scr > monitor.bin || (rm monitor.bin; exit 1)
