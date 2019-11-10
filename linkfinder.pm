#!/usr/bin/perl
use cPanelUserConfig;
#linkfinder.pm

# 10/27/2019 - this is a utility package for finding links between different
# statements.  Which is important in implication finding.

package linkfinder;

use Exporter;
use debugout;
use strict;
use warnings;
use sqlhandler;
#use CGI::Inspect;
use List::MoreUtils qw(uniq);
use premise;
use ioshiftvar;
use ioshiftvalue;
use logichelper;

our @ISA = qw(Exporter);
our @EXPORT = qw( linkfinder_findpartnerlink linkfinder_findallsinglethensfromdoubleif 
				linkfinder_findcoifs linkfinder_findcothens 
				linkfinder_findallsingleifs linkfinder_findallsinglethens
				linkfinder_findallcodoubleifs linkfinder_findpartnerlinkfromif
				linkfinder_findcommonif linkfinder_findalldoubleifs 
				linkfinder_findallsingleifsfromdoublethen linkfinder_returnioshiftmatchesboth
				linkfinder_getalliostatementvalues linkfinder_getshiftedioshiftvals
				linkfinder_getalldoubleiostatementvalues linkfinder_getshiftedioshiftvalsdouble
				linkfinder_findallsingleifswithiostatement linkfinder_isvalidsplice
				linkfinder_findallsinglethens_openif);


sub linkfinder_findcommonif($$)
{
	#	 		  /->$inputprem1
	#  @commonifs- 				   
	#	          \->$inputprem2
	# returns array of @commonifs that include both if statements that lead to thens separately
	
	my $inputpremioshift1 = shift;
	my $inputpremioshift2 = shift;
	my @prem1singleifs = linkfinder_findallsingleifswithiostatement( $inputpremioshift1 );
	my @prem2singleifs = linkfinder_findallsingleifswithiostatement( $inputpremioshift2 );
	my @commonifs = linkfinder_returnioshiftmatchesboth( \@prem1singleifs, \@prem2singleifs );
}

sub linkfinder_findpartnerlinkfromif($$)
{
	# Note: I don't think this needs fixing for transferability - finding by 
	# ioshiftval should be fine because if vars are different not a true match?
	#	                /->$inputioshift--\
	#  $inputifioshift -    				->$inputifthen  #partnerlink is a co-if that is also a co-then
	#	                \->$partnerlink --/
	my $inputioshiftvalue = shift;
	my $inputifioshiftvalue = shift;
	my @coifs = linkfinder_findallcodoubleifs($inputioshiftvalue);
	my @inputifthens = linkfinder_findallsinglethens($inputifioshiftvalue);
	my @partnerlinks = linkfinder_returnioshiftmatches( \@coifs, \@inputifthens );
	my @output;
	
	# avoid returning same value we started with - don't want to create A -> B && B
	foreach my $partnerlink (@partnerlinks){
		if( $partnerlink->{"ioshiftvalueid"} != $inputioshiftvalue){
			@output = (@output, $partnerlink);
		}
	}
	return @output;#premises to be linked as a double conclusion with conclprem;
}


sub linkfinder_findcothens($)
{
	#	  /->$inputprem
	#   A-			     #need to find results of if that has common iostatement for vars
	#	  \->$cothen
	# need to get:
	# 1. Conclusion-ioshift
	# 2. that follow from a single if-premise
	#    a, which uses the same iostatement as the if-premise the input follows from
 	#    b. and has the same varincrements as the input's if-premise
 	
 	# so first step is get all the if-premises that lead to the $inputprem:
 	my $inputioshiftvalue = shift;
 	my @ifioshifts = linkfinder_findallsingleifs($inputioshiftvalue);
 	
 	# now find all single conclusions stemming from that if that are not the $inputprem
 	my @cothens;
 	
 	#Need to use premise_getfromiovarshift (when it's finished)
 	foreach my $ifioshiftvalue( @ifioshifts )
 	{
		my %ifioshift = %{($ifioshiftvalue)};
		my @returnthens = linkfinder_findallsinglethens($ifioshift{'ioshiftvalueid'});
		@cothens = (@cothens, @returnthens );
	}
	@cothens = uniq @cothens;
	@cothens = grep { $_[0] != $inputioshiftvalue }@cothens;  #CAN BE OPTIMIZED

	return @cothens;
}

