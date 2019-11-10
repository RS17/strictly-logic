#!/usr/bin/perl 
#truthstatusupdater.pl
package truthstatusupdater;

use strict;
use lib './'; #need for taint mode
use warnings;
use implicationhandler;
use debugout;
#use diagnostics;
use CGI::Pretty qw(:all);
use strict;
use CGI; 
use DBI;
#use LWP::Simple;
use Carp; #this is needed for stack tracing.
use CGI::Carp 'fatalsToBrowser';
use Exporter;
#use CGI::Inspect;

our @ISA = qw(Exporter);
our @EXPORT = qw(TSU @updates);

sub debugoutTSU($);




my $dbh;
my $sth;
my $debugmode = 0;
my $origprin;
our @updates;

#KNOWN PROBLEM: Checks links in a random manner, does not return to check afterwards.  This appears to be due to the way is set up from create - first checks implication handler, then sends to TSU. When vote it may check TS more often.

sub TSU{
	debugoutTSU("STARTED NEW INSTANCE OF TSU");
	
	sub printruth($$$);
	sub gettruth;
	$origprin = (shift);
	if ($origprin eq 0){
		return;
	}

	my $cgi = new CGI; #not using SQL handler because don't want to keep connecting for each query - there's a lot here.
	$dbh=DBI->connect('dbi:mysql:surilega_postulates','surilega_webuser','silverpikul1') ||
		confess "Error opening database: $DBI::errstr\n";
	our @updates;

	sub modusponens($$);
	sub modustollens($$);
	sub directassign($);
	sub gettruthofprin($);
	sub updater($$);

	my $startingprin;
	#$startingprin =(shift); 
	#debugoutTSU("Running prin $startingprin as original starting prin through TSU");
	
	#my $startingprin=1109; #this is for testing.  964 is ideal because appears in all three fields
	my $startlimitstart =0;
	debugoutTSU( "Reset Start limit - now equals $startlimitstart");

	updater($origprin, $startlimitstart);
	
	$sth->finish;
	$dbh->disconnect;
	
	debugoutTSU("FINISHED TSU<br><br><br><br>");
	1;
}
sub updater($$){ 
		#print "ran updater";
		my $startingprin=(shift);
		my $startlimit =(shift);
		debugoutTSU( "<br><br><br><br>starting iteration of truthstatus updater with $startingprin\n from initial prin $origprin. Computation level is $startlimit<br>");
		$startlimit++;
		if ($startlimit>15){ #checks if past limit.  If not, keeps running sub recursively/
			croak "Reached computation limit";
		}


		my @allprins;
		my @allconcls;
		my $mcprintruth;
		my $mpconcltruth;
		my $mcconcltruth;
		my $index;
		my $truthcheck;
		my $message;
		my $sqlcmd;
		#for testing input



	#1. gets called by outer function when a prin's truth value is externally updated
	# or created.  
	# 2 then uses transitive table to figure out what other truth values depend on startingprin as prin, for modus ponens AND modus tollens (in case existing concl that is false)
	# 3.0 updates using direct assignment if principle is null
	# 3.1 otherwise, updates truth values using modus ponens
	# 4. then uses trans table to figure out what prins depend on startingprin as concl, for modus tollens only
	# 5. then updates those truth values using modus tollens
	# 6. re-calls self to update values based on those.  (NOTE: THIS WILL LEAD TO INFINITE LOOP WITH CURRENT SETUP - need to check if change before updating/calling). 
	# Note that this may cause loops.  Maybe should have some way of figuring out how deep it is.
	# 
	#sub-functions
	#modusponens- if both prins are true, conclusion is true
	#modustollens - if conclusion is false and one prin is true, then other prin is false
	#gettruthval of prins - figures out whether each prin is true or false, based on 
	# vote value and establish value.



	#1 - happens above - note that $startingprin is principle used to call this functions
	#2 
		debugoutTSU("Got to 2");
		#$sqlcmd = "SELECT secondprin, resultprin FROM transitive WHERE firstprin=$startingprin";
		$sqlcmd = "SELECT d2.conclusion_id, t.conclusion from dependency d1 JOIN transitive t on d1.transitive_id = t.id left join dependency d2 on d2.transitive_id = t.id where d1.conclusion_id = $startingprin";
		debugoutTSU($sqlcmd);
		$sth=$dbh->prepare($sqlcmd); #finds all applications to ifstatement
		$sth->execute();
		$index = 0; #for some reason $_ doesn't work right for below, so I'm using this and doing it manually
		while (my @row=$sth->fetchrow_array){ #need to do this because dbi outputs column here, and fetchrowarray only gets one row (not col) at a time.
			$allprins[$index]=$row[0];
			$allconcls[$index]=$row[1];
			$index++;
			#print "iteration secondprins $_";
		}
		#$sqlcmd = "SELECT firstprin, resultprin FROM transitive WHERE secondprin=$startingprin";
		#$sth=$dbh->prepare($sqlcmd); #finds all applications to ifstatement
		#debugoutTSU("$sqlcmd");
		#$sth->execute();
		#$index = 0; 
		#while (my @row=$sth->fetchrow_array){ #need to do this because dbi outputs column here, and fetchrowarray only gets one row (not col) at a time.
			
		#	$firstprins[$index]=$row[0];
		#	$firstconcls[$index]=$row[1];
		#	$index++;
		#}
	#	#}
		#my @allprins=(@firstprins, @secondprins);
		#my @allconcls=(@firstconcls, @secondconcls);
		if ($debugmode ==1){
			foreach (@allprins){
				debugoutTSU("prin is $_");
			}
			foreach (@allconcls){
				debugoutTSU( "<br>concl is $_");
			}
		}
			
	#3.0
		debugoutTSU("Got to 3");
		$index=0;
		foreach (@allprins){
			debugoutTSU( "measuring $startingprin with principle $_");
			if ($_== 0){
				debugoutTSU("got directassign because I think $_ the same as 0");
				$mpconcltruth = directassign($startingprin);
				unless ($mpconcltruth eq "unknown"){
					debugoutTSU("direct assignment has implied that statement is $mpconcltruth");
				
					$sth=$dbh->prepare("SELECT impliedstatus FROM conclusion WHERE id=$allconcls[$index]"); #
					$sth->execute();
					$truthcheck=$sth->fetchrow_array;
					debugoutTSU("ran truthcheck got result $truthcheck");
					unless ($truthcheck eq $mpconcltruth){
						$sth=$dbh->prepare("UPDATE conclusion SET impliedstatus='$mpconcltruth' where id=$allconcls[$index]"); 
						$sth->execute() || confess "could not execute update of truth value from truth status updater $DBI::errstr\n";
						debugoutTSU("ran truth update on $allconcls[$index]");
						@updates = (@updates, $allconcls[$index]);
						updater($allconcls[$index], $startlimit);#||die $!;
					}
				}
	#3.1
			}else{
				$mpconcltruth=modusponens($_, $startingprin);
			#print "result $mpconcltruth";
				if ($mpconcltruth eq 'true'){
					debugoutTSU( "modus ponens has implied that statement is true");
					#first check if true, then go.
					$sth=$dbh->prepare("SELECT impliedstatus FROM conclusion WHERE id=$allconcls[$index]"); #finds all applications to ifstatement
					$sth->execute();
					$truthcheck=$sth->fetchrow_array;
					debugoutTSU("ran truthcheck got result $truthcheck");
					unless ($truthcheck eq 'true'){
						$sth=$dbh->prepare("UPDATE conclusion SET impliedstatus='true' where id=$allconcls[$index]"); #finds all applications to ifstatement
						$sth->execute() || confess "could not execute update of truth value from truth status updater $DBI::errstr\n";
						@updates = (@updates, $allconcls[$index]);
						debugoutTSU("ran truth update on $allconcls[$index]");
						updater($allconcls[$index], $startlimit);#||die $!;
					}
				}
			}
			$index++;
		}
		#print "/n";
		#print "modustollens as prin:";
		$index=0;
		foreach(@allconcls){
			$mcprintruth=modustollens($startingprin, $_);
			if ($mcprintruth eq 'false'){
				debugoutTSU("modustollens has implied that statement is false");
				$sth=$dbh->prepare("UPDATE conclusion SET impliedstatus='false' where id=$allprins[$index]"); #finds all applications to ifstatement
				$sth->execute();
				@updates = (@updates, $allprins[$index]);
				updater($allprins[$index], $startlimit);
			}
			$index++;
		}
	#4
		#$sth=$dbh->prepare("SELECT firstprin, secondprin FROM transitive WHERE resultprin=$startingprin"); #finds all applications to ifstatement
		$sth=$dbh->prepare("SELECT d1.conclusion_id, d2.conclusion_id from dependency d1 RIGHT JOIN transitive t on d1.transitive_id = t.id RIGHT join dependency d2 on d2.transitive_id = t.id and NOT  d1.conclusion_id = d2.conclusion_id where d1.conclusion_id = $startingprin");
		$sth->execute();
		$index = 0;
		my @firstprins;
		my @secondprins;
		while (my @row=$sth->fetchrow_array){ #need to do this because dbi outputs column here, and fetchrowarray only gets one row (not col) at a time.
			$firstprins[$index]=$row[0];
			$secondprins[$index]=$row[1];
			$index++;
		}
		
		#inspect();
	#5
		#first run first prin,
		#print "mcconcltruth";
		$index=0;
		foreach my $firstprin(@firstprins){
			$mcconcltruth=modustollens($firstprin, $startingprin);
			if ($mcconcltruth eq 'false'){
				debugoutTSU("modustollens has implied that statement is false");
				$sth=$dbh->prepare("UPDATE conclusion SET impliedstatus='false' where id=$secondprins[$index]"); #finds all applications to ifstatement
				$sth->execute();
				@updates = (@updates, $secondprins[$index]);
				updater($secondprins[$index], $startlimit);
			}
			$index++
		}
		#then second prin
		$index=0;
		foreach my $secondprin(@secondprins){
			$mcconcltruth=modustollens($secondprin, $startingprin);
			if ($mcconcltruth eq 'false'){
				debugoutTSU("modustollens has implied that statement is false");
				$sth=$dbh->prepare("UPDATE conclusion SET impliedstatus='false' where id=$firstprins[$index]"); #finds all applications to ifstatement
				$sth->execute();
				@updates = (@updates, $firstprins[$index]);
				updater($firstprins[$index], $startlimit);
			}
			$index++
		}

}


