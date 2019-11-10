#!/usr/bin/perl
#createprinciple.pl
use warnings;
use diagnostics;
use CGI::Pretty qw(:all);
use strict;
use CGI; 
use DBI;
#use LWP::Simple;
use Carp;
use CGI::Carp 'fatalsToBrowser';

#use CGI::Inspect; #debugger
#use lib "/cgi-bin/";
use lib './'; #need for taint mode
use implicationhandler;
#use principlesplitter;
use debugout;
use varfixer;
use stringutil;
use reorderstuff;
use iovar;
use iovarposition;
use premise;
use conclusion;
use truthstatusupdater;
use sqlhandler;
$debugmode = 0;

#This takes prin from user input, then calls enterstatement sub in implicationhandler.pm to put the statement into the database. 

my $princheck;
my $laststatement;
my $cgi = new CGI;
my $dbh;
my $dbh=returndbh();
my $complete = 1;
my $thenstatement;
my $outputonly=0;
my $mbf;
my $count2;
my $counter;
my $finalstatement;
my $currstatement;
my $passedstatement;
my $url;
my $truth;
my $sth;
my $finalcall=0;
my $secondrun = 0;
my $ifstatementnew;
my $okchars='-a-zA-Z0-9_@~&';
my $cgiifstatementid1 = '';
my $cgithenstatementid = ''; 
my $cgitruthvalue = '';
my $directcall=0;
my $cgifinalstatement = '';
my $debugmode=1;
my $sqlcmd;
my @args;
my @args2;

#testing:
#$cgiifstatementid1=290;
#$cgithenstatementid=289;
#$cgitruthvalue='true';

if(@ARGV[0]){
	$cgifinalstatement=@ARGV[0]; #the plan is that this will be handled in a future version of the sending script, and will be a combination of all ifstatements.  That way won't have to change the way its done below.
	$cgiifstatementid1=@ARGV[0]; #this is just a lazy way of keeping consistency with prior changes.  Bad.  Will take care of later.
	$cgithenstatementid=@ARGV[1];
	$cgitruthvalue=@ARGV[2];
	$cgi->delete_all;
	$directcall=1;
}elsif($cgi->param('truthvalue')){
	$cgitruthvalue=$cgi->param('truthvalue');
	$cgiifstatementid1=$cgi->param('ifstatementid1');
	$cgithenstatementid=$cgi->param('thenstatementid');
}
if ($directcall==0){
	print header();
	print start_html (title=>"Create if-then.");
}
$cgifinalstatement=~ s/[^$okchars]/ /go;
$cgiifstatementid1=~ s/[^$okchars]/ /go;
$cgithenstatementid=~ s/[^$okchars]/ /go;
$cgitruthvalue=~ s/[^$okchars]/ /go;

if ($cgi->param('ifstatement') && $cgi->param('thenstatement')){
	print "<form action=''>";
	my $entry = $cgi->param('ifstatement') ;
	
	$entry=~s/[^$okchars]/ /go;
	
	if ($entry =~ / he | she | it | her | hers | herself | him | himself | his | I | its | itself | me | mine | myself | she | their | theirs | them | thenselves | they | those | us | we | you | your | yours | yourself | yourselves /){
		print 'You used a pronoun.  Generally, you should use a variable such as @1 in place of a pronoun<br>';
	}
	if ($entry =~ / and /){
		print "You used and.  If this can be written as two independent clauses, please write it that way using '&&' to separate them.<br>";
	}
	if ($entry =~ / not /){
		print "You used not. Go back and use ~ at the beginning instead (e.g. ~@1 read the directions, meaning @1 did not read the directions.";
		exit;#do not die because don't want error message - this is normal.  
	}

	if ($entry =~ /&&/){#if statement separator detected
		my @entries=split /&&/, $entry;
		$count2 = 1;
		foreach (@entries){
			$mbf=$_; #$_ is each row of @entries (so each if statement separated by &&)
			print "For statements $mbf<br>";
			&ifchecker;
			$count2++;
		}
	}else{
		$count2 = 1;
		$mbf=$entry;
		&ifchecker;
	}
	&thenchecker;
	&defaulttruth;
	&submitter;
	print "</form>";
	$secondrun=1;
}elsif($cgi->param('thenstatement')){
	print "<form action=''>";
	$outputonly=1;
	&thenchecker;
	&submitter;
	print "</form>";
	$secondrun=1;
}elsif ($directcall==0){
	unless($finalcall==1){
		print "<big>STRICTLY LOGIC</big><br>
		<br>
		<a href=/index.html>Home</a><br>
		<a href=/search.html>Search</a><br>
		<a href=http://www.strictlylogic.com/slblog>BLOG</a><br>";
		print "<br> If you've not used this before read the instructions below first.";
		print generate_form(); # this must be called with print, not & statement, otherwise will not work
	}
}

