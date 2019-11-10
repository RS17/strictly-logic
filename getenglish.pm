#!/usr/bin/perl
#getenglish.pm

package getenglish;

use stringutil;
use List::MoreUtils 'first_index', 'uniq';
use Exporter;
use debugout;
use strict;
use warnings;
use Carp;
use CGI::Carp 'fatalsToBrowser';
use sqlhandler;
use conclusion;
use varfixer;
#use CGI::Inspect;
our @ISA = qw(Exporter);
our @EXPORT = qw(getenglishfromiforthen2 getenglishfromprin getenglishfromconcl);


sub getenglishfromprin($){
	#turns principleid into if-then
	my $prinid = shift;
	my $ifstatement;
	my $thenstatement;
	my $engstatement;
	my $dbh = returndbh();
	my $sth = $dbh->prepare("select concat(if(a.ifstatement like '~%', 'not ', ''), b.description), concat(if(a.thenstatement like '~%', 'not ', ''), c.description), 
		a.ifstatement, a.thenstatement from principles as a 
		inner join iostatements as b on REPLACE(a.ifstatement, '~','') = b.id inner join iostatements as c on REPLACE(a.thenstatement, '~','')  = 
		c.id where a.id = $prinid;" ); # this is probably the greatest sql statement I've ever written # unfortunately since I neglected to make a useful comment I've forgotten what this does now.
	$sth->execute() || die "Couldn't execute query: $DBI::errstr\n";
	my (@statementarray) = $sth->fetchrow_array;
	if ($statementarray[2] =~ /\|/){ #need each ifstatement if split
		debugout("\ngot split $statementarray[2]");
		my @splitif = split(/\|/, $statementarray[2]); 
		$splitif[0] =~ s/[\~]//g;
		$splitif[1] =~ s/[\~]//g;
		my @ifarray = arrayofresults("select description from iostatements where id = REPLACE($splitif[0],'~','') or id = REPLACE($splitif[1],'~','');" );
		debugout("ifarray is @ifarray");
		#too hard to do this in sql.
		$ifarray[0] = notstatement($splitif[0], $ifarray[0]);
		$ifarray[1] = notstatement($splitif[1], $ifarray[1]);
		
		$ifstatement= "<a href=\\prin$splitif[0].html>$ifarray[0]</a> && <a href=\\prin$splitif[0].html>$ifarray[1]</a>";
	}else{
		my $special=$statementarray[2];
		$special=~ s/[\~]//g;
		$ifstatement = "<a href=\\prin$special.html>$statementarray[0]</a>";
	}
	if ($statementarray[3] =~ /\|/){ #need each thenstatement then split
		debugout("\ngot split $statementarray[3]");
		my @splitthen = split(/\|/, $statementarray[3]); 
		$splitthen[0] =~ s/[\~]//g;
		$splitthen[1] =~ s/[\~]//g;
		my @thenarray = arrayofresults("select description from iostatements where id = REPLACE($splitthen[0],'~','') or id = REPLACE($splitthen[1],'~','');" );
		debugout("thenarray is @thenarray");
		#too hard to do this in sql.
		$thenarray[0] = notstatement($splitthen[0], $thenarray[0]);
		$thenarray[1] = notstatement($splitthen[1], $thenarray[1]);
		$thenstatement= "<a href=\\prin$splitthen[0].html>$thenarray[0]</a> && <a href=\\prin$splitthen[1].html>$thenarray[1]</a>";
	}else{
		my $specialthen=$statementarray[3];
		$specialthen=~ s/[\~]//g;
		$thenstatement = "<a href=\\prin$specialthen.html>$statementarray[1]</a>";
	}
	$engstatement="if $ifstatement then $thenstatement";
	$dbh->disconnect;
	return $engstatement;
}

sub getenglishfromiforthen($){
	#gets if statement or thenstatement, splits if necessary, and returns array.
	my $iforthen = shift;
	my $dbh = returndbh();
	my @statementarray;
	if ($iforthen =~ /\|/){ #need each ifstatement if split
		my @splitstatement = split(/\|/, $iforthen); 
		$splitstatement[0] =~ s/[\~]//g;
		$splitstatement[1] =~ s/[\~]//g;
		@statementarray = arrayofresults("select description from iostatements where id = REPLACE($splitstatement[0],'~','') or id = REPLACE($splitstatement[1],'~','');" );
		debugout("ifarray is @statementarray");
	}else{
		@statementarray = arrayofresults("select description from iostatements where id = $iforthen;" );
	}

	$dbh->disconnect;
	return @statementarray;
}


sub getenglishfromconcl($)
{
	my @premises = conclusion_getpremisesonly(shift);
	my $endstring;
	foreach my $premise(@premises)
	{
		my $premisestring = getenglishfromiforthen2($premise);
		$endstring = "$endstring$premisestring";
		
	}
	return $endstring;
}


sub getenglishfromiforthen2($){
	#gets if statement or thenstatement, splits if necessary, and returns array.
	my $prinid = shift;
	my $sql = "select concat( if( p.position = 0 and p.type = 'I', 'IF ', '' ), if( p.position = 0 and p.type = 'C', ' THEN ', '' ), if( p.position = 1, ' AND ', ''), if( v.value = 'F', 'NOT ', '' ), i.description ) from iostatements i join ioshift s on i.id = s.iostatement_id join ioshiftvalue v on v.ioshift_id = s.id join premise p on p.ioshiftvalue_id = v.id where p.id = $prinid;";
	my $resultstring = stringreturn($sql);
	my $shiftssql = "select v.shift from ioshiftvar v join ioshift s on v.ioshift_id = s.id join ioshiftvalue w on w.ioshift_id = s.id join premise p on w.id = p.ioshiftvalue_id where p.id = $prinid;";
	my @shifts = arrayofresults( $shiftssql );
	#use shifts to replace
	my @positions = getthepositions_notrim( $resultstring, "@" );
	my $ind = 0;
	
	foreach my $position(@positions)
	{
		my $shift = $shifts[$ind];
		#note - assumes number is a single character, probably should change at some point
		substr( $resultstring, $position + 1, 1 ) = substr( $resultstring, $position + 1, 1 ) + $shift; 
		$ind++;
	}
	return $resultstring;
}

1;
