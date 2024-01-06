;  zak-supervisor.s -- Zak Supervisor
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

; keys:

; 1-8 - set position N
; left - decrement current position (low byte only)
; right - increment current position (low byte only)
; up - decrement current position by 16 (low byte only)
; down - increment current position by 16 (low byte only)
; + - increment current position by $100
; - - decrement current position by $100
; Shift-+ - increment current position by $1000
; Shift-- - decrement current position by $1000
; Run/Stop - reset maximum raster time
; Shift-E - exit (reset)

.section code

.public entry .address 12800 .used {
    jmp start
    jmp restart
}

start {
    lda #CTRL_COLOR_NORMAL
    jsr CHROUT
    jsr CLRSCR
    lda #CTRL_COLOR_FOCUS
    jsr CHROUT
    ldx #VIC_ADDRESS(screen, charset)
    stx VIC_VIDEO_ADDRESS
    ldx #COLOR_BACKGROUND
    stx VIC_BORDER_COLOR
    stx VIC_BACKGROUND_COLOR
    copy_screen start_screen
    lda #9
    ldx #COLOR_FOCUS
    jsr color_line
    ldx #9
    ldy #11
    clc
    jsr PLOT
    lda #CHAR_CURSOR
    jsr CHROUT
    ldx #$00
    stx filename_length
    jsr read_filename
    lda #9
    ldx #COLOR_NORMAL
    jsr color_line
    lda filename_length
    beq load_ok
    jsr load_music
    ldx ST
    cpx #$40
    beq load_ok
    jmp start
load_ok:
    ; init: sta or jsr
    lda #11
    ldx #COLOR_FOCUS
    jsr color_line
    ldx #11
    ldy #35
    clc
    jsr PLOT
    lda #2
    jsr read_digit
    lda #$20
    dex
    beq :+
    ldx #COLOR_DISABLED
    lda #13
    jsr color_line
    lda #14
    jsr color_line
    lda #$8d
:   sta init_music_instruction
    lda #11
    ldx #COLOR_NORMAL
    jsr color_line

    ; init: a
    lda #12
    ldx #COLOR_FOCUS
    jsr color_line
    ldx #12
    ldy #17
    clc
    jsr PLOT
    jsr read_hex_byte
    sta init_music_a
    lda #12
    ldx #COLOR_NORMAL
    jsr color_line
    lda init_music_instruction
    bpl :+
    jmp read_init_address
:

    ; init: x
    lda #13
    ldx #COLOR_FOCUS
    jsr color_line
    ldx #13
    ldy #17
    clc
    jsr PLOT
    jsr read_hex_byte
    sta init_music_x
    lda #13
    ldx #COLOR_NORMAL
    jsr color_line

    ; init: y
    lda #14
    ldx #COLOR_FOCUS
    jsr color_line
    ldx #14
    ldy #17
    clc
    jsr PLOT
    jsr read_hex_byte
    sta init_music_y
    lda #14
    ldx #COLOR_NORMAL
    jsr color_line

read_init_address:
    ; init: address
    lda #15
    ldx #COLOR_FOCUS
    jsr color_line
    ldx #15
    ldy #17
    clc
    jsr PLOT
    jsr read_hex_word
    stx init_music + 1
    sty init_music
    lda #15
    ldx #COLOR_NORMAL
    jsr color_line

    ; play: address
    lda #17
    ldx #COLOR_FOCUS
    jsr color_line
    ldx #17
    ldy #17
    clc
    jsr PLOT
    jsr read_hex_word
    stx play_music + 1
    sty play_music
    lda #17
    ldx #COLOR_NORMAL
    jsr color_line

    ; play: number of interrupts
    lda #18
    ldx #COLOR_FOCUS
    jsr color_line
    ldx #18
    ldy #33
    clc
    jsr PLOT
    lda #4
    jsr read_digit
    stx number_of_interrupts
    jsr init_positions

.private setup_playing_screen:
    ldx #0
    stx current_interrupt
    stx in_help
    jsr display_play_screen
    sei
    ldx #VIC_INTERRUPT_RASTER
    stx VIC_INTERRUPT_MASK
    ldx #0
    stx CIA1_TIMER_A_CONTROL
    lda #$1b
    sta VIC_CONTROL_1
    lda #$33
    sta VIC_RASTER
    ldx number_of_interrupts
    dex
    lda irq_low,x
    sta IRQ_VECTOR
    lda irq_high,x
    sta IRQ_VECTOR + 1
    nop
    lda #$35
    sta $01
init_music_a_instruction:
init_music_a = init_music_a_instruction + 1
    lda #$00
init_music_x_instruction:
init_music_x = init_music_x_instruction + 1
    ldx #$00
init_music_y_instruction:
init_music_y = init_music_y_instruction + 1
    ldy #$00
init_music_instruction:
init_music = init_music_instruction + 1
    jsr $0000
    lda #$37
    sta $01
    cli

main_loop:
    jsr GETIN_CHECKED
    beq main_loop
    cmp #$2b ; +
    bne not_plus
    inc monitor_current + 1
update_current:
    lda monitor_current + 1
update_page:
    sta monitor_page + 1
    jsr format_hex
    stx screen_monitor_current - 8
    sta screen_monitor_current - 7
    jmp main_loop
not_plus:
    cmp #$2d ; -
    bne not_minus
    ; previous page
    dec monitor_current + 1
    jmp update_current
not_minus:
    cmp #$db ; shift +
    bne not_shift_puls
    lda monitor_current + 1
    clc
    adc #$10
    sta monitor_current + 1
    jmp update_page
not_shift_puls:
    cmp #$dd ; shift -
    bne not_shift_minus
    lda monitor_current + 1
    sec
    sbc #$10
    sta monitor_current + 1
    jmp update_page
not_shift_minus:
    cmp #$1d ; right
    bne not_right
    lda #COLOR_NORMAL
    ldx monitor_current
    sta color_monitor_page,x
    inx
update_page_low:
    lda #COLOR_FOCUS
    sta color_monitor_page,x
    stx monitor_current
    txa
    jsr format_hex
    stx screen_monitor_current - 6
    sta screen_monitor_current - 5
    jmp main_loop
not_right:
    cmp #$9d ; left
    bne not_left
    ldx monitor_current
    lda #COLOR_NORMAL
    sta color_monitor_page,x
    dex
    jmp update_page_low
not_left:
    cmp #$11 ; down
    bne not_down
    ldx monitor_current
    lda #COLOR_NORMAL
    sta color_monitor_page,x
    txa
    clc
    adc #40
    bcc :+
    adc #15
    cmp #40
    bcc :+
    sbc #40
:    tax
    jmp update_page_low
not_down:
    cmp #$91 ; up
    bne not_up
    ldx monitor_current
    lda #COLOR_NORMAL
    sta color_monitor_page,x
    txa
    sec
    sbc #40
    bcs :+
    sbc #15
    cmp #255-39
    bcs :+
    adc #40
:    tax
    jmp update_page_low
not_up:    cmp #$03 ; run/stop
    bne not_runstop
    ldx #3
    lda #0
:    sta maximum_raster_time,x
    dex
    bpl :-
    jmp main_loop
not_runstop:
    cmp #$31 ; 1
    bne not_one
    lda monitor_current
    sta monitor_1
    jsr format_hex
    stx screen_monitor_1 - 6
    sta screen_monitor_1 - 5
    lda monitor_current + 1
    sta monitor_1 + 1
    jsr format_hex
    stx screen_monitor_1 - 8
    sta screen_monitor_1 - 7
    jmp main_loop
not_one:
    cmp #$32 ; 2
    bne not_two
    lda monitor_current
    sta monitor_2
    jsr format_hex
    stx screen_monitor_2 - 6
    sta screen_monitor_2 - 5
    lda monitor_current + 1
    sta monitor_2 + 1
    jsr format_hex
    stx screen_monitor_2 - 8
    sta screen_monitor_2 - 7
    jmp main_loop
not_two:
    cmp #$33 ; 3
    bne not_three
    lda monitor_current
    sta monitor_3
    jsr format_hex
    stx screen_monitor_3 - 6
    sta screen_monitor_3 - 5
    lda monitor_current + 1
    sta monitor_3 + 1
    jsr format_hex
    stx screen_monitor_3 - 8
    sta screen_monitor_3 - 7
    jmp main_loop
not_three:
    cmp #$34 ; 4
    bne not_four
    lda monitor_current
    sta monitor_4
    jsr format_hex
    stx screen_monitor_4 - 6
    sta screen_monitor_4 - 5
    lda monitor_current + 1
    sta monitor_4 + 1
    jsr format_hex
    stx screen_monitor_4 - 8
    sta screen_monitor_4 - 7
    jmp main_loop
not_four:
    cmp #$35 ; 5
    bne not_five
    lda monitor_current
    sta monitor_5
    jsr format_hex
    stx screen_monitor_5 - 6
    sta screen_monitor_5 - 5
    lda monitor_current + 1
    sta monitor_5 + 1
    jsr format_hex
    stx screen_monitor_5 - 8
    sta screen_monitor_5 - 7
    jmp main_loop
not_five:
    cmp #$36 ; 6
    bne not_six
    lda monitor_current
    sta monitor_6
    jsr format_hex
    stx screen_monitor_6 - 6
    sta screen_monitor_6 - 5
    lda monitor_current + 1
    sta monitor_6 + 1
    jsr format_hex
    stx screen_monitor_6 - 8
    sta screen_monitor_6 - 7
    jmp main_loop
not_six:
    cmp #$37 ; 7
    bne not_seven
    lda monitor_current
    sta monitor_7
    jsr format_hex
    stx screen_monitor_7 - 6
    sta screen_monitor_7 - 5
    lda monitor_current + 1
    sta monitor_7 + 1
    jsr format_hex
    stx screen_monitor_7 - 8
    sta screen_monitor_7 - 7
    jmp main_loop
not_seven:
    cmp #$38 ; 8
    bne not_eight
    lda monitor_current
    sta monitor_8
    jsr format_hex
    stx screen_monitor_8 - 6
    sta screen_monitor_8 - 5
    lda monitor_current + 1
    sta monitor_8 + 1
    jsr format_hex
    stx screen_monitor_8 - 8
    sta screen_monitor_8 - 7
    jmp main_loop
not_eight:
    cmp #$0d ; return
    bne not_return
    lda monitor_current
    sta monitor_running
    jsr format_hex
    stx screen_position_running + 2
    sta screen_position_running + 3
    lda monitor_current + 1
    sta monitor_running + 1
    jsr format_hex
    stx screen_position_running
    sta screen_position_running + 1
ignore:
    jmp main_loop
not_return:
    cmp #$c5 ; shift E
    bne not_shift_e
    brk
not_shift_e:
    cmp #CTRL_F7
    bne ignore
    ldx #1
    stx in_help
    jsr display_help_screen
    ; FALLTHROUGH to main_loop_help

main_loop_help:
    jsr GETIN_CHECKED
    cmp #CTRL_F7
    bne main_loop_help
    jsr display_play_screen
    ldx #0
    stx in_help
    jmp main_loop
}

