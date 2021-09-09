.export start

.include "c64.inc"
.include "cbm_kernal.inc"
.include "defines.inc"

.macpack cbm

GETIN_CHECKED = $e124
Se544 = $e544
ENDIRQ = $ea31
RESET = $fce2

LAST_DEVICE = $ba

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

screen = $0400
screen_monitor_current = screen + 33
screen_monitor_1 = screen + 2 * 40 + 17
screen_monitor_2 = screen + 3 * 40 + 17
screen_monitor_3 = screen + 4 * 40 + 17
screen_monitor_4 = screen + 5 * 40 + 17
screen_monitor_5 = screen + 2 * 40 + 34
screen_monitor_6 = screen + 3 * 40 + 34
screen_monitor_7 = screen + 4 * 40 + 34
screen_monitor_8 = screen + 5 * 40 + 34
screen_monitor_running = screen + 11 * 40
color_monitor_running = COLOR_RAM + 11 * 40
screen_position_running = screen + 17 * 40 + 17
screen_monitor_page = screen + 1000 - 256
color_monitor_page = COLOR_RAM + 1000 - 256
screen_rastertime_current = screen + 8 * 40 + 34
screen_rastertime_maximum = screen + 9 * 40 + 34

screen_filename = screen + 9 * 40 + 11

CHAR_CURSOR = $5f ; _

Z90 = $90
Z9d = $9d
Zb7 = $b7
Zb9 = $b9
Zba = $ba
Zbb = $bb
Zbc = $bc

.segment "CHARSET"

charset:
	.incbin "charset.bin"

.code

start:
	lda #CTRL_COLOR_DARK_GRAY
	jsr BSOUT
	jsr CLRSCR
	lda #CTRL_COLOR_MEDIUM_GRAY
	jsr BSOUT
	ldx #<((screen / $40) | (charset / $400))
	stx VIC_VIDEO_ADR
	ldx #COLOR_BLACK
	stx VIC_BORDERCOLOR
	stx VIC_BG_COLOR0
:	lda start_screen,x
	sta screen,x
	lda start_screen + $100,x
	sta screen + $100,x
	lda start_screen + $200,x
	sta screen + $200,x
	dex
	bne :-
	ldx #39
	lda #COLOR_MID_GRAY
:	sta COLOR_RAM + 9 * 40,x
	dex
	bpl :-
	ldx #$09
	ldy #$0b
	clc
	jsr PLOT
	lda #CHAR_CURSOR
	jsr BSOUT
	ldx #$00
	stx filename_length
	jsr read_filename
	ldx #39
	lda #COLOR_DARK_GRAY
:	sta COLOR_RAM + 9 * 40,x
	dex
	bpl :-
	ldx filename_length
	beq :+
	jsr load_music
	ldx Z90
	cpx #$40
	beq :+
	jmp start
:	ldx #39
	lda #COLOR_MID_GRAY
:	sta COLOR_RAM + 11 * 40,x
	dex
	bpl :-
	ldx #$0b
	ldy #$0f
	clc
	jsr PLOT
	jsr read_hex_byte
	sta init_music_a + 1
	ldx #$10
	lda #COLOR_DARK_GRAY
:	sta COLOR_RAM + 11 * 40 + 10,x
	dex
	bpl :-
	ldx #39
	lda #COLOR_MID_GRAY
:	sta COLOR_RAM + 12 * 40,x
	dex
	bpl :-
	ldx #$0c
	ldy #$0f
	clc
	jsr PLOT
	jsr read_hex_byte
	sta init_music_x + 1
	ldx #39
	lda #COLOR_DARK_GRAY
:	sta COLOR_RAM + 12 * 40,x
	dex
	bpl :-
	ldx #39
	lda #COLOR_MID_GRAY
:	sta COLOR_RAM + 13 * 40,x
	dex
	bpl :-
	ldx #$0d
	ldy #$0f
	clc
	jsr PLOT
	jsr read_hex_byte
	sta init_music_y + 1
	ldx #39
	lda #COLOR_DARK_GRAY
:	sta COLOR_RAM + 13 * 40,x
	dex
	bpl :-
	ldx #39
	lda #COLOR_MID_GRAY
