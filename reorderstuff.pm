#!/usr/bin/perl
#reorderstuff.pm

package reorderstuff;
use strict;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(reorderprins reordersinglestatement);
use stringutil;
use debugout;
use Carp;
use CGI::Carp 'fatalsToBrowser';
use varfixer;


sub reorderprins($$){
# make && statements ordered with first prin first (to avoid duplicates)
	my $esfinalstatement = (shift);
	my $esthenstatement = (shift);
	if ($esfinalstatement =~ /\|/){
		my @essplitif = split(/\|/, $esfinalstatement);
		if ($essplitif[1]<$essplitif[0]){
			$esfinalstatement = "$essplitif[1]|$essplitif[0]";
			debugout("Reformulated if, checking again if exists");
			if (checkifprinexists($esfinalstatement, $esthenstatement)){  #Recheck if exists because now different
				return; #for now just exits, should eventually return error explaining why not working. 
			};
		}
	}
	if ($esthenstatement =~ /\|/){ #for now, && thenstatements should only be entered by implication handler.
		my @essplitthen = split(/\|/, $esthenstatement);
		if ($essplitthen[1]<$essplitthen[0]){
			$esthenstatement = "$essplitthen[1]|$essplitthen[0]";
			debugout("Reformulated then, checking again if exists");
			if (checkifprinexists($esfinalstatement, $esthenstatement)){  #Recheck if exists because now different
				return; #for now just exits, should eventually return error explaining why not working. 
			};
		}
	}
}

sub reordersinglestatement($){
	my $esfinalstatement = (shift);
	if ($esfinalstatement =~ /\|/){
		my @essplitif = split(/\|/, $esfinalstatement);
		if ($essplitif[1]<$essplitif[0]){
			$esfinalstatement = "$essplitif[1]|$essplitif[0]";
					
		}
	}
	return $esfinalstatement;
}


1;
