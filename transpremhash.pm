#!/usr/bin/perl
#transpremhash.pm
package transpremhash;

use Exporter;
use debugout;
#use CGI::Inspect;
use strict;
use warnings;
use sqlhandler;
use linkfinder;
use conclusion;
use premise;
use ioshiftvalue;
use ioshiftvar;

our @ISA = qw(Exporter);
our @EXPORT = qw( transpremhash_returnmatches 
				 transpremhash_buildpseudohash transpremhash_idealize);

sub transpremhash_ismatch($$)
{
	#I don't think this works - how can it do anything except return if 
	#the last premise is a match (of any premise)?  But I don't know what this was supposed to do.
	my %tphash1 = %{(shift)};
	my %tphash2 = %{(shift)};
	my @premises1 = @{($tphash1{'premises'})};
	my @premises2 = @{($tphash2{'premises'})};
	my $value = 1;
	foreach my $premisehash1(@premises1) #for each premise in the group
	{
		$value = 0;
		foreach my $premisehash2(@premises2) #for each premise in the group
		{
			my %phash1 = %{$premisehash1};
			my %phash2 = %{$premisehash2};
			if( $phash1{'ioshiftvalueid'} eq $phash2{'ioshiftvalueid'} )
			{
				$value = 1;  #set to true if any match
			}
		}
	}
	$value = $value and ( scalar(@premises1 ) eq scalar(@premises2) );
	return $value;	
}

sub transpremhash_returnmatches($$)
{
	#takes arrays of tphashes and returns matches
	my @tphasharr1 = @{(shift)};
	my @tphasharr2 = @{(shift)};
	my @matches;
	foreach my $tphash1(@tphasharr1) #for each premise in the group
	{
		foreach my $tphash2(@tphasharr2) #for each premise in the group
		{
			if( transpremhash_ismatch( $tphash1, $tphash2 ) )
			{
				@matches = ( @matches, {%{$tphash2}} );
			}
		}
	}
	return @matches;
}

sub transpremhash_idealize( $ )
{
	
	#4/8/17 - takes transpremhash, shifts array so that first iosv is good.
	my %tphash = %{(shift)};
	my @premises = @{($tphash{'premises'})};
	#get ideal shift for first
	my @shiftdiff;
	my %newtphash;
	my @newpremises;
	foreach my $premisehashref( @premises )
	{
		my %premisehash = %{($premisehashref)};

		if( $premisehash{'position'} eq '0' and $premisehash{'type'} eq 'I' )
		{
			#for the first if, shift it to 0 and get the shift diff
			my $iosv = $premisehash{'ioshiftvalueid'};
			$premisehash{'ioshiftvalueid'} = ioshiftvalue_shifttoideal( $iosv );
			#get the shift diff to apply later
			@shiftdiff = ioshiftvar_getshiftdiff( $premisehash{'ioshiftvalueid'}, $iosv );
			@newpremises = ( @newpremises, \%premisehash );
		}
	}
	#separate loop because may be unsorted

	foreach my $premisehashref( @premises )
	{
		my %premisehash = %{($premisehashref)};
		if( $premisehash{'position'} ne '0' or $premisehash{'type'} eq 'C' )
		{
			#for the everything BUT the first if, shift according to shift diff
			my $iosv = $premisehash{'ioshiftvalueid'};
			$premisehash{'ioshiftvalueid'} = ioshiftvalue_shiftvars( $iosv, \@shiftdiff );
			@newpremises = ( @newpremises, \%premisehash );
		}
	}
	$tphash{'premises'} = \@newpremises;

	return %tphash;
}

sub transpremhash_buildpseudohash($)
{
	# takes a conclusion and builds a not-quite-right tphash with it.  
	# Currently used only for testing.
	my $conclid = shift;
	my %conclusionhash = conclusion::conclusion_getwithpremises( $conclid );
	my %tphash;
	my @premises;
	my @prems = @{($conclusionhash{'premises'})};
	foreach my $premid( @prems )
	{
		my %phash = premise_gethash( $premid );
		$phash{'ioshiftvalueid'} = $phash{'ioshiftvalue_id'};
		@premises = ( @premises, \%phash );
	}
	$tphash{'premises'} = \@premises;
	return %tphash;
}
