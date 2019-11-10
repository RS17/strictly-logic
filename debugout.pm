#!/usr/bin/perl
#debugout.pm

package debugout;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(debugout $depth $debugmode);
our $debugmode = 0;
our $depth = 0;

sub debugout($){
	if ($debugmode == 1 ){ 
		my $string = (shift);
		my @caller = caller;
		$depthstring = "  |" x $depth;
		print "<br>$depthstring  <small>$caller[1] $caller[2]</small> $string";
	}
}
1;
