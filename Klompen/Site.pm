package Klompen::Site;

use utf8;
use strict;
use warnings;

use HTML::Tiny;

sub sidebar_generate {
    my $h = shift;
    # Generate the list of categories
    $h->h1({'id' => 'categories'}, "Categories"),
    sidebar_category_list($h),
    $h->h1({'id' => 'links'}, "Links"),
    sidebar_links_list($h),
}

sub sidebar_category_list {
    my $h = shift;
    $h->ul([
	$h->li($h->a("Categories")),
	$h->li($h->a("Will")),
	$h->li($h->a("Appear")),
	$h->li($h->a("Here")),
	   ]);
}

sub sidebar_links_list {
    my $h = shift;
    $h->ul([
	$h->li($h->a("Links")),
	$h->li($h->a("Listed")),
	$h->li($h->a("Here")),
	   ]);
}

1;
