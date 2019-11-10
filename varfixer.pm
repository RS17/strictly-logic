#!/usr/bin/perl

use cPanelUserConfig; 
#varfixer.pm

package varfixer;

use stringutil;
use List::MoreUtils 'first_index', 'uniq';
use Exporter;
use debugout;
use getenglish;
use strict;
use warnings;
#use CGI::Inspect;

our @ISA = qw(Exporter);
our @EXPORT = qw(statementvarfixer variableincrements checkvariablematch
				getvarspositions splitifsandthens );

sub statementvarfixer($)
{
	#takes statement apart, changes the vars, puts it back together 
	#again hopefully sort of like it was originally, because that's important.
	my $origstatement = shift;							#@1 is a @2 thing
	my @origstatementnovars;
	my @uservars;
	my $uservar;
	my $novarstring;
	my @statementarray;
	my $statementbit;
	my @splitorig = split('@', $origstatement);
	my $frontbit = shift(@splitorig);					#pops anything before first @
	foreach(@splitorig)									#1 is a |2 thing
	{				
		$statementbit = $_	;							#1 is a
		$novarstring = "";
		if (not trim($statementbit) eq "")
		{ 				
			@statementarray = split(' ', $statementbit);
			$uservar = shift(@statementarray);     #pops front of array leaving novars string as array of spaced words - is|a
			@uservars = (@uservars, $uservar);    #uservars = 1
			foreach (@statementarray){
				$novarstring = "$novarstring $_";				#is a
			}
			$novarstring = "$novarstring ";
			@origstatementnovars = (@origstatementnovars, $novarstring); #is a thing
		}
	};

	my $newstatement = $frontbit;
	my $thevar;
	my $anindex = 0;
	my $allowedvarlevel=0; 						#must be in order from left to right.
	my %processedvars;
	my $ispoisoned = 0;							#if any variable is out of order, all remaining is poisoned (must be auto-handled)
	foreach(@uservars){   						#so look at each variable.
		my $origvar = $_;
		$thevar = $_;							#1		
		if ($processedvars{$thevar} )			#if seen it already, assign it to what assigned it to already, 
		{
			$thevar = $processedvars{$thevar};
		}
		elsif( $thevar > $allowedvarlevel or $ispoisoned )			#but variables we haven't seen can be at most 1 more than what is already.
		{										#what's to the left of it it's invalid #so make it one above what's to the left of it instead.
			$thevar = $allowedvarlevel+1;			
			$allowedvarlevel = $allowedvarlevel+1;
			$ispoisoned = 1;
		}
		$processedvars{$origvar}=$thevar;
		#now we have to push it back onto the statement
		$newstatement = "$newstatement\@$thevar$origstatementnovars[$anindex]";
		$anindex++;
	}
	return trim($newstatement);
	
}

sub variableincrements($){
	#returns some sort of string including variable increments to be added to statements in principle
	my $fixedifthen = (shift);
	my $incrementstring = "";
	my $number;
	my $increment;
	my $iforthen;
	my @vararray;
	debugout("\n got here with $fixedifthen");
	foreach( split( '\*\*', $fixedifthen ) ){  #splits the if an then
		$iforthen = $_;
		debugout("\n got here with $iforthen");
		my @splitarray = split( '\|\|', $iforthen );
		shift (@splitarray);
		foreach( @splitarray ){	 #splits each statement within if or then, discarding first
			@vararray = split( " ", $_ );
			$number = shift( @vararray );  #@1
			$number =~ s/[^0-9]/ /go;		#1
			$increment = $number - 1;
			$incrementstring = "$incrementstring$increment||";
		}
		$incrementstring = "$incrementstring$increment**";
	}
	return $incrementstring;
}

