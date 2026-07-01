#!/usr/bin/env perl

use strict;
use warnings;

my $key = shift or die "Usage: extractBibtexEntry KEY library.bib\n";
my $file = shift or die "Usage: extractBibtexEntry KEY library.bib\n";

open my $fh, '<', $file or die "Cannot open $file: $!\n";

my ($buf, $depth, $inEntry, $wanted) = ("", 0, 0, 0);

while (my $line = <$fh>) {
	if (!$inEntry && $line =~ /^\s*@\w+\s*\{\s*([^,\s]+)\s*,/) {
		$inEntry = 1;
		$wanted = ($1 eq $key);
		$buf = $line;
		$depth = () = $line =~ /\{/g;
		$depth -= () = $line =~ /\}/g;
		next;
	}

	if ($inEntry) {
		$buf .= $line;
		$depth += () = $line =~ /\{/g;
		$depth -= () = $line =~ /\}/g;
		if ($depth <= 0) {
			print $buf if $wanted;
			exit 0 if $wanted;
			($buf, $depth, $inEntry, $wanted) = ("", 0, 0, 0);
		}
	}

}