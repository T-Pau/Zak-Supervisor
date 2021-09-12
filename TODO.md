- documentation on the C64
- Ask for `sta`/`jsr` first, skip `x`/`y` for `sta`.
- packed version that can be started with `RUN`.
	`pucrunch -ffast -c64 -x12800 zak-supervisor.prg zak-basic.prg`
- d64 image with packed and unpacked version
- return to BASIC when exiting (instead of reset)
- reset raster time: reset all 4 bytes
- help screen?
