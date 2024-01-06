;  zak-supervisor.inc -- global defines
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

DEBUG_DISPLAY = 0 ; 1

GETIN_CHECKED = $e124

COLOR_BACKGROUND = COLOR_BLACK

COLOR_FOCUS = COLOR_WHITE
CTRL_COLOR_FOCUS = CTRL_COLOR_WHITE

COLOR_NORMAL = COLOR_GREY_2
CTRL_COLOR_NORMAL = CTRL_COLOR_MID_GRAY

COLOR_DISABLED = COLOR_GREY_1

COLOR_LINE1 = COLOR_RED
COLOR_LINE1_FOCUS = COLOR_LIGHT_RED
COLOR_LINE2 = COLOR_GREY_3
COLOR_LINE2_FOCUS = COLOR_WHITE

screen_address(screen, x_, y_) = screen + x_ + y_ * 40

screen = $0400
screen_monitor_current = screen_address(screen, 33, 0)
screen_monitor_1 = screen_address(screen, 17, 1)
screen_monitor_2 = screen_address(screen, 17, 2)
screen_monitor_3 = screen_address(screen, 17, 3)
screen_monitor_4 = screen_address(screen, 17, 4)
screen_monitor_5 = screen_address(screen, 34, 1)
screen_monitor_6 = screen_address(screen, 34, 2)
screen_monitor_7 = screen_address(screen, 34, 3)
screen_monitor_8 = screen_address(screen, 34, 4)
screen_monitor_running = screen_address(screen, 0, 11)
color_monitor_running = screen_address(COLOR_RAM, 0, 11)
screen_position_running = screen_address(screen, 18, 17)
screen_monitor_page = screen + 1000 - 256
color_monitor_page = COLOR_RAM + 1000 - 256
screen_rastertime_current = screen_address(screen, 18, 8)
screen_rastertime_maximum = screen_address(screen, 18, 9)

screen_filename = screen_address(screen, 11, 9)

CHAR_CURSOR = $5f ; _


.macro copy_screen source {
    lda #<source
    sta ptr1
    lda #>source
    sta ptr1 + 1
    lda #<screen
    sta ptr2
    lda #>screen
    sta ptr2 + 1
    jsr expand
}