; restart without init
restart {
    ldx #COLOR_BACKGROUND
    stx VIC_BORDER_COLOR
    stx VIC_BACKGROUND_COLOR
    ldx #<(screen / $40) | (charset / $400)
    stx VIC_VIDEO_ADDRESS
    jmp setup_playing_screen
}

display_play_screen {
    lda #COLOR_NORMAL
    jsr color_screen
    copy_screen playing_screen
    ldx #0
    ldy #0
    lda #$24 ; '$'
:   sta screen_rastertime_current - 1,y
    sta screen_rastertime_maximum - 1,y
    iny
    iny
    iny
    iny
    iny
    inx
    cpx number_of_interrupts
    bne :-
    ldx #199
    stx running_index
    ldx monitor_current
    lda #COLOR_FOCUS
    sta color_monitor_page,x

    ; update positions
    lda #<positions
    sta ptr1
    lda #>positions
    sta ptr1 + 1
    ldy #0
loop:
    lda (ptr1),y
    sta ptr2
    iny
    lda (ptr1),y
    sta ptr2 + 1
    sty tmp_y_1 + 1
    ldy #0
    lda (ptr2),y
    sta init_value
    iny
    lda (ptr2),y
    sta init_value + 1
tmp_y_1:
    ldy #00
    iny
    lda (ptr1),y
    sta ptr2
    iny
    lda (ptr1),y
    sta ptr2 + 1
    iny
    sty tmp_y_2 + 1

    ldy #3
    lda init_value
    jsr format_hex
    sta (ptr2),y
    dey
    txa
    sta (ptr2),y
    dey
    lda init_value + 1
    jsr format_hex
    sta (ptr2),y
    dey
    txa
    sta (ptr2),y

tmp_y_2:
    ldy #$00
    cpy #10 * 4
    bne loop
    rts
}