sub linkfinder_findallsingleifs($)
{
	# $ifpremise -> $inputioshift (inputio is single)
	my $inputioshiftvalue = shift;
	my $sql	= "select DISTINCT p2.ioshiftvalue_id, p2.conclusion_id from premise p1 inner join premise p2 on p1.conclusion_id = p2.conclusion_id left join premise p3 on p2.conclusion_id = p3.conclusion_id and p3.id <> p2.id and p3.type = p2.type left join premise p4 on p1.conclusion_id = p4.conclusion_id and p1.id <> p4.id and p1.type = p4.type where p1.type = 'C' and p2.type='I' and p1.ioshiftvalue_id = $inputioshiftvalue and p3.id IS NULL and p4.id IS NULL;";
	my @ifresults = arrayofresults2($sql);
	my @arr = twocolarrtoioconclhash( \@ifresults );
	return @arr;
}


sub linkfinder_findallsingleifswithiostatement($)
{
	# $ifpremise -> $inputioshift (inputio is single)
	my $inputioshiftvalue = shift;
	my $sql	= "select DISTINCT p2.ioshiftvalue_id, p2.conclusion_id from ioshiftvalue ioshv1 inner join ioshift ios1 on ios1.id = ioshv1.ioshift_id	inner join ioshift ios2 on ios2.iostatement_id = ios1.iostatement_id inner join ioshiftvalue ioshv2 on ioshv2.ioshift_id = ios2.id and ioshv2.value = ioshv1.value inner join premise p1 on p1.ioshiftvalue_id = ioshv2.id inner join premise p2 on p1.conclusion_id = p2.conclusion_id left join premise p3 on p2.conclusion_id = p3.conclusion_id and p3.id <> p2.id and p3.type = p2.type left join premise p4 on p1.conclusion_id = p4.conclusion_id and p1.id <> p4.id and p1.type = p4.type where p1.type = 'C' and p2.type='I' and ioshv1.id = $inputioshiftvalue and p3.id IS NULL and p4.id IS NULL;";
	my @ifresults = arrayofresults2($sql);
	my @arr = twocolarrtoioconclhash( \@ifresults );
	return @arr;
}

sub linkfinder_findalldoubleifs($)
{
	#TODO: USED BUT PROBABLY INSUFFICIENT FOR TRANSFERABILITY BECAUSE MATCHES ON IOSHIFTVALUE 
	# $ifresult1 && $ifresult2 -> $inputioshift  (inputio is single)
	my $inputioshiftvalue = shift;
	my $sql	= "select DISTINCT p2.ioshiftvalue_id, p2.conclusion_id, p3.ioshiftvalue_id, p3.conclusion_id from premise p1 inner join premise p2 on p1.conclusion_id = p2.conclusion_id left join premise p3 on p2.conclusion_id = p3.conclusion_id and p3.id <> p2.id and p3.type = p2.type left join premise p4 on p1.conclusion_id = p4.conclusion_id and p1.id <> p4.id and p1.type = p4.type where p1.type = 'C' and p1.position = 0 and p2.type='I' and p1.ioshiftvalue_id = $inputioshiftvalue and NOT p3.id IS NULL and p3.position = 1 AND p4.id IS NULL;";
	my @ifresults = arrayofresults2($sql);
	my @arr = fourcolarrtoioconclhash( \@ifresults );
	return @arr;
}

