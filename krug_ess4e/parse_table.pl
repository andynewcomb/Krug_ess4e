#!/usr/bin/perl -w

# Note that tables may contain other boxes, such as figures, images, and tables

use strict;

my $chapter = shift @ARGV;

my $htmlfile = "html/all_ch${chapter}.html";

# supplemental window skeleton code
my $supp_win = "<!DOCTYPE HTML>
<html>
<head>
    <meta charset=\"utf-8\">
    <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge,chrome=1\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>DL_REPLACE_TITLE</title>
    <link href=\"../../../css/boilerplate.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../css/jquery-ui-custom.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../css/manuscript.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../css/digfir_ebook_fw.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../css/krugmanwellsessentials4e.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../css/krugmanwellsessentials4e_ch${chapter}.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
</head>
<body id=\"supp_win\">
    <div id=\"manuscript\" data-chapter-number=\"2\">
        <div data-type=\"section\" id=\"krugmanwellsessentials4e_supp_win_sec\" class=\"table\" level=\"1\">


    DL_REPLACE_HTML


        </div>
    </div>
    
    <script type=\"text/javascript\" src=\"../../../js/utilities.js\"></script>
    <script type=\"text/javascript\" src=\"../../../js/query_types.js\"></script>
    <script type=\"text/javascript\" src=\"../../../js/player.js\"></script>
    <script type=\"text/javascript\" src=\"../../../js/jquery.js\"></script>
    <script type=\"text/javascript\" src=\"../../../js/jquery-ui-1.8.16.custom.min.js\"></script>
    <script type=\"text/javascript\" src=\"../../../js/jquery_extensions.js\"></script>
    <script type=\"text/javascript\" src=\"../../../js/swfobject.js\"></script>
    <script type=\"text/javascript\" src=\"http://admin.brightcove.com/js/BrightcoveExperiences.js\"></script>
    <script type=\"text/javascript\" src=\"../../../js/digfir_ebook_fw.js\"></script>
    <script type=\"text/javascript\" src=\"../../../js/krugmanwellsessentials4e.js\"></script>
    <script type=\"text/javascript\" src=\"../../../js/krugmanwellsessentials4e_ch${chapter}.js\"></script>
    <script type=\"text/javascript\">

    //<!--
    \$(window).ready(function () {
            player.initialize('52c6e83c757a2ef70c000000');
    });
    //-->
</script>
</body>
</html>";

# read in the HTML file
open my $fh, "<$htmlfile" or die;
my @html_lines = <$fh>;
close $fh;

# now collapse lines array into a single string
my $html_line = "@html_lines";

# show all table divs, both numbered and unnumbered

my $table_cnt = 0;
my @table_divs;

# get all numbered tables
while ($html_line =~ s/(<div .*?data-type=\")table/$1NUMTABLE/) {
	push @table_divs, getWholeTagBlock();
	$table_cnt++;
}
# print STDERR "$table_cnt numbered tables found\n";
# # get all unnumbered tables
# while ($html_line =~ s/(<div .*?data-block_type=\")(un_table)/$1UN_TABLE/) {
	# push @table_divs, getWholeTagBlock();
	# $table_cnt++;
# }
# print STDERR "@table_divs\n";

print STDERR "$table_cnt total tables found\n";

foreach my $table (@table_divs) {
    # my $supp_win_code;
    my $supp_win_name;
    (my $new_table_code = $supp_win) =~ s/DL_REPLACE_HTML/$table/;

    # numbered tables
    if ($new_table_code =~ m/data-block_type="table"/) {
        $new_table_code =~ m/data-block_type="tbl_num">([\d\-]+)/;
        my $tblnum = $1;
        $tblnum =~ s/-/_/;
        $supp_win_name = "table_$tblnum.html";
        $new_table_code =~ s/DL_REPLACE_TITLE/Table $tblnum/;

    #unnumbered tables
    } elsif ($new_table_code =~ m/data-block_type="un_table"/) {
        $new_table_code =~ m/id=".*?untab-(\d+)"/;
        my $tblnum = $1;
        $supp_win_name = "untable_${chapter}_$tblnum.html";
        $new_table_code =~ s/DL_REPLACE_TITLE/Table/;

    } else {
	$supp_win_name = "UNKNOWN_ID.html";
	# probably need to flag and exit here
    }
    print STDERR "new supp win = $supp_win_name\n";
    
    # Fix all image references, reconstructing the path to be relative from the supplemental window URL
    $new_table_code =~ s`src="asset/ch\d+`src="..`g;
    # and change left column images (icons, etc.)
    # $new_table_code =~ s`src="asset/images`src="../../../images`g;
    # fix inline links to be relative from current supp_win sub-directory.
    # Note: need to step back to asset root in case reference is to different chapter.
    # $new_table_code =~ s`(data-url=")(asset/ch\d+/supp_win)`$1../../../../$2`g;
    
    # restore UNNUMBERED_TABLE to lower case
    $new_table_code =~ s/UN_TABLE/un_table/g;
    # restore NUMBERED_TABLE to lower case
    $new_table_code =~ s/NUMTABLE/table/g;
    
    # create the new file
    open my $fh2, ">html/asset/ch${chapter}/tables/$supp_win_name" or die;
    print $fh2 $new_table_code;
    close $fh2;
}

print STDERR "---> html/asset/ch${chapter}/tables written ($table_cnt)\n";

sub getWholeTagBlock {
    my $tag_block;
    my $indent_level = 0;
    
    # capture opening tag
    $html_line =~ s/(.*?)(<div data-type=\"table\"[^>]+>)//si;
    $tag_block = $2;
    # print STDERR "$tag_block\n";
    # increment indention level counter
    $indent_level++;
    
    # search for the closing </div> based on indention level, gather all HTML in-between
    while ($indent_level > 0) {
        
        (my $next_div) = $html_line =~ s/(.*?(<\/?div[^>]*>))//si;
        # append gathered HTML
        $tag_block .= $1;
        
        if ($2 eq "</div>") {
            $indent_level--;
        } else {
            $indent_level++;
        }
    }

    # return the gather HTML code block
    return $tag_block;
}