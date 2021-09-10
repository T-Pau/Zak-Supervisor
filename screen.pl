#!/usr/bin/perl

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