:	sta COLOR_RAM + 14 * 40,x
	dex
	bpl :-
	ldx #$0e
	ldy #$23
	clc
	jsr PLOT
	jsr read_one_or_two
	bne L30ea
	lda #$20
	bne L30ec
L30ea:	lda #$8d
L30ec:	sta init_music
	ldx #$27
	lda #COLOR_DARK_GRAY
:	sta COLOR_RAM + 14 * 40,x
	dex
	bpl :-
	ldx #$27
	lda #COLOR_MID_GRAY
:	sta COLOR_RAM + 15 * 40,x
	dex
	bpl :-
	ldx #$0f
	ldy #$11
	clc
	jsr PLOT
	jsr read_hex_word
	stx init_music + 2
	sty init_music + 1
	ldx #39
:	lda #COLOR_DARK_GRAY
	sta COLOR_RAM + 15 * 40,x
	sta COLOR_RAM + 11 * 40,x
	lda #COLOR_MID_GRAY
	sta COLOR_RAM + 17 * 40,x
	dex
	bpl :-
	ldx #$11
	ldy #$11
	clc
	jsr PLOT
	jsr read_hex_word
	stx play_music + 2
	sty play_music + 1

setup_playing_screen:	lda #$97
	jsr BSOUT
	jsr Se544 ; TODO: symbolize
	ldx #0
:	lda playing_screen,x
	sta screen,x
	lda playing_screen + $100,x
	sta screen + $100,x
	lda playing_screen + $200,x
	sta screen + $200,x
	dex
	bne :-
	jsr init_positions
	sei
	ldx #$01	; 1 .
	stx VIC_IMR
	dex
	stx CIA1_CRA
	lda #$1b	; 27 .
	sta VIC_CTRL1
	lda #$33	; 51 3
	sta VIC_HLINE
	lda #<irq_main
	sta IRQVec
	lda #>irq_main
	sta IRQVec + 1
	nop
	lda #$35	; 53 5
	sta $01
init_music_a:
	lda #$00
init_music_x:
	ldx #$00
init_music_y:
	ldy #$00
init_music:
	jsr $0000
	lda #$37
	sta $01
	cli

main_loop:
.scope
	jsr GETIN_CHECKED
	beq main_loop
	cmp #$2b ; +
	bne not_plus
	inc load_monitor_current + 2
update_current:
	lda load_monitor_current + 2
update_page:
	sta load_monitor_page + 2
	jsr format_hex
	stx screen_monitor_current - 8
	sty screen_monitor_current - 7
	jmp main_loop
not_plus:
	cmp #$2d ; -
	bne not_minus
	; previous page
	dec load_monitor_current + 2
	jmp update_current
not_minus:
	cmp #$db ; shift +
	bne not_shift_puls
	lda load_monitor_current + 2
	clc
	adc #$10
	sta load_monitor_current + 2
	jmp update_page
not_shift_puls:
	cmp #$dd ; shift -
	bne not_shift_minus
	lda load_monitor_current + 2
	sec
	sbc #$10
	sta load_monitor_current + 2
	jmp update_page
not_shift_minus:
	cmp #$1d ; right
	bne not_right
	lda #COLOR_DARK_GRAY
	ldx load_monitor_current + 1
	sta color_monitor_page,x
	inx
update_page_low:
	lda #COLOR_LIGHT_GRAY
	sta color_monitor_page,x
	stx load_monitor_current + 1
	txa
	jsr format_hex
	stx screen_monitor_current - 6
	sty screen_monitor_current - 5
	jmp main_loop
not_right:
	cmp #$9d ; left
	bne not_left
	ldx load_monitor_current + 1
	lda #COLOR_DARK_GRAY
	sta color_monitor_page,x
	dex
	jmp update_page_low
not_left:
	cmp #$11 ; down
	bne not_down
	ldx load_monitor_current + 1
	lda #COLOR_DARK_GRAY
	sta color_monitor_page,x
	txa
	clc
	adc #$10
update_page_low_high_nibble:
	tax
	lda #COLOR_LIGHT_GRAY
	sta color_monitor_page,x
	txa
	sta load_monitor_current + 1
	jsr format_hex
	stx screen_monitor_current - 6
	jmp main_loop
not_down:
	cmp #$91 ; up
	bne not_up
	ldx load_monitor_current + 1
	lda #COLOR_DARK_GRAY
	sta color_monitor_page,x
	txa
	sec
	sbc #$10
	jmp update_page_low_high_nibble
