#!/usr/bin/perl

#  screen.pl -- Convert ASCII to run length encoded Commodore 64 screen codes
#  Copyright (C) 2021 Dieter Baron
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

my $width = 40;
my $mode = "plain";

if ($ARGV[0] eq "-c") {
	$mode = "collapse";
	shift;
}

my $screen = "";

while (my $line = <>) {
	chomp $line;
	if (length($line) > $width) {
		die "line too long";
	}
	$line = sprintf("%-*s", $width, $line);

	$line =~ tr/\x60-\x7f_/\x00-\x1f\x7d/;

	$screen .= $line;
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


sub output_collapse_run {
	my ($length, $char) = @_;

	if ($length < 3) {
		print($char x $length);
	}
	else {
		print(chr(0x80 + $length) . $char);
	}
}
