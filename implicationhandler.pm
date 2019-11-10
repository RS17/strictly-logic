#!/usr/bin/perl 
use cPanelUserConfig;
#implicationhandler.pm
package implicationhandler;
use warnings;
#use diagnostics;
use CGI::Pretty qw(:all);
use strict;
use CGI; 
use DBI;
#use LWP::Simple;
use Carp;
use CGI::Carp 'fatalsToBrowser';
use Exporter;
use lib './'; #need for taint mode
use truthstatusupdater;
#use CGI::Inspect;
use debugout;
use stringutil;
use reorderstuff;
use getenglish;
use sqlhandler;
use varfixer;
use conclusion;
use premise;
use ioshift;
use ioshiftvar;
use conjunction;
use transitiveimplication;
use contrapositive;
use then2;
use transpremhash;

our @ISA = qw(Exporter);
our @EXPORT = qw(alltherules2 checkifprinexists @updates enterstatementnew 
				 enterconclusion enterconclusionfromioshift);
my $depthstring; 
our @updates; #this is all the updated pages - called from createprinciple

sub alltherules2($)
{
	#run for each premise
	#things useful for multiple functions
	my $conclusionid = shift;
	my %conclprems = conclusion::conclusion_getwithpremises($conclusionid);
	my @premises = @{($conclprems{'premises'})};
	my @conclusions = premise_returnonlytype( \@premises, 'C' ); 
	my @ifs = premise_returnonlytype(\@premises, 'I');
	
	#conjunction 
	my @newconcls = conjunction_checkcreate( $conclusionid, \@ifs, \@conclusions );
	enterconclusionfromioshift( \@newconcls );
	my $newnum = scalar(@newconcls);
	print( "\n<br> Entered $newnum for conjunction" );
	
	#transitive implication
	@newconcls = transitiveimplication_checkcreate( $conclusionid, \@ifs, \@conclusions );
	enterconclusionfromioshift( \@newconcls );
	$newnum = scalar(@newconcls);
	print( "\n<br> Entered $newnum for transitive" );
	
	#contraposition
	@newconcls = contrapositive_checkcreate( $conclusionid, \@ifs, \@conclusions );
	enterconclusionfromioshift( \@newconcls );
	$newnum = scalar(@newconcls);
	print( "\n<br> Entered $newnum for contrapositive" );

	#then-2
	@newconcls = then2_checkcreate( $conclusionid, \@ifs, \@conclusions );
	enterconclusionfromioshift( \@newconcls );
	$newnum = scalar(@newconcls);
	print( "\n<br> Entered $newnum for then-2" );
	
}


#########################################################################
#	S	U	B	S
#########################################################################
# NOTE: After refactoring it nayno longer makes sense for some of these functions to be here.  


sub checkifprinexists($$){ #check if statement is already in principles, returns prinid if does (else 0)
	#NOTE: The role of this function has expanded to check for more than if a prin simply exists, but is rather a general validate. 
	# if a principle cannot be entered for reasons other than not existing (probably to keep things simplified by avoiding unnecessary entries)
	# but a thrown error is not warranted, it will return -1.
	my $sqlcmd;
	my $prinsexist;
	my $checkif = shift;
	my $checkthen = shift;
	my @caller = caller;
	reorderprins($checkif, $checkthen);
	debugout("received checkif as ($checkif) from $caller[1] $caller[2]");
	debugout("received checkthen as ($checkthen)");

	my $dbh = returndbh();
	my $sth;
	$sqlcmd = "SELECT id FROM principles WHERE ifstatement = '$checkif' AND thenstatement='$checkthen'";
	
	$sth=$dbh->prepare($sqlcmd);
	debugout("sql is $sqlcmd");
	$sth->execute() || confess "<br>$depthstring Couldn't execute query: $DBI::errstr\n ";
	$prinsexist = $sth->fetchrow_array;
	debugout("Prinsexist = $prinsexist");
	debugout("got here");
	if ($checkif eq $checkthen){
		debugout("skipped tautology"); #don't enter tautologies because leads to bizarre logical consequences that can cause errors and are difficult to weed out, and serve little use. 
		return -1;
	}
	if ($prinsexist > 0){
		return $prinsexist;
	}else{
		return 0;
	}
	
	$sth->finish;
	$dbh->disconnect;
}