if ( $cgi->param('enteredthen')&& $cgithenstatementid eq 'pass'){
	my $enteredthen=($cgi->param('enteredthen'));
	$enteredthen=~ s/[^$okchars]/ /go;
	$thenstatement=newstatementmaker($enteredthen);	
}
else
{
	$thenstatement = $cgithenstatementid;
}

#finalcall

if ((($cgiifstatementid1)||$cgifinalstatement) && ($cgithenstatementid) && ($cgitruthvalue)|| $thenstatement){
	$truth = $cgitruthvalue;
	&enterifthen;
	
}else{
	#print "error: if or then statement or default truthvalue not detected";
}

unless ($finalcall==1 || $secondrun==1 || $directcall==1){
	print '<br><br>NOTICE: Anything you enter here will be stored in a database and posted on this site, and will be accessible to the general public.  Do not post any personal information.  This site is experimental.  It is possible to likely that everything posted to this site will be completely deleted as changes are made.  It is also possible that what you enter here will be stored and publicly available for the indefinite future.';  
	print '<br><br>Enter both statements below or only then statement.  Use "&&" to separate multiple if statements.<br><br>';
	print 'Before entering a principle please take note of the following rules:<br>';
	print '<br>1. You must fill in both if and then fields.';
	print '<br>2. You may include multiple (up to 5) if statements joined by the && operator.  && means AND.  There is no OR.  If you wish to enter an or, enter it as two separate if-then statements instead.  You may not use multiple THEN statements.  Again, this can be handled with multiple if-then statements.';
	print '<br>3. Each statement must include at least one variable, denoted by @(digit), as in "@1 is Socrates."  This is necessary to ensure that statements are being entered in a format that is useful.';
	print '<br>4. Your principle will not be entered until after you select your statements on the next page.';
	print '<br>5. No characters are allowed except letters, numbers, &, ~, and @.  Anything else will automatically be removed from a statement.';
	print '<br>6. By the way ~ means not and must be placed at the beginning (e.g. ~@1 is something, meaning @1 is not something).  Negation is not yet fully integrated into the system,';
	print '<br>7. Despite the incompleteness of negation, you still are not allowed to use the word "not" because you should use the negation indicator instead to cut down on multiple statements that mean the same thing.  You are also  discouraged from using "and" if you can avoid it.';
	print '<br><br>Example 1 (simple):<br>IF: @1 is socrates';
	print '<br> THEN: @1 is mortal.';
	print '<br><br>Example 2 (complex):<br>IF: @1 is a plane that is traveling at takeoff speed relative to the ground on treadmill @2 && @1s forward velocity relative to the ground matches @2s rearward velocity';
	print '<br>THEN: @1 will take off from treadmill @2';
}

sub generate_form{
	return start_form(),
		p('IF', textfield(-name=>'ifstatement', -size=>100)),
		p('THEN', textfield(-name=>'thenstatement', -size=>100)),
		p(submit),
			end_form;
}

