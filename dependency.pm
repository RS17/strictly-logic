#!/usr/bin/perl
#dependency.pm

package dependency;

use stringutil;
use Exporter;
use debugout;
#use CGI::Inspect;
use strict;
use warnings;
use sqlhandler;
use stringutil;

our @ISA = qw(Exporter);
our @EXPORT = qw( dependency_create dependency_createhash dependency_buildhash );

sub dependency_create($$$)
{
	my $transitiveid = unquote( shift );
	my $position = unquote( shift );
	my $conclid = unquote( shift );
	my $sql = "INSERT INTO dependency (transitive_id, transitive_pos, conclusion_id) VALUES ($transitiveid, $position, $conclid );";
	my $id = returnid($sql);
}