sub linkfinder_findallsinglethens($)
{
	# $inputprem (single only) -> $thenpremise (single only) #note that this is the same as findallsingleifs with I and C changed
	my $inputioshiftvalue = shift;
	my $sql	= "select DISTINCT p2.ioshiftvalue_id, p2.conclusion_id from premise p1 inner join premise p2 on p1.conclusion_id = p2.conclusion_id left join premise p3 on p2.conclusion_id = p3.conclusion_id and p3.id <> p2.id and p3.type = p2.type left join premise p4 on p1.conclusion_id = p4.conclusion_id and p1.id <> p4.id and p1.type = p4.type where p1.type = 'I' and p2.type='C' and p1.ioshiftvalue_id = $inputioshiftvalue and p3.id IS NULL and p4.id IS NULL;";
	my @thenresults = arrayofresults2($sql);
	my @arr = twocolarrtoioconclhash( \@thenresults );
	return @arr;
}

sub linkfinder_findallsinglethens_openif($)
{
	# $inputprem (include double) -> $thenpremise (single only) 
	my $inputioshiftvalue = shift;
	my $sql	= "select DISTINCT p2.ioshiftvalue_id, p2.conclusion_id from premise p1 inner join premise p2 on p1.conclusion_id = p2.conclusion_id left join premise p3 on p2.conclusion_id = p3.conclusion_id and p3.id <> p2.id and p3.type = p2.type left join premise p4 on p1.conclusion_id = p4.conclusion_id and p1.id <> p4.id and p1.type = p4.type where p1.type = 'I' and p2.type='C' and p1.ioshiftvalue_id = $inputioshiftvalue and p3.id IS NULL;";
	my @thenresults = arrayofresults2($sql);
	my @arr = twocolarrtoioconclhash( \@thenresults );
	return @arr;
}


sub linkfinder_findalldoubleifsfromdoublethen($$)
{
	#CREATED but NOT TESTED or used yet.
	# $ifpremise1 && $ifpremise2 -> $inputioshiftvalue1 && inputioshiftvalue2  (inputio is single)
	my $inputioshiftvalue1 = shift;
	my $inputioshiftvalue2 = shift;
	my $sql	= "select DISTINCT p2.ioshiftvalue_id, p2.conclusion_id, p3.ioshiftvalue_id, p3.conclusion_id from premise p1 inner join premise p2 on p1.conclusion_id = p2.conclusion_id left join premise p3 on p2.conclusion_id = p3.conclusion_id and p3.id <> p2.id and p3.type = p2.type left join premise p4 on p1.conclusion_id = p4.conclusion_id and p1.id <> p4.id and p1.type = p4.type where p1.type = 'I' and p1.position = 0 and p2.type='C' and p1.ioshiftvalue_id = $inputioshiftvalue1 and NOT p3.id IS NULL and p3.position = 1 AND p4.ioshiftvalue_id = $inputioshiftvalue2;";
	my @ifresults = arrayofresults2($sql);
	my @arr = fourcolarrtoioconclhash( \@ifresults );
	return @arr;
}

sub linkfinder_findallsingleifsfromdoublethen($$)
{
	# $ifpremise1 -> $inputioshiftvalue1 && inputioshiftvalue2  (inputio is single)
	my $inputioshiftvalue1 = shift;
	my $inputioshiftvalue2 = shift;
	my $sql	= "select DISTINCT p2.ioshiftvalue_id, p2.conclusion_id from premise p1 inner join premise p2 on p1.conclusion_id = p2.conclusion_id left join premise p3 on p2.conclusion_id = p3.conclusion_id and p3.id <> p2.id and p3.type = p2.type left join premise p4 on p1.conclusion_id = p4.conclusion_id and p1.id <> p4.id and p1.type = p4.type where p1.type = 'C' and p1.position = 0 and p2.type='I' and p1.ioshiftvalue_id = $inputioshiftvalue1 and p3.id IS NULL AND p4.ioshiftvalue_id = $inputioshiftvalue2;";
	my @ifresults = arrayofresults2($sql);
	my @arr = twocolarrtoioconclhash( \@ifresults );
	return @arr;
}

