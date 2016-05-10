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
    <link href=\"../../../../css/boilerplate.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../../css/jquery-ui-custom.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../../css/manuscript.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../../css/digfir_ebook_fw.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../../css/discostat3e.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
    <link href=\"../../../../css/discostat3e_ch${chapter}.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" >
</head>
<body id=\"supp_win\">
    <div id=\"manuscript\" data-chapter-number=\"2\">
        <div data-type=\"section\" id=\"discostat3e_supp_win_sec\" class=\"question\" level=\"1\">


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

### Josh - code added to include questions instructions with affected questions ###
my @instructions;

my $html_line2 = $html_line;
###Put instructions in hash -- added data-block_type2 to work around one with block_type="case"
while($html_line2 =~ m/<div[^>]*(block_type="instruction"|data-block_type2="instruction")/) {
	my $tag = getWholeTagBlock2();
	if($tag =~ m/data-instructions="(\d+)"/) {
		my $num = $1;
		$instructions[$num] = $tag;
	}
}

###################################################################################

# show all question divs

my $question_cnt = 0;
# note that other div blocks may intervene between opening question div and final matching </div>
# also note that questions use data-type, not data-block_type
my @question_divs;

while ($html_line =~ m/<div .*?data-type=\"question\"/) {
	push @question_divs, getWholeTagBlock();
	$question_cnt++;
}

# print STDERR "$question_cnt questions found\n";

foreach my $question (@question_divs) {

    ### Josh - code added to include questions instructions with affected questions ###
    # Adding data instructions before each question in the supp_wins. This produces bad output if $instructions[number] does not exist
    if($question =~ m/data-instructions="(\d+)"/){
	if (exists $instructions[$1]) {
            $question = $instructions[$1] . $question;
	} else {
	    print STDERR "instructions[" . $1 . "] does not exist\n";
	}
    }
    ###################################################################################


    # my $supp_win_code;
    my $supp_win_name;
    (my $new_qstn_code = $supp_win) =~ s/DL_REPLACE_HTML/$question/;
    # No, do not use ID
    # if ($new_qstn_code =~ m/id="(moore4e_ch[^"]+)"/) {
        
    # instead, look for question number in the text (<span data-type="number">
    
    if ($new_qstn_code =~ m/span data-type="number">([\d\.]+)/) {
        my $qnum = $1;
        $supp_win_name = "question_$qnum.html";
        # print STDERR "$supp_win_name\n"; 
        # Need to give sane title here IF it is displayed
        $new_qstn_code =~ s/DL_REPLACE_TITLE/Question $qnum/;
    } else {
	$supp_win_name = "UNKNOWN_QUESTION_NUMBER.html";
	# probably need to flag and exit here
    }
    # print "new supp win = $supp_win_name\n";
    
    # Fix all image references, reconstructing the path to be relative from the supplemental window URL
    $new_qstn_code =~ s`src="asset/ch\d+/images`src="../../images`g;
    # and change left column images (icons, etc.)
    $new_qstn_code =~ s`src="asset/images`src="../../../images`g;
    # fix inline links to be relative from current supp_win sub-directory.
    # Note: need to step back to asset root in case reference is to different chapter.
    $new_qstn_code =~ s`(data-url=")(asset/ch\d+/supp_win)`$1../../../../$2`g;
    
    # create the new file
    open my $fh2, ">html/asset/ch${chapter}/supp_wins/questions/$supp_win_name" or die;
    print $fh2 $new_qstn_code;
    close $fh2;
}

print STDERR "---> html/asset/ch${chapter}/supp_wins/questions written ($question_cnt)\n";

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

### Josh - code added to include questions instructions with affected questions ###
sub getWholeTagBlock2 {
    my $tag_block;
    my $indent_level = 0;
    
    # capture opening tag (NOTE: needed to change first + to * in following regex
    $html_line2 =~ s/(.*?)(<div[^>]*(block_type="instruction"|data-block_type2="instruction").*?>)//si;
    $tag_block = $2;
    
    # increment indention level counter
    $indent_level++;
    
    # search for the closing </div> based on indention level, gather all HTML in-between
    while ($indent_level > 0) {
        
        (my $next_div) = $html_line2 =~ s/(.*?(<\/?div[^>]*>))//si;
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
###################################################################################
