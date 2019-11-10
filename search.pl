#!/usr/bin/perl
#search.pl
use warnings;
#use diagnostics;
use strict;
#use LWP::Simple;
use Carp;
use CGI::Pretty qw(:all);
use CGI;
use lib './'; #need for taint mode
use implicationhandler;
use sqlhandler;
#use CGI::Inspect;

print header();
print start_html (title=>"Create if-then.");

my $cgi = new CGI;
my $okchars='-a-zA-Z0-9_@~&';
my $statementtofind = $cgi->param('statementtosearch');
$statementtofind =~s/[^$okchars]/ /go;

my $sqlcmd = "SELECT id, description FROM iostatements WHERE (description) like ? or MATCH (description) AGAINST (? with query expansion)";

my %searchresults = returnhash_secure2($sqlcmd, $statementtofind, $statementtofind);

if (scalar(keys(%searchresults)) != 0){
	for my $id(keys %searchresults){
		print "$searchresults{$id}<a href=/prin$id.html> [page]</a><br>";  
	}
}else{
	print "no results";
}
print end_html;

#