display_help_screen {
    lda #COLOR_NORMAL
    jsr color_screen
    copy_screen help_screen
    rts
}


; filename is returned at filename, length at filename_length
; cursor must be at correct position
read_filename {
    jsr GETIN_CHECKED
    cmp #$0d
    beq return
    cmp #$14
    beq backspace
    cmp #$20
    bmi read_filename
    cmp #$60
    bpl read_filename
    inc filename_length
    ldx filename_length
    cpx #$11
    bne character
    dec filename_length
    bne read_filename
character:
    ; TODO: use bsout_with_cursor
    pha
    lda #$14
    jsr CHROUT
    pla
    jsr CHROUT
    lda #CHAR_CURSOR
    jsr CHROUT
    jmp read_filename
backspace:
    dec filename_length
    ldx filename_length
    cpx #$ff
    bne character
    inc filename_length
    beq read_filename
return:
    ldx filename_length
    beq end
convert_to_petscii:
    lda screen_filename,x
    cmp #$20
    bpl :+
    clc
    adc #$40
:    sta filename,x
    dex
    bpl convert_to_petscii
end:
    lda #$14
    jmp CHROUT
}

load_music {
    lda #0
    jsr SETMSG
    ldx #<filename
    ldy #>filename
    lda filename_length
    jsr SETNAM
    lda #$01
    ldx LAST_DEVICE
    bne :+
    ldx #$08
:   ldy #$03
    jsr SETLFS
    lda #0
    jmp LOAD
}