#my @args = ($origprin);
#system($^X, "principlesplitter.pl", @args); #this calls createstatementpage.pl for both if and then statements

sub modusponens($$){ #gets prin1 and prin2, returns true if prin 1 and 2 are true
	my $concltruth;
	my($prin1, $prin2)=(shift, shift);
	if ($debugmode == 1){print "<br>running modusponens with $prin1, $prin2";}
	my $truthprin1=gettruthofprin($prin1);
	my $truthprin2=gettruthofprin($prin2);
	#print "truth of prins is $truthprin1, $truthprin2";
	if (($truthprin1 eq 'true') && ($truthprin2 eq 'true')){
		$concltruth='true';
	}else{
		$concltruth='none';
	}
	debugout("modus ponens returning $concltruth for conclusion");
	return $concltruth

}
sub modustollens($$){#gets prin 1 and concl, returns false if prin 1 is true and concl is false
	my $printruth;
	my($prin1, $concl)=(shift, shift);
	debugout("running modustollens with $prin1, $concl");
	my $truthprin1=gettruthofprin($prin1);
	my $truthconcl=gettruthofprin($concl);
	if (($truthprin1 eq 'true') && ($truthconcl eq 'false')){
		$printruth='false';
	}else{
		$printruth='none';
	}
	return $printruth
}

