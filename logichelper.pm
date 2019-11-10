#!/usr/bin/perl
#logichelper.pm

package logichelper;

use Exporter;
use debugout;
use strict;
use warnings;
use sqlhandler;
#use CGI::Inspect;
use List::MoreUtils qw(uniq);
use premise;

our @ISA = qw(Exporter);
our @EXPORT = qw( logichelper_arrayseqnoorder
					logichelper_arrayseq);



sub logichelper_arrayseq($$)
{
	#returns true if arrays are equal
	my @arr1 = @{(shift)};
	my @arr2 = @{(shift)};
	my $value = scalar(@arr1) == scalar(@arr2);
	my $ind = 0;
	foreach my $arrval( @arr1 )
	{
		$value = $value && ( $arrval eq $arr2[$ind] );
		$ind++;
	}
	return $value;
}

sub logichelper_arrayseqnoorder($$)
{
	#returns true if arrays are equal
	my @arr1 = @{(shift)};
	my @arr2 = @{(shift)};
	@arr1 = sort @arr1;
	@arr2 = sort @arr2;
	my $value = logichelper_arrayseq( \@arr1, \@arr2 );
	return $value;
}
