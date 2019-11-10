#!/usr/bin/perl
#votehandler.pl

#NOTE: this program will keep track of all votes ever.  May need to be cut down if system gets too big.

use warnings;
use diagnostics;
use CGI::Pretty qw(:all);
use strict;
use CGI; 
use DBI;
use truthstatusupdater;
use principlesplitter;
use debugout;
use conclusion;
#use CGI::Inspect;

my $dbh=DBI->connect('dbi:mysql:surilega_postulates','surilega_webuser','silverpikul1');
#|| confess "Error opening database: $DBI::errstr\n";

my $cgi=new CGI;
my $vote = $cgi->param('vote');
my $conclid = $cgi->param('conclid');
my $table = 'conclusion';#$cgi->param('table');
my $sth;
my $ip = $ENV{"REMOTE_ADDR"};
my $back = $ENV{'HTTP_REFERER'};
my $time = time;
my @ipquarter;

print header();
print start_html (title=>"vote submitted");

#print "prin id is $prinid, time is $time";

#convert ip to single decimal number so can enter easier
my $i=3;
my $numip=0;
@ipquarter=split(/\./, $ip, 4);
foreach (@ipquarter){
	$numip=$numip+$_*256 ** $i; 
	$i=$i-1;
}


#check if ipvoted already in this principle.
my $cutofftime=$time-630000;#i.e. approx 1 week ago, 630000 seconds.  This should be randomized.
$sth=$dbh->prepare("SELECT count(*) FROM voteips WHERE ip=$numip AND prinid=? AND time>$cutofftime");
$sth->execute($conclid);
my $dqvotes = $sth->fetchrow_array;

#depending on where this is rel to the if dqvotes->die line, will record attempts or succesful votes.
#note that failed votes will reset timer.  This is deliberate.
$sth=$dbh->prepare("INSERT INTO voteips (prinid, ip, time) values (?, $numip, $time)");
$sth->execute($conclid);

if ($dqvotes >0){
	print "You have voted for this principle already.  Chill."; 
	exit; #don't confess or die, just want error.
}

if ($vote=~ /True/){
	$sth=$dbh->prepare("UPDATE $table SET truevotes=truevotes+1 WHERE id=?");#put db command in quotes;
	$sth->execute($conclid);
	$sth=$dbh->prepare("UPDATE $table SET totalvotes=totalvotes+1 WHERE id=?");#put db command in quotes;
	$sth->execute($conclid);
	#print "vote submitted true";
	$sth=$dbh->prepare("SELECT truevotes FROM $table WHERE id=?");#put db command in quotes;
	$sth->execute($conclid);
	my $truevotes = $sth->fetchrow_array;
	$sth=$dbh->prepare("SELECT totalvotes FROM $table WHERE id=?");#put db command in quotes;
	$sth->execute($conclid);
	my $totalvotes = $sth->fetchrow_array;
	if ($totalvotes>0 )
	{
		if( $truevotes/$totalvotes >= .5 )
		{
			$sth=$dbh->prepare("UPDATE $table SET votestatus='true' WHERE id=$conclid");#put db command in quotes;
			$sth->execute();
		}
	}
		
}
if ($vote=~ /False/){
	$sth=$dbh->prepare("UPDATE $table SET falsevotes=falsevotes+1 WHERE id=?");#put db command in quotes;
	$sth->execute($conclid);
	$sth=$dbh->prepare("UPDATE $table SET totalvotes=totalvotes+1 WHERE id=?");#put db command in quotes;
	$sth->execute($conclid);	
	#print "vote submitted false";
	$sth=$dbh->prepare("SELECT falsevotes FROM $table WHERE id=?");#put db command in quotes;
	$sth->execute($conclid);
	my $falsevotes = $sth->fetchrow_array;
	$sth=$dbh->prepare("SELECT totalvotes FROM $table WHERE id=?");#put db command in quotes;
	$sth->execute($conclid);
	my $totalvotes = $sth->fetchrow_array;
	if (($falsevotes/$totalvotes)>=.5 && $totalvotes>0){
		$sth=$dbh->prepare("UPDATE $table SET votestatus='false' WHERE id=?");#put db command in quotes;
		$sth->execute($conclid);
	}
		
}
if ($vote=~ /Unknown/){
	$sth=$dbh->prepare("UPDATE $table SET unknownvotes=unknownvotes+1 WHERE id=?");#put db command in quotes;
	$sth->execute($conclid);
	$sth=$dbh->prepare("UPDATE $table SET totalvotes=totalvotes+1 WHERE id=?");#put db command in quotes;
	$sth->execute($conclid);
	#print "vote submitted unknown";
	$sth=$dbh->prepare("SELECT unknownvotes FROM $table WHERE id=?");#put db command in quotes;
	$sth->execute($conclid);
	my $unknownvotes = $sth->fetchrow_array;
	$sth=$dbh->prepare("SELECT totalvotes FROM $table WHERE id=?");#put db command in quotes;
	$sth->execute($conclid);
	my $totalvotes = $sth->fetchrow_array;
	if (($totalvotes>0 && $unknownvotes/$totalvotes)>=.50 ){
		$sth=$dbh->prepare("UPDATE $table SET votestatus='unknown' WHERE id=?");#put db command in quotes;
		$sth->execute($conclid);
	}
		
}
print "Vote ($vote) has been submitted<br>";
$sth=$dbh->prepare("SELECT truevotes, falsevotes, unknownvotes, totalvotes FROM $table WHERE id=?");
$sth->execute($conclid);
my @result=$sth->fetchrow_array;
print "Total votes are:<br>";
print "True: @result[0]<br>";
print "False: @result[1]<br>";
print "Unknown: @result[2]<br>";
my @args ;
TSU($conclid);
#@args = (@args, $prinid);
#system($^X, "principlesplitter.pl", @args);
#copied from createprinciple - captures output from implicationhandler on updates.
@updates = (@updates, $conclid);
	#debugout("Added principle $laststatement to updates");
	my %seen;
	my @uniqupdates = grep { ! $seen{$_}++ } @updates; #It looks like this plays some role in figuring out what was updated so we know which pages to update
	#debugout( "updates is @updates, uniqupdateas is @uniqupdates"); 
foreach (@uniqupdates){
		#@args = ($_ =~ s/[^$okchars]/ /go);
		debugout("trying to call splitter");
		#$ENV{"PATH"} = "";
		conclusion_createsubpages($_);
		#system($^X, "principlesplitter.pl", @args) || confess $!; #this calls createstatementpage.pl for both if and then statements
		debugout( "got past splitter");
	}
print "<br>Go back to <a href=$back>previous page</a>";



print end_html;

$sth->finish ;
$dbh->disconnect ;


	
