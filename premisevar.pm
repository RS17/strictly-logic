#!/usr/bin/perl
#ioshiftvar.pm

package premisevar;

use stringutil;
use Exporter;
use debugout;
use getenglish;
use strict;
use warnings;
use sqlhandler;
#use CGI::Inspect;

our @ISA = qw(Exporter);
our @EXPORT = qw( ioshiftvar_create ioshiftvar_builder );

sub premisevar_create($$$)
{
	my $ioshiftid = shift;
	my $iovarid = shift;
	my $shiftval = shift;
	my $sqlcmd = "INSERT INTO ioshiftvar( ioshift_id, iovar_id, shift ) VALUES ( $ioshiftid, $iovarid, $shiftval )";
	nullquery( $sqlcmd );
}

sub premisevar_builder($$$)
{
	my @pos = @{(shift)};
	my $ioshiftid = shift;
	my $iostatement = shift;
	my @returnarray;
	foreach my $element(@pos)
	{

		my @enteredpos = @{$element};
		my $enteredval = $enteredpos[0];
		my $enteredpos = $enteredpos[1];
		# can select first because any match will be correct var
		my @ioreturn = arrayofresults2( "SELECT var, i.id FROM iovar AS i JOIN 
							iovarposition AS p ON i.id = p.iovar_id
							WHERE i.iostatement_id = $iostatement AND 
							p.position = $enteredpos LIMIT 1");		
		my $shiftval = $enteredval - $ioreturn[0];		
		my %varstuff;
		$varstuff{"iovarid"} = $ioreturn[1];
		$varstuff{"shiftval"} = $shiftval;
		@returnarray = (@returnarray, {%varstuff} );
	}
}