sub getthevars($) 
{
	my $origstatement = shift;							#@1 is a @2 thing
	my @origstatementnovars;
	my @uservars;
	my $uservar;
	my $novarstring;
	my @statementarray;
	my $statementbit;
	my @splitorig = split('@', $origstatement);
	my $frontbit = shift(@splitorig);					#pops anything before first @
	foreach(@splitorig)									#1 is a |2 thing
	{				
		$statementbit = $_	;							#1 is a
		$novarstring = "";
		if (not trim($statementbit) eq "")
		{ 				
			@statementarray = split(' ', $statementbit);
			$uservar = shift(@statementarray);     #pops front of array leaving novars string as array of spaced words - is|a
			@uservars = (@uservars, $uservar);    #uservars = 1
			foreach (@statementarray){
				$novarstring = "$novarstring $_";				#is a
			}
			$novarstring = "$novarstring ";
			@origstatementnovars = (@origstatementnovars, $novarstring); #is a thing
		}
	};
	my $varstring = "";
	foreach(@uservars)
	{
		$varstring = "$varstring.$_";
	}
	return $varstring;
}


sub checkvariablematch($$){
		my $ifstatement = shift;
		my $thenstatement = shift;
		
		#get the statements
		my @ifarray = getenglishfromiforthen($ifstatement);
		my @thenarray = getenglishfromiforthen($thenstatement);

		#extract the vars on each side.  This is ugly but fuck regex.
		my @ifvars;
		my @thenvars;
		my @temparray;
		foreach(@ifarray){
			foreach(split("@", $_)){
				@temparray = split(" ", $_);
				@ifvars = (@ifvars, $temparray[0])
			};
		}
		foreach(@thenarray){
			foreach(split("@", $_)){
				@temparray = split(" ", $_);
				@thenvars = (@thenvars, $temparray[0])
			};
		}

		#my @ifvars = grep {s/[^\s]+//} @ifarray;  #fuuuuuuuuuuu...
		#my @thenvars = grep {s/[^\s]+//} @thenarray;
		
		#if all the vars on the if side match the then side and vice versa, is valid.  Otherwise, not valid.
		my $thethingimmatching;
		my $matchindex;
		my $thenindex;
		
		#convert both arrays to string for comparison (no way to just compare arrays efficiently in perl)
		my $stringifvars = join("|", uniq sort(@ifvars));
		my $stringthenvars = join("|", uniq sort(@thenvars));
		#inspect();
		if (not $stringifvars eq $stringthenvars){
			return 0;
		}
		
		
		#foreach(@ifvars){
		#	$thethingimmatching = $_;
		#	my $matchindex = first_index{ /$thethingimmatching/ } @thenvars;
		#	#inspect();
		#	if ($matchindex == -1 ){ return 0; } #assuming -1 is no match, don't really know that.
		#	$thenindex = 0;
		#	my @nextthenarray;
		#	foreach (@thenvars) #want to delete all matches, not just the index
		#	{ 
		#		if (not $_ eq $thethingimmatching)
		#		{
		#			@nextthenarray = (@nextthenarray, $_);
		#		}
		#	}
		#	my @thenvars = @nextthenarray;
		#}
		
		return 1;		
}

sub getthevarscorrectly($)
{
	my $iostatement = shift;
	my @positions;
	my @vars;
	while( $iostatement =~ /@/gi )
	{
		my $spot = pos($iostatement);
		@vars = (@vars, substr( $iostatement, $spot, 1 ) );
	}
	return uniq sort @vars;
}

sub getvarspositions($)
{
	my $iostatement = shift;
	my @retarray;
	my @vars = &getthevarscorrectly($iostatement);
	my @posarray;
	my $searchstr;
	while( my $var = pop @vars )
	{
		$searchstr = '@';
		$searchstr = "$searchstr$var";
		@posarray = ($var, &getthepositions($iostatement, "$searchstr" ) );
		@retarray = (@retarray, [@posarray] );
	}
	return @retarray;
}

sub splitifsandthens($)
{
	#returns array of arrays - 1st array is ifs, second array is thens
	my $fullifthen = shift;
	my @ifthenarr;
	foreach my $splitifthen( split('\*\*', $fullifthen) )
	{
		my @statementarr;
		foreach my $statement( split('\|\|', $splitifthen ) )
		{
			@statementarr = (@statementarr, $statement );
		}
		@ifthenarr = (@ifthenarr, [@statementarr] );
	}
	return \@ifthenarr;
	
}

1;