not_up:	cmp #$03 ; run/stop
	bne not_runstop
	ldx #$00	; 0 .
	stx maximum_raster_time
	jmp main_loop
not_runstop:
	cmp #$31 ; 1
	bne not_one
	lda load_monitor_current + 1
	sta load_monitor_1 + 1
	jsr format_hex
	stx screen_monitor_1 - 6
	sty screen_monitor_1 - 5
	lda load_monitor_current + 2
	sta load_monitor_1 + 2
	jsr format_hex
	stx screen_monitor_1 - 8
	sty screen_monitor_1 - 7
	jmp main_loop
not_one:
	cmp #$32 ; 2
	bne not_two
	lda load_monitor_current + 1
	sta load_monitor_2 + 1
	jsr format_hex
	stx screen_monitor_2 - 6
	sty screen_monitor_2 - 5
	lda load_monitor_current + 2
	sta load_monitor_2 + 2
	jsr format_hex
	stx screen_monitor_2 - 8
	sty screen_monitor_2 - 7
	jmp main_loop
not_two:
	cmp #$33 ; 3
	bne not_three
	lda load_monitor_current + 1
	sta load_monitor_3 + 1
	jsr format_hex
	stx screen_monitor_3 - 6
	sty screen_monitor_3 - 5
	lda load_monitor_current + 2
	sta load_monitor_3 + 2
	jsr format_hex
	stx screen_monitor_3 - 8
	sty screen_monitor_3 - 7
	jmp main_loop
not_three:
	cmp #$34 ; 4
	bne not_four
	lda load_monitor_current + 1
	sta load_monitor_4 + 1
	jsr format_hex
	stx screen_monitor_4 - 6
	sty screen_monitor_4 - 5
	lda load_monitor_current + 2
	sta load_monitor_4 + 2
	jsr format_hex
	stx screen_monitor_4 - 8
	sty screen_monitor_4 - 7
	jmp main_loop
not_four:
	cmp #$35 ; 5
	bne not_five
	lda load_monitor_current + 1
	sta load_monitor_5 + 1
	jsr format_hex
	stx screen_monitor_5 - 6
	sty screen_monitor_5 - 5
	lda load_monitor_current + 2
	sta load_monitor_5 + 2
	jsr format_hex
	stx screen_monitor_5 - 8
	sty screen_monitor_5 - 7
	jmp main_loop
not_five:
	cmp #$36 ; 6
	bne not_six
	lda load_monitor_current + 1
	sta load_monitor_6 + 1
	jsr format_hex
	stx screen_monitor_6 - 6
	sty screen_monitor_6 - 5
	lda load_monitor_current + 2
	sta load_monitor_6 + 2
	jsr format_hex
	stx screen_monitor_6 - 8
	sty screen_monitor_6 - 7
	jmp main_loop
not_six:
	cmp #$37 ; 7
	bne not_seven
	lda load_monitor_current + 1
	sta load_monitor_7 + 1
	jsr format_hex
	stx screen_monitor_7 - 6
	sty screen_monitor_7 - 5
	lda load_monitor_current + 2
	sta load_monitor_7 + 2
	jsr format_hex
	stx screen_monitor_7 - 8
	sty screen_monitor_7 - 7
	jmp main_loop
not_seven:
	cmp #$38 ; 8
	bne not_eight
	lda load_monitor_current + 1
	sta load_monitor_8 + 1
	jsr format_hex
	stx screen_monitor_8 - 6
	sty screen_monitor_8 - 5
	lda load_monitor_current + 2
	sta load_monitor_8 + 2
	jsr format_hex
	stx screen_monitor_8 - 8
	sty screen_monitor_8 - 7
	jmp main_loop
not_eight:
	cmp #$0d ; return
	bne not_return
	lda load_monitor_current + 1
	sta load_monitor_running + 1
	jsr format_hex
	stx screen_position_running + 2
	sty screen_position_running + 3
	lda load_monitor_current + 2
	sta load_monitor_running + 2
	jsr format_hex
	stx screen_position_running
	sty screen_position_running + 1
ignore:
	jmp main_loop
not_return:
	cmp #$c5 ; shift E
	bne ignore
	jmp RESET
.endscope

