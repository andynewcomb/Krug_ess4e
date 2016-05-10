#!/usr/bin/perl

# This script produces
use utf8;
use strict;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

###################################
# From original process_xml.pl

# GLOBALS that may be useful

my $BOOK_ID = "krugmanwellsessentials4e";
my $PUBLISHER = "fw";
my $CHAPTER;
my $CHAPTER_TITLE;

if ($BOOK_ID eq "") {
    print STDERR "Please set the BOOK_ID variable in this script\n";
    exit();
}
if ($PUBLISHER ne "bsm" && $PUBLISHER ne "fw") {
    print STDERR "Please set the PUBLISHER variable in this script to either 'bsm' or 'fw'\n";
    exit();
}

# print STDERR "BOOK_ID: $BOOK_ID, ";
# print STDERR "PUBLISHER: $PUBLISHER\n";

###################################
# get entire contents of file into single line: $contents
my $contents;
my $temp_line;
while ($temp_line = <STDIN>) {
    chomp($temp_line);

    # remove all <xml> lines
    $temp_line =~ s`<\?xml [^>]+>``g;
    # remove <manuscript> lines from start and end
    $temp_line =~ s`<(\/)?manuscript( [^>]+)?>``g;

    $temp_line =~ s/[\t\r\n]//g; #remove tabs, line feeds, returns
    $temp_line =~ s/[ ]{2,}/ /g; # remove multiple spaces
    $temp_line =~ s/^\s+//; # remove leading spaces
    $contents .= $temp_line;
}

$_ = $contents;


# At this point, the xml from the file is now one big string with no newlines


# Get chapter info/check for start-numbering-at
s`<chapter ([^>]+)>`"<chapter " . get_chapter_info($1) . ">"`e;

# print STDERR "Clean\n  Chapter: $CHAPTER, $CHAPTER_TITLE\n";

sub get_chapter_info {
    my $tag = shift;

    ($CHAPTER_TITLE) = $tag =~ /title="([^"]+)"/;
    ($CHAPTER) = $tag =~ /number="(?:ch)?(?:[0]+)?(\d+)"/i;

    if ($CHAPTER_TITLE eq "") {
	print STDERR "Can't find chapter title\n";
	exit();
    }
    if ($CHAPTER eq "") {
	print STDERR "Can't find chapter number\n";
	exit();
    }

    # If chapter does not have start-numbering-at attribute then add it
    if ($tag !~ /start-numbering-at/) {
	$tag .= qq` start-numbering-at="${CHAPTER}"`;
    }
    # Otherwise, make sure start-numbering-at is the same as chapter number
    else {
	$tag =~ s`start-numbering-at="[^"]+"`start-numbering-at="${CHAPTER}"`;
    }

    return $tag;
}


# PAGE NUMBERS begin
my $LAST_PAGE; # last page number seen in section
my %PAGE_NUMBERS;
my %PRINT_PAGE;
my %PAGE_START;
# Set this to 1 if you want the new page number checking, otherwise 0.
# If your book does not have page numbers definitely set this to 0.
my $ENABLE_PAGE_NUMBER_CHECKING = 1;

# PAGE NUMBERS end





# PAGE NUMBERS begin
# Sometimes the vendor uses page-start instead of page_start
if ($ENABLE_PAGE_NUMBER_CHECKING) {
  s`block_type="page-start"`block_type="page_start"`g;
  # Fix page_start IDs
  s`<p ([^>]+)?block_type="page_start"([^>]+)?>(.*?)</p>`"<p id=\"${BOOK_ID}_page_${3}\" block_type=\"page_start\"${2}>${3}</p>" . add_page_start($3)`ge;
}

sub add_page_start {
    my $page = shift;
    $PAGE_START{$page} = 1;
    return "";
}
# PAGE NUMBERS end

# BEGINNING THE PROCESS FUNCTIONS
# This script is designed to cycle through all the major elements in the xml file.
# For each element there is a corresponding "process" function where you can add your
# custom code.


