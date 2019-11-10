#!/usr/bin/perl
#contrapositive.pm

package contrapositive;

use Exporter;
use debugout;
#use CGI::Inspect;
use strict;
use warnings;
use sqlhandler;

use premise;
use linkfinder;
use transitive;

use ioshiftvalue;
use stringutil;

our @ISA = qw(Exporter);
our @EXPORT = qw( contrapositive_checkcreate );

########################### CONTRAPOSITION #######################################
# (@1 -> ~@2) => (@2 -> ~@1).  And vice versa.
#Does for every rule, no need to see if conditions apply EXCEPT that statement does not already exist

#1 - checks if contraposition statement already exists
#2 - Enters in transitive 

sub contrapositive_checkcreate($$$)
{
	my $conclusionid = shift;

	my @ifs = @{(shift)};
	my @conclusions = @{(shift)} ;
	my @returnconcls;
	if( scalar( @ifs ) eq 1 and scalar( @conclusions eq 1 ) )  #see below for why
	{
 		#1
 		debugout("starting contraposition");
 		my $ifio = premise_getioshiftvalue($ifs[0]);
 		my $thenio = premise_getioshiftvalue( $conclusions[0] );
 		#create antiif
 		my %ifhash = ioshiftvalue_gethash( $ifio );
 		my $antiifio = ioshiftvalue_getcreate( $ifhash{'ioshiftid'}, 
											   value_flip( $ifhash{'value'} ) );
		#create antithen
		my %thenhash = ioshiftvalue_gethash( $thenio );
 		my $antithenio = ioshiftvalue_getcreate( $thenhash{'ioshiftid'}, 
												 value_flip( $thenhash{'value'} ) );
 		
 		#2
 		my %newifhash = premise_buildhashwshift( $antithenio, 'I', 0 );
 		my %newthenhash = premise_buildhashwshift( $antiifio, 'C', 0 );
		my @retprems = ( \%newifhash, \%newthenhash );
		my %rethash;
		$rethash{'premises'} = \@retprems;
		#build transhash and add to returnconcls
		my %transhash = transitive_buildhash( -1, $conclusionid, -1 );
		$rethash{'transhash'} = \%transhash;
		@returnconcls = ( @returnconcls, {%rethash} );
 		

	}
		#contraposition of doubleifs is not necessary or possible. Nothing useful can be determined because OR's are not in the system.
		#perhaps in the future where the system automatically converts ors to ands for human assistance, some sort of 
		#implementation should be here. 
	return @returnconcls;
}
