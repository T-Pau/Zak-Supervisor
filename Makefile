all: zak-supervisor.prg

zak-supervisor.prg: zak-supervisor.s defines.inc c64-asm-3000.cfg
	cl65 -C c64-asm-3000.cfg -t c64 -o zak-supervisor.prg zak-supervisor.s
