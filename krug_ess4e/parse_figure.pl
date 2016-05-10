#!/usr/bin/perl -w

use strict;

my $chapter = shift @ARGV;

my $htmlfile = "html/all_ch${chapter}.html";

# supplemental window skeleton code
# Need to add manuscript and section divs for glossary key terms in captions to work
my $supp_win = "<!DOCTYPE HTML>
<html>
<head>
    <meta charset=\"utf-8\">
    <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge,chrome=1\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>DL_REPLACE_TITLE</title>
    <link href=\"../../css/boilerplate.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../css/jquery-ui-custom.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../css/manuscript.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../css/digfir_ebook_fw.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../css/krugmanwellsessentials4e.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../css/krugmanwellsessentials4e_ch${chapter}.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
</head>
<body id=\"supp_win\">


    DL_REPLACE_HTML



    <script type=\"text/javascript\" src=\"../../js/utilities.js\"></script>
    <script type=\"text/javascript\" src=\"../../js/query_types.js\"></script>
    <script type=\"text/javascript\" src=\"../../js/player.js\"></script>
    <script type=\"text/javascript\" src=\"../../js/jquery.js\"></script>
    <script type=\"text/javascript\" src=\"../../js/jquery-ui-1.8.16.custom.min.js\"></script>
    <script type=\"text/javascript\" src=\"../../js/jquery_extensions.js\"></script>
    <script type=\"text/javascript\" src=\"../../js/swfobject.js\"></script>
    <script type=\"text/javascript\" src=\"http://admin.brightcove.com/js/BrightcoveExperiences.js\"></script>
    <script type=\"text/javascript\" src=\"../../js/digfir_ebook_fw.js\"></script>
    <script type=\"text/javascript\" src=\"../../js/krugmanwellsessentials4e.js\"></script>
    <script type=\"text/javascript\" src=\"../../js/krugmanwellsessentials4e_ch${chapter}.js\"></script>
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

# show all figure divs

my $figure_cnt = 0;
# note that other div blocks may intervene between opening figure div and final matching </div>
# also note that figures use data-type, not data-block_type
my @figure_divs;

while ($html_line =~ m/<div .*?data-type=\"figure\"/) {
	push @figure_divs, getWholeTagBlock();
	$figure_cnt++;
}

# print STDERR "$figure_cnt figures found\n";

foreach my $figure (@figure_divs) {
    # my $supp_win_code;
    my $supp_win_name;
    
    # print STDERR "\n----------------\n$figure\n-------------------\n";
    
    #############################################################
    # CREATE SUPP WIN HTML
    
    (my $new_fig_code = $supp_win) =~ s/DL_REPLACE_HTML/$figure/;

    #############################################################
    # CREATE SUPP WIN FILE NAME
    # supp_wins must match the figure name exactly
    # possible types (name prepends) are fig, photo, and unfig
    $figure =~ m`<img.*?src="asset/ch\d+/([^\.]+).jpg"`;
    $supp_win_name = $1 . ".html";
    # print STDERR "$supp_win_name\n";
    
    #############################################################
    # fix inline links - images are in current file, so strip path name
    $new_fig_code =~ s`(<img.*?src=")asset/ch\d+/`$1`g;
    $new_fig_code =~ s`DL_REPLACE_TITLE`Figure`g;
    
    # create the new file
    open my $fh2, ">html/asset/ch${chapter}/$supp_win_name" or die;
    print $fh2 $new_fig_code;
    close $fh2;
}

print STDERR "---> html/asset/ch${chapter} written ($figure_cnt)\n";

sub getWholeTagBlock {
    my $tag_block;
    my $indent_level = 0;
    
    # capture opening tag (NOTE: needed to change first + to * in following regex
    $html_line =~ s/(.*?)(<div[^>]* data-type=\"figure\"[^>]+>)//si;
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