sub linkfinder_findallsinglethensfromdoubleif($$)
{
	# $inputprem && otherprem -> $thenpremise  #I don't think we use this
	my $inputioshiftvalue1 = shift;
	my $inputioshiftvalue2 = shift;
	#my $sql = "select p2.iostatement_id, v2.iovar_id, v2.shift from premise p1 join conclusion c on p1.conclusion_id = c.id join premise p2 on p2.conclusion_id = c.id join premisevar v2 on v2.premise_id = p2.id LEFT JOIN premise p3 on p3.conclusion_id = p1.conclusion_id and p3.type = p1.type and NOT p1.id = p3.id where p1.type = 'I' and p2.type = 'C' and p1.id = $inputprem and p3.id IS NULL order by p2.iostatement_id;";
	my $sql	= "select DISTINCT p2.ioshiftvalue_id, p2.conclusion_id from premise p1 inner join premise p2 on p1.conclusion_id = p2.conclusion_id left join premise p3 on p2.conclusion_id = p3.conclusion_id and p3.id <> p2.id and p3.type = p2.type inner join premise p4 on p1.conclusion_id = p4.conclusion_id and p1.id <> p4.id and p1.type = p4.type where p1.type = 'I' and p2.type='C' and p1.ioshiftvalue_id = $inputioshiftvalue1 and p4.ioshiftvalue_id = $inputioshiftvalue2 and p3.id IS NULL;";
	my @ifresults = arrayofresults2($sql);
	my @arr = twocolarrtoioconclhash( \@ifresults );
	return @arr;
}

sub linkfinder_findallcodoubleifs($)
{
	# $inputprem && $coifresult -> otherprem 
	# searches on iostatement.
	my $inputioshiftvalue = shift;
	my $sql	= "select DISTINCT p4.ioshiftvalue_id, p4.conclusion_id from ioshiftvalue ioshv1 inner join ioshift ios1 on ios1.id = ioshv1.ioshift_id	inner join ioshift ios2 on ios2.iostatement_id = ios1.iostatement_id inner join ioshiftvalue ioshv2 on ioshv2.ioshift_id = ios2.id and ioshv2.value = ioshv1.value inner join premise p1 on p1.ioshiftvalue_id = ioshv2.id inner join premise p2 on p1.conclusion_id = p2.conclusion_id left join premise p3 on p2.conclusion_id = p3.conclusion_id and p3.id <> p2.id and p3.type = p2.type inner join premise p4 on p1.conclusion_id = p4.conclusion_id and p1.id <> p4.id and p1.type = p4.type where p1.type = 'I' and p2.type='C' and ioshv1.id = $inputioshiftvalue and p3.id IS NULL";
	my @coifresults = arrayofresults2($sql);
	# shift the second ifs according to the original, based on the version of $inputioshiftvalue used in the double if
	my @shiftedresults;
	foreach my $coifresultref( @coifresults )
	{
		my @coifresult = @{($coifresultref)};
		my $shiftedinputio = linkfinder_getotherif($coifresult[0], $coifresult[1]);
		my @ioshiftdiff = ioshiftvar_getshiftdiff( $shiftedinputio, $inputioshiftvalue );
		my $newioshiftval = ioshiftvalue_shiftvars( $coifresult[0], \@ioshiftdiff );
	
		my @temparr = ( $newioshiftval, $coifresult[1] );
		@shiftedresults = (@shiftedresults, [@temparr] );
	}
	my @arr = twocolarrtoioconclhash( \@shiftedresults );
	return @arr;
}

sub linkfinder_getotherif($$)
{
	# $inputconcl ($inputprem && $coifresult -> otherprem )
	my $inputioshiftvalue = shift;
	my $inputconcl = shift;
	my $sql	= "select DISTINCT ioshiftvalue_id, conclusion_id  from premise where conclusion_id = $inputconcl and ioshiftvalue_id != $inputioshiftvalue and type = 'I'";
	my $coifresult = stringreturn($sql);
	return $coifresult;
}