; low byte of rasterline to start at in A
play {
:    cmp VIC_RASTER
    bcs :-
    inc VIC_BORDER_COLOR
    lda #$35
    sta $01
    lda VIC_RASTER
    ldx current_interrupt
    sta current_raster_time,x
jsr_play_music:
.private play_music = jsr_play_music + 1
    jsr $0000
    lda VIC_RASTER
    dec VIC_BORDER_COLOR
    ldx current_interrupt
    sec
    sbc current_raster_time,x
    sta current_raster_time,x
    cmp maximum_raster_time,x
    bmi :+
    sta maximum_raster_time,x
:    inx
    stx current_interrupt
    ldx in_help
    bne end_play
    ldx running_index
    cpx #40
    bcc non_focus_line1
    cpx #121
    bcs non_focus_line1
    lda #COLOR_LINE2
    bne store_non_focus
non_focus_line1:
    lda #COLOR_LINE1
store_non_focus:
    sta color_monitor_running,x
    sta color_monitor_running + 40,x
    inx
    cpx #40
    bne :+
    ldx #80
    bne inc_end
:    cpx #120
    bne :+
    ldx #160
    bne inc_end
:    cpx #200
    bne inc_end
    ldx #0
inc_end:
    stx running_index
load_monitor_running:
.private monitor_running = load_monitor_running + 1
    lda $ffff
    jsr format_hex
    tay
    txa
    ldx running_index
    sta screen_monitor_running,x
    tya
    sta screen_monitor_running + 40,x
    cpx #40
    bcc focus_line1
    cpx #121
    bcs focus_line1
    lda #COLOR_LINE2_FOCUS
    bne store_focus
focus_line1:
    lda #COLOR_LINE1_FOCUS
store_focus:
    sta color_monitor_running,x
    sta color_monitor_running + 40,x
end_play:
    rts
}

