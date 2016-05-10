#!/usr/bin/perl -w

use strict;

# Note that we cannot use ids for file naming, because they do not match the question number in the text.
# In-text references to questions would not then be correct unless some sort of map was used to get to the
# correct id from the question number.

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

###################################################################################

# show all question divs

my $question_cnt = 0;
my $question_cnt2 = 0;
my @question_divs;

# while ($html_line =~ m/<div .*?data-type=\"question\" .*?data-block_type=\"q_prob\"[^>]+>/) {
while ($html_line =~ m/<div .*?data-type=\"question\"/) {
	push @question_divs, getWholeTagBlock();
	$question_cnt++;
}

# print STDERR "$question_cnt questions found\n";

foreach my $question (@question_divs) {
    my $supp_win_name;
    my $new_qstn_code;
    
    # PROBLEMS section questions
    if ($question =~ /data-block_type=\"q_prob\"/) {
        $question_cnt2++;
        # my $supp_win_code;
        ($new_qstn_code = $supp_win) =~ s/DL_REPLACE_HTML/$question/;

        # look for question number in qnum span
      
        if ($new_qstn_code =~ m/span data-block_type="qnum">([\d]+)/) {
            my $qnum = $1;
            $supp_win_name = "question_$qnum.html";
            # print STDERR "$supp_win_name\n"; 
            # Give sane window title
            $new_qstn_code =~ s/DL_REPLACE_TITLE/Problem Question $qnum/;
        } else {
            $supp_win_name = "UNKNOWN_QUESTION_NUMBER.html";
            # probably need to flag and exit here
        }
    }
    
    # CHECK YOUR UNDERSTANDING feature questions
    elsif ($question =~ /data-block_type=\"q_cyu\"/) {
        $question_cnt2++;
        # my $supp_win_code;
        ($new_qstn_code = $supp_win) =~ s/DL_REPLACE_HTML/$question/;

        # look for question number in quesstion ID
      
        if ($new_qstn_code =~ m/id="krugmanwellsessentials4e-ch\d+-cyuquestion-(\d+)">/) {
            my $qnum = $1;
            $supp_win_name = "cyu_question_$qnum.html";
            # print STDERR "$supp_win_name\n"; 
            # Give sane window title
            $new_qstn_code =~ s/DL_REPLACE_TITLE/Check Your Understanding Question/;
        } else {
            $supp_win_name = "UNKNOWN_CYU_QUESTION_NUMBER.html";
            # probably need to flag and exit here
        }
    }
    
    # Other question types will be ignored, such as the key terms quiz question ("q_kt")
    else {
        next;
    }
    # print "new supp win = $supp_win_name\n";
    
    # Not implementing the following rules until found in a chapter.
    # Not found in the model chapter (3).
    
    # # Fix all image references, reconstructing the path to be relative from the supplemental window URL
    # $new_qstn_code =~ s`src="asset/ch\d+`src="..`g;
    # # and change left column images (icons, etc.)
    # $new_qstn_code =~ s`src="asset/images`src="../../images`g;
    # # fix inline links to be relative from current supp_win sub-directory.
    # # Note: need to step back to asset root in case reference is to different chapter.
    # $new_qstn_code =~ s`(data-url=")(asset/ch\d+)`$1../../../$2`g;
    
    # create the new file
    open my $fh2, ">html/asset/ch${chapter}/questions/$supp_win_name" or die;
    print $fh2 $new_qstn_code;
    close $fh2;
}

print STDERR "---> html/asset/ch${chapter}/questions written ($question_cnt2)\n";

sub getWholeTagBlock {
    my $tag_block;
    my $indent_level = 0;
    
    # capture opening tag (NOTE: needed to change first + to * in following regex
    $html_line =~ s/(.*?)(<div[^>]* data-type=\"question\"[^>]+>)//si;
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