sub twocolarrtoioconclhash($)
{
	my @arr = @{(shift)};
	my @returnarray;
	foreach my $row(@arr)
	{
		my @subarr = @{($row)};
		my %hash = premise_iovalconclhashbuild($subarr[0], $subarr[1]);
		@returnarray = (@returnarray, {%hash});
	} 
	return @returnarray;
}

sub fourcolarrtoioconclhash($)
{
	#takes array of results from sql, returns array of arrays of hashes 
	#- each array of hashes representing a doubleif
	my @arr = @{(shift)};
	my @returnarray;
	foreach my $row(@arr)
	{
		my @subarr = @{($row)};
		my @arrofhash;
		$arrofhash[0] = {premise_iovalconclhashbuild($subarr[0], $subarr[1])};
		$arrofhash[1] = {premise_iovalconclhashbuild($subarr[2], $subarr[3])};
		@returnarray = (@returnarray, [@arrofhash]);
	} 
	return @returnarray;
}


sub linkfinder_returnioshiftmatches($$)
{
	#this returns the hash from the *first* array if there is a match between the two arrays on ioshift
	#can be optimized?
	my @arr1 = @{(shift)};
	my @arr2 = @{(shift)};
	my @returnarr;
	foreach my $hashref1( @arr1 )
	{
		my %hash1 = %{($hashref1)};
		foreach my $hashref2(@arr2)
		{
			my %hash2 = %{($hashref2)};
			if( $hash1{'ioshiftvalueid'} = $hash2{'ioshiftvalueid'} )
			{
				@returnarr = (@returnarr, {%hash1});
				last;
			}
		}
	}
	return @returnarr;
}

sub linkfinder_returnioshiftmatchesboth($$)
{
	#this returns an *array of* hashes from both arrays if there is a match between the two arrays on ioshift
	#can be optimized?
	my @arr1 = @{(shift)};
	my @arr2 = @{(shift)};
	my @returnarr;
	foreach my $hashref1( @arr1 )
	{
		foreach my $hashref2(@arr2)
		{
			@returnarr = (@returnarr, linkfinder_returnifhashmatch( $hashref1, $hashref2 ) );
		}
	}
	return @returnarr;
}

sub linkfinder_returnifhashmatch($$)
{
	my %hash1 = %{(shift)};
	my %hash2 = %{(shift)};
	my @returnarr;
	if( $hash1{'ioshiftvalueid'} = $hash2{'ioshiftvalueid'} )
	{
		@returnarr = [ {%hash1}, {%hash2} ];
	}
	return @returnarr;
}

sub linkfinder_getalliostatementvalues($)
{
	#get all ioshiftvals with same iostatement and values
	my $inputioshiftvalue = shift;
	my $sql	= "SELECT DISTINCT iosv2.id from ioshiftvalue iosv1 LEFT JOIN ioshift ios1 on iosv1.ioshift_id = ios1.id INNER JOIN ioshift ios2 on ios1.iostatement_id = ios2.iostatement_id INNER JOIN ioshiftvalue iosv2 on iosv2.ioshift_id = ios2.id and iosv2.value = iosv1.value WHERE iosv1.id = $inputioshiftvalue;";
	my @sameiovals = arrayofresults($sql);
	return @sameiovals;
}

sub linkfinder_getalldoubleiostatementvalues($$)
{
	#3/18/17 - get all ioshiftvals with same iostatement and values as 2 statements (adapted from above)
	my $inputioshiftvalue1 = shift;
	my $inputioshiftvalue2 = shift;
	my $sql	= "SELECT DISTINCT iosv3.id, iosv4.id from ioshiftvalue iosv1 LEFT JOIN ioshift ios1 on iosv1.ioshift_id = ios1.id  LEFT JOIN ioshift ios3 on ios1.iostatement_id = ios3.iostatement_id LEFT JOIN ioshiftvalue iosv3 on ios3.id = iosv3.ioshift_id LEFT JOIN premise p3 on p3.ioshiftvalue_id = iosv3.id LEFT JOIN premise p4 on p4.conclusion_id = p3.conclusion_id LEFT JOIN ioshiftvalue iosv4 on p4.ioshiftvalue_id = iosv4.id LEFT JOIN ioshift ios4 on iosv4.ioshift_id = ios4.id LEFT JOIN ioshift ios2 on ios4.iostatement_id = ios2.iostatement_id LEFT JOIN ioshiftvalue iosv2 on iosv2.ioshift_id = ios2.id WHERE iosv1.id = $inputioshiftvalue1 and iosv2.id = $inputioshiftvalue2 and p3.id <> p4.id";
	my @sameiovals = arrayofresults2($sql);
	return @sameiovals;
}

