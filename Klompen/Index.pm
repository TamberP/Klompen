package Klompen::Index;

use Klompen;
use Klompen::Archive;

use utf8;
use warnings;
use strict;

use XML::RSS::SimpleGen;

# Builds the index page. Is really just a specialised version of the
# archive page.

my $h = HTML::Tiny->new('mode' => 'html');

sub generate {
    # Use the sorted list of posts from Klompen::Archive

    my @posts = sort { $b->{'date'} cmp $a->{'date'} } @Klompen::Archive::post_stack;

    my $postH;

    my $rss = XML::RSS::SimpleGen->new(Klompen->conf_base_url(), Klompen->conf_site_name());
    $rss->item_limit(Klompen->conf_rss_limit());

    open($postH, ">:encoding(UTF-8)", Klompen->conf_output_directory()
	 . "/index" . Klompen->conf_output_extension())
	|| print STDERR "!! Could not create index page " . Klompen->conf_output_directory()
	. "/index" . Klompen->conf_output_extension() . "\n" && return -1;

    print $postH Klompen::Site::doctype() . "\n";

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
		    [Klompen::Archive::create_links(1, $rss, @posts)]),
	    $h->div({'id' => 'menu'}, [Klompen::Site::sidebar_generate($h) ]),
	    $h->div({'id' => 'footer'}, [
			Klompen->get_footer_contents(),
			$h->p({'id' => 'credit'}, "Proudly powered by " . $h->tag('a', {'href' => 'https://github.com/TamberP/Klompen',
											'title' => 'Klompen on GitHub'}, 'Klompen') . "."),
		 ])])]);

    $rss->save(Klompen->conf_rss_name());

    close $postH;
}

