.export start

STARTADDRESS=$3000

.include "c64.inc"
.include "cbm_kernal.inc"
.include "defines.inc"

PLOT_XXX = $e50a
LAOD_XXX = $f49e

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

start:
	lda #$97
	jsr BSOUT
	jsr CLRSCR
	lda #$98
	jsr BSOUT
	ldx #$1f
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
	jsr PLOT_XXX
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
	jsr PLOT_XXX
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
	jsr PLOT_XXX
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
	jsr PLOT_XXX
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
	jsr PLOT_XXX
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
	jmp start2

	; padding, remove
	.byte $00, $00, $00                         	; "..."

last_hex_digit:	.byte $43                                   	; "C"

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

	; padding, remove
	.byte $00, $00, $00, $00, $00, $00, $00     	; "......."

backspace_with_cursor:
	lda #$14 ; backspace
	jsr BSOUT
	lda #$14 ; backspace
	jsr BSOUT
	lda #CHAR_CURSOR ; '_'
	jmp BSOUT

	; padding, remove
	.byte $00                                   	; "."

bsout_with_cursor:
	pha
	lda #$14
	jsr BSOUT
	pla
	jsr BSOUT
	lda #CHAR_CURSOR
	jmp BSOUT

; TODO: move to bss
filename_length:
	.byte $00

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

	; padding, remove
	.byte $00, $00, $00                         	; "..."

load_music:
	; TODO: don't hardcode device 8
	; TODO: use SETLFS, SETNAM
	ldx #$08	; 8 .
	stx Zba
	ldx filename_length
	stx Zb7
	ldx #$01	; 1 .
	stx Zb9
	ldx #<filename
	ldy #>filename
	stx Zbb
	sty Zbc
	lda #$00	; 0 .
	sta Z9d
	jmp LAOD_XXX

	; padding, remove
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00                    	; "...."

filename:
	.byte $32, $30, $43, $43, $20, $30, $30, $32	; "20CC 002"
	.byte $2a, $5f, $5f, $20, $2f, $4d, $54, $4c	; "*__ /MTL"
	.byte $5f, $00, $00, $00, $00, $00, $00     	; "_......"

; TODO: move to bss and into read_hex_byte scope
hex_byte:
	.byte $00                                   	; "."

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

	; padding, remove
	.byte $00                                   	; "."

; TOOD: move to bss and into scope of read_hex_word
hex_word:
	.byte $10, $6c

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

	; padding, remove
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00                              	; ".."


; TODO: move to bss, into scope of read_one_or_two
one_or_two:
	.byte $01                                   	; "."

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

	; padding, remove
	.byte $00, $00, $00                         	; "..."

; TODO: merge with start
start2:
	ldx #$27
	lda #COLOR_MID_GRAY
:	sta COLOR_RAM + 15 * 40,x
	dex
	bpl :-
	ldx #$0f
	ldy #$11
	clc
	jsr PLOT_XXX
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
	jsr PLOT_XXX
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

	; padding, remove
	.byte $00, $00, $00, $00, $00, $00, $00     	; "......."

L35e0:
	ldx #COLOR_BLACK
	stx VIC_BORDERCOLOR
	stx VIC_BG_COLOR0
	ldx #$1f
	stx VIC_VIDEO_ADR
	jmp setup_playing_screen

	; padding, remove
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00          	; "......"

maximum_raster_time:
	.byte $00
current_raster_time:
	.byte $00

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
	lda monitor_page,x
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

	; padding, remove
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00                         	; "..."

D36fe:	.byte $b9                                   	; "."
D36ff:	.byte $00                                   	; "."

; garbage, remove
L3700:	lda VIC_HLINE
	sta $36ff
	inc VIC_BORDERCOLOR
	lda #$35	; 53 5
	sta $01
	jsr $ffff
	lda VIC_HLINE
	sec
	sbc $36ff
	cmp $36fe
	bmi :+
	sta $36fe
:	jsr format_hex
	stx $0538
	sty $0539
	jmp $37f0

	; padding, remove
	.byte $00, $00, $00, $00, $00               	; "....."