.bss

last_hex_digit:
	.res 1

.code
; read hex digit, returns digit in A and last_hex_digit
; returns $81 for return, $80 for backspace
read_hex_digit:
.scope
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
:	cmp #$41	; 'A'
	bmi read_hex_digit
	cmp #$47	; 'G'
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
:	cmp #$14
	bne read_hex_digit
	lda #$80
	rts
.endscope

backspace_with_cursor:
	lda #$14 ; backspace
	jsr BSOUT
	lda #$14 ; backspace
	jsr BSOUT
	lda #CHAR_CURSOR ; '_'
	jmp BSOUT

bsout_with_cursor:
	pha
	lda #$14
	jsr BSOUT
	pla
	jsr BSOUT
	lda #CHAR_CURSOR
	jmp BSOUT

.bss

filename_length:
	.res 1

.code
; filename is returned at filename, length at filename_length
; cursor must be at correct position
read_filename:
.scope
	jsr GETIN_CHECKED
	cmp #$0d	; 13 .
	beq return
	cmp #$14	; 20 .
	beq backspace
	cmp #$20	; 32
	bmi read_filename
	cmp #$60	; 96 `
	bpl read_filename
	inc filename_length
	ldx filename_length
	cpx #$11	; 17 .
	bne character
	dec filename_length
	bne read_filename
character:
	; TODO: use bsout_with_cursor
	pha
	lda #$14	; 20 .
	jsr BSOUT
	pla
	jsr BSOUT
	lda #CHAR_CURSOR
	jsr BSOUT
	jmp read_filename
backspace:
	dec filename_length
	ldx filename_length
	cpx #$ff	; 255 .
	bne character
	inc filename_length
	beq read_filename
return:
	ldx filename_length
	beq end
convert_to_petscii:
	lda screen_filename,x
	cmp #$20	; 32
	bpl :+
	clc
	adc #$40	; 64 @
:	sta filename,x
	dex
	bpl convert_to_petscii
end:
	lda #$14	; 20 .
	jmp BSOUT
.endscope

load_music:
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

.bss

filename:
	.res 17

.bss
; TODO: move to bss and into read_hex_byte scope
hex_byte:
	.res 1

.code
read_hex_byte:
.scope
	lda #CHAR_CURSOR
	jsr BSOUT
read_first_digit:
	jsr read_hex_digit
	bmi read_first_digit
	asl
	asl
	asl
	asl
	sta hex_byte
	lda last_hex_digit
	jsr bsout_with_cursor
read_second_digit:
	jsr read_hex_digit
	bmi :+
	ora hex_byte
	sta hex_byte
	lda last_hex_digit
	jsr bsout_with_cursor
	jmp read_return
:	cmp #$81
	beq read_second_digit
	jsr backspace_with_cursor
	jmp read_first_digit
read_return:
	jsr read_hex_digit
	bpl read_return
	cmp #$81	; 129 .
	beq end
	jsr backspace_with_cursor
	lda #$f0	; 240 .
	and hex_byte
	sta hex_byte
	jmp read_second_digit
end:
	lda #$14	; 20 .
	jsr BSOUT
	lda hex_byte
	rts
.endscope


.bss

; TOOD: move to bss and into scope of read_hex_word
hex_word:
	.res 2

.code

; reads hex word, returns in x/y
read_hex_word:
.scope
	lda #CHAR_CURSOR
	jsr BSOUT
read_first_digit:
	jsr read_hex_digit
	bmi read_first_digit
	asl
	asl
	asl
	asl
	sta hex_word
	lda last_hex_digit
	jsr bsout_with_cursor
read_second_digit:
	jsr read_hex_digit
	bmi :+
	ora hex_word
	sta hex_word
	lda last_hex_digit
	jsr bsout_with_cursor
	jmp read_third_digit
:	cmp #$81
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
	sta hex_word + 1
	lda last_hex_digit
	jsr bsout_with_cursor
	jmp read_fourth_digit
:	cmp #$81
	beq read_third_digit
	jsr backspace_with_cursor
	lda #$f0
	and hex_word
	sta hex_word
	jmp read_second_digit
read_fourth_digit:
	jsr read_hex_digit
	bmi :+
	ora hex_word + 1
	sta hex_word + 1
	lda last_hex_digit
	jsr bsout_with_cursor
	jmp read_return
