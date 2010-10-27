#!/usr/bin/perl -w
# Xcode auto-versioning script for Subversion
# by Axel Andersson, modified by Daniel Jalkut to add
# "--revision HEAD" to the svn info line, which allows
# the latest revision to always be used.
        
use strict;
        
die "$0: Must be run from Xcode" unless $ENV{"BUILT_PRODUCTS_DIR"};
        
# Get the current subversion revision number and use it to set the CFBundleVersion value
my $REV = `export PATH=\$PATH:/usr/local/bin;/usr/bin/env svnversion -n ./`;
my $INFO = "$ENV{BUILT_PRODUCTS_DIR}/$ENV{WRAPPER_NAME}/Resources/Info.plist";
        
my $version = $REV;
$version =~ s/([\d]*:)(\d+[M|S]*).*/$2/;
die "$0: No Subversion revision found" unless $version;
        
open(FH, "$INFO") or die "$0: $INFO: $!";
my $info = join("", <FH>);
close(FH);
        
$info =~ s/([\t ]+<key>BuildRevision<\/key>\n[\t ]+<string>).*?(<\/string>)/$1$version$2/;
        
open(FH, ">$INFO") or die "$0: $INFO: $!";
print FH $info;
close(FH);