init_positions:	ldx #$00	; 0 .
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

	; padding, remove
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00                              	; ".."

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

	; padding, remove
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00               	; "....."

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
	ldx #$1f
	stx VIC_VIDEO_ADR
	ldx #$37
	stx $01
	ldx #$01
	stx VIC_IRR
	jmp ENDIRQ

	;padding, remove
	.byte $00, $00, $00, $00, $00, $00, $00

.segment "FIXED"

charset:
	.incbin "charset.bin"

start_screen:
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $1a, $01, $0b, $20, $2d, $20, $13	; " ... - ."
	.byte $15, $10, $05, $12, $16, $09, $13, $0f	; "........"
	.byte $12, $20, $20, $16, $31, $2e, $30, $20	; ".  .1.0 "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $09	; "       ."
	.byte $0e, $20, $31, $39, $39, $30, $20, $02	; ". 1990 ."
	.byte $19, $20, $20, $20, $20, $20, $20, $20	; ".       "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $04, $09	; "      .."
	.byte $0c, $0c, $0f, $20, $2f, $14, $27, $10	; "... /.'."
	.byte $01, $15, $20, $20, $20, $20, $20, $20	; "..      "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $20, $20, $1a, $01, $0b, $20, $0d, $15	; "  ... .."
	.byte $13, $14, $0e, $27, $14, $20, $0c, $0f	; "...'. .."
	.byte $01, $04, $20, $14, $0f, $20, $24, $33	; ".. .. $3"
	.byte $30, $30, $30, $2d, $24, $33, $06, $06	; "000-$3.."
	.byte $06, $20, $21, $21, $21, $21, $20, $20	; ". !!!!  "
	.byte $20, $20, $20, $20, $28, $10, $12, $0f	; "    (..."
	.byte $07, $07, $09, $05, $20, $17, $0f, $15	; ".... ..."
	.byte $0c, $04, $20, $03, $12, $01, $13, $08	; ".. ....."
	.byte $20, $0f, $14, $08, $05, $12, $17, $09	; " ......."
	.byte $13, $05, $2e, $29, $20, $20, $20, $20	; "...)    "
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $06, $09, $0c, $05, $0e, $01, $0d	; " ......."
	.byte $05, $3a, $20, $20, $20, $20, $20, $20	; ".:      "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $09, $0e, $09, $14, $20, $20, $20	; " ....   "
	.byte $20, $3a, $20, $01, $3a, $20, $24, $20	; " : .: $ "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $18, $3a, $20, $24, $20	; "   .: $ "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $19, $3a, $20, $24, $20	; "   .: $ "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $31, $3a, $20, $0a, $13	; "   1: .."
	.byte $12, $20, $2f, $20, $32, $3a, $20, $13	; ". / 2: ."
	.byte $14, $01, $20, $20, $28, $31, $2f, $32	; "..  (1/2"
	.byte $29, $3f, $20, $20, $20, $20, $20, $20	; ")?      "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $01, $14, $20, $3a, $20	; "   .. : "
	.byte $24, $20, $20, $20, $20, $20, $20, $20	; "$       "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $10, $0c, $01, $19, $20, $20, $20	; " ....   "
	.byte $20, $3a, $20, $0a, $13, $12, $3a, $20	; " : ...: "
	.byte $24, $20, $20, $20, $20, $20, $20, $20	; "$       "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "

