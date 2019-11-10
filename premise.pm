#!/usr/bin/perl
#premise.pm

package premise;

use stringutil;
use Exporter;
use debugout;
use strict;
use warnings;
use sqlhandler;
use Carp;
#use CGI::Inspect;
use ioshift;
use ioshiftvalue;

our @ISA = qw(Exporter);
our @EXPORT = qw( premise_create premise_createhash premise_buildhash 
				 premise_getfromiovarshift premise_getfromiovarshiftarray
				 premise_getioshiftvalue premise_returnonlytype premise_getvalue
				 premise_buildhashwshift premise_createhashwshift premise_getiovalconclhash
				 premise_iovalconclhashbuild premise_getallconclusions
				 premise_getiostatementid premise_gethash );
				

sub premise_create($$$$)
{
	my $conclusionid = shift;
	my $position = shift;
	my $type = shift;
	my $ioshiftvalueid = shift;
	my $sqlcmd;
	$sqlcmd = "INSERT INTO premise(conclusion_id, position,
				type, ioshiftvalue_id ) VALUES ( $conclusionid, $position, 
				'$type', $ioshiftvalueid )";
	debugout($sqlcmd);
	my $id = returnid( $sqlcmd );
	return $id;
}

sub premise_createhash($$$)
{
	my $conclusionid = shift;
	my %hash = %{(shift)};
	my $ioshiftvarstuff = shift;
	my $ioshiftid = ioshift_getcreate( $hash{'iostatementid'}, $ioshiftvarstuff );
	my $ioshiftvalueid = ioshiftvalue_getcreate( $ioshiftid, $hash{'value'} );
	return premise_create( $conclusionid, $hash{"position"},$hash{"type"}, $ioshiftvalueid );
}

sub premise_createhashwshift($$)
{
	my $conclusionid = shift;
	my %hash = %{(shift)};
	return premise_create( $conclusionid, $hash{'position'}, $hash{'type'}, $hash{'ioshiftvalueid'});
}

sub premise_buildhash($$$$)
{
	my %hash;
	$hash{"position"} = shift;
	$hash{"iostatementid"} = shift;
	$hash{"type"} = shift;
	my $statement = shift;
	$hash{"statement"} = trim($statement);
	if( substr( $statement, 0, 1 ) eq "~" )
	{
		$hash{"value"} = 'F';
	}
	else
	{
		$hash{"value"} = 'T';
	}
	
	#add values used for the hashwithshift so can use same methods
	$hash{'ioshiftvalue'} = -1;
	
	return \%hash;
}

sub premise_buildhashwshift($$$)
{
	my %hash;
	$hash{'ioshiftvalueid'} = shift;
	$hash{'type'} = shift;
	$hash{'position'}= shift;
	#add values used for the hashwithshift so can use same methods
	$hash{'iostatementid'} = -1;
	return %hash;
}

sub premise_getioshiftvalue($)
{
	my $premiseid = shift;
	my $sql = "SELECT ioshiftvalue_id FROM premise WHERE id = $premiseid";
	my $val = stringreturn($sql);
	return $val;
}

sub premise_getiovalconclhash($)
{
	my $premiseid = shift;
	my $sql = "SELECT ioshiftvalue_id, conclusion_id FROM premise WHERE id = $premiseid";
	my @val = arrayofresults2($sql);
	
	my %hash = premise_iovalconclhashbuild( $val[0], $val[1] );
	return %hash;
}

sub premise_iovalconclhashbuild($$)
{
	my %hash;
	$hash{'ioshiftvalueid'} = shift;
	$hash{'conclusionid'} = shift;
	return %hash;
}

sub premise_getfromiovarshift($$$)
{
	#gets applicable prems with the same iostatement, vars, and shifts (not done yet)
	my $iostatementid = shift;
	my $iovars = shift;
	my $shifts = shift;
	my $sql = "select id from premise where iostatement_id = $iostatementid";
	my @premiseids = arrayofresults( $sql );
	my @resultpremises;
	foreach my $premiseid( @premiseids )
	{
		my $ismatch = premise_checkiovarshiftmatch($iovars, $shifts, $premiseid );
		if( $ismatch )
		{
			@resultpremises = (@resultpremises, $premiseid );
		}
	}
	return @resultpremises;
}

sub premise_gethash($)
{
	my $premiseid = shift;
	my $sqlcmd = "SELECT * FROM premise where id = $premiseid";
	return returnhash( $sqlcmd );
}

sub premise_getiostatementid($)
{
	my $premiseid = shift;
	my $sql = "select i.id from iostatements i join ioshift s on i.id = s.iostatement_id join ioshiftvalue v on v.ioshift_id = s.id join premise p on p.ioshiftvalue_id = v.id where p.id = $premiseid";
	my $val = stringreturn($sql);
	if( $val eq undef )
	{
		confess("premise_getiostatementid returned undef - that's bad");
	}
	return $val;
}

sub premise_getfromiovarshiftarray($)
{
	my @iovarshiftarray = @{(shift)};
	my @returnarray;
	foreach my $iovarshift(@iovarshiftarray)
	{
		my @iovarshiftdata = @{($iovarshift)};
		my @retprem = premise_getfromiovarshift($iovarshiftdata[0], $iovarshiftdata[1], $iovarshiftdata[2]);
		@returnarray = (@returnarray, @retprem );
	}
	return @returnarray;
}

sub premise_checkiovarshiftmatch($$$)
{
	my @iovars = @{(shift)};
	my @shifts = @{(shift)};
	my $premiseid = shift;
	my $index = 0;
	my $ismatch = 1; 
	foreach my $iovar( @iovars )
	{	
		my $varshift = $shifts[$index];
		my $sql = "SELECT shift FROM premisevar WHERE premise_id = $premiseid AND iovar_id = $iovar;";
		my $checkshift = stringreturn( $sql );
		if ( not $varshift eq $checkshift )
		{
			$ismatch = 0;
		}
		$index++;
	}
	return $ismatch;
}

sub premise_returnonlytype($$)
{
	my @premises = @{(shift)};
	my $gettype = shift;
	my @conclusions;
	foreach my $premise(@premises)
	{
		my $sql = "SELECT type FROM premise WHERE id = $premise";
		my $type = stringreturn($sql);
		if( $type eq $gettype )
		{
			@conclusions = (@conclusions, $premise );
		}
	}
	
	return @conclusions;
	
}

