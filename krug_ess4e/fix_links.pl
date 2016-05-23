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

# get chapter number from first line
m`<chapter number="(\d+)"`;
my $chapter = $1;

# change the Krugman images with src="images" to src="asset/ch<CHAPTER>"
s`src="images/Krug`src="asset/ch${chapter}/Krug`g;

# change other to book level images directory
s`src="images/`src="asset/images/`g;


###################################
# fix inline chapter links

s`(<link href="krugmanwellsessentials4e)-ch\d+\.xml(">Chapter (\d+)<\/link>)`$1_ch$3_1.html$2`g;

###################################
# fix inline figure links

s`(<link href=")#krugmanwellsessentials4e-ch\d+-fig-\d+(">Figure (\d+)-(\d+)<\/link>)`${1}asset/ch${3}/KrugESS4e_fig_${3}_${4}.html${2}`g;
# caption links
s`(<caption><link href=")#krugmanwellsessentials4e-ch\d+-fig-\d+(">.*?<phrase block_type="fig_num">(\d+)-(\d+))`${1}asset/ch${3}/KrugESS4e_fig_${3}_${4}.html${2}`g;
# also fix zero padding for figure numbers less than 10
s`(KrugESS4e_fig_\d+_)(\d)(\.html)`${1}0${2}${3}`g;

###################################
# fix table links

s`(<link href=")#krugmanwellsessentials4e-ch(\d+)-tab-(\d+)`${1}asset/ch${2}/table_${2}_${3}.html`g;
# numbered tables
s`(data-href=")#krugmanwellsessentials4e-ch(\d+)-tab-(\d+)`${1}asset/ch${2}/table_${2}_${3}.html`g;
# unnumbered tables
s`(data-href=")#krugmanwellsessentials4e-ch(\d+)-untab-(\d+)`${1}asset/ch${2}/un_table_${2}_${3}.html`g;

###################################
# output contents to STDOUT

print;

