##################################################################################
# Generate key terms file from each chapter XML file
##################################################################################

my $inputfile;
my $outputfile;

for $chapter (5) { #(1..16)
    $inputfile = "xml/0_ch${chapter}_handedit.xml";
    $outputfile = "keyterms/kt_ch${chapter}.js";

    print STDERR "\nProcessing Chapter $chapter key terms\n";
    system("perl keyterms.pl < $inputfile > $outputfile");
}