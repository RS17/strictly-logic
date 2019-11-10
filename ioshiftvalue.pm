#!/usr/bin/perl
#ioshiftvalue.pm

package ioshiftvalue;

use stringutil;
use Exporter;
use debugout;
use strict;
use warnings;
use sqlhandler;
use ioshift;
#use CGI::Inspect;

our @ISA = qw(Exporter);
our @EXPORT = qw( ioshiftvalue_create ioshiftvalue_getcreate 
					ioshiftvalue_gethash ioshiftvalue_shiftvars
					ioshiftvalue_getioshiftvarshifts 
					ioshiftvalue_getiostatementid
					ioshiftvalue_shifttoideal);

sub ioshiftvalue_create($$)
{
	my $ioshift = shift;
	my $value = shift;
	my $sql = "INSERT INTO ioshiftvalue ( ioshift_id, value ) VALUES ($ioshift, '$value');";
	my $returnid = returnid($sql);
	return $returnid;
}

sub ioshiftvalue_get($$)
{
	my $ioshift = shift;
	my $value = shift;
	my $sql = "SELECT id FROM ioshiftvalue WHERE ioshift_id = $ioshift and value = '$value'";
	my $returnid = stringreturn($sql);
	return $returnid;	
}

sub ioshiftvalue_gethash($)
{
	my $id = shift;
	my %hash;
	my $sql = "SELECT ioshift_id, value FROM ioshiftvalue WHERE id=$id";
	my @retarr = arrayofresults2($sql);
	$hash{'ioshiftid'} = $retarr[0]->[0];
	$hash{'value'} = $retarr[0]->[1];
	return %hash;	
}

sub ioshiftvalue_getcreate($$)
{
	my $ioshift = shift;
	my $value = shift;
	my $returnid;
	$returnid = ioshiftvalue_get($ioshift, $value);
	if( not defined $returnid )
	{
		$returnid = ioshiftvalue_create($ioshift, $value );
	}
	return $returnid;
}

sub ioshiftvalue_shiftvars($$) 
{
	#2/26/2017
	#shifts iovars of existing ioshift values by specified array
	#(creating new iovars/shifts if necessary
	# [ioshiftvalue] >- [ioshift] -< [ioshiftvar]
	my $ioshiftvalueid = shift;
	my %iosvhash  = ioshiftvalue_gethash( $ioshiftvalueid );
	my $arref = shift;
	my @shiftarray = @{$arref};
	# get current ioshiftvars (ordered by iovar_id like shiftarray)
	my @ioshiftvals = ioshiftvalue_getioshiftvarshifts( $ioshiftvalueid );
	my $shiftindex = 0;
	my @finalshifts;
	foreach my $ioshiftrow( @ioshiftvals )
	{
		my %varstuff;
		my @ioshiftstuff =  @{$ioshiftrow};
		
		$varstuff{'iovarid'} = $ioshiftstuff[0];
		$varstuff{'shiftval'} = $ioshiftstuff[1] + $shiftarray[$shiftindex];
		@finalshifts = (@finalshifts, \%varstuff );
		$shiftindex++;
	}
	# get/create ioshift (auto-creates ioshiftvars)
	my $iostatementid = ioshiftvalue_getiostatementid( $ioshiftvalueid );
	my $ioshiftid = ioshift_getcreate( $iostatementid, \@finalshifts );
	# get/create ioshiftvalue
	my $ioshiftvalueshifted = ioshiftvalue_getcreate( $ioshiftid, $iosvhash{'value'} );
	return $ioshiftvalueshifted;
}

sub ioshiftvalue_getioshiftvarshifts($)
{
	#2/28/2017
	#NOTE THAT ordered by iovar.var (@1, @2, etc) - this is the standard 
	# ordering for iovars to keep consistent across methods
	my $ioshiftvalueid = shift;
	my $sql = "select iosv.iovar_id, iosv.shift from ioshiftvar iosv join ioshiftvalue iosh on iosh.ioshift_id = iosv.ioshift_id INNER JOIN iovar iov on iov.id = iosv.iovar_id WHERE iosh.id = $ioshiftvalueid ORDER BY iov.var;";
	my @retarr = arrayofresults2( $sql );
	return @retarr;
}

sub ioshiftvalue_getiostatementid($)
{
	#2/28/2017
	my $ioshiftvalueid = shift;
	my $sql = "select ios.iostatement_id from ioshiftvalue iosv join ioshift ios on ios.id = iosv.ioshift_id where iosv.id = $ioshiftvalueid;";
	my $iostatementid = stringreturn( $sql );
	return $iostatementid;
}

sub ioshiftvalue_shifttoideal($)
{
	#4/8/17 - creates "ideal" @1 x @2 etc. shiftvalue
	my $iosvid = shift;
	my %iosvhash = ioshiftvalue_gethash($iosvid );
	my $value = $iosvhash{'value'};
	my @shifts = ioshiftvalue_getioshiftvarshifts( $iosvid );
	my @finalshifts;
	foreach my $shift( @shifts )
	{
		my %varstuff;
		my @ioshiftstuff =  @{$shift};
		debugout("row is @ioshiftstuff" );
		$varstuff{'iovarid'} = $ioshiftstuff[0];
		$varstuff{'shiftval'} = 0; #means @number is same as iovar
		@finalshifts = (@finalshifts, \%varstuff );
	}
	my $iostatementid = ioshiftvalue_getiostatementid( $iosvid );
	my $ioshiftid = ioshift_getcreate( $iostatementid, \@finalshifts );
	# get/create ioshiftvalue
	my $newiosv = ioshiftvalue_getcreate( $ioshiftid, $iosvhash{'value'} );
	return $newiosv;
}
