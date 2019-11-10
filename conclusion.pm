#!/usr/bin/perl

#conclusion.pm

package conclusion;

use stringutil;
use Exporter;
use debugout;
use getenglish;
use strict;
use warnings;
use sqlhandler;
use premise;

use createstatementpage;
use createtransitivedetail;

our @ISA = qw(Exporter);
our @EXPORT = qw( conclusion_create conclusion_getwithpremises 
				conclusion_checkifpremsexist conclusion_hasduplicateprem
				conclusion_isvalid conclusion_getpremisesonly
				conclusion_createsubpages );

sub conclusion_create($)
{
	my $estruth = shift;
	my $sqlcmd;
	if ($estruth =~ 'false'){
		$sqlcmd = "INSERT into conclusion(votestatus, impliedstatus, totalvotes, falsevotes ) values ('false', 'unknown', 1, 1 )";
	}elsif($estruth =~ 'true'){
		$sqlcmd = "INSERT into conclusion(votestatus, impliedstatus, totalvotes, truevotes ) values ('true', 'unknown', 1, 1 )";
	}elsif($estruth =~ 'unknown'){
		$sqlcmd = "INSERT into conclusion(votestatus, impliedstatus, totalvotes, unknownvotes ) values ('unknown', 'unknown', 1, 1 )";
	}elsif($estruth =~ 'skip'){
		$sqlcmd = "INSERT into conclusion(votestatus, impliedstatus ) values ('unknown', 'unknown' )";
	}
	return returnid( $sqlcmd );
}


sub conclusion_getwithpremises($)
{
	my $conclusionid = shift;
	my @premiseids = conclusion_getpremisesonly($conclusionid);
	my %conclusionhash;
	if( scalar (@premiseids) > 0)
	{
		$conclusionhash{'id'} = $conclusionid;
		$conclusionhash{'premises'} = \@premiseids;
	}
	return %conclusionhash;
}

sub conclusion_getpremisesonly($)
{
	my $conclusionid = shift;
	my $sql = "select id from premise where conclusion_id = $conclusionid order by type DESC, position;";
	my @premiseids = arrayofresults($sql);
	return @premiseids;
}

sub conclusion_checkifpremsexist($)
{
	#checks if conclusion with prems (from hashes) exists 
	#only 3 prems supported - should never enter 2 ifs and 2 thens
	my @prems = @{(shift)};
	my %prem1 = %{($prems[0])};
	my %prem2 = %{($prems[1])};
	my $sqlpart1 = "select p1.conclusion_id from premise p1 join premise p2 on p1.conclusion_id = p2.conclusion_id and p1.id <> p2.id ";
	my $sqlpart2 = "where p1.type = '$prem1{'type'}' and p1.ioshiftvalue_id = $prem1{'ioshiftvalueid'} and p2.type = '$prem2{'type'}' and p2.ioshiftvalue_id = $prem2{'ioshiftvalueid'}";

	if( scalar( @prems ) > 2 )
	{
		#if 3 prems, add third
		my %prem3 = %{($prems[2])};
		$sqlpart1 = "$sqlpart1 join premise p3 on p1.conclusion_id = p3.conclusion_id and p3.id <> p2.id and p3.id <> p1.id";
		$sqlpart2 = "$sqlpart2 and p3.type = '$prem3{'type'}' and  p3.ioshiftvalue_id = $prem3{'ioshiftvalueid'};";
	}
	else
	{
		#if only 2 prems, exclude any that has a third prem
		$sqlpart1 = "$sqlpart1 left join premise p3 on p1.conclusion_id = p3.conclusion_id and p3.id <> p2.id and p3.id <> p1.id";
		$sqlpart2 = "$sqlpart2 and p3.id IS NULL ;";

	}
	my $result = stringreturn("$sqlpart1 $sqlpart2");
	return $result;
}


sub conclusion_isvalid($)
{
	#takes prem hash array and decides whether it's valid
	my $premhashref = shift;
	my $isvalid = 1;#conclusion_hasnoduplicateprem($premhashref);
	return $isvalid;
}

sub conclusion_hasnoduplicateprem($)
{
	#takes prem hash array and detects any duplicate ifs or thens
	#note that can handle both initial input and implication hash
	my @prems = @{(shift)};
	while( my $premref = pop @prems  )
	{
		my %premhash = %{($premref)};
		foreach my $premref2( @prems )
		{
			my %premhash2 = %{($premref2)};
			if( $premhash{'ioshiftvalue'} eq $premhash2{'ioshiftvalue'}
				and $premhash{'iostatementid'} eq $premhash2{'iostatementid'}
				and $premhash{'type'} eq $premhash2{'type'} )
			{
				return 0;
			}
		}
	}
	return 1;
}

sub conclusion_isdoublethen($)
{
	#CAN BE OPTIMIZED - make conclusion_id an index in premise
	my $conclusionid = shift;
	my $sql = "select id from premise where conclusion_id = $conclusionid and type = 'C' and position = 1;";
	my @premiseids = arrayofresults($sql);
	return scalar(@premiseids) ne 0;
}

sub conclusion_createsubpages($)
{
	my $conclusionid = shift;
	my @premises = conclusion_getpremisesonly( $conclusionid );
	debugout( "got this many premises: scalar(@premises) for conclusion $conclusionid");
	foreach my $premise(@premises)
	{
		debugout("creating statement page for $premise");
		CreateTheStatementPage($premise);
	}
}
