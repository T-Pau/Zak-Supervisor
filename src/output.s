;  output.s -- output routines
;  Copyright (C) 1990-2021 Dieter Baron
;
;  This file is part of Zak Supervisor, a Music Monitor for the Commodore 64.
;  The authors can be contacted at <zak-supervisor@tpau.group>.
;
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions
;  are met:
;  1. Redistributions of source code must retain the above copyright
;     notice, this list of conditions and the following disclaimer.
;  2. The names of the authors may not be used to endorse or promote
;     products derived from this software without specific prior
;     written permission.
;
;  THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS
;  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
;  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
;  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
;  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
;  IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

.export backspace_with_cursor, bsout_with_cursor, color_screen, color_line

.include "zak-supervisor.inc"

backspace_with_cursor:
.scope
	lda #$14 ; backspace
	jsr BSOUT
	lda #$14 ; backspace
	jsr BSOUT
	lda #CHAR_CURSOR ; '_'
	jmp BSOUT
.endscope


bsout_with_cursor:
.scope
	pha
	lda #$14
	jsr BSOUT
	pla
	jsr BSOUT
	lda #CHAR_CURSOR
	jmp BSOUT
.endscope


; fills color ram with color
color_screen:
.scope
	ldx #0
:	sta COLOR_RAM,x
	sta COLOR_RAM + $100,x
	sta COLOR_RAM + $200,x
	sta COLOR_RAM + 1000 - $100,x
	dex
	bne :-
	rts
.endscope


; fills one line in color ram with color
; line number in A, color in X
; uses tmp1, pt1, A, Y
color_line:
.scope
	; 40 is %101000
	sta tmp1
	ldy #0
	sty ptr1 + 1
	asl
	rol ptr1 + 1
	asl
	rol ptr1 + 1
	adc tmp1
	asl
	rol ptr1 + 1
	asl
	rol ptr1 + 1
	asl
	rol ptr1 + 1
	sta ptr1
	lda #>COLOR_RAM
	clc
	adc ptr1 + 1
	sta ptr1 + 1
	txa
	ldy #39
:	sta (ptr1),y
	dey
	bpl :-
	rts
.endscope
