#!/usr/bin/perl
#sqlhandler.pm

package sqlhandler;

use stringutil;
use List::MoreUtils 'first_index', 'uniq';
use Exporter;
use debugout;
use strict;
use warnings;
use Carp;
use CGI::Carp 'fatalsToBrowser';
#use CGI::Inspect;
our @ISA = qw(Exporter);
our @EXPORT = qw(stringreturn arrayofresults arrayofresults2 arrayofresults3 nullquery nullquery_2
					returnid returnid_2 returnid_3 newstatementmaker returnhash 
					stringreturn_secure arrayofresults2_secure2 returnhash_secure2);

### SQL ###

sub stringreturn($){
	my $sqlcmd = shift;
	my @output = arrayofresults($sqlcmd);
	return $output[0];
}

sub stringreturn_secure($$){
	my $querystring = shift;
	my $parameter = shift;
	my $dbh = DBI->connect('dbi:mysql:surilega_postulates','surilega_webuser','silverpikul1') 
	|| confess "Error opening database: $DBI::errstr\n";
	my $sth = $dbh->prepare( $querystring );
	$sth -> execute( $parameter ) || confess "Error executing $DBI::errstr\n" ;
	my ($output) = $sth->fetchrow_array;
	
	$sth->finish; 
	$dbh->disconnect;
	debugout($querystring);
	return $output;
}

sub arrayofresults($){ #this only returns one col, if need more use below.
	my $sqlcmd = shift;
	#debugout( $sqlcmd );
	my @returnarray;
	my $ref = 0;
	my $dbh = returndbh();
	my $engstatement;
	my $sth;
	$sth = $dbh->prepare($sqlcmd);
	$sth->execute() || confess "Couldn't execute query: $DBI::errstr\n";
	while (my @row=$sth->fetchrow_array){ 
		$returnarray[$ref]=$row[0];
		#debugout($row[0]);
		$ref++;
	}		
	#debugout($sqlcmd);
	$dbh->disconnect;
	$sth->finish;	
	return @returnarray;
}

sub arrayofresults2($){ 
	#this now returns any number of columns in a hash.  Unlike old 
	#version of method which was single array, this is array of arrays.
	my $sqlcmd = shift;
	my $dbh = returndbh();
	my $sth;
	$sth = $dbh->prepare($sqlcmd);
	#debugout($sqlcmd);
	$sth->execute() || confess "Couldn't execute query: $DBI::errstr\n";
	my $arref = $sth->fetchall_arrayref();
	
	my @returnarr = @{($arref)};

	$dbh->disconnect;
	$sth->finish;
	return @returnarr;
}

sub arrayofresults2_secure2($$$){ 
	#this now returns any number of columns in a hash.  Unlike old 
	#version of method which was single array, this is array of arrays.
	my $sqlcmd = shift;
	my $param1 = shift;
	my $param2 = shift;
	my $dbh = returndbh();
	my $sth;
	$sth = $dbh->prepare($sqlcmd);
	#debugout($sqlcmd);
	$sth->execute($param1, $param2) || confess "Couldn't execute query: $DBI::errstr\n";
	my $arref = $sth->fetchall_arrayref();
	
	my @returnarr = @{($arref)};

	$dbh->disconnect;
	$sth->finish;
	return @returnarr;
}

sub arrayofresults3($){ #use this when three cols to return
	die "this method is faulty, see arrayofresults2 for correct multi-column method";
	my $sqlcmd = shift;
	my @returnarr;
	my @rowarr;
	my $dbh = returndbh();
	my $engstatement;
	my $sth;
	$sth = $dbh->prepare($sqlcmd);
	#debugout($sqlcmd);
	$sth->execute() || confess "Couldn't execute query: $DBI::errstr\n";
	while (my @row=$sth->fetchrow_array){ 
		$rowarr[0] = $row[0];
		$rowarr[1] = $row[1];
		$rowarr[2] = $row[2];
		@returnarr = (@returnarr, [@rowarr]);
	}		
	$dbh->disconnect;
	$sth->finish;
	return @returnarr;
}