:	cmp #$81
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
	and hex_word + 1
	sta hex_word + 1
	jmp read_fourth_digit
end:
	lda #$14	; 20 .
	jsr BSOUT
	ldx hex_word
	ldy hex_word + 1
	rts
.endscope


.bss

; TODO: move to bss, into scope of read_one_or_two
one_or_two:
	.res 1

.code

read_one_or_two:
.scope
	lda #CHAR_CURSOR
	jsr BSOUT
read_digit:
	jsr GETIN_CHECKED
	cmp #$31 ; '1'
	beq :+
	cmp #$32 ; '2'
	bne read_digit
:	pha
	sec
	sbc #$31	; 49 1
	sta one_or_two
	pla
	jsr bsout_with_cursor
read_return:
	jsr GETIN_CHECKED
	cmp #$0d
	beq end
	cmp #$14
	bne read_return
	jsr backspace_with_cursor
	jmp read_digit
end:
	lda #$14
	jsr BSOUT
	lda one_or_two
	rts
.endscope

L35e0:
	ldx #COLOR_BLACK
	stx VIC_BORDERCOLOR
	stx VIC_BG_COLOR0
	ldx #<((screen / $40) | (charset / $400))
	stx VIC_VIDEO_ADR
	jmp setup_playing_screen


.bss

maximum_raster_time:
	.res 1
current_raster_time:
	.res 1

.code

irq_main:
	inc VIC_BORDERCOLOR
	lda VIC_HLINE
	sta current_raster_time
	lda #$35
	sta $01
play_music:
	jsr $0000
	lda VIC_HLINE
	dec VIC_BORDERCOLOR
	sec
	sbc current_raster_time
	cmp maximum_raster_time
	bmi :+
	sta maximum_raster_time
:	jsr format_hex
	stx screen_rastertime_current
	sty screen_rastertime_current + 1
	lda maximum_raster_time
	jsr format_hex
	stx screen_rastertime_maximum
	sty screen_rastertime_maximum + 1
	ldx #$00
load_monitor_page:
	lda $ff00,x
	sta screen_monitor_page,x
	dex
	bne load_monitor_page
load_monitor_current:
	lda $ffff
	jsr format_hex
	stx screen_monitor_current
	sty screen_monitor_current + 1
load_monitor_1:
	lda $ffff
	jsr format_hex
	stx screen_monitor_1
	sty screen_monitor_1 + 1
load_monitor_2:
	lda $ffff
	jsr format_hex
	stx screen_monitor_2
	sty screen_monitor_2 + 1
load_monitor_3:
	lda $ffff
	jsr format_hex
	stx screen_monitor_3
	sty screen_monitor_3 + 1
load_monitor_4:
	lda $ffff
	jsr format_hex
	stx screen_monitor_4
	sty screen_monitor_4 + 1
load_monitor_5:
	lda $ffff
	jsr format_hex
	stx screen_monitor_5
	sty screen_monitor_5 + 1
load_monitor_6:
	lda $ffff
	jsr format_hex
	stx screen_monitor_6
	sty screen_monitor_6 + 1
load_monitor_7:
	lda $ffff
	jsr format_hex
	stx screen_monitor_7
	sty screen_monitor_7 + 1
load_monitor_8:
	lda $ffff
	jsr format_hex
	stx screen_monitor_8
	sty screen_monitor_8 + 1
load_monitor_running:
	lda $ffff
	jsr format_hex
	txa
load_running_index:
	ldx #$00
	sta screen_monitor_running,x
	tya
	sta screen_monitor_running + 40,x
	inx
	cpx #40
	bne :+
	ldx #80
	bne inc_end
:	cpx #120
	bne :+
	ldx #160
	bne inc_end
:	cpx #200
	bne inc_end
	ldx #$00	; 0 .
inc_end:
	stx load_running_index + 1
	jmp bottom_irq


D36fe:	.byte $b9                                   	; "."
D36ff:	.byte $00                                   	; "."

