#!/usr/bin/perl
#transitive.pm

package transitive;

use stringutil;
use Exporter;
use debugout;
#use CGI::Inspect;
use strict;
use warnings;
use sqlhandler;
use dependency;

our @ISA = qw(Exporter);
our @EXPORT = qw( transitive_create transitive_createhash transitive_buildhash );

sub transitive_create($$$)
{
	my $conclid = shift;
	my $dependency1 = shift;
	my $dependency2 = shift; 
	#TODO: check if it exists before create;
	my $sql = "INSERT INTO transitive (conclusion) VALUES ($conclid);";
	my $transid = returnid( $sql );
	dependency_create( $transid, 0, $dependency1 );
	if( $dependency2 != -1 )
	{
		dependency_create( $transid, 1, $dependency2 );
	}
	return $transid;
}


sub transitive_createhash($)
{
	my %hash = %{(shift)};
	return transitive_create( $hash{'transitiveconcl'}, $hash{'dependency1'}, $hash{'dependency2'} );
}

sub transitive_buildhash($$$)
{

	my %hash;
	$hash{'transitiveconcl'} = shift;
	$hash{'dependency1'} = shift;
	$hash{'dependency2'} = shift;
	return %hash;
}

