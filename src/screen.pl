#!/usr/bin/perl

#  screen.pl -- Convert ASCII to run length encoded Commodore 64 screen codes
#  Copyright (C) Dieter Baron
#
#  This file is part of Zak Supervisor, a Music Monitor for the Commodore 64.
#  The authors can be contacted at <zak-supervisor@tpau.group>.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. The names of the authors may not be used to endorse or promote
#     products derived from this software without specific prior
#     written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS
#  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
#  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
#  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
#  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
#  IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

use strict;
use warnings;

my $width = 40;
my $page_size = 12;
my $mode = "plain";

if ($ARGV[0] eq "-c") {
    $mode = "collapse";
    shift;
}
elsif ($ARGV[0] eq "-m") {
    $mode = "messymaker";
    shift;
}

my $screen = "";
my $lineno = 0;

while (my $line = <>) {
    chomp $line;
    if (length($line) > $width) {
        die "line too long";
    }
    if ($mode eq "messymaker" && $line =~ m//) {
        if ($lineno > 0) {
            $screen .= " " x (($page_size - $lineno) * $width);
        }
        $lineno = 0;
        next;
    }

    $line = sprintf("%-*s", $width, $line);

    $line =~ tr/\x60-\x7f_/\x00-\x1f\x7d/;

    if ($mode eq "messymaker") {
        if (0) {
            # Font from Messy Maker 2
            # [ABC] \LG T'Pau logo
            # [D]   [   period
            # [E]   |   exclamation mark
            # [F]   ]   question mark
            # [G]   {    star
            # [H]   ^   spider
            # [IJ]  \T  time
            # [KL]  \P  phone
            # [MN]  \D  calendar (date)
            # [OP]  \S  stamp
            # [QRS] \FD floppy disk
            # [T]   ~   thick line
            # [UV]  \=  double line
            # [WX]  \<  line scrolling left
            # [YZ]  \>  line scrolling right

            $line =~ s/\\LG/abc/g;
            $line =~ s/\[/d/g;
            $line =~ s/\|/e/g;
            $line =~ s/\]/f/g;
            $line =~ s/\x1b/g/; # {
            $line =~ s/\^/h/;
            $line =~ s/\\T/ij/g;
            $line =~ s/\\P/kl/g;
            $line =~ s/\\D/mn/g;
            $line =~ s/\\S/op/g;
            $line =~ s/\\FD/qrs/g;
            $line =~ s/\x1e/t/g; # ~
            $line =~ s/\\=/uv/g;
            $line =~ s/\\</wx/g;
            $line =~ s/\\>/yz/g;
        }
        else {
            # Font from Messy Maker 2
            # [@AB] \LG T'Pau logo
            # [C]   [   period
            # [D]   {    star
            # [E]   |   exclamation mark
            # [F]   ^   spider
            # [G]   ]   question mark
            # [HI]  \T  time
            # [JK]  \P  phone
            # [LMN] \FD floppy disk
            # [O]   ~   double line
            # [PQ]  \)  pac man
            # [RSTUVW] \BLITZ lightning
            # [XY]  \=  single line
            # [Z{]  \Q  square
            # [|}]  \D  calendar
            # [~ ]  \S  stamp

            $line =~ s/\\LG/`ab/g;
            $line =~ s/\[/c/g;
            $line =~ s/\x1b/d/; # {
            $line =~ s/\x1c/e/g; # |
            $line =~ s/\^/f/;
            $line =~ s/\]/g/g;
            $line =~ s/\\T/hi/g;
            $line =~ s/\\P/jk/g;
            $line =~ s/\\FD/lmn/g;
            $line =~ s/\x1e/o/g; # ~
            $line =~ s/\\\)/pq/g;
            $line =~ s/\\BLITZ/rstuvw/g;
            $line =~ s/\\=/xy/g;
            $line =~ s/\\Q/z{/g;
            $line =~ s/\\D/|}/g;
            $line =~ s/\\S/~\x7f/g;
        }
    }

    $screen .= $line;
    $lineno = ($lineno + 1) % $page_size;
}

if ($mode eq "plain") {
    print $screen;
}
elsif ($mode eq "collapse") {
    my $runlength = 0;
    my $runchar = "";
    foreach my $char (split //, $screen) {
        if (ord($char) > 0x80) {
            die "can't collapse inverted character";
        }
        if ($char eq $runchar && $runlength < 125) {
            $runlength += 1;
        }
        else {
            output_collapse_run($runlength, $runchar);
            $runlength = 1;
            $runchar = $char;
        }
    }
    output_collapse_run($runlength, $runchar);
    print("\xff");
}
elsif ($mode eq "messymaker") {
    if ($lineno > 0) {
        $screen .= " " x (($page_size - $lineno) * $width);
    }
    print $screen;
}


sub output_collapse_run {
    my ($length, $char) = @_;

    if ($length < 3) {
        print($char x $length);
    }
    else {
        print(chr(0x80 + $length) . $char);
    }
}
