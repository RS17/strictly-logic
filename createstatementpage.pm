#!/usr/bin/perl 
#createstatementpage.pm

package createstatementpage;
use warnings;

use CGI::Pretty qw(:all);
use strict;
use CGI; 
use DBI;
#use Graph::Easy;
use Carp;
use implicationhandler;
use sqlhandler;
use debugout;
use getenglish;
use conclusion;
use premise;
use iostatement;

our @ISA = qw(Exporter);
our @EXPORT = qw(CreateTheStatementPage);


# goal is to output webpage (or webpage edits) for each object.
# should have two modes: 1) create new object page 2) edit page for 
# existing object.  Creates new object page when new object created.
# Should list statements applied to, and how - e.g. by direct application
# or by implications.

# This program requires the following as inputs from CGI:
# - objectid
# - objectname
# - whether new or existing (if passes new param, is new)
# - any changes made

# if new object, create a new html page.  This will just create the page,
# not enter in any data.  That will happen with the "edit" section, which
# is run after the program is created, as well as when future changes made.

sub CreateTheStatementPage($){

my $cgi=new CGI;
my $premiseid=(shift);

my $dbh=returndbh();
my $statement;
my @objects;
my $count;
my $ifstatement;
my $ifhyperlink;
my $thenstatement;
my $thenhyperlink;
my @ifstatements;
my @principledata;
my $currprinid;
my $sqlcmd;
my $sth ;
	my $statementname;
	my $graph;
	my $filename;
	
############################ Update Calling Page ######################
my $iostatement = premise_getiostatementid($premiseid);
if ($iostatement =~ / /){  #ands create problems, these will have spaces in them.
	return;
}

$statementname = getenglish::getenglishfromiforthen2($premiseid); #for some reason need getenglish:: here?
#$graph=Graph::Easy->new();
$filename = "prin$iostatement";
print "<br>Page updated for <a href=/$filename.html>$statementname</a>";

############################ Update Statement Page ########################
open (STATEMENTPAGE, ">../$filename.html") or confess $!;

print STATEMENTPAGE "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>";

print STATEMENTPAGE start_html 
print "<title/>$statementname</title>";
print STATEMENTPAGE "$statementname<br><br>";
my @conclmatches = iostatement::iostatement_getconclusions($iostatement);

foreach my $conclid(@conclmatches){

	$sth = $dbh->prepare("select impliedstatus, votestatus from conclusion where id=$conclid;"); 
	$sth->execute() || confess "Couldn't execute query: $DBI::errstr\n";
	@principledata= $sth->fetchrow_array;
	if ( conclusion::conclusion_isdoublethen($conclid) ){
		next; 	#don't want double thens to show up
	}


		##################### VOTING FUNCTION ##########################
		#$_ = ID of statement application
		print STATEMENTPAGE "<form action='cgi-bin/votehandler.pl' method='post'>";
		if( $debugmode eq 1 )
		{
			print(STATEMENTPAGE "<br>**************<br>conclid: $conclid");
		}
		print STATEMENTPAGE "<br><br>It is implied @principledata[0] and voted @principledata[1] that  ";
		print STATEMENTPAGE getenglish::getenglishfromconcl($conclid); print STATEMENTPAGE "<br>"; #why the fuck does use not work?
		my $laststatement=$ifstatements[-1];

		#print STATEMENTPAGE "then $thenstatement<br>"; #this will refer to an application withobjectname in it.
		print STATEMENTPAGE "<input type='radio' name='vote' value='True'> Vote as true <br>";  
		print STATEMENTPAGE "<input type='radio' name='vote' value='False'> Vote as false <br>"; 
		print STATEMENTPAGE "<input type='radio' name='vote' value='Unknown'> Vote as unknown <br>";  
		print STATEMENTPAGE "<input type='hidden' name='conclid' value='$conclid'>";
		print STATEMENTPAGE "<input type='submit' value='Submit'/>";
		print STATEMENTPAGE "</form>";
		
}
########################## PRINT GRAPH #################################
########################## PRINT GRAPH #################################
#print STATEMENTPAGE "<style type='text/css'>";
#print STATEMENTPAGE $graph->css();
#print STATEMENTPAGE "</style>";
#print STATEMENTPAGE $graph->as_ascii_html( );#need this for links to work, apparently
# going to skip graph until it can work.

print STATEMENTPAGE end_html;
close (STATEMENTPAGE);
$sth->finish ;
$dbh->disconnect ;


}