sub ifchecker {
	my @similars;
	print "IF STATEMENT:<br>";
	my $searchentry=$mbf;#mbf is already cleaned of bad characters, but this allows search that is most accurate
	$searchentry =~ trim($searchentry); # removes trailing spaces
	#validation
	if ($searchentry =~ /[^^]~/ ){ #This means "tilde coming anywhere not at the beginning" (^ is both not (after [) and at the beginning (^ on its own))
		print "Error: ~ must be at beginning of a statement.  You can only make a whole statement negative, not parts.\n"; # do this because don't want people to think they can make a not apply to only part of a statement 
		exit; 
	}
	if ($searchentry =~ /^if /){
		print "Do not use if at the beginning of a clause, it is included for you.";
		exit;
	}

	$searchentry=~ tr/~//d;# this should remove ~ - do this because ~ is in principle table instead.
	$searchentry = statementvarfixer($searchentry);
	my $duplicateif = stringreturn_secure( "SELECT id FROM iostatements WHERE description=?", $searchentry );
	if ($duplicateif){
		print "<br>Duplicate statement:<br>";
		print "<input type='radio' name='ifstatementid$count2' value='$duplicateif'> $mbf <a href=/prin$duplicateif.html>[page]</a><br>";  # when actually do script, this should print out statement instead of id.
		print "<input type='hidden' name='enteredif$count2' value='$mbf'>";
	}else{
		my $sth = $dbh->prepare("select id, description from iostatements where match (description) against (? with query expansion)") ;
		$sth->execute($searchentry) || confess "Couldn't execute query: $DBI::errstr\n";
		my $matches=$sth->rows(); #I think this takes the number of matches in the result - sth being the result
		$sth -> finish();
		unless ($matches){
			$complete = 0;
			print "<br>No matches.  Click below to enter this as a new statement?<br>";
			print "<input type='radio' name='newstatementif$count2' value='$mbf'>$mbf<br>";  
			print "<input type='hidden' name='ifstatementid$count2' value='pass'>";  
			#print "No matches.  Enter in then field by itself to enter as new statement. <br>";
			#die;
		}else{
			print "<br>$matches Similar statements:<br> ";
			my $count = 0;
			print "Select your if statement (create a new statement if not listed) <br>";
			while (my @row = $sth->fetchrow_array){
				$count = $count+1;
				@similars[$count] = @row;
				#create radio buttons and form below
				print "<input type='radio' name='ifstatementid$count2' value='$similars[$count]' enteredif$count' = $row[1]> $row[1] <a href=/@similars[$count].html>[page]</a><br>";  
				print "<input type='hidden' name='enteredif$count2' value='$row[1]'>";  
			}
			print "Or, enter as new:<br><input type='radio' name='ifstatementid$count2' value='pass'>$mbf<br>";  
			print "<input type='hidden' name='newstatementif$count2' value='$mbf'>";  
		}
	}
	if ($mbf =~ /~/){
		print "<input type='hidden' name='not$count2' value=1>";
	}
	print "<br>";
}

sub thenchecker{
	my @similars;
	my $mbf = $cgi->param('thenstatement') ;
	$mbf =~s/[^$okchars]/ /go;
	if ($mbf =~ / and /){
		print "You used and.  If this can be written as two independent clauses, please write it that way using '&&' to separate them.<br>";
	}
	if ($mbf =~ / not /){
		print "You used not. Go back and use ~ at the beginning instead (e.g. ~@1 read the directions, meaning @1 did not read the directions.";
		exit;
	}
	if ($mbf =~ /^then /){
		print "Do not use then at the beginning of a clause, it is entered for you.";
		exit;
	}
	if ($mbf =~ /&&/){
		print "You are trying to combine two then statements as one.  Don't be lazy, enter this as two separate if statements.";
		exit;
	}
	my $searchentry=$mbf;#mbf is already cleaned of bad characters, but this allows search that is most accurate
	$searchentry=~ tr/~//d;# this should remove ~ - do this because ~ is in principle table instead.
	$searchentry=~ s/^\s+//; # removes leading spaces
	$searchentry=~ s/\s+$//; # removes trailing spaces

	
	$searchentry = statementvarfixer($searchentry);
	
	my $duplicatethen = stringreturn_secure( "SELECT id FROM iostatements WHERE description= ? ", $searchentry );
	print "THEN STATEMENT:<br>";
	if ($duplicatethen){
		print "<br>Duplicate statement:<br>";
		print "<input type='radio' name='thenstatementid' value='$duplicatethen'> $mbf <a href=/prin$duplicatethen.html>[page]</a><br>";  
		print "<input type='hidden' name='enteredthen' value='$mbf'>"; 
	}else{
		my $sth = $dbh->prepare("SELECT id, description FROM iostatements WHERE MATCH (description) AGAINST (? with query expansion)") ;
		$sth->execute($mbf) || confess "Couldn't execute query: $DBI::errstr\n";
		my $matches=$sth->rows(); #I think this takes the number of matches in the result - sth being the result
		
		unless ($matches){
			print "<br>No matches.  Click below to enter this as a new statement?<br>";
			print "<input type='radio' name='enteredthen' value='$mbf'> $mbf<br>";  # when actually do script, this should print out statement instead of id.
			print "<input type='hidden' name='thenstatementid' value='pass'>";  # when actually do script, this should print out statement instead of id.

		}else{
			print "<br>$matches similar statements <br> ";
			my $count = 0;
			print "Select your then statement (create a new statement if not listed) <br>";
			if ($outputonly==1){
				print "if you intend to use a statement below, it already exists.  Go back and enter it as part of a full principle.<br>";
			}
			while (my @row = $sth->fetchrow_array){
				$count = $count+1;
				@similars[$count] = @row;
				#create radio buttons and form below
				if ($outputonly==1){
					print "@row[1]<br>"
				}else{
					print "<input type='radio' name='thenstatementid' value='$similars[$count]'> $row[1] <a href=/prin@similars[$count].html>[page]</a><br>";  
					print "<input type='hidden' name='enteredthen$count2' value='$row[1]'>"; 
				}
			}
			
			$sth->finish() ;
			print "Or, enter as new:<br><input type='radio' name='thenstatementid' value='pass'> $mbf<br>";  # when actually do script, this should print out statement instead of id.
			print "<input type='hidden' name='enteredthen' value='$mbf'>";  # when actually do script, this should print out statement instead of id.			
		}
	}
	if ($mbf =~ /~/){
		print "<input type='hidden' name='notthen' value=1>";
	}
	print "<br>";	
}