init_positions:
	ldx #$00	; 0 .
	stx maximum_raster_time
	stx load_running_index + 1
	ldx #$00	; 0 .
	ldy #$10	; 16 .
	stx load_monitor_page + 1
	sty load_monitor_page + 2
	stx load_monitor_current + 1
	sty load_monitor_current + 2
	stx load_monitor_1 + 1
	sty load_monitor_1 + 2
	stx load_monitor_2 + 1
	sty load_monitor_2 + 2
	stx load_monitor_3 + 1
	sty load_monitor_3 + 2
	stx load_monitor_4 + 1
	sty load_monitor_4 + 2
	stx load_monitor_5 + 1
	sty load_monitor_5 + 2
	stx load_monitor_6 + 1
	sty load_monitor_6 + 2
	stx load_monitor_7 + 1
	sty load_monitor_7 + 2
	stx load_monitor_8 + 1
	sty load_monitor_8 + 2
	stx load_monitor_running + 1
	sty load_monitor_running + 2
	ldx #COLOR_LIGHT_GRAY
	stx color_monitor_page
	ldx #79
:	lda #COLOR_RED
	sta color_monitor_running,x
	sta color_monitor_running + 160,x
	lda #COLOR_LIGHT_GRAY
	sta color_monitor_running + 80,x
	dex
	bpl :-
	rts

; converts A to two hex digits returned in x/y
format_hex:
.scope
	pha
	lsr
	lsr
	lsr
	lsr
	cmp #$0a	; 10 .
	bmi digit_high
	sec
	sbc #$09	; 9 .
	bne end_high
digit_high:
	clc
	adc #$30	; 48 0
end_high:
	tax
	pla
	and #$0f	; 15 .
	cmp #$0a	; 10 .
	bmi digit_low
	sec
	sbc #$09	; 9 .
	bne end_low
digit_low:
	clc
	adc #$30	; 48 0
end_low:
	tay
	rts
.endscope

bottom_irq:
	ldx #$c1	; 193 .
:	cpx VIC_HLINE
	bne :-
	ldx #$14	; 20 .
:	dex
	bne :-
	ldx #$17
	stx VIC_VIDEO_ADR
	ldx #$ff
:	cpx VIC_HLINE
	bne :-
	ldx #<((screen / $40) | (charset / $400))
	stx VIC_VIDEO_ADR
	ldx #$37
	stx $01
	ldx #$01
	stx VIC_IRR
	jmp ENDIRQ

start_screen:
	scrcode "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	scrcode "         zak - supervisor  v1.0         "
	scrcode "               in 1990 by               "
	scrcode "              dillo /t'pau              "
	scrcode "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	scrcode "  zak mustn't load to $3000-$3fff !!!!  "
	scrcode "    (proggie would crash otherwise.)    "
	scrcode "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	scrcode "                                        "
	scrcode " filename:                              "
	scrcode "                                        "
	scrcode " init    : a: $                         "
	scrcode "           x: $                         "
	scrcode "           y: $                         "
	scrcode "           1: jsr / 2: sta  (1/2)?      "
	scrcode "           at : $                       "
	scrcode "                                        "
	scrcode " play    : jsr: $                       "
	scrcode "                                        "
	scrcode "        "

playing_screen:
	scrcode "^0   current position  ($1000): $..   0^"
	scrcode "^1                                    1^"
	scrcode "^2  #1 ($1000): $..  #5 ($1000): $..  2^"
	scrcode "^3  #2 ($1000): $..  #6 ($1000): $..  3^"
	scrcode "^4  #3 ($1000): $..  #7 ($1000): $..  4^"
	scrcode "^5  #4 ($1000): $..  #8 ($1000): $..  5^"
	scrcode "^6                                    6^"
	scrcode "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	scrcode "    current rastertime         : $..    "
	scrcode "    maximum rastertime (so far): $..    "
	scrcode "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	scrcode "0000000000000000000000000               "
	scrcode "0000000000000000000000000               "
	scrcode "0000000000000000000000000               "
	scrcode "0000000000000000000000000               "
	scrcode "0000000000000000000000000               "
	scrcode "0000000000000000000000000               "
	scrcode "position above: $1000  "
	.byte $1c ; £
	scrcode "@@@@@@@@@@@@@@@@"

	.byte $40, $40, $40, $40, $40, $40, $40, $40	; "@@@@@@@@"
	.byte $40, $40, $40, $40, $40, $40, $40, $40	; "@@@@@@@@"
	.byte $40, $40, $40, $40, $40, $40, $40, $7d	; "@@@@@@@}"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
