#!/usr/bin/perl

use strict;

# This script will create the page number mappings you need to put in links.js.

# See https://macmillanhighered.atlassian.net/wiki/display/MP/Adding+page+numbers+to+e-Book+pages for more details.

# HOW TO USE THIS SCRIPT

# 1. Create a directory specifically for your book's html files and place this
#    script in that directory.

# 2. In that same directory, create a file named config.txt and add the following to
#    to the file:
#    a. On the first line, add BOOKID:book_id, where book_id is the ID of your book
#    b. On the following lines, add the manuscript names for your book in the order
#       they appear in the print book (i.e. page number order).  For example:
#
#       BOOKID:morris2e
#       morris2e_ch1
#       morris2e_ch2
#

# 3. Do a "pre-publish all" on your book to generate a fresh zip file (you should
#    do this each time before you run this script).

# 4. Download the zip file into the directory you created in 1 and unzip.

# 5. Run the script and direct the output to a file:
#
#    ./create_page_number_map.pl > mapping.txt
#
#    The contents of that file can be copy/pasted into your links.js file.   

# Apply steps 3-5 each time you make updates to page numbers in the book.

# You can also run this script to test for warnings as follows:

#  ./create_page_number_map.pl -test

# Running it as a test will only show you warnings, it will not output the page
# number mappings.

my $BOOK_ID;
my @MANUSCRIPTS;

my $TEST = 0;

if ($ARGV[0] eq "-test") {
    $TEST = 1;
    print STDERR "Running in test mode\n";
}


if (!open(CONF, "<config.txt")) {
    print STDERR "Can't read config.txt: $!\n";
    exit();
}
my $line = <CONF>;
chomp($line);
if ($line !~ /BOOKID:\s*(\S+)/) {
    print STDERR "ERROR: First line of config.txt must set BOOKID\n";
    exit();
}
$BOOK_ID = $1;
while ($line = <CONF>) {
    chomp($line);
    if ($line =~ /^\s*(\S+)(_\d+\.html)?/) {
	push(@MANUSCRIPTS, $1);
    }
}

opendir(DIR, ".") or die "can't read this dir: $!\n";
my @files = grep /\.html$/, readdir DIR;
closedir(DIR);

my %files;

my $f;
for $f (sort @files) {
    $files{$f} = 1;
}

my $i;
my $j;
my $filename;
my @fake_files;
my $manuscript;
my $line;
my $curr_sec_id = "";
my $curr_sec_level;
my %PRINT_PAGE_NUM;
my %PRINT_PAGE_ALPHA;
my %PAGE_START_NUM;
my %PAGE_START_ALPHA;
my $print_page_num;
my $page_start_num;
my $level;
my $num;
my $alpha;
my $prev_manuscript;
my $curr_file;
my $last_print_page = "";

# go through each manuscript
for ($i = 0; $i < scalar(@MANUSCRIPTS); $i++) {

    # go through each html page in the manuscript
    for ($j = 1; 1; $j++) {

	my $print_page_num_set = 0;
	
	$filename = $MANUSCRIPTS[$i] . "_" . $j . ".html";

	# if the curr_file doesn't exist then we are done
	if (!-e $filename) {
	    last;
	}
	
	#print STDERR "Processing $filename...\n";
	
	$manuscript = $MANUSCRIPTS[$j];

	if (!open(FILE, "<$filename")) {
	    print STDERR "Can't open $filename: $!\n";
	    exit();
	}
	
	while ($line = <FILE>) {
	    
	    if ($line =~ /<div data-type="section"/) {
		$line =~ / id="([^"]+)"/;
		$curr_sec_id = $1;
		$line =~ / level="(\d)"/;
		$level = $1;
		
		if ($line !~ /print_page="([^"]+)"/) {
		    print STDERR "ERROR: section ID $curr_sec_id in $filename does not have print_page attribute set\n"; 
		}
		else {
		    $print_page_num = $1;
		    if ($print_page_num =~ /^\d+$/) {
			if (!$print_page_num_set) {
			    $PRINT_PAGE_NUM{$print_page_num} = $filename;
			    $print_page_num_set = 1;
			}
			if ($last_print_page ne "") {
			    if ($print_page_num < $last_print_page) {
				if ($TEST) {
				    print STDERR "WARNING: section $curr_sec_id, print_page is less than previous section print_page\n";
				}
			    }
			}
			$last_print_page = $print_page_num;
		    }
		    else {
			$PRINT_PAGE_ALPHA{$print_page_num} = $filename;
		    }
		}
		
		$line =~ / level="(\d)"/;
		$curr_sec_level = int($1);
	    }
	    
	    if ($line =~ /<div[^>]*data-block_type="page_start"[^>]*><p>(.*?)<\/p><\/div>/) {
		$page_start_num = $1;
		
		#print STDERR "Found page_start $page_start_num\n";
		
		if ($page_start_num =~ /^\d+$/) {
		    if (exists($PAGE_START_NUM{$page_start_num})) {
			print STDER "ERROR: page_start $page_start_num already found in $PAGE_START_NUM{$page_start_num}\n";
		    }
		    else {
			$PAGE_START_NUM{$page_start_num} = $filename;
		    }
		}
		else {
		    if (exists($PAGE_START_ALPHA{$page_start_num})) {
			print STDER "ERROR: page_start $page_start_num already found in $PAGE_START_ALPHA{$page_start_num}\n";
		    }
		    else {
			$PAGE_START_ALPHA{$page_start_num} = $filename;
		    }
		}  
	    }
	} # end while
	
	close(FILE);
	
    } # end inner for
    
} # end outer for


# print out numbered pages

my $last_page = "";

foreach $num (sort { $a <=> $b } keys %PAGE_START_NUM) {

    if ($last_page ne "") {
	if ($num > ($last_page + 1)) {
	    if ($TEST) {
		print STDERR "WARNING: page_starts jumped from $last_page to $num\n";
	    }
	}
    }

    if (!$TEST) {
	if (exists($PRINT_PAGE_NUM{$num})) {
	    print qq`xBookUtils.links['page_${num}'] = {href: '$PRINT_PAGE_NUM{$num}'};\n`;
	}
	else {
	    print qq`xBookUtils.links['page_${num}'] = {href: '$PAGE_START_NUM{$num}#${BOOK_ID}_page_${num}'};\n`;
	}
    }
	
    $last_page = $num;
}


foreach $alpha (sort keys %PAGE_START_ALPHA) {

  if (!$TEST) {
    if (exists($PRINT_PAGE_ALPHA{$alpha})) {
      print qq`xBookUtils.links['page_${alpha}'] = {href: '$PRINT_PAGE_ALPHA{$alpha}'};\n`;
    }
    else {
      print qq`xBookUtils.links['page_${alpha}'] = {href: '$PAGE_START_ALPHA{$alpha}#${BOOK_ID}_page_${alpha}'};\n`;
    }
  }

  $last_page = $num;
}