sub defaulttruth{
	print "In your opinion, is this principle always true, not always true, or not discernible?<br>";
	print "<input type='radio' name='truthvalue' value='true'>Always True<br>";
	print "<input type='radio' name='truthvalue' value='false'>Not Always True<br>";
	print "<input type='radio' name='truthvalue' value='unknown'>Don't Know/Not Discernible<br>";
	
}

sub submitter{
	print "<input type='submit' value='Submit'/>"; # if submit doesn't work, check that HTML form set up properly
} 

sub enterifthen{
	my $fixedacrossifthen;
	my @premises;
	my %thenhash = %{premise_buildhash( 0, $thenstatement, 'C', $cgi->param('enteredthen') )};
		debugout($thenhash{"iostatementid"});
	@premises = (@premises, {%thenhash} );
	debugout($thenhash{"iostatementid"});
	for ($counter=1; $counter<=5; $counter++) {
		debugout("oncounter$counter");
		my $enteredif;
		if ($cgi->param("ifstatementid$counter")){
			#enter any new ifstatements
			my $thisparam = $cgi->param("ifstatementid$counter");
			debugout("got param $thisparam");
			if ($cgi->param("newstatementif$counter") && ($cgi->param("ifstatementid$counter") eq 'pass')){
				my $newstatementif=($cgi->param("newstatementif$counter"));
				$enteredif = $newstatementif;
				if ( length( $fixedacrossifthen ) > 0 )
				{
					$fixedacrossifthen = "$fixedacrossifthen||";
				}
				debugout("fixed is now $fixedacrossifthen" );
  				$ifstatementnew=newstatementmaker($newstatementif);  #ifstatementnew is fixed statement as entered.
			}else{ #if not new
				$ifstatementnew=$cgi->param("ifstatementid$counter");
				$enteredif=$cgi->param("enteredif$counter");
				debugout("got ifstatementnew $ifstatementnew");
			}
			my %ifhash = %{premise_buildhash( $counter-1, $ifstatementnew, 'I', $enteredif )};
  			@premises = (@premises, {%ifhash} );
			if ( length( $fixedacrossifthen ) > 0 )
			{
				$fixedacrossifthen = "$fixedacrossifthen||";
			}
			$fixedacrossifthen = "$fixedacrossifthen$enteredif";
			debugout("fixed is now $fixedacrossifthen" );
			$currstatement=$ifstatementnew;
			if ($cgi->param("not$counter")){ #if it's a negative - "if not"
				debugout("got back here" );
				$currstatement="~$currstatement";
			}
			debugout("got back here $finalstatement, $currstatement");
			$finalstatement="$finalstatement$currstatement|"; 
			debugout("Finalstatement is $finalstatement");

		}else{
			#$fixedacrossifthen = $finalstatement;
			debugout("got to else");
		}
	}
	
	#fix full statement to get the increment.
	my $enteredthen = $cgi->param('enteredthen');
	$fixedacrossifthen = "$fixedacrossifthen**$enteredthen";
	my @splitifandthens = @{splitifsandthens($fixedacrossifthen)};
	
	unless ($thenstatement){
		$thenstatement=$cgithenstatementid;
		#print $thenstatement;
	}
	if ($cgi->param("notthen")){ #if it's a negative - "if not"
		$thenstatement="~$thenstatement";
	}
	if ($directcall==0){
		$finalstatement=substr($finalstatement, 0, -1); #this removes the | placed at the end of the for loop above.  
	}
	
	
	debugout("got here");
	
	#TODO - make princheck work with new system
	#$princheck = checkifprinexists($finalstatement, $thenstatement);
	$princheck = 0;
	#create the principle
	unless ($princheck > 0){
		debugout("got here @premises");
		$laststatement = enterconclusion( \@premises, \@splitifandthens, $cgitruthvalue, 0 );
		#$laststatement = enterstatement($finalstatement, $thenstatement, $cgitruthvalue);
		debugout("got here");
	}else{
		debugout("got here");
		print "Principle already exists <a href = /prin$finalstatement.html>see here</a>";
		die;
	}
	debugout("got here");
	@updates = (@updates, $laststatement);
	debugout("Added principle $laststatement to updates");
	#takes gets the unique updates from @updats.  No idea what %seen is for.
	my %seen;
	my @uniqupdates = grep { ! $seen{$_}++ } @updates; 
	debugout( "updates is @updates, uniqupdateas is @uniqupdates"); 
	
	#split the principle
	foreach my $updateconcl(@uniqupdates){
		TSU($updateconcl);
		debugout("trying to call splitter with $updateconcl");
		conclusion_createsubpages($updateconcl);
		debugout( "got past splitter");
	}
}