# "pre-process" sections
# Anything you need to do to a section before you begin processing the elements
# within that section goes in the pre_process_section function
s`<section ([^>]+)>(.*?)</section>`pre_process_section($1, $2)`ge;

sub pre_process_section {
    my $args = shift; # attributes on the <section> tag
    my $content = shift; # content of section

    my ($section_id) = $args =~ /id="([^"]+)"/;
    
    # Fix title if there are inline tags (e.g. {em})
    if ($args =~ /title="([^"]+)"/ && $content !~ /<section-metadata>/) {
	my $title = $1;

	if ($title =~ /\{[^}]+\}/) {
	    $title =~ s`\{([^}]+)\}`<${1}>`g;
	    $content = "<section-metadata><section-title>${title}</section-title></section-metadata>" . $content;
	    $args =~ s`title="[^"]+"`title=""`;
	}
    }

    # PAGE NUMBERS begin
    # Process the page numbers in the section, adding the print_page
    # attribute if needed
    if ($ENABLE_PAGE_NUMBER_CHECKING) {
      if ($content =~ /^(<section-metadata>.*?<\/section-metadata>)?<p ([^>]+)?block_type="page_start"([^>]+)?>(.*?)<\/p>/) {
        $LAST_PAGE = $4;
        $args =~ s`\s*print_page="[^"]*"``;
        $args .= qq` print_page="${LAST_PAGE}"`;
	#print STDERR "NOTICE: section ID $section_id is at the beginning of page $LAST_PAGE, setting print_page to $LAST_PAGE\n";
      }
      
      my ($print_page) = $args =~ /print_page="([^"]+)"/;
      
      # If print_page does not exist then set it to LAST_PAGE 
      if ($print_page eq "") {
        if ($LAST_PAGE ne "") {
	  $args =~ s`\s*print_page="[^"]*"``;
	  $args .= qq` print_page="${LAST_PAGE}"`;
	  $print_page = $LAST_PAGE;
	  #print STDERR "NOTICE: section ID $section_id did not have print_page attribute, setting to ${LAST_PAGE}\n";
        }
        else {
	  print STDERR "ERROR: section ID $section_id does not have print_page set\n";
        }
      }
      else {
        # print_page was included in XML - if we don't have a page_start for the 
        # print_page then assume this is the beginning of a new page and add it
        if (!exists($PAGE_START{$print_page})) {
	  if ($content =~ /<\/section-metadata>/) {
	    $content =~ s`</section-metadata>`</section-metadata><p id="${BOOK_ID}_page_${print_page}" block_type="page_start">${print_page}</p>`;
	  }
	  else {
	    $content = "<p id=\"${BOOK_ID}_page_${print_page}\" block_type=\"page_start\">${print_page}</p>" . $content;
	  }
	  add_page_start($print_page);
	  $LAST_PAGE = $print_page;
        }
      }
      
      if ($print_page ne "") {
        $PRINT_PAGE{$print_page} = 1;
      }
      
      # Theoretically, the print_page attribute should match up with LAST_PAGE, but there
      # may be instances where it doesn't so don't fix, just send a warning
      if ($print_page ne "" && $LAST_PAGE ne "" &&  $print_page ne $LAST_PAGE) {
        print STDERR "WARNING: section ID $section_id has possible bad print_page (current = $print_page, possibly should be $LAST_PAGE)\n";
      }
    }
    # PAGE NUMBERS end


    # Your custom code goes below



    # PAGE NUMBERS begin
    # Last thing to do - set $LAST_PAGE
    if ($ENABLE_PAGE_NUMBER_CHECKING) {
      if ($args =~ /print_page="([^"]+)"/) {
        $LAST_PAGE = $1;
      }
      $content =~ s`(<p .*?block_type="page_start".*?>(.*?)</p>)`$1 . set_last_page($2, $section_id)`ge;
    }
    # PAGE NUMBERS end

    return qq`<section ${args}>${content}</section>`;
}
# PAGE NUMBERS begin
# Set the LAST_PAGE variable (only page_starts should be passed into this)
sub set_last_page {
    my $page = shift;
    my $sec_id = shift;

    if ($LAST_PAGE =~ /^\d+$/ && $page =~ /^\d+$/) {
	if ($page < $LAST_PAGE) {
	    print STDERR "WARNING: page_start number $page falls after page_start number $LAST_PAGE in section ID $sec_id\n";
	}
    }

    if (exists($PAGE_NUMBERS{$page})) {
	if ($PAGE_NUMBERS{$page} ne $sec_id) {
	    print STDERR "ERROR: Duplicate page_start number $page in sections $sec_id and $PAGE_NUMBERS{$page}\n";
	}
	else {
	    print STDERR "ERROR: Duplicate page_start number $page in section $sec_id\n";
	}
    }
    else {
	$PAGE_NUMBERS{$page} = $sec_id;
	$LAST_PAGE = $page;
    }
    
    return "";
}
# PAGE NUMBERS end





# PAGE NUMBERS begin
if ($ENABLE_PAGE_NUMBER_CHECKING) {
  check_page_numbers();
}

sub check_page_numbers {
    my $num;
    my $prev_page;
    my $error = 0;
    my $first;
    my $last;

    foreach $num (sort {$a<=>$b} keys %PRINT_PAGE) {
        if (!exists($PAGE_START{$num})) {
            print STDERR "ERROR: no page_start found for page $num\n";
        }
    }

    foreach $num (keys %PAGE_NUMBERS) {
        # first get rid of all non-numeric page numbers
        if ($num !~ /^\d+$/) {
            delete($PAGE_NUMBERS{$num});
        }
    }
    # now go through them and make sure we aren't missing any
    foreach $num (sort {$a<=>$b} keys %PAGE_NUMBERS) {  
        if ($prev_page eq "") {
            # do nothing, this is the first page_start number
            $first = $num;
        }
        # if we skipped one page
        elsif ($num == ($prev_page + 2)) {
            print STDERR "ERROR: no page_start found for page " . ($prev_page + 1) . "\n"; 
            $error = 1;
        }
        elsif ($num > ($prev_page + 2)) {
            print STDERR "ERROR: " . (($num - $prev_page) - 1) . " page_start numbers missing between " . $prev_page . " and " . $num . "\n";
            $error = 1;
        }  
        $prev_page = $num;
        $last = $num;
    }
    
    if (!$error && $first && $last) {
        print STDERR "INFO: Consecutive print_page numbers found from $first to $last\n";
    }
}
# PAGE NUMBERS end






###################################
# SECTION level transformations

# fix section links
# <link href="gore1e-ch01.xml#gore1e-ch01-sec1-001">
# s/(<link href=")gore1e-ch\d+\.xml#(gore1e-ch\d+-sec\d+-\d+">)/$1$2/g;

# level 2 sections should not be their own sections
# no action needed - *** Note that the <section> tag has been left in place, not changed to <p> or <phrase>
# while (s/<\/section>\s*<section[^>]+(id="[^"]+")[^>]+level="2"[^>]*>\s*<section-metadata><section-title>([^<]+)<\/section-title><\/section-metadata>(.*?)<\/section>/<box block_type="h2"><p $1 block_type="cr-h2">$2<\/p>$3<\/box><\/section>/sg) {}

###################################
# Image Conversions

# first convert original image file names to renamed versions
# also add on correct DF file path
# GOR_01236_03_F05.jpg ----> fig_ch3_5.jpg
# GOR_01236_03_U01.jpg ----> unfig_ch3_1.jpg
# GOR_01236_03_P05.jpg ----> photo_ch3_5.jpg
    
# numbered figures
# s/src="GOR_01236_0?(\d+)_F0?(\d+)(a)?\.jpg/src="asset\/ch$1\/fig_ch$1_$2$3.jpg/gi;
# unnumbered figures
# s/src="GOR_01236_0?(\d+)_U0?(\d+)\.jpg/src="asset\/ch$1\/unfig_ch$1_$2.jpg/gi;
# photos
# s/src="GOR_01236_0?(\d+)_P0?(\d+)(a)?\.jpg/src="asset\/ch$1\/photo_ch$1_$2$3.jpg/gi;

# HANDEDITTED FOR NOW - FIX LATER
# move captions to top of figures
# while (s/<figure([^>]+>)(.*?)<\/figure>/<fig39yur$1$2<\/fig39yur>/s) {
    # my $figcontents = $1;
    # $figcontents =~ s/(.*?)(<image[^>]+>)(<caption>.*?<\/caption>)(.*)/$1$3$2$4/s;
    # print STDERR "image = $2\ncaption = $3\n";
    # exit();
# }
# restore figure tags
# s/fig39yur/figure/g;

# Fix figure caption
# remove Figure numbers from text part of captions
# s/(<caption><strong>)FIGURE [\d\.]+ /$1/g;

###################################
# Table Conversions
# caption-placement must be "Top", not "top"
# s/caption-placement="top"/caption-placement="Top"/g;

###################################
# Fix footnote references: link -> termref
# s`<link href="gore1e-notes.xml#gore1e-notes-p\d+"><sup>(\d+)</sup></link>`<termref term="fn_ch${CHAPTER}_$1"><sup>$1</sup></termref>`gi;