sub nullquery($){
	my $dbh = DBI->connect('dbi:mysql:surilega_postulates','surilega_webuser','silverpikul1') 
	|| confess "Error opening database: $DBI::errstr\n";
	my $querystring = shift;
	#my $parameter = shift;
	debugout($querystring);
	my $sth = $dbh->prepare( $querystring );
	$sth -> execute( ) || confess "Couldn't execute query: $DBI::errstr\n";; 
	$dbh->disconnect;
	$sth->finish;
}

sub nullquery_2($$){
	my $dbh = DBI->connect('dbi:mysql:surilega_postulates','surilega_webuser','silverpikul1') 
	|| confess "Error opening database: $DBI::errstr\n";
	my $querystring = shift;
	my $parameter = shift;
	#my $parameter = shift;
	my $sth = $dbh->prepare( $querystring );
	$sth -> execute( $parameter );
	$dbh->disconnect;
	$sth->finish;
}

sub returnid_3($$$)
{
	my $dbh = returndbh();
	my $querystring = shift;
	my $parameter1 = shift;
	my $parameter2 = shift;
	my $sth = $dbh->prepare( $querystring );
	$sth -> execute( $parameter1, $parameter2 ) || confess "Couldn't execute query: $DBI::errstr\n";;
	my $insertedstatement=getid( $sth, $dbh );
	$sth->finish;
	$dbh->disconnect;
	return $insertedstatement;
}

sub returnid_2($$)
{
	my $dbh = returndbh();
	my $querystring = shift;
	my $parameter = shift;
	my $sth = $dbh->prepare( $querystring );
	$sth -> execute( $parameter );
	my $insertedstatement=getid( $sth, $dbh );
	$sth->finish;
	$dbh->disconnect;
	return $insertedstatement;
}

sub returnid($)
{
	#my $dbh = DBI->connect('dbi:mysql:surilega_postulates','surilega_webuser','silverpikul1') 
	#|| confess "Error opening database: $DBI::errstr\n";
	my $dbh = returndbh();
	my $querystring = shift;
	my $sth = $dbh->prepare( $querystring );
	$sth -> execute( ) || confess "Couldn't execute query: $DBI::errstr\n";;
	my $insertedstatement=getid( $sth, $dbh );
	$sth->finish;
	$dbh->disconnect;

	return $insertedstatement;
}

sub returnhash( $ )
{
	my $sqlcmd = shift;
	my $ref = 0;
	my $dbh = returndbh();
	my $hash =$dbh-> selectrow_hashref( $sqlcmd ) || confess "Couldn't execute query: $DBI::errstr\n";
	my %rethash = %{($hash)};
	
	$dbh->disconnect;
	return %rethash;
}
sub returnhash_secure2( $$$ )
{
	my $sqlcmd = shift;
	my $param1 = shift;
	my $param2 = shift;
	my $ref = 0;
	my $dbh = returndbh();
	my $sth = $dbh -> prepare( $sqlcmd );
	$sth->execute( $param1, $param2 ) || confess "Couldn't execute query: $DBI::errstr\n";
	my %rethash;
	while( my @row = $sth -> fetchrow_array)
	{
		$rethash{$row[0]} = $row[1];
	}
	
	#my %rethash = %{($hash)};
	$sth -> finish();
	$dbh->disconnect;
	
	return %rethash;
}
sub returndbh()
{
	my $dbh = DBI->connect('dbi:mysql:surilega_postulates','surilega_webuser','silverpikul1') 
	|| confess "Error opening database: $DBI::errstr\n";
	return $dbh;
}


sub getid($$)
{
	my $sth = shift;
	my $dbh = shift;
	$sth = $dbh->prepare("SELECT last_insert_id()");#put db command in quotes;
	$sth->execute() || confess "Couldn't execute query: $DBI::errstr\n";;
	my $insertedstatement=$sth->fetchrow_array;
	return $insertedstatement;
}