sub newstatementmaker($){
	debugout("entering statement");
	my $newstatement=shift;#$cgi->param('newstatement');
	#here, check if has variable
	if ($newstatement =~ /@\d/){ #regular expression thing
	}else{
		print "<br>You need to use a variable in your statement.";
		die;
	}
	if ($newstatement =~ / not /){
		print "Dude, not cool.";
		die;
	}
	if ($newstatement =~ /^if /){
		print "Dude, not cool.";
		die;
	}
	if ($newstatement =~ /^then /){
		print "Dude, not cool.";
		die;
	}
	if ($newstatement =~ /&&/){
		print "A statement has a && in it.  Something has gone horribly awry.";  
		die;
	}
	if ($newstatement =~ /  /){
		print "A statement has a double space in it.  I would just change this to a single space but I don't feel like it.  Enter it again.";  
		die;
	}
	
	$newstatement=~ s/^\s+//; # removes leading spaces
	$newstatement=~ s/\s+$//; # removes trailing spaces
	
	if ($newstatement =~ /[^^]~/ ){ #This means "tilde coming anywhere not at the beginning" (^ is both not (after [) and at the beginning (^ on its own))
		print "Error: ~ must be at beginning of a statement.  You can only make a whole statement negative, not parts.\n"; # do this because don't want people to think they can make a not apply to only part of a statement 
		die; 
	}
	
	$newstatement=~ tr/~//d;# this should remove ~ - do this because ~ is in principle table instead.

	#ensure that the variables are correctly ordered.  Enforcing a common format avoids weird logic problems.
	$newstatement = statementvarfixer($newstatement);
	my @vars = getvarspositions(trim($newstatement));

	# Do a final check to ensure that not already entered:
	$sqlcmd = "SELECT id FROM iostatements WHERE description=?";
	my $existingstmnt = stringreturn_secure( $sqlcmd, $newstatement);#=$sth->fetchrow_array;
	my $insertedstatement = $existingstmnt; #in case it exists already, return the existing id for the principle..
	if ($existingstmnt){
		print "<br>IOStatement not entered because it was detected as existing already.  Click <a href=/prin$existingstmnt.html>here</a> to visit the page for it, if it exists.";
		debugout( "existing statement is $insertedstatement" );
		exit;
	}
	else
	{
		$insertedstatement=returnid_2("INSERT into iostatements(description) values (?)", $newstatement);#$sth->fetchrow_array;
		#enter vars and positions	
		iovar_entervarsandpositions( \@vars, $insertedstatement ); 
	}
	debugout("returning insertedstatement $insertedstatement" );
	return $insertedstatement;
}

if ($depth == 0){
	debugout("ending html, depth is $depth");
	print end_html;
}
$dbh->disconnect ;

