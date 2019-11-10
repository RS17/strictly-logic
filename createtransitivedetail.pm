#!/usr/bin/perl
#createtransitivedetail.pm
package createtransitivedetail;
use warnings;
use lib './'; #need for taint mode
use implicationhandler;
#use diagnostics;
use CGI::Pretty qw(:all);
use strict;
use CGI; 
use DBI;
use Graph::Easy;
use Carp;
use getenglish;
use sqlhandler;

	my $transitivedepth;
	my %prinidlist;

our @ISA = qw(Exporter);
our @EXPORT = qw(CreateTheTranPage);

# Takes principle, creates transitive map (shows all principles from which 
# it is implied, and how those are implied, and so on) for principle.  
# Recursively calls self for every sub-principle.

# NOTE: This isn't being called anywhere but it seems useful so I'm keeping it?
sub CreateTheTranPage($){


	my $prinid = (shift);
		print "got to createtransitivedetail with prinid $prinid";
	my $filename = "connection$prinid";
	print "<br>Page updated for <a href=/$filename.html>principle $prinid</a>";
	#want below to all go on single page.  Maybe for efficiency can make 
	#sub pages that can be plugged in as html segments in the future, but 
	# following KISS for now.

	open (TRANSITIVEPAGE, ">../$filename.html") or confess $!;
	print TRANSITIVEPAGE "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>";

	print TRANSITIVEPAGE start_html ;
	print "<title/>Title will go here at some point</title>";
	print TRANSITIVEPAGE "Title<br><br>";
	CreateTheTranSubPage($prinid);
	undef %prinidlist; #need to do this because somehow its maintaining this across instances.
		print TRANSITIVEPAGE end_html;
	close (TRANSITIVEPAGE);

}

sub CreateTheTranSubPage($){
	my $cgi=new CGI;
	my $prinid=(shift);
	if (exists($prinidlist{$prinid})){ #avoid unstoppable loop due to contrapositive

		return;
	}
	$prinidlist{$prinid} = 1;
	my $resultprins;
	my $sth;
	#my @resultprins;

	my $dbh=returndbh();
	#my @prinid ;
	#my $statement;
	#my @objects;
	#my $count;
	#my $ifstatement;
	#my $ifhyperlink;
	#my $thenstatement;
	#my $thenhyperlink;
	#my @ifstatements;
	#my @principledata;

	############################ Update Calling Page ######################
		
	#my $sth = $dbh->prepare("select description from iostatements where id=$statementid");
	#$sth->execute() || die "Couldn't execute query: $DBI::errstr\n";
	#my $prinid = $sth->fetchrow_array;



	############################ Update Statement Page ########################
	#my $graph=Graph::Easy->new();
	
	############################ Substatements ########################
	my $depthstring = "  |" x $transitivedepth;
	print TRANSITIVEPAGE "<br>$depthstring";  
	print TRANSITIVEPAGE getenglishfromprin($prinid);
	################### Uniprins #############################
	print "prinid is $prinid";
	$sth = $dbh->prepare("select firstprin, secondprin, resultprin from transitive where resultprin = $prinid;");
	$sth->execute() || confess "Couldn't execute query: $DBI::errstr\n";
	my (@firstprins, @secondprins);
	#my $ref = 0;
	my @row = $sth->fetchrow_array;
	print TRANSITIVEPAGE "<br>$depthstring ______________________________________________"; #separates related principles
	$transitivedepth++;
	my $depthstring = "  |" x $transitivedepth;
	unless ($row[0] == 0){
		CreateTheTranSubPage($row[0]);
	}
	unless ($row[1] == 0){
		CreateTheTranSubPage($row[1]);
	}
	#$firstprins[$ref] = $row[0];
	#$secondprins[$ref] = $row[1];
	#$resultprins[$ref] = $row[2];
	#$ref=$ref+1;
	$transitivedepth--;
	
	
	 #  }

	#$ref = -1;
	#for($ref = -1, $ref<scalar(@firstprins), $ref++){ #I don't know why this for loop has to be different from every other fucking for loop I've ever run.  Ref should start at 0.  Why is it increasing?
	#	#my $startinghyperlink= "<a href=principle$_.html>$_</a>";
	#	$graph->add_edge ("<a href = /principle$firstprins[$ref].html>$firstprins[$ref]</a> and <a href= /principle$secondprins[$ref].html>$secondprins[$ref].html</a>", "<a href= /principle$resultprins[$ref].html>$resultprins[$ref]</a>");

	#}

	########################## PRINT GRAPH #################################
	#print TRANSITIVEPAGE "<style type='text/css'>";
	#print TRANSITIVEPAGE $graph->css();
	#print TRANSITIVEPAGE "</style>";
	#print TRANSITIVEPAGE $graph->as_ascii_html( );#need this for links to work, apparently
	#print TRANSITIVEPAGE $graph->as_html( );
		$sth->finish ;
	$dbh->disconnect ;
}


