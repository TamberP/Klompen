package Klompen::Site;

use utf8;
use strict;
use warnings;

use HTML::Tiny;

sub sidebar_generate {
    my $h = shift;
    # Generate the list of categories
    $h->h3({'id' => 'categories'}, "Categories"),
    sidebar_category_list($h),
    $h->h3({'id' => 'links'}, "Links"),
    sidebar_links_list($h),
}

sub sidebar_category_list {
    my $h = shift;
    $h->p("Will list categories here");
}

sub sidebar_links_list {
    my $h = shift;
    $h->p("Will list links here");
}

1;
