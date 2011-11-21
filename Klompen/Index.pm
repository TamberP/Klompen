package Klompen::Index;

use Klompen;
use Klompen::Archive;

use utf8;
use warnings;
use strict;

# Builds the index page. Is really just a specialised version of the
# archive page.

my $h = HTML::Tiny->new('mode' => 'html');

sub generate {
    # Use the sorted list of posts from Klompen::Archive

    my @posts = sort { $b->{'date'} cmp $a->{'date'} } @Klompen::Archive::post_stack;

    my $postH;

    open($postH, ">:encoding(UTF-8)", Klompen->conf_output_directory()
	 . "/index" . Klompen->conf_output_extension())
	|| print STDERR "!! Could not create index page " . Klompen->conf_output_directory()
	. "/index" . Klompen->conf_output_extension() . "\n" && return -1;

    print $postH $h->html([
	$h->head([
	    $h->meta ({'http-equiv' => 'Content-Type',
		       'content' => 'text/html; charset=UTF-8'}),
	    $h->title($h->entity_encode(Klompen->conf_site_name)),
	    $h->link({'rel' => 'stylesheet', 'type' => 'text/css',
		      'media' => 'screen', 'href' => Klompen->stylesheet_url}),
	    ]),
	$h->body([
	    Klompen->get_header_contents(),
	    $h->h1($h->entity_encode(Klompen->conf_site_name)),
	    $h->div({'id' => 'content'},
		    [Klompen::Archive::create_links(1, @posts)]),
	    $h->div({'id' => 'menu'}, [Klompen::Site::sidebar_generate($h) ]),
	    Klompen->get_footer_contents(),
		 ])]);
    close $postH;
}

