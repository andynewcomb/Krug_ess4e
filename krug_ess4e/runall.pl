##################################################################################
# Generic script to drive other scripts
# Uncomment sections below to run the subscripts
# Most need running only once
##################################################################################

my $inputfile;
my $outputfile;

for $chapter (3) { #(1..16)

    ##################################################################################
    # KEY TERM Processing
    # Generate key terms file from each chapter XML file
    ##################################################################################

    # $inputfile = "XML/0_ch${chapter}_handedit.xml";
    # $outputfile = "keyterms/kt_ch${chapter}.js";

    # print STDERR "\nProcessing Chapter $chapter key terms\n";
    # system("perl keyterms.pl < $inputfile > $outputfile");

	

    ##################################################################################
    # Page Numbering Processing
    # Fix page numbering in XML file IF NEEDED
    ##################################################################################

    # $inputfile = "XML/0_ch${chapter}_handedit.xml";
    # $outputfile = "XML/1_ch${chapter}_clean.xml";

    # system("perl page_nums.pl < $inputfile > $outputfile");

    # print STDERR "$outputfile written (page_nums.pl)\n";

    # print STDERR "\n";
    
    
    
    ##################################################################################
    # Fix inline links
    ##################################################################################

    $inputfile = "XML/0_ch${chapter}_handedit.xml";
    $outputfile = "XML/1_ch${chapter}_links.xml";

    system("perl fix_links.pl < $inputfile > $outputfile");

    print STDERR "$outputfile written (fix_links.pl)\n";

    print STDERR "\n";
}
