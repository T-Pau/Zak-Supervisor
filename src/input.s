;  input.s -- input routines
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


max_digit = buffer + 1

.section code

; read digit, returned in X
; maximum allowed digit in A
read_digit {
    clc
    adc #$31
    sta max_digit
    lda #CHAR_CURSOR
    jsr CHROUT
read_first_digit:
    jsr GETIN_CHECKED
    cmp #$31 ; '1'
    bmi read_first_digit
    cmp max_digit
    bpl read_first_digit
    sta tmp1
    sec
    sbc #$30 ; '0'
    sta buffer
    lda tmp1
    jsr bsout_with_cursor
read_return:
    jsr GETIN_CHECKED
    cmp #$0d
    beq end
    cmp #$14
    bne read_return
    jsr backspace_with_cursor
    jmp read_first_digit
end:
    lda #$14
    jsr CHROUT
    ldx buffer
    rts
}


; read hex digit, returns digit in A and last_hex_digit
; returns $81 for return, $80 for backspace
read_hex_digit {
    jsr GETIN_CHECKED
    beq read_hex_digit
    cmp #$30 ; '0'
    bmi control
    cmp #$3a ; ':'
    bpl :+
    sta last_hex_digit
    sec
    sbc #$30
    rts
:    cmp #$41    ; 'A'
    bmi read_hex_digit
    cmp #$47    ; 'G'
    bpl read_hex_digit
    sta last_hex_digit
    sec
    sbc #$37
    rts
control:
    cmp #$0d
    bne :+
    lda #$81
    rts
:    cmp #$14
    bne read_hex_digit
    lda #$80
    rts
}


; read hex byte, returned in A
read_hex_byte {
    lda #CHAR_CURSOR
    jsr CHROUT
read_first_digit:
    jsr read_hex_digit
    bmi read_first_digit
    asl
    asl
    asl
    asl
    sta buffer
    lda last_hex_digit
    jsr bsout_with_cursor
read_second_digit:
    jsr read_hex_digit
    bmi :+
    ora buffer
    sta buffer
    lda last_hex_digit
    jsr bsout_with_cursor
    jmp read_return
:    cmp #$81
    beq read_second_digit
    jsr backspace_with_cursor
    jmp read_first_digit
read_return:
    jsr read_hex_digit
    bpl read_return
    cmp #$81    ; 129 .
    beq end
    jsr backspace_with_cursor
    lda #$f0    ; 240 .
    and buffer
    sta buffer
    jmp read_second_digit
end:
    lda #$14    ; 20 .
    jsr CHROUT
    lda buffer
    rts
}

; reads hex word, returned in x/y
read_hex_word {
    lda #CHAR_CURSOR
    jsr CHROUT
read_first_digit:
    jsr read_hex_digit
    bmi read_first_digit
    asl
    asl
    asl
    asl
    sta buffer
    lda last_hex_digit
    jsr bsout_with_cursor
read_second_digit:
    jsr read_hex_digit
    bmi :+
    ora buffer
    sta buffer
    lda last_hex_digit
    jsr bsout_with_cursor
    jmp read_third_digit
:    cmp #$81
    beq read_second_digit
    jsr backspace_with_cursor
    jmp read_first_digit
read_third_digit:
    jsr read_hex_digit
    bmi :+
    asl
    asl
    asl
    asl
    sta buffer + 1
    lda last_hex_digit
    jsr bsout_with_cursor
    jmp read_fourth_digit
:    cmp #$81
    beq read_third_digit
    jsr backspace_with_cursor
    lda #$f0
    and buffer
    sta buffer
    jmp read_second_digit
read_fourth_digit:
    jsr read_hex_digit
    bmi :+
    ora buffer + 1
    sta buffer + 1
    lda last_hex_digit
    jsr bsout_with_cursor
    jmp read_return
:    cmp #$81
    beq read_fourth_digit
    jsr backspace_with_cursor
    jmp read_third_digit
read_return:
    jsr read_hex_digit
    bpl read_return
    cmp #$81
    beq end
    jsr backspace_with_cursor
    lda #$f0
    and buffer + 1
    sta buffer + 1
    jmp read_fourth_digit
end:
    lda #$14    ; 20 .
    jsr CHROUT
    ldx buffer
    ldy buffer + 1
    rts
}

.section reserved

buffer .reserve 2

last_hex_digit .reserve 1