irq_single {
    lda #0
    jsr play
    lda #0
    jsr update_monitor_page
    lda #$80
    jsr update_monitor_page
    jsr switch_for_page
    jsr wait_for_high_set
    jmp update_display
}

irq_double {
    lda #0
    jsr play
    lda #0
    jsr update_monitor_page
    lda #$80
    jsr update_monitor_page
    jsr switch_for_page
    lda #207
    jsr play
    jsr wait_for_high_set
    jmp update_display
}

;   3: 51, 150 (155), 259
irq_tripple {
    lda #0
    jsr play
    lda #0
    jsr update_monitor_page
    lda #150
    jsr play
    jsr switch_for_page
    jsr wait_for_high_set
    lda #<259
    jsr play
    lda #$80
    jsr update_monitor_page
    jmp update_display
}

;   4: 51, 129, 207, 285
irq_quadruple {
    lda #0
    jsr play
    lda #0
    ldx #$80
    jsr update_monitor_page
    lda #129
    jsr play
    jsr switch_for_page
    lda #207
    jsr play
    lda #$80
    tax
    jsr update_monitor_page
    jsr wait_for_high_set
    lda #<285
    jsr play
    jmp update_display
}

; offset in A, number of bytes in X
update_monitor_page {
    ldy in_help
    bne end_update_monitor_page
    .if DEBUG_DISPLAY {
        dec VIC_BORDER_COLOR
    }
    sta monitor_page
    clc
    adc #<screen_monitor_page
    sta load_monitor_page + 4
    lda #0
    adc #>screen_monitor_page
    sta load_monitor_page + 5
    ldx #$80
load_monitor_page:
.private monitor_page = load_monitor_page + 1
    lda $ff00,x
    sta screen_monitor_page,x
    dex
    bpl load_monitor_page
    .if DEBUG_DISPLAY {
        inc VIC_BORDER_COLOR
    }
end_update_monitor_page:
    rts
}

update_display {
    ldx in_help
    beq :+
    jmp end_irq
    ; switch back to our charset
:    ldx #<((screen / $40) | (charset / $400))
    stx VIC_VIDEO_ADDRESS

    .if DEBUG_DISPLAY {
        dec VIC_BORDER_COLOR
    }

    ; update raster times
    ldx #<screen_rastertime_current
    stx ptr3
    ldx #>screen_rastertime_current
    stx ptr3 + 1
    ldx #<screen_rastertime_maximum
    stx ptr4
    ldx #>screen_rastertime_maximum
    stx ptr4 + 1
    ldy #0
loop:
    sty current_interrupt
    lda current_raster_time,y
    jsr format_hex
    ldy #1
    sta (ptr3),y
    txa
    dey
    sta (ptr3),y
    ldy current_interrupt
    lda maximum_raster_time,y
    jsr format_hex
    ldy #1
    sta (ptr4),y
    txa
    dey
    sta (ptr4),y
    clc
    lda #5
    adc ptr3
    sta ptr3
    bcc :+
    inc ptr3 + 1
    clc
:    lda #5
    adc ptr4
    sta ptr4
    bcc :+
    inc ptr4 + 1
:    ldy current_interrupt
    iny
    cpy number_of_interrupts
    bne loop

    ; update current and 1-8
load_monitor_current:
.private monitor_current = load_monitor_current + 1
    lda $ffff
    jsr format_hex
    stx screen_monitor_current
    sta screen_monitor_current + 1
load_monitor_1:
.private monitor_1 = load_monitor_1 + 1
    lda $ffff
    jsr format_hex
    stx screen_monitor_1
    sta screen_monitor_1 + 1
load_monitor_2:
.private monitor_2 = load_monitor_2 + 1
    lda $ffff
    jsr format_hex
    stx screen_monitor_2
    sta screen_monitor_2 + 1
load_monitor_3:
.private monitor_3 = load_monitor_3 + 1
    lda $ffff
    jsr format_hex
    stx screen_monitor_3
    sta screen_monitor_3 + 1
load_monitor_4:
.private monitor_4 = load_monitor_4 + 1
    lda $ffff
    jsr format_hex
    stx screen_monitor_4
    sta screen_monitor_4 + 1
load_monitor_5:
.private monitor_5 = load_monitor_5 + 1
    lda $ffff
    jsr format_hex
    stx screen_monitor_5
    sta screen_monitor_5 + 1
load_monitor_6:
.private monitor_6 = load_monitor_6 + 1
    lda $ffff
    jsr format_hex
    stx screen_monitor_6
    sta screen_monitor_6 + 1
load_monitor_7:
.private monitor_7 = load_monitor_7 + 1
    lda $ffff
    jsr format_hex
    stx screen_monitor_7
    sta screen_monitor_7 + 1
load_monitor_8:
.private monitor_8 = load_monitor_8 + 1
    lda $ffff
    jsr format_hex
    stx screen_monitor_8
    sta screen_monitor_8 + 1

    ; reset current interrupt
    ldx #$00
    stx current_interrupt

    .if DEBUG_DISPLAY {
        inc VIC_BORDER_COLOR
    }

end_irq:
    ; bank in kernal and end interrupt
    ldx #$37
    stx $01
    ldx #VIC_INTERRUPT_RASTER
    stx VIC_INTERRUPT_REQUEST
    jmp ENDIRQ
}

