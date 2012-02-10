package Klompen::Author;

use utf8;
use strict;
use warnings;

use Klompen;
use Text::Markdown 'markdown';
use HTML::Tiny;

# Maintain a little bit of state to ensure we don't regenerate the
# author's profile page for every post they've uploaded.

my $a_state = { };

# Mark this author as having their profile page already generated.
sub generated {
    $a_state->{shift} = 1;
}

# Check whether or not the specified author has had their profile
# generated or not.
sub gen_p{
    return $a_state->{shift};
}

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


sub generate {
    my $author = shift;
    # Create the profile page for the given author.  Uses the
    # lower-cased printified author name to figure out where to get
    # the file from, and where to put it.

    croak("Asked to generate author profile for undefined author.")
    if(!defined($author));

    my $h = HTML::Tiny->new( 'mode' => 'html' );

    File::Slurp::write_file(Klompen::author_path(lc($author)),
			  Klompen::Site::doctype() . "\n" .
			    $h->html([
				$h->head([
				    $h->title($h->entity_encode("$author | Profile")),
				    $h->link({
					'rel'   => 'stylesheet',
					'type'  => 'text/css',
					'media' => 'screen',
					'href'  => Klompen::style_url()
					     }),
				    $h->meta({
					'http-equiv' => 'Content-Type',
					'content'    => 'text/html; charset=UTF-8'
					     }),
				    ]),
				$h->body([
				    Klompen->header_contents(),
				    $h->h1({'id' => 'author_prof_title'},
					   $h->entity_encode($author)),
				    $h->div({'id' => 'profile'}, [
						markdown(File::Slurp::read_file(
							     Klompen::author_src_path(lc($author))))
					    ]),
				    $h->div({'id' => 'menu'}, [Klompen::Site::sidebar_generate($h)]),
				    $h->div({'id' => 'footer'}, [
						Klompen->footer_contents(),
						$h->p({'id' => 'credit'},
						      "Proudly powered by " .
						      $h->tag('a', {'href' => 'https://github.com/TamberP/Klompen',
								    'title' => 'Klompen on Github'},
							      'Klompen') . "."),
					    ])])]));
    # Make sure we mark this author's profile as generated, so we
    # don't regenerate it every time.
    generated($author);
}

1;
