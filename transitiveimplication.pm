#!/usr/bin/perl
#transitiveimplication.pm

package transitiveimplication;

use Exporter;
use debugout;
#use CGI::Inspect;
use strict;
use warnings;
use sqlhandler;

use premise;
use linkfinder;
use transitive;
use transpremhash;
use ioshiftvar;
use ioshiftvalue;

our @ISA = qw(Exporter);
our @EXPORT = qw( transitiveimplication_checkcreate );

	########################################  TRANSITIVE ###################################################################
	# so:
	# 1. use ifstatement array and thenstatement determined above (these are the if and then from the main principle)
	# 2. TRANSITIVE: check if thenstatement ever appears as ifstatement by itself.
	# 3. TRANSITIVE: if it does, and new principle does not already exist, then do new principle with if statement group from first if, with then 
	# 	statement from second if(do not worry about if then appears with second statement as if - too 
	# 	remote to deal with here). 
	# 4. If created, enter into transitive database.
	# 5. TRANSITIVE: Now, check the if side of the new prin.  Check if ifstatement or ifstatements(ifstatementout) appears as conclusion in another statement.
	# 6. TRANSITIVE: If it does, make that statement's if(secondaryifs) and original statement's then a new prin.
	# 7. TRANSITIVE: Enter into transitive database if created.

	# If Double-if, should check both forward and reverse of if.  Use @splitif

	# TODO: check if thens appear in double if. This is necessary.  #2 already pulls candidates.
	# above steps  may no longer be accurate with numbers

