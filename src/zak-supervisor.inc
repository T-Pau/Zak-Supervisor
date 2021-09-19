.ifndef HAD_ZAK_SUPERVISOR_INC
.define HAD_ZAK_SUPERVISOR_INC

;  zak-supervisor.inc -- global defines
;  Copyright (C) 2021 Dieter Baron
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

.include "c64.inc"
.include "cbm_kernal.inc"
.include "defines.inc"

.macpack cbm

; DEBUG_DISPLAY = 1

GETIN_CHECKED = $e124

COLOR_BACKGROUND = COLOR_BLACK

COLOR_FOCUS = COLOR_WHITE
CTRL_COLOR_FOCUS = CTRL_COLOR_WHITE

COLOR_NORMAL = COLOR_MID_GRAY
CTRL_COLOR_NORMAL = CTRL_COLOR_MID_GRAY

COLOR_DISABLED = COLOR_DARK_GRAY

COLOR_LINE1 = COLOR_RED
COLOR_LINE1_FOCUS = COLOR_LIGHT_RED
COLOR_LINE2 = COLOR_LIGHT_GRAY
COLOR_LINE2_FOCUS = COLOR_WHITE

screen = $0400
screen_monitor_current = screen + 33
screen_monitor_1 = screen + 1 * 40 + 17
screen_monitor_2 = screen + 2 * 40 + 17
screen_monitor_3 = screen + 3 * 40 + 17
screen_monitor_4 = screen + 4 * 40 + 17
screen_monitor_5 = screen + 1 * 40 + 34
screen_monitor_6 = screen + 2 * 40 + 34
screen_monitor_7 = screen + 3 * 40 + 34
screen_monitor_8 = screen + 4 * 40 + 34
screen_monitor_running = screen + 11 * 40
color_monitor_running = COLOR_RAM + 11 * 40
screen_position_running = screen + 17 * 40 + 18
screen_monitor_page = screen + 1000 - 256
color_monitor_page = COLOR_RAM + 1000 - 256
screen_rastertime_current = screen + 8 * 40 + 18
screen_rastertime_maximum = screen + 9 * 40 + 18

screen_filename = screen + 9 * 40 + 11

CHAR_CURSOR = $5f ; _


.macro copy_screen source
	lda #<source
	sta ptr1
	lda #>source
	sta ptr1 + 1
	lda #<screen
	sta ptr2
	lda #>screen
	sta ptr2 + 1
	jsr expand
.endmacro


.endif