playing_screen:
	.byte $1e, $30, $20, $20, $20, $03, $15, $12	; ".0   ..."
	.byte $12, $05, $0e, $14, $20, $10, $0f, $13	; ".... ..."
	.byte $09, $14, $09, $0f, $0e, $20, $20, $28	; ".....  ("
	.byte $24, $31, $30, $30, $30, $29, $3a, $20	; "$1000): "
	.byte $24, $2e, $2e, $20, $20, $20, $30, $1e	; "$..   0."
	.byte $1e, $31, $20, $20, $20, $20, $20, $20	; ".1      "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $31, $1e	; "      1."
	.byte $1e, $32, $20, $20, $23, $31, $20, $28	; ".2  #1 ("
	.byte $24, $31, $30, $30, $30, $29, $3a, $20	; "$1000): "
	.byte $24, $2e, $2e, $20, $20, $23, $35, $20	; "$..  #5 "
	.byte $28, $24, $31, $30, $30, $30, $29, $3a	; "($1000):"
	.byte $20, $24, $2e, $2e, $20, $20, $32, $1e	; " $..  2."
	.byte $1e, $33, $20, $20, $23, $32, $20, $28	; ".3  #2 ("
	.byte $24, $31, $30, $30, $30, $29, $3a, $20	; "$1000): "
	.byte $24, $2e, $2e, $20, $20, $23, $36, $20	; "$..  #6 "
	.byte $28, $24, $31, $30, $30, $30, $29, $3a	; "($1000):"
	.byte $20, $24, $2e, $2e, $20, $20, $33, $1e	; " $..  3."
	.byte $1e, $34, $20, $20, $23, $33, $20, $28	; ".4  #3 ("
	.byte $24, $31, $30, $30, $30, $29, $3a, $20	; "$1000): "
	.byte $24, $2e, $2e, $20, $20, $23, $37, $20	; "$..  #7 "
	.byte $28, $24, $31, $30, $30, $30, $29, $3a	; "($1000):"
	.byte $20, $24, $2e, $2e, $20, $20, $34, $1e	; " $..  4."
	.byte $1e, $35, $20, $20, $23, $34, $20, $28	; ".5  #4 ("
	.byte $24, $31, $30, $30, $30, $29, $3a, $20	; "$1000): "
	.byte $24, $2e, $2e, $20, $20, $23, $38, $20	; "$..  #8 "
	.byte $28, $24, $31, $30, $30, $30, $29, $3a	; "($1000):"
	.byte $20, $24, $2e, $2e, $20, $20, $35, $1e	; " $..  5."
	.byte $1e, $36, $20, $20, $20, $20, $20, $20	; ".6      "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $20, $20, $20, $20, $20, $20, $36, $1e	; "      6."
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $20, $20, $20, $20, $03, $15, $12, $12	; "    ...."
	.byte $05, $0e, $14, $20, $12, $01, $13, $14	; "... ...."
	.byte $05, $12, $14, $09, $0d, $05, $20, $20	; "......  "
	.byte $20, $20, $20, $20, $20, $20, $20, $3a	; "       :"
	.byte $20, $24, $2e, $2e, $20, $20, $20, $20	; " $..    "
	.byte $20, $20, $20, $20, $0d, $01, $18, $09	; "    ...."
	.byte $0d, $15, $0d, $20, $12, $01, $13, $14	; "... ...."
	.byte $05, $12, $14, $09, $0d, $05, $20, $28	; "...... ("
	.byte $13, $0f, $20, $06, $01, $12, $29, $3a	; ".. ...):"
	.byte $20, $24, $2e, $2e, $20, $20, $20, $20	; " $..    "
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $20, $20, $20, $20, $20, $20, $20	; "0       "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $20, $20, $20, $20, $20, $20, $20	; "0       "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $20, $20, $20, $20, $20, $20, $20	; "0       "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $20, $20, $20, $20, $20, $20, $20	; "0       "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $20, $20, $20, $20, $20, $20, $20	; "0       "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $30, $30, $30, $30, $30, $30, $30	; "00000000"
	.byte $30, $20, $20, $20, $20, $20, $20, $20	; "0       "
	.byte $20, $20, $20, $20, $20, $20, $20, $20	; "        "
	.byte $10, $0f, $13, $09, $14, $09, $0f, $0e	; "........"
	.byte $20, $01, $02, $0f, $16, $05, $3a, $20	; " .....: "
	.byte $24, $31, $30, $30, $30, $20, $20, $1c	; "$1000  ."
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $40, $40, $40, $40, $40, $40, $40, $40	; "@@@@@@@@"
	.byte $40, $40, $40, $40, $40, $40, $40, $40	; "@@@@@@@@"
	.byte $40, $40, $40, $40, $40, $40, $40, $7d	; "@@@@@@@}"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"
	.byte $00, $00, $00, $00, $00, $00, $00, $00	; "........"

monitor_page = $9200
D9210 = $9210


GETIN_CHECKED = $e124
Se544 = $e544
ENDIRQ = $ea31
RESET = $fce2
