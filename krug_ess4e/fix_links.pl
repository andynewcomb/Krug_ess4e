##################################################################################
# Fix inline links
##################################################################################

use utf8;
use strict;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

# GLOBALS that may be useful

###################################
# get entire contents of file into single line: $contents
my $contents;
my $temp_line;
while ($temp_line = <STDIN>) {
    $contents .= $temp_line;
}

$_ = $contents;

###################################
# fix inline chapter links

s`(<link href="krugmanwellsessentials4e)-ch\d+\.xml(">Chapter (\d+)<\/link>)`$1_ch$3_1.html$2`g;

###################################
# fix inline figure links

s`(<link href=")#krugmanwellsessentials4e-ch\d+-fig-\d+(">Figure (\d+)-(\d+)<\/link>)`${1}asset/ch${3}/KrugESS4e_fig_${3}_${4}.html$2`g;
# also fix zero padding for figure numbers less than 10
s`(KrugESS4e_fig_\d+_)(\d)(\.html)`${1}0${2}${3}`g;

###################################
# output contents to STDOUT

print;

