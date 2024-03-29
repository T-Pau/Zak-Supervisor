;  defines.inc -- Global definitions for Commodore 64.
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

CLRSCR = $E544

CTRL_COLOR_WHITE = $05
CTRL_DISABLE_CHARSET_SWITCH = $08
CTRL_ENABLE_CHARSET_SWITCH = $09
CTRL_RETURN = $0D
CTRL_LOWERCASE = $0E
CTRL_CURSOR_DOWN = $11
CTRL_REVERSE_ON = $12
CTRL_HOME = $13
CTRL_DELETE = $14
CTRL_COLOR_RED = $1C
CTRL_CURSOR_RIGHT = $1D
CTRL_COLOR_GREEN = $1E
CTRL_COLOR_BLUE = $1F
CTRL_COLOR_ORANGE = $81
CTRL_F7 = $88
CTRL_UPPERCASE = $8E
CTRL_COLOR_BLACK = $90
CTRL_CURSOR_UP = $91
CTRL_REVERSE_OFF = $92
CTRL_CLEAR = $93
CTRL_INSERT = $94
CTRL_COLOR_BROWN = $95
CTRL_COLOR_LIGHT_RED = $96
CTRL_COLOR_DARK_GRAY = $97
CTRL_COLOR_MID_GRAY = $98
CTRL_COLOR_LIGHT_GREEN = $99
CTRL_COLOR_LIGHT_BLUE = $9A
CTRL_COLOR_LIGHT_GRAY = $9B
CTRL_COLOR_PURPLE = $9C
CTRL_CURSOR_LEFT = $9D
CTRL_COLOR_YELLOW = $9E
CTRL_COLOR_CYAN = $9F

COLOR_RAM = $d800

ST = $90
LAST_DEVICE = $ba

ENDIRQ = $ea31
RESET = $fce2

.section zero_page

; main loop
tmp1 .reserve 1
ptr1 .reserve 2
ptr2 .reserve 2

; interrupt
ptr3 .reserve 2
ptr4 .reserve 2
