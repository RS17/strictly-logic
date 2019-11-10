#!/usr/bin/perl
#conjunction.pm

package conjunction;

use stringutil;
use Exporter;
use debugout;
use strict;
use warnings;
use sqlhandler;
#use CGI::Inspect;
use linkfinder;
use premise;
use transitive;
use conclusion;


our @ISA = qw(Exporter);
our @EXPORT = qw( conjunction_checkcreate );

########################## SPECIAL RULE OF CONJUNCTION ###############################
	# NOTE: see double-ifs in transitive, this may help.  This rule does not
	# just create conjunctions willy-nilly - it needs the conjunction be useful.
	#
	# This is a rule that will allow an implication in the following circumstance:
	# 1. B&&C->D
	# 2. A->B
	# 3. A->C 
	# thus A->D
	# To do this, need to have principle in the form A->B&&C.  This is because the transitive table must have 
	# At most two principles and one conclusion, so it cannot use three principles at once.  
	# This is in keeping with the atomistic design of the logic portion.  So 2+3 must be combined to 1.  
	# Do as follows:
	# 0a. if single if:
	# 1a. Detect all statements where Conclusion (B) conjoined with another conclusion (C) in a type 1 double if statement to get a second conclusion (D). - do this because otherwise would be burdensome number of combinations, only ones with double ifs need this.
	# 2a. See if statements with same if (A) with (C) as conclusion.  
	# 3a. If found, Create new double-then prin A->B&&C
	# 4a. Create in transitive as if A->B, and if A->C, then A->B&&C (new prin)
	# --------
	# 0b. If doubleif: 
	# 1b. Split if and detect all statements where same if has both ifs as conclusion.
	# 2b. If found,  Create new prin A->B&&C
	# 3b. Create in transitive as if A->B, and if A->C, then A->B&&C (new prin)
	
	#For now, double thens are ONLY useful for entering transitives.  All other rules should ignore statements with double thens (including this)
#########################################################################################################

sub conjunction_checkcreate($$$)
{
	#can be optimized?  Many calls to premise table, but maybe index makes it similar to small list?
	my $conclusionid = shift;
	
	my @ifs = @{(shift)};
	my @thens = @{(shift)} ;
	my @returnconcls;
	#double ifs to be handled later, double thens don't need fixin' (this is what creates the double then)
	if( scalar( @ifs ) eq 1 and scalar( @thens eq 1 ) ) 
 	{
		my $if = $ifs[0];
		foreach my $then(@thens) #if this loop runs more than once, that's bad
		{
			#1a and 1b
			my $ifio = premise_getioshiftvalue($if);
			my $thenio = premise_getioshiftvalue($then);
			my @codoubleifs = linkfinder_findpartnerlinkfromif( $thenio, $ifio );
			
			foreach my $codoubleifref(@codoubleifs)
			{
			#3a
				#create new with if and doubleif as conclusion
				my %rethash;
				my %codoubleif = %{($codoubleifref)};
				my %ifhash = premise_buildhashwshift( $ifio, 'I', 0 );
				my %codoubleifhash = premise_buildhashwshift( $codoubleif{'ioshiftvalueid'}, 'C', 0 );
				my %theniohash = premise_buildhashwshift( $thenio, 'C', 1 ); 
				my @retprems = ( \%ifhash, \%codoubleifhash, \%theniohash );
				$rethash{'premises'} = \@retprems;
				my %transhash = transitive_buildhash( -1, $codoubleif{'conclusionid'}, $conclusionid );
				$rethash{'transhash'} = \%transhash;
				@returnconcls = ( @returnconcls, {%rethash} );

			#4a - done in calling function
			}
		}
		
	}
	
	# handle double ifs here #Works with shift 4/8/17
	# 1b - get common if of ifs (so 1 statement implies both ifs in other conclusions).  For shift, it searches by iostatement when seeking implying ifs.
	# 2b - for each of the common if pairs, get the thens.  Use this to check for a "valid splice" - so for different variables, must be the same difference between if and then.
	# 3b - enter the conclusion.
	elsif ( scalar( @ifs ) eq 2 )
	{
		#1b
		my $ifio1 = premise_getioshiftvalue($ifs[0]);
		my $ifio2 = premise_getioshiftvalue($ifs[1]);
		my @commonifs = linkfinder_findcommonif( $ifio1, $ifio2 );
		#each common if is a combo of the 2 conclusions, with the ioshiftval from the if
		#2b
		foreach my $commonifref(@commonifs)
		{
			#get then premise from each conclusion
			my @commonifarr = @{($commonifref)};
			my %commonif1 = %{($commonifarr[0])};
			my %commonif2 = %{($commonifarr[1])};
			my @prems1 = conclusion::conclusion_getpremisesonly($commonif1{'conclusionid'});
			my @prems2 = conclusion::conclusion_getpremisesonly($commonif2{'conclusionid'});
			my %then1 = premise_gethash(@prems1[1]);
			my %then2 = premise_gethash(@prems2[1]); 

			#to avoid false conjuctions, only allow creation if the ifs 
			#have the same shift from the orig
		
			if( linkfinder_isvalidsplice( $then1{'ioshiftvalue_id'}, $then2{'ioshiftvalue_id'}, $ifio1, $ifio2 ) )
			{
				my %commonifhash = premise_buildhashwshift( $commonif1{'ioshiftvalueid'}, 'I', 0 );
				my %if1hash = premise_buildhashwshift( $ifio1, 'C', 0 );
				my %if2hash = premise_buildhashwshift( $ifio2, 'C', 1 );
				#3b
				my %transhash = transitive_buildhash( -1, $commonif1{'conclusionid'}, $commonif2{'conclusionid'} );
				my @retprems = ( \%commonifhash, \%if1hash, \%if2hash );
				my %rethash; 
				$rethash{'premises'} = \@retprems;
				$rethash{'transhash'} = \%transhash;
				@returnconcls = ( @returnconcls, {%rethash} );
			}
		}
		
		
	}
	return @returnconcls;

}
