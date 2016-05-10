##################################################################################
# Generate key terms file from section in XML
# also removes section from output XML
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
    # chomp($temp_line);
    $contents .= $temp_line;
}

$_ = $contents;

my $kt;
my $ktdef;
my $keyterms;

# while (s`<p .*?block_type="mn-gl-def">(<strong>(.*?)</strong>) &\#8211\; (.*?)</p>``) {
while (s`<p .*?block_type="mn-gl-def">(.*?)<\/p>``) {
    $ktdef = $1;
    $ktdef =~ m`<strong>([^<]+)</strong>`;
    $kt = $1;
    $keyterms .= "xBookUtils.terms['${kt}'] = '${ktdef}'\;\n";
    # print STDERR "$keyterms\n";
}
print $keyterms;

