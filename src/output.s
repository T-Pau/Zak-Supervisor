;  output.s -- output routines
;  Copyright (C) Dieter Baron
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

.section code 

backspace_with_cursor {
    lda #$14 ; backspace
    jsr CHROUT
    lda #$14 ; backspace
    jsr CHROUT
    lda #CHAR_CURSOR ; '_'
    jmp CHROUT
}

bsout_with_cursor {
    pha
    lda #$14
    jsr CHROUT
    pla
    jsr CHROUT
    lda #CHAR_CURSOR
    jmp CHROUT
}


; fills color ram with color
color_screen {
    ldx #0
:   sta COLOR_RAM,x
    sta COLOR_RAM + $100,x
    sta COLOR_RAM + $200,x
    sta COLOR_RAM + 1000 - $100,x
    dex
    bne :-
    rts
}

; fills one line in color ram with color
; line number in A, color in X
; uses tmp1, ptr1, A, Y
color_line {
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
:   sta (ptr1),y
    dey
    bpl :-
    rts
}