###################################
# Fix key term references -- lc($1) with /e doesn't seem to work
# first 7 chapters
# s`<phrase block_type="kt"><link href=[^>]+><strong>([^<]+)</strong></link></phrase>`<termref term="\l$1">$1</termref>`gi;
# last 7 chapters flip outer phrase with inner link
# s`<link href=[^>]+><phrase block_type="kt"><strong>([^<]+)</strong></phrase></link>`<termref term="\l$1">$1</termref>`gi;

###################################
# Fix inline text references for figures
#
# s`(<link href=)[^>]+>(Figure (\d+)\.(\d+)<\/link>)`$1"asset/ch$3/fig_ch$3_$4.html">$2`gi;

###################################
# Fix inline text references for tables
#
# s`<link href="[^"]+(">Table (\d+)\.(\d+))<\/link>`<phrase block_type="tbl_link" data-url="asset/ch$2/table_$2_$3.html$1</phrase>`gi;

# NOTE: Implement when info available
# s`<link href="#?ch0*(\d+)-tab-0*(\d+)">(Table \d+)<\/link>`<phrase block_type="tbl_link" data-url="asset/ch$1/supp_wins/tables/table_$1.$2.html">$3</phrase>`gi;

###################################
# Force inline text reference targets to pop
# s`<link href="asset`<link target="_pop" href="asset`gi;


