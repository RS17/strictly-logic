#!/usr/bin/perl
#then2.pm

package then2;

use Exporter;
use debugout;
#use CGI::Inspect;
use strict;
use warnings;
use sqlhandler;

use premise;
use linkfinder;
use transitive;
use conclusion;

our @ISA = qw(Exporter);
our @EXPORT = qw( then2_checkcreate );

########################### THEN-2 ########################################
# NOTE: this differs signficantly from original, which was weird and
# would enter unnecessary statements before they were necessary.  
# We should always wait for the building blocks to exist, we should 
# not enter them
#rule is if (A && B -> C) then if (A->B) then (A->C)
#this can be implemented as follows:
#if double if ( A&&B->C ):
#1a. Check if A->B exists
#2a. If yes, Enter A->C
#3a. enter the following into transitive table"
#	a. A&&B->C & A->B => A->C
#4a. Repeat steps 1-3, checking if A->C exists for step 1 instead.
#if single if->single then (A->B)
#1b. Check if statement of form (A&&B->C) (or B&&A->C) exists
#2b. If yes, enter A->C
#3b. enter the following into transitive table"
#	a. A&&B->C & A->B => A->C
#No need to repeat - 1b should check both directions
	
sub then2_checkcreate($$$)
{
	my $conclusionid = shift;
	my @ifs = @{(shift)};
	my @conclusions = @{(shift)};
	my @returnconcls;
	my $conclio = premise_getioshiftvalue($conclusions[0] );
	my %conclhash = premise_buildhashwshift( $conclio, 'C', 0 );
	my $ifio1 = premise_getioshiftvalue($ifs[0]);
	my %ifhash1 = premise_buildhashwshift( $ifio1, 'I', 0 );
	#a
	if( scalar(@ifs) eq 2 and scalar @conclusions eq 1 ) 										
	{
		my $ifio2 = premise_getioshiftvalue($ifs[1]);
		my %ifhash2 = premise_buildhashwshift( $ifio2, 'I', 0 );
		#1a
		my %ifhash2asthen = %ifhash2;
		$ifhash2asthen{'type'} = 'C';
		my @premstocheck = (\%ifhash1, \%ifhash2asthen );
		my $impliedthenconclid = conclusion::conclusion_checkifpremsexist( \@premstocheck );
		if( $impliedthenconclid ne "" )
		{
			#2a
			my @retprems = ( \%ifhash2, \%conclhash );
			my %rethash;
			$rethash{'premises'} = \@retprems;
			#3a
			my %transhash = transitive_buildhash( -1, $conclusionid, $impliedthenconclid);
			$rethash{'transhash'} = \%transhash;
			@returnconcls = ( @returnconcls, {%rethash} );
		}
		#4a
		my %ifhash1asthen = %ifhash1;
		$ifhash1asthen{'type'} = 'C';
		@premstocheck = (\%ifhash2, \%ifhash1asthen );
		$impliedthenconclid = conclusion::conclusion_checkifpremsexist( \@premstocheck );
		if( $impliedthenconclid ne "" )
		{
			my @retprems = ( \%ifhash1, \%conclhash );
			my %rethash;
			$rethash{'premises'} = \@retprems;
			my %transhash = transitive_buildhash( -1, $conclusionid, $impliedthenconclid);
			$rethash{'transhash'} = \%transhash;
			@returnconcls = ( @returnconcls, {%rethash} );
		}
	}
	elsif( scalar(@ifs) eq 1 and scalar @conclusions eq 1 ) 	
	{
		#1b
		my @impliedthens = linkfinder_findallsinglethensfromdoubleif( $ifio1, $conclio );
		foreach my $impliedthenref( @impliedthens )
		{
			#2b
			my %impliedthen = %{($impliedthenref)};
			my %impliedthenhash = premise_buildhashwshift( $impliedthen{'ioshiftvalueid'}, 'C', 0 );
			my @retprems = (\%ifhash1,  \%impliedthenhash );
			my %rethash;
			$rethash{'premises'} = \@retprems;
			#3b
			my %transhash = transitive_buildhash( -1, $conclusionid, $impliedthen{'conclusionid'});
			$rethash{'transhash'} = \%transhash;
			@returnconcls = ( @returnconcls, {%rethash} );
		}
	}
	return @returnconcls;
}
