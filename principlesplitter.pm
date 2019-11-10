#!/usr/bin/perl -T
#principlesplitter.pm
package principlesplitter;
use warnings;
#use diagnostics;
use CGI::Pretty qw(:all);
use strict;
use CGI; 
use DBI;
#use LWP::Simple;
use Carp;
use createprinpage;
use createstatementpage;
use createtransitivedetail;

# this script takes a principle and calls createstatement page for each iostatement in the principle.
our @ISA = qw(Exporter);
our @EXPORT = qw(splittheprinciple);

sub splittheprinciple{
	my $okchars='-a-zA-Z0-9_@~&';
	my $dbh=DBI->connect('dbi:mysql:surilega_postulates','surilega_webuser','silverpikul1') ||
		confess "Error opening database: $DBI::errstr\n";
	my $sth;
	my $mbf;
	my $prinid=(shift);#@ARGV[0];#$cgi->param("id"); # if app, this should be id of iostatement (appid on page), not object (what is in the url).
	#my $prinid=1178;
	my @args;


	#@args=$prinid;
	#$ENV{"PATH"} = "";
	#system($^X, "createprinpage.pl", @args);
	#CreateThePrinPage($prinid); - skipping this part for now.

	#get if
	$sth = $dbh->prepare("select ifstatement from principles where id=$prinid");
	$sth->execute() || confess "Couldn't execute query: $DBI::errstr\n";
	my $ifstatement = $sth->fetchrow_array;
	$ifstatement =~tr/~//d;

	#get then
	$sth = $dbh->prepare("select thenstatement from principles where id=$prinid");
	$sth->execute() || confess "Couldn't execute query: $DBI::errstr\n";
	my $thenstatement = $sth->fetchrow_array;
	$thenstatement =~tr/~//d;

	my $stmntid;
	#call createstatementpage
	if ($ifstatement=~/\|/){
		my @ifstatements=split /\|/, $ifstatement;
		foreach (@ifstatements){
			$stmntid = $_ ;
			$stmntid =~ s/[^$okchars]/ /go;
			#system($^X, "createstatementpage.pl", @args);
			CreateTheStatementPage($stmntid);
		}
	}else{
		$ifstatement =~ s/[^$okchars]/ /go;
		#system($^X, "createstatementpage.pl", @args);# || die "Could not open implh $!"; 
		CreateTheStatementPage($ifstatement);
	}


	$thenstatement =~ s/[^$okchars]/ /go;
	#system($^X, "createstatementpage.pl", @args);# || die "Could not open implh $!"; 
	CreateTheStatementPage($thenstatement);
	CreateTheTranPage($prinid);
}