##################################################################################
# Generate footnotes file from section in XML
##################################################################################

# if (s/(<section[^>]*>\s*<section-metadata>\s*<section-title>\s*<phrase block_type="section_title">[^<]*<\/phrase>\s*<\/section-title>\s*<\/section-metadata>\s*<p[^>]*><phrase[^>]*block_type="footnote".*?<\/section>)//s) {
    # my $fn_section = $1;
    # my $fn_file_contents = '';
    
    # while ($fn_section =~ s`<p id="(\w+)"><phrase block_type="footnote"><sup>[^<]+</sup></phrase>\s?(.*?)</p>``s) {
	    # my $fn_num = $1;
	    # my $fn_text = $2;
	    # # print STDERR "$fn_num => $fn_text\n";
	    # $fn_file_contents .= "xBookUtils.terms['" . $fn_num . "'] = '" . "$fn_text" . "';\n";
    # }
    
    # # now output footnotes to file
    # open my $fn_fh, ">footnotes/ch${CHAPTER}_footnotes.js" or die;
    # print $fn_fh $fn_file_contents;
    # close $fn_fh;
# }

##################################################################################
# Miscellaneous modifications
##################################################################################

###################################
# Final output of processed file

# add new lines back in to xml
s`(<(rawhtml|chapter|section|box|layout|table|tbody|tr|list|figure|layout|question|image|asset_source)(/| [^>]+)?>)`\1\n`g;
s`(</(metadata|p|div|table|tr|td|list|li|box|question|query|tbody|th|rawhtml|caption|figure|section-metadata)>)`\1\n`g;
s`</section>`</section>\n`g;
s`</rawhtml>`\n</rawhtml>`g;


### print out the xml ###

print $_, "\n";