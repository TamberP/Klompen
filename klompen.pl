#!/usr/bin/perl

# Klompen : Perl Blog Generator : Or something like that.
# Copyright (C) 2011 by Tamber Penketh <tamber@furryhelix.co.uk>

# Permission to use, copy, modify, and distribute this software for
# any purpose with or without fee is hereby granted, provided that the
# above copyright notice and this permission notice appear in all
# copies.

# THE SOFTWARE IS PROVIDED "AS IS" AND INTERNET SOFTWARE CONSORTIUM
# DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL
# INTERNET SOFTWARE CONSORTIUM BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
# RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
# CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 
# (Why 'Klompen'? Because its predecessor, written in Common Lisp was
# called 'clog'.)

use utf8;
use strict;
use warnings;

sub article_gen{
    my $post_path = shift;

    my $metadata = {
	'title'  => "",
	'author' => "",
	'date'   => "",
	'id'     => "",
	'tags'   => [],
    };

    # Open file
    my $post_fh;
    open($post_fh, '<:encoding(UTF-8)', $post_path)
	|| { print stderr "Cannot open $post_path: $!"; return -1; }

    # Read through, grabbing the metadata until a line with only this:
    # "--text follows this line--" is reached.
    my $line;
    foreach $line (<$post_fh>){
	if($line eq "--text follows this line--")
	    last;
	my @tmp = split(/:/, $line, 2);
	$metadata->{lc($tmp[0])} = $tmp[1];
    }

    # Slurp in the article's text. (This is markdown source.)
    my $termin = $/;
    undef $/;
    my $article_src = <$post_fh>;
    $/ = $termin;
    undef $termin;
    close($post_fh);

    my $post_header = header_generate('post', $metadata);
}