init_positions {
    ldx #3
    lda #0
:    sta maximum_raster_time,x
    dex
    bpl :-
    ldx #$00
    ldy #$10
    stx monitor_page
    sty monitor_page + 1
    stx monitor_current
    sty monitor_current + 1
    stx monitor_1
    sty monitor_1 + 1
    stx monitor_2
    sty monitor_2 + 1
    stx monitor_3
    sty monitor_3 + 1
    stx monitor_4
    sty monitor_4 + 1
    stx monitor_5
    sty monitor_5 + 1
    stx monitor_6
    sty monitor_6 + 1
    stx monitor_7
    sty monitor_7 + 1
    stx monitor_8
    sty monitor_8 + 1
    stx monitor_running
    sty monitor_running + 1
    rts
}


; converts A to two hex digits returned in x/a
format_hex {
    pha
    lsr
    lsr
    lsr
    lsr
    cmp #$0a
    bmi digit_high
    sec
    sbc #$09
    bne end_high
digit_high:
    clc
    adc #$30
end_high:
    tax
    pla
    and #$0f
    cmp #$0a
    bmi digit_low
    sec
    sbc #$09
    bne end_low
digit_low:
    clc
    adc #$30
end_low:
    rts
}

switch_for_page {
    ldx in_help
    bne end
    ldx #192
:    cpx VIC_RASTER
    bcs :-
    ldx #$14
:    dex
    bne :-
    ldx #$17
    stx VIC_VIDEO_ADDRESS
end:
    rts
}


wait_for_high_set {
:    lda VIC_CONTROL_1
    bpl :-
    rts
}


.section reserved

init_value .reserve 2

in_help .reserve 1

running_index .reserve 1

number_of_interrupts .reserve 1

current_interrupt .reserve 1

filename .reserve 17
filename_length .reserve 1

maximum_raster_time .reserve 4
current_raster_time .reserve 4


.section data

positions {
    .data monitor_current, screen_monitor_current - 8
    .data monitor_1, screen_monitor_1 - 8
    .data monitor_2, screen_monitor_2 - 8
    .data monitor_3, screen_monitor_3 - 8
    .data monitor_4, screen_monitor_4 - 8
    .data monitor_5, screen_monitor_5 - 8
    .data monitor_6, screen_monitor_6 - 8
    .data monitor_7, screen_monitor_7 - 8
    .data monitor_8, screen_monitor_8 - 8
    .data monitor_running, screen_position_running
}

; raster lines:
;   1: 51
;   2: 51, 207
;   3: 51, 150 (155), 259
;   4: 51, 129, 207, 285
;
;   charset switch: 194
;   charset switch back: > 250

irq_low {
    .data <irq_single, <irq_double, <irq_tripple, <irq_quadruple
}

irq_high {
    .data >irq_single, >irq_double, >irq_tripple, >irq_quadruple
}
