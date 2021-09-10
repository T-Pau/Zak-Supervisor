.export expand

.autoimport +

.macpack utility

.include "defines.inc"

expand:
.scope
	ldy #0
loop:
	lda (ptr1),y
	bmi runlength
	sta (ptr2),y
	iny
	bne loop
	inc ptr1 + 1
	inc ptr2 + 1
	bne loop
runlength:
	cmp #$ff
	bne :+
	rts
:	and #$7f
	sta tmp1
	tya
	clc
	adc_16 ptr2
	tya
	sec
	adc_16 ptr1
	ldy #0
	lda (ptr1),y
	ldy tmp1
	dey
runlength_loop:
	sta (ptr2),y
	dey
	bpl runlength_loop
	lda tmp1
	clc
	adc_16 ptr2
	inc_16 ptr1
	ldy #0
	beq loop
.endscope
