#!/usr/bin/perl

# This script may be used to run all other processing scripts for the krugmanwellsessentials4e project
# Notes will be made with each subscript which will state their function, inputs and outputs,
# and possible removal (commenting out) from the chain of scripts

my $inputfile;
my $outputfile;

for $chapter (3) { #(1..14) {
	
	print STDERR "CHAPTER $chapter\n";
	
#####################################################################################
# Run page numbering script
#####################################################################################

$inputfile = "XML/0_ch${chapter}_handedit.xml";
$outputfile = "XML/1_ch${chapter}_clean.xml";

system("perl page_nums.pl < $inputfile > $outputfile");

print STDERR "$outputfile written (page_nums.pl)\n";

print STDERR "\n";
}


