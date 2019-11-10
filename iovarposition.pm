#!/usr/bin/perl
#iovarposition.pm

# 10/27/19 - an iovarposition is the position of a variable in a statement.
# It helps with processing and shifting the variables

package iovarposition;

use stringutil;
use Exporter;
use debugout;
use getenglish;
use strict;
use warnings;
use sqlhandler;

our @ISA = qw(Exporter);
our @EXPORT = qw( iovarposition_create );

sub iovarposition_create($$$)
{
	my $iovarid = shift;
	my $position = shift;
	my $iostatementid = shift;
	my $sqlcmd = "INSERT INTO iovarposition( iovar_id, position, iostatement_id ) VALUES ( $iovarid, $position, ? )";
	nullquery_2( $sqlcmd, $iostatementid );
}