sub entertransitive($$$){
	my $firstprin = shift;
	my $secondprin = shift;
	my $resultprin = shift;
	my $tempprin;
	my $sth;
	my $sqlcmd;
	my $dbh = returndbh();
	#put prins in order to avoid problems
	if ($resultprin == -1){
		return; #this is code from checkifprinexists that neither prin nor transitive should be entered - skip entirely (e.g. where statement does not exist but otherwise unentered)
	}
	
	if ($firstprin < $secondprin){
		$tempprin = $firstprin;
		$firstprin = $secondprin;
		$secondprin = $tempprin;
	}
	#check that variables don't match - don't want principles implying themselves - leads to ballooning of unnecessary statements
	if (($firstprin == $secondprin) || ($firstprin==$resultprin) || ($secondprin ==$resultprin)){
		#this does not detect duplicate transitive, but instead detects transitives that imply themselves. Could skip, but probably indicates logic error somewhere. 
		confess "Error entering into transitive: implication from self detected: $firstprin, $secondprin, $resultprin.  
		This is never supposed to happen.  Then again, if you are looking at this, that means it has happened nonetheless.";
	}
	debugout("got here");
	if (checkiftransexists($firstprin, $secondprin, $resultprin)){
		debugout("Transitive skipped because duplicate");
	}else{
		my $sqlcmd = "INSERT INTO transitive (firstprin, secondprin, resultprin) VALUES ($firstprin, $secondprin, $resultprin)";
		debugout("Entering transitive $sqlcmd");
		$sth=$dbh->prepare($sqlcmd);
		$sth->execute || confess "Couldn't execute query: $DBI::errstr\n";
	}
	$dbh->disconnect;
	TSU($firstprin);TSU($secondprin);TSU($resultprin) #this is probably rather inefficient, but makes sure gets everything.
}

sub checkiftransexists($$$){
	my $firstprin = shift;
	my $secondprin = shift;
	my $resultprin = shift;
	my $sth;
	my $dbh = returndbh();
	my $sqlcmd = "select id from transitive where firstprin = $firstprin and secondprin = $secondprin and resultprin = $resultprin";
	debugout($sqlcmd);
	$sth = $dbh->prepare($sqlcmd);
	$sth->execute() || confess "Couldn't execute query: $DBI::errstr\n";
	my $transexists = $sth->fetchrow_array;
	$dbh->disconnect;
	if ($transexists>0){
		return $transexists;
	}else{
		return 0;
	}
}

#This sub is used from both this script and the create principle script to enter code in the database.
#Then it calls alltherules (big sub above) and later enters info into iostatement database (this is ok because iostatement isn't used 
#until someone tries to enter new statement). 
sub enterconclusion($$$$)
{
	my @premises = @{(shift)};
	my @splitifandthens = @{(shift)};
	my $truth = (shift);
	my $hasioshifts = shift;
	my $conclid;
	#enter conclusion 
	if( conclusion_isvalid( \@premises) )
	{
		$conclid = conclusion_create($truth);
		debugout("entered conclusion $conclid");
		#enter each premise
		my @pos;
		my $ele = 0;
		debugout("entering premises");
		foreach my $premiseref(@premises)
		{
			my %premise = %{$premiseref};
			debugout("entering premise for $premise{'iostatementid'}");
			my $enteredstatement;
			if( $premise{'type'} eq 'C' )
			{
				debugout("entering conclusion");
				my @conclusions = @{$splitifandthens[0]};
				$enteredstatement = $premise{'statement'}; #not sure if this should work -vars may be  different due to UF across
				#grep( $_ eq $premise{'statement'}, @conclusions);
			}
			else
			{
				debugout("entering if");
				my @ifs = @{$splitifandthens[1]};
				$enteredstatement = $premise{'statement'};#grep( $_ eq $premise{'statement'}, @ifs);
			}

			@pos = getvarspositions( $enteredstatement );
			my @ioshiftvarstuff = ioshiftvar_builder(\@pos, $premise{'iostatementid'});
			my $premiseid = premise_createhash($conclid, \%premise, \@ioshiftvarstuff );
		}

		debugout("done with premises");
		alltherules2($conclid);
	}
	else
	{
		die "invalid entry";
	}
	return $conclid;
	
}

sub enterconclusionfromioshift($)
{
	use transitive;
	my @concls = @{(shift)};
	foreach my $transpremhash(@concls)  #for each group of premises (each making up a full conclusion-principle)
	{
		#get idealized version so consistent varshift setup
		my %tphash = transpremhash_idealize( $transpremhash );
		if( conclusion::conclusion_isvalid( $tphash{'premises'} ) )
		{
			
			my $conclid = conclusion::conclusion_checkifpremsexist($tphash{'premises'});

			if( $conclid eq "" )
			{
				$conclid = conclusion::conclusion_create('skip');
				#transitive_create($conclid);
				debugout("created conclusion $conclid");
				foreach my $premise(@{($tphash{'premises'})}) #for each premise in the group
				{
					
					premise_createhashwshift($conclid, $premise);
				}
				alltherules2( $conclid );
			}
			
			my %transhash = %{($tphash{'transhash'})};
			$transhash{'transitiveconcl'} = $conclid;
			my $transid = transitive_createhash( \%transhash );
			debugout( "Created transitive $transid" );
		}
	}
}


1;
	
