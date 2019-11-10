#!/usr/bin/perl
#test.pl

#run tests here.

use warnings;
use diagnostics;
use varfixer;
use implicationhandler;
use sqlhandler;
use conclusion;
use premise;
use iovar;
use iovarposition;
use linkfinder;
use conjunction;
use CGI::Inspect;
use ioshiftvalue;
use transitive;
use transitiveimplication;
use stringutil;
use getenglish;
use createstatementpage;
use truthstatusupdater;
use ioshiftvar;
use transpremhash;
use logichelper;
use debugout;

#samples:
$debugmode = 1;
# 1472 -> 1473 && 1474

#original test



my %conclprems = conclusion::conclusion_getwithpremises(1488);
	my @premises = @{($conclprems{'premises'})};
	my @conclusions = premise_returnonlytype( \@premises, 'C' ); 
	my @ifs = premise_returnonlytype(\@premises, 'I');
	
	#conjunction 
	my @newconcls = transitiveimplication_checkcreate( 1488, \@ifs, \@conclusions );
	debugout( scalar(@newconcls));
debugout( getenglishfromconcl(1488));
inspect();


#print( getenglishfromconcl(1425));
#my @arr = linkfinder_findallsinglethens_openif(666);
#foreach my $val(@arr){
#	print( $val);
#}
#print ioshiftvalue_getiostatementid( 255 );
#print ioshiftvar_getshiftdiff( 250, 255 );
#print alltherules2(1090);
