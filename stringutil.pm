#!/usr/bin/perl
#stringutil.pm

package stringutil;
use strict;
use Exporter;
use debugout;
#use CGI::Inspect;
our @ISA = qw(Exporter);
our @EXPORT = qw(trim notstatement unquote value_flip getthepositions
				  getthepositions_notrim);				  

sub trim($){
	my $trimstring = shift;
	$trimstring=~ s/^\s+//; # removes leading spaces
	$trimstring=~ s/\s+$//; # removes trailing spaces
	return $trimstring;
}

sub notstatement($$){
	my $raw = shift;
	my $english = shift;
	if ($raw =~ /~/){
		$english = "not $english";
	}
	return $english;
}

sub unquote($)
{
	my $string = shift;
	$string =~ s/^\s+//;  
	return $string;
}


sub value_flip($)
{
	my $value = shift;
	if( $value eq 'T' )
	{
		$value = 'F';
	}
	else 
	{
		$value = 'T';
	}
	return $value;
}

sub getthepositions_notrim($$)
{
	#called directly from getenglish and from the method below
	
	#position = position of searchstr in iostatement. 
	#input: @1 loves @2, @2
	#output: 9 (0-based, gets @)
	#Notoriously frustrating for such a short bit of code.
	
	my $iostatement = shift;
	my $searchstr = shift;	
	my @positions;
	my @vars;
	my $lastpos = 0;
	while( $iostatement =~ /$searchstr/gi ) 
	{
		#use index to specifically control where searching from - I don't trust pos
		my $spot = index($iostatement, $searchstr, $lastpos );
		#debugout( "finding $spot for x-$iostatement-x for x-$searchstr-x");
		$lastpos = $spot+1;
		@positions = ( @positions, $spot );
	}
	return @positions;
}
sub getthepositions($$)
{
	my $iostatement = trim(shift);
	my $searchstr = trim(shift);
	
	$iostatement =~ s/~//; #remove tilde from negatives;
	my @positions = getthepositions_notrim( $iostatement, $searchstr );
	return @positions;
}
