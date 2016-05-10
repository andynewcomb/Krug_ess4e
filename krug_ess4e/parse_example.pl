#!/usr/bin/perl -w

# Note that examples may contain other boxes, such as figures, images, and tables

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
    <link href=\"../../../../css/boilerplate.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../../css/jquery-ui-custom.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../../css/manuscript.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../../css/digfir_ebook_fw.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../../css/discostat3e.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../../css/discostat3e_ch${chapter}.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
</head>
<body id=\"supp_win\">
    <div id=\"manuscript\" data-chapter-number=\"2\">
        <div data-type=\"section\" id=\"discostat3e_supp_win_sec\" class=\"example\" level=\"1\">


    DL_REPLACE_HTML


        </div>
    </div>
    
    <script type=\"text/javascript\" src=\"../../../../js/utilities.js\"></script>
    <script type=\"text/javascript\" src=\"../../../../js/query_types.js\"></script>
    <script type=\"text/javascript\" src=\"../../../../js/player.js\"></script>
    <script type=\"text/javascript\" src=\"../../../../js/jquery.js\"></script>
    <script type=\"text/javascript\" src=\"../../../../js/jquery-ui-1.8.16.custom.min.js\"></script>
    <script type=\"text/javascript\" src=\"../../../../js/jquery_extensions.js\"></script>
    <script type=\"text/javascript\" src=\"../../../../js/swfobject.js\"></script>
    <script type=\"text/javascript\" src=\"http://admin.brightcove.com/js/BrightcoveExperiences.js\"></script>
    <script type=\"text/javascript\" src=\"../../../../js/digfir_ebook_fw.js\"></script>
    <script type=\"text/javascript\" src=\"../../../../js/discostat3e.js\"></script>
    <script type=\"text/javascript\" src=\"../../../../js/discostat3e_ch${chapter}.js\"></script>
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

# show all example divs

my $example_cnt = 0;
# finding matching end </div> for this box
my $exampledivhtml = "<div .*?data-block_type=\"example\".*?(<div.*<\/div>)*<\/div>";
my @example_divs;

# while ($html_line =~ s/($exampledivhtml)//si) {
while ($html_line =~ m/<div .*?data-block_type=\"example\"/) {
	push @example_divs, getWholeTagBlock();
	$example_cnt++;
	
	# print STDERR "@example_divs";
}

# print STDERR "@example_divs";
# print STDERR "$example_cnt examples found\n";

foreach my $example (@example_divs) {
    # Setup supplemental window code
    my $supp_win_name;
    (my $new_example_code = $supp_win) =~ s/DL_REPLACE_HTML/$example/;
    # No, do not use ID
    # if ($new_example_code =~ m/id="(moore4e_ch[^"]+)"/) {
    if ($new_example_code =~ m/data-block_type="example_num">EXAMPLE ([\d\.]+)/) {
        my $exnum = $1;
        $supp_win_name = "example_$exnum.html";
        # Need to give sane title here IF it is displayed
        $new_example_code =~ s/DL_REPLACE_TITLE/Example $exnum/;
    } else {
	$supp_win_name = "UNKNOWN_ID.html";
	# probably need to flag and exit here
    }
    # print "new supp win = $supp_win_name\n";
    
    # Fix all image references, reconstructing the path to be relative from the supplemental window URL
    $new_example_code =~ s`src="asset/ch\d+/images`src="../../images`g;
    # and change left column images (icons, etc.)
    $new_example_code =~ s`src="asset/images`src="../../../images`g;
    # fix inline links to be relative from current supp_win sub-directory.
    # Note: need to step back to asset root in case reference is to different chapter.
    $new_example_code =~ s`(data-url=")(asset/ch\d+/supp_win)`$1../../../../$2`g;
    
    # create the new file
    open my $fh2, ">html/asset/ch${chapter}/supp_wins/examples/$supp_win_name" or die;
    print $fh2 $new_example_code;
    close $fh2;
}

print STDERR "---> html/asset/ch${chapter}/supp_wins/examples written ($example_cnt)\n";

sub getWholeTagBlock {
    my $tag_block;
    my $indent_level = 0;
    
    # capture opening tag
    $html_line =~ s/(.*?)(<div [^>]+ data-block_type=\"example\"[^>]+>)//si;
    $tag_block = $2;
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