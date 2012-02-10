package Klompen::Author;

use utf8;
use strict;
use warnings;

use Klompen;

use HTML::Tiny;

sub linkify {
    # Turns the author's printable name (from printify) into a link to
    # their author info page. This doesn't do anything to sanitise,
    # etc, the link; since the only person who could insert XSS here
    # would be the site owner, and they can do that /anyway/.
    my $author = lc(printify(shift));

    return HTML::Tiny->tag('a',
			   {'href' => Klompen::author_url($author) . Klompen::output_ext(),
			    'title' => "See $author\'s profile page."}, $author);
}

sub printify {
    # Convert an author's name/email tag ("Name <e@mail.host>") into a
    # nice, printable piece of text.

    my $author_tag = shift;
    croak("Not passed an author tag to printify!") if(!defined($author_tag));

    # Remove the email section, we don't need it for this.
    $author_tag =~ s/\s+<.*@.*>\s+//i;
    $author_tag =~ s/^\s*//;
    return $author_tag;
}


1;
