#!/usr/bin/perl

# This script creates supplemental HTML files for popup windows. The source HTML
# file must be created first, so all XML opeations must be completed, the XML uploaded
# to DF, published to HTML, then downloaded back to where this script can use it.

#####################################################################################
# Create supplemental windows
# Function: Creates popup supplemental windows.
# Input:  Digital First HTML file. Currently, this is produced manually, downloading
#         the DF-created HTML, concatenating all chapter-level files into one. This
#         file is kept in the HTML directory.
# Output: supplemental HTML files are produced in asset/CHAPTER. These files are
#         then uploaded to the corresponding directory on Digital First.
#####################################################################################

for $chapter (3) { #(1..14) {
	print STDERR "\nProcessing Chapter $chapter\n";
	# system("perl parse_figure.pl  $chapter");
	# system("perl parse_table.pl  $chapter");
	system("perl parse_question.pl  $chapter");
}

# for $appendix (1) {
	# print STDERR "\nProcessing APPENDIX $appendix\n";
	# system("perl parse_figure_app.pl  $appendix");
# }
