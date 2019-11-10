#!/usr/bin/perl
#iovar.pm

package iovar;

use stringutil;
use Exporter;
use debugout;
use getenglish;
use strict;
use warnings;
use sqlhandler;

our @ISA = qw(Exporter);
our @EXPORT = qw( iovar_create iovar_entervarsandpositions iovar_gethash );

use iovarposition;

sub iovar_create($$)
{
	my $iostatementid = shift;
	my $var = shift;
	my $sqlcmd;
	$sqlcmd = "INSERT INTO iovar( iostatement_id, var ) VALUES ( ?, ? )";
	my $id = returnid_3( $sqlcmd, $iostatementid, $var );
	return $id;
}

sub iovar_gethash($)
{
	my $iovarid = shift;
	return returnhash( "Select * from iovar where id = $iovarid");
}

sub iovar_entervarsandpositions($$)
{
	my @vars = @{(shift)};
	my $iostatement = shift;
	
	foreach my $vararr (@vars)
	{
		my @posarr = @{$vararr};
		my $var = shift( @posarr );
		my $iovarid = iovar_create( $iostatement, $var );
		foreach my $pos(@posarr)
		{
			iovarposition_create( $iovarid, $pos, $iostatement );
		}
	}
}
