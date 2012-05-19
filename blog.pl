#!/bin/env perl

# Small script to make writing blog-entries a little less work.

# Most likely doesn't work on Windows machines, and I don't
# care. Works for me on Linux, BSD and Solaris; it should be good
# enough for anyone.

use strict;
use warnings;
use utf8;
use File::Slurp;
use File::Temp;
use File::Spec;
use Date::Format qw(time2str);

my (undef, $tmp_article)  = File::Temp::tempfile();

my ($title, $author, $post_date, $src_dir);

print "Opening text editor for post text. (Tempfile: $tmp_article)\n";

# Use the user's favourite editor; assuming they set their damn
# environment variables correctly.

my $editor;

if(!defined($ENV{EDITOR}) || $ENV{EDITOR} eq ""){
    # User doesn't have EDITOR set.
    # If /this/ doesn't exist, then the system is beyond hope. (Or a
    # Windows box, but I repeat myself.)
    $editor = "ed";
} else {
    $editor = $ENV{EDITOR};
}

system($editor, "$tmp_article");

# Ask for a title.
print "Title of this post: ";
chomp($title = <>);

if(defined($ENV{KLOMP_USER}) && !($ENV{KLOMP_USER} eq "")){
    $author = $ENV{KLOMP_USER};
}

if(!defined($author) && defined($ENV{USER}) && !($ENV{USER} eq "")){
    $author = $ENV{USER};
}

if(!defined($author)){
    print "Post author: ";
    chomp($author = <>);
}

# Timestamp the post.
$post_date = time2str("%Y-%m-%dT%H:%M:%S%z",time());

if(!defined($ENV{KLOMP_SRC}) || ($ENV{KLOMP_SRC} eq "")){
    print "Directory of article sources: ";
    chomp($src_dir = <>);
} else {
    $src_dir = $ENV{KLOMP_SRC};
}

# Ask for categories here.  Until that's done, just slap 'em in
# 'uncategorised'. They can be edited manually anyway.

my $crushed_title = $title;
$crushed_title =~ s/\s/_/g;

my $filename = "$post_date-$crushed_title.txt";
my $path = File::Spec->canonpath(File::Spec->catpath($src_dir, $filename));

print "Writing post \"$title\" to $path...\n";

File::Slurp::write_file($path, ["Title: $title\n", "Author: $author\n",
				"Date: $post_date\n", "Tags: uncategorised\n",
				"--text follows this line--\n",
				File::Slurp::read_file($tmp_article)]);

# Make sure we clean up after ourselves, by removing our tempfile.
unlink($tmp_article);