sub transitiveimplication_checkcreate($$$)
{
	debugout("in transitive");
	my $conclusionid = shift;
	my @ifs = @{(shift)};
	my @conclusions = @{(shift)};
	my @returnconcls;
	my $ifio1;  #these are only used for double ifs
	my %ifhash1;
	my $ifio2;
	my %ifhash2;
	my $ifio;   #these are for single ifs
	my %ifhash;
	my @impliedifs;
	my @impliedthens;
	my @implieddoubleifs;
	my @firstdoublethenreturn;
	
	if( scalar(@ifs) eq 2 ) 										#handle double ifs
	{
		debugout("in eq 2");
		$ifio1 = premise_getioshiftvalue($ifs[0]);
		%ifhash1 = premise_buildhashwshift( $ifio1, 'I', 0 );
		$ifio2 = premise_getioshiftvalue($ifs[1]);
		%ifhash2 = premise_buildhashwshift( $ifio2, 'I', 1 );
		my @ifioarr = linkfinder_getalldoubleiostatementvalues( $ifio1, $ifio2 );
		foreach my $ifioarrref( @ifioarr )
		{
			debugout("in foreach");
			my @ifioarrrow = @{($ifioarrref)};
			my @impliedifresults = linkfinder_findallsingleifsfromdoublethen( $ifioarrrow[0], $ifioarrrow[1] );
			#shift values of the implied based on the originals.  
			#Remember, @impliedifresults is an array of single ifs.
			@impliedifresults = linkfinder_getshiftedioshiftvalsdouble( \@impliedifresults, $ifioarrrow[0], $ifioarrrow[1], $ifio1, $ifio2 );
			@impliedifs = ( @impliedifs, @impliedifresults );
			
		}
	}
	else 															#single if
	{
		$ifio = premise_getioshiftvalue($ifs[0]);
		%ifhash = premise_buildhashwshift( $ifio, 'I', 0 );
		my @ifiovals = linkfinder_getalliostatementvalues( $ifio ); #get all ioshiftvals with same iostatement and values
		foreach my $ifioval(@ifiovals)
		{
			my @impliedifresults = linkfinder_findallsingleifs( $ifioval );
			@impliedifs = (@impliedifs, linkfinder_getshiftedioshiftvals( \@impliedifresults, $ifioval, $ifio ) );
		#TODO - FIX DOUBLE-IF MATCHING HERE#
			@implieddoubleifs = ( @implieddoubleifs, linkfinder_findalldoubleifs( $ifioval ) );
		}
		debugout("ifiovals, @ifiovals, impliedifs, @impliedifs, @implieddoubleifs");
	}
	
	#double ifs also handled here
	my $isfirst = 1;
	foreach my $conclusion(@conclusions) #unlike conjunction, this *should* be able to run more than once
	{
		#2
		my $conclio = premise_getioshiftvalue($conclusion);
		my %conclhash = premise_buildhashwshift( $conclio, 'C', 0 );
		my @concliovals = linkfinder_getalliostatementvalues( $conclio ); #get all ioshiftvals with same iostatement and value
		foreach my $conclioval(@concliovals)
		{
			my @impliedthenresults = linkfinder_findallsinglethens( $conclioval );       #logic all happens here.
			@impliedthens = (@impliedthens, linkfinder_getshiftedioshiftvals( \@impliedthenresults, $conclioval, $conclio ) );
			
		}
		#3
		foreach my $impliedthenref( @impliedthens )
		{
			my %impliedthen = %{($impliedthenref)};
			my %impliedthenhash = premise_buildhashwshift( $impliedthen{'ioshiftvalueid'}, 'C', 0 );
			my @retprems;
			if( scalar(@ifs) eq 2 ) 										#handle double ifs
			{
				@retprems = ( \%ifhash1, \%ifhash2, \%impliedthenhash );
			}
			else 															#single if
			{
				@retprems = ( \%ifhash, \%impliedthenhash );
			}
			#4
			my %rethash;
			$rethash{'premises'} = \@retprems;
			#build transhash and add to returnconcls
			my %transhash = transitive_buildhash( -1, $conclusionid, $impliedthen{'conclusionid'} );
			$rethash{'transhash'} = \%transhash;
			@returnconcls = ( @returnconcls, {%rethash} );
		}
	
		#NOTE: Handle ifs for each conclusion separatelly if multiple.  
		#Conjunction rule should ensure that principles using them 
		#together as ifs will know that implications to them separately 
		#will be reflected for the combo.
		
		#5
	
		#implied single ifs (ifs that lead to the conclusion that is an if in this statement)
		foreach my $impliedifref( @impliedifs )
		{
			my %impliedif = %{($impliedifref)};		
			my %impliedifhash= premise_buildhashwshift( $impliedif{'ioshiftvalueid'}, 'I', 0 );
			
			my @retprems = ( \%impliedifhash, \%conclhash );
			#4
			my %rethash;
			$rethash{'premises'} = \@retprems;
			#build transhash and add to returnconcls
			my %transhash = transitive_buildhash( -1, $impliedif{'conclusionid'}, $conclusionid );
			$rethash{'transhash'} = \%transhash;
			@returnconcls = ( @returnconcls, {%rethash} );
		}
		
		#implied double ifs
		foreach my $implieddoubleifref( @implieddoubleifs ) #remember - each result here is a 2-element array of ifs
		{
			my @implieddoubleif = @{($implieddoubleifref)};
			my %impliedif1 = %{($implieddoubleif[0])};
			my %impliedif2 = %{($implieddoubleif[1])};
			my %impliedifhash1= premise_buildhashwshift( $impliedif1{'ioshiftvalueid'}, 'I', 0 );
			my %impliedifhash2= premise_buildhashwshift( $impliedif2{'ioshiftvalueid'}, 'I', 1 );
			my @retprems = ( \%impliedifhash1, \%impliedifhash2, \%conclhash );
			#4
			my %rethash;
			$rethash{'premises'} = \@retprems;
			#build transhash and add to returnconcls
			my %transhash = transitive_buildhash( -1, $impliedif1{'conclusionid'}, $conclusionid ); #impliedif1 and 2 should have same conclusionid
			$rethash{'transhash'} = \%transhash;
			@returnconcls = ( @returnconcls, {%rethash} );				
			
		}
		
		#handle double thens - a bit of a ex post-facto hack - ensure return concls in both statements
		if( scalar(@conclusions) eq 2 ) #also sorry for using "conclusions" when I mean "thens"
		{
			debugout("In double conclusions $isfirst, scalar(@returnconcls), scalar( @firstdoublethenreturn )");
			if( $isfirst eq 1 ) #if first conclusion, put in @firstdoublethenreturn and reset @returnconcls
			{
				
				@firstdoublethenreturn = @returnconcls;
				$isfirst = 0;
			}
			else
			{
				@returnconcls = transpremhash_returnmatches( \@returnconcls, \@firstdoublethenreturn );
			}
				
		}
		
	}
	
	return @returnconcls;
}
