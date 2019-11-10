#!/usr/bin/perl
#iostatement.pm

package iostatement;

use stringutil;
use Exporter;
use debugout;
use strict;
use warnings;
use sqlhandler;
use Carp;
#use CGI::Inspect;


our @ISA = qw(Exporter);
our @EXPORT = qw( premise_create premise_createhash premise_buildhash 
				 premise_getfromiovarshift premise_getfromiovarshiftarray
				 premise_getioshiftvalue premise_returnonlytype premise_getvalue
				 premise_buildhashwshift premise_createhashwshift premise_getiovalconclhash
				 premise_iovalconclhashbuild premise_getallconclusions);
				

sub iostatement_getconclusions($)
{
	my $iostatementid = shift;
	my $sql = "select p.conclusion_id from iostatements i join ioshift s on i.id = s.iostatement_id join ioshiftvalue v on v.ioshift_id = s.id join premise p on p.ioshiftvalue_id = v.id  where i.id = $iostatementid;";
	my @val = arrayofresults($sql);
	return @val;
}
