package Klompen::Site;

use utf8;
use strict;
use warnings;

use HTML::Tiny;
use JSON;
use Klompen::Archive;

sub sidebar_generate {
    my $h = shift;
    # Generate the list of categories
    $h->h1({'id' => 'categories'}, "Categories"),
    sidebar_category_list($h),
    $h->h1({'id' => 'links'}, "Links"),
    sidebar_links_list($h),
    # Include include/sidebar.txt here, too.
}

sub sidebar_category_list {
    my $h = shift;
    my @tag_l = Klompen::Archive->tag_list();
    my @rslt;
    foreach my $tag (@tag_l){
	push @rslt, $h->li(
	    $h->tag('a', 
		    {'href' => Klompen::tag_url($h->url_encode($tag)),
			 'title' => 'See all posts in category "' .
			 $h->entity_encode($tag) . '"'}, 
		    $h->entity_encode($tag)));
    }
    return $h->ul([@rslt]);
}

sub sidebar_links_list {
    # Create the list of links on the sidebar.
    my $h = shift;

    my $src;
    foreach(Klompen::links_list){
	$src = $src . $h->li($h->a({
	    'title' => $h->entity_encode($_->{'title'}),
	    'href' => $_->{'href'}}, 
	    $h->entity_encode($_->{'name'})));
    };
    $h->ul([
	$src]);
}

1;