sub directassign($){
	my $concltruth;
	my ($prin1)=(shift);

	my $truthprin1=gettruthofprin($prin1);
	#print "truth of prins is $truthprin1, $truthprin2";
	$concltruth = $truthprin1;
	return $concltruth;
}
	

sub gettruthofprin($){ #returns true, false, unknown, or conflicted for single prin
	my $tval;
	my $prin=(shift);
	my $votestatus;
	my $impliedstatus;
	my $sqlcmd;
	my @output;
	$sqlcmd = "SELECT votestatus, impliedstatus FROM conclusion WHERE id=$prin";
	$sth=$dbh->prepare("SELECT votestatus, impliedstatus FROM conclusion WHERE id=$prin"); #finds all applications to ifstatement
	$sth->execute() || confess "<br>Couldn't execute query: $DBI::errstr\n but did not exit - probably duplicate transitive statement";
	@output = $sth->fetchrow_array;
	$votestatus= $output[0];
	$impliedstatus= $output[1];
	#print "votestatus is $votestatus, impliedstatus is $impliedstatus /n";
	if ($votestatus eq $impliedstatus){
		$tval=$votestatus;
	}elsif ($impliedstatus eq 'unknown'){
		$tval=$votestatus;
	}elsif ($votestatus eq 'unknown'){
		$tval=$impliedstatus;
	}else{
		$tval='conflict';#later on there will be a conflict checker that will make use of this
	}
	return $tval;
}
sub debugoutTSU($){
	if($debugmode == 1){
		my 	$outstring = shift;
		my @caller = caller;
		debugout("<i>from $caller[2] $outstring</i>");
	}
}


1;