sub linkfinder_getshiftedioshiftvals( $$$ )
{
	
	#3/18/17 - shifts array of hashes (1st arg) based on second and third args, which are iostatements;
	my @impliedprems = @{(shift)};
	my $impliedsideiosv = shift;
	my $originaliosv = shift;
	my @shiftedvals;
	foreach my $impliedhashref( @impliedprems )
	{
		my %impliedhash = %{($impliedhashref)};
		my @ioshiftdiff = ioshiftvar_getshiftdiff( $impliedsideiosv, $originaliosv );
		my $newioshiftval = ioshiftvalue_shiftvars( $impliedhash{'ioshiftvalueid'}, \@ioshiftdiff );
		$impliedhash{'ioshiftvalueid'} = $newioshiftval;
		@shiftedvals = (@shiftedvals, \%impliedhash );
	}
	return @shiftedvals;
}

sub linkfinder_isvalidsplice( $$$$ )
{
	# checks if 0 and 1 have same shifts (for conjoining at double if)
	my $impliedsideiosv0 = shift;
	my $impliedsideiosv1 = shift;
	my $originalsideiosv0 = shift;
	my $originalsideiosv1 = shift;
	my $shiftediosv;
	my @ioshiftdiff0 = ioshiftvar_getshiftdiff( $impliedsideiosv0, $originalsideiosv0 );
	
	my @ioshiftdiff1 = ioshiftvar_getshiftdiff( $impliedsideiosv1, $originalsideiosv1 );
	my $value = logichelper_arrayseqnoorder( \@ioshiftdiff0, \@ioshiftdiff1 );
	
	return $value;
}

sub linkfinder_getshiftedioshiftvalsdouble( $$$$$ )
{
	
	#3/18/17 -version of above that handles 2-column array for double if/thens
	#totally untested,half-done (?)  Not used anywhere
	#	v-fix this	    /---iosv0\
	#   @impliedprems -<		  >--- some conclusion
	#					\---iosv1/
	my @impliedprems = @{(shift)};
	my $impliedsideiosv0 = shift;
	my $impliedsideiosv1 = shift;
	my $originalsideiosv0 = shift;	
	my $originalsideiosv1 = shift;
	my @shiftedvals;
	foreach my $impliedhashref( @impliedprems )
	{
		my %impliedhash = %{($impliedhashref)};
		
		my @ioshiftdiff0 = ioshiftvar_getshiftdiff( $impliedsideiosv0, $originalsideiosv0 );
		my $newioshiftval0 = ioshiftvalue_shiftvars( $impliedhash{'ioshiftvalueid'}, \@ioshiftdiff0 );
		
		my @ioshiftdiff1 = ioshiftvar_getshiftdiff( $impliedsideiosv1, $originalsideiosv1 );
		my $newioshiftval1 = ioshiftvalue_shiftvars( $impliedhash{'ioshiftvalueid'}, \@ioshiftdiff1 );
		
		# only create if the resulting shift is the same!  Otherwise not really the same.
		# this may lead to missed logic(?), but better than false positives.
		if( $newioshiftval0 eq $newioshiftval1 )
		{
			$impliedhash{'ioshiftvalueid'} = $newioshiftval0;
			@shiftedvals = (@shiftedvals, \%impliedhash );
		}
	}
	return @shiftedvals;
}

