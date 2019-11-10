 #!/usr/bin/perl
#ioshiftvar.pm

package ioshiftvar;

use stringutil;
use Exporter;
use debugout;
use getenglish;
use strict;
use warnings;
use sqlhandler;
#use CGI::Inspect;
use Carp;

our @ISA = qw(Exporter);
our @EXPORT = qw( ioshiftvar_create ioshiftvar_builder ioshiftvar_createarr 
				  ioshiftvar_getshiftdiff );

sub ioshiftvar_create($$$)
{
	my $ioshiftid = shift;
	my $iovarid = shift;
	my $shiftval = shift;
	my $sqlcmd = "INSERT INTO ioshiftvar( ioshift_id, iovar_id, shift ) VALUES ( $ioshiftid, $iovarid, $shiftval )";
	return returnid( $sqlcmd );
}

sub ioshiftvar_createarr($$)
{
	#this creates a database row from an array, not an array from a database row.
	my $ioshiftid = shift;
	my @ioshiftvars = @{(shift)};
	foreach my $ioshiftvar( @ioshiftvars )
	{
		my %shiftdata = %{($ioshiftvar)};
		ioshiftvar_create( $ioshiftid, $shiftdata{'iovarid'}, $shiftdata{'shiftval'} );
	}
}


sub ioshiftvar_builder($$)
{
	#builds array of hashes representing iovar and shift values for later processing.
	my @pos = @{(shift)};
	my $iostatement = shift;
	my @returnarray;
	foreach my $element(@pos)
	{

		my @enteredpos = @{$element};
		my $enteredval = $enteredpos[0];
		my $enteredposval = $enteredpos[1];
		# can select first because any match will be correct var
		my @ioreturn = arrayofresults2( "SELECT var, i.id FROM iovar AS i JOIN 
							iovarposition AS p ON i.id = p.iovar_id
							WHERE i.iostatement_id = $iostatement AND 
							p.position = $enteredposval LIMIT 1");
							
		my @iorow = @{$ioreturn[0]};
		my $shiftval = $enteredval - $iorow[0];		
		#premisevar_create( $premiseid, $ioreturn[1], $shiftval );
		my %varstuff;
		$varstuff{"iovarid"} = $iorow[1];
		$varstuff{"shiftval"} = $shiftval;
		@returnarray = (@returnarray, {%varstuff} );

	}
	return @returnarray;
}

sub ioshiftvar_getshiftdiff($$)
{
	#takes two ioshiftvals and gets the var shift diff between them
	#first arg should be one that gets shifted (for future reference)
	#results are ordered by iovar.var (so @1, @2, @3)
	my $ioshiftval1 = shift;
	my $ioshiftval2 = shift;
	my $sql	="SELECT var1.shift - var2.shift from ioshiftvar var1  INNER JOIN ioshift shift1 on var1.ioshift_id = shift1.id INNER JOIN ioshiftvalue sv1 on shift1.id = sv1.ioshift_id INNER JOIN ioshift shift2 on shift1.iostatement_id = shift2.iostatement_id  INNER JOIN ioshiftvalue sv2 on sv2.ioshift_id = shift2.id INNER JOIN ioshiftvar var2 on var2.ioshift_id = shift2.id and var1.iovar_id = var2.iovar_id INNER JOIN iovar iov on var1.iovar_id = iov.id WHERE sv1.id = $ioshiftval1 and sv2.id = $ioshiftval2 ORDER BY iov.var;"; 
	my @shiftdiff = arrayofresults($sql);
	if( scalar (@shiftdiff) eq 0){ confess "error getting shift diff, probably mismatched inputs" }
	return @shiftdiff;
}

sub ioshiftvar_getshiftdiffnoerr($$)
{
	# is copy of above because I'm lazy. In some cases a null shiftdiff is valid, like conjunction.
	my $ioshiftval1 = shift;
	my $ioshiftval2 = shift;
	my $sql	="SELECT var1.shift - var2.shift from ioshiftvar var1  INNER JOIN ioshift shift1 on var1.ioshift_id = shift1.id INNER JOIN ioshiftvalue sv1 on shift1.id = sv1.ioshift_id INNER JOIN ioshift shift2 on shift1.iostatement_id = shift2.iostatement_id  INNER JOIN ioshiftvalue sv2 on sv2.ioshift_id = shift2.id INNER JOIN ioshiftvar var2 on var2.ioshift_id = shift2.id and var1.iovar_id = var2.iovar_id INNER JOIN iovar iov on var1.iovar_id = iov.id WHERE sv1.id = $ioshiftval1 and sv2.id = $ioshiftval2 ORDER BY iov.var;"; 
	my @shiftdiff = arrayofresults($sql);
	return @shiftdiff;
}
