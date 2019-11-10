#!/usr/bin/perl
#ioshift.pm

# 10/26/19 - From what I recall ioshift refers to "shifting" the number 
# values of a statement for compatibility. With different numbers.  So 
# if @1 is worse than @2 then @2 is better than @1 needs to see the connection 
# to @1 is better than @2.  This object somehow helps with that.

package ioshift;

use stringutil;
use Exporter;
use debugout;
use getenglish;
use strict;
use warnings;
use sqlhandler;
#use CGI::Inspect;
use ioshiftvar;

our @ISA = qw(Exporter);
our @EXPORT = qw( ioshift_create ioshift_getcreate ioshift_get );

sub ioshift_create($)
{
	my $iostatementid = shift;
	my $value = shift;
	my $sqlcmd = "INSERT INTO ioshift( iostatement_id ) VALUES ( $iostatementid )";
	my $returnid = returnid( $sqlcmd );
	return $returnid;
}

sub ioshift_get($)
{
	my @ioshiftvars = @{(shift)};
	my @qualifyingioshifts;
	my $firstrun = 1;
	foreach my $ioshiftvar( @ioshiftvars )
	{
		my %varstuff = %{($ioshiftvar)};
		my $sqlcmd = "select s.id from ioshift s join ioshiftvar v on v.ioshift_id = s.id where v.iovar_id = $varstuff{'iovarid'} and v.shift = $varstuff{'shiftval'}";
		my @ioshiftids = arrayofresults( $sqlcmd );
		if ( $firstrun ne 1 )
		{
		    #quick hack because can't install modules - 6/6/2017
		    my %qualifyingioshifts=map{$_ =>1} @qualifyingioshifts;
            my %ioshiftids=map{$_=>1} @ioshiftids;
		    @qualifyingioshifts = grep( $qualifyingioshifts{$_}, @ioshiftids );
			#@qualifyingioshifts = intersect( @qualifyingioshifts, @ioshiftids );
		}
		else
		{
			@qualifyingioshifts = @ioshiftids;
			$firstrun = 0;
		}
	}
	my $num = scalar(@qualifyingioshifts);
	return @qualifyingioshifts;
}

sub ioshift_getcreate($$)
{
	#takes ioshift and ioshiftvars and only creates if not already exists
	my $iostatementid = shift;
	my $ioshiftids = shift; #is ref
	my $returnioshift;
	my @qualifyingioshifts = ioshift_get( $ioshiftids );
	if( scalar( @qualifyingioshifts ) eq 0 )
	{
		debugout("entering qualifyingio");
		$returnioshift = ioshift_create( $iostatementid );
		#also create ioshiftvars
		ioshiftvar_createarr( $returnioshift, $ioshiftids );
	}
	else
	{
		debugout("skipping enter");
		$returnioshift = $qualifyingioshifts[0];
	}
	return $returnioshift; 
}
