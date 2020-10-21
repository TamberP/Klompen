package Klompen::Site;

use utf8;
use strict;
use warnings;

use HTML::Tiny;
use JSON;
use Klompen::Archive;

=head2 sidebar_generate ( $html_object )

Bundles up all the HTML for the side-bar, including header, list of
categories, list of sidebar links, and the footer.

=cut

sub sidebar_generate {
    my $h = shift;
    $h->div({'id' => 'menu_header'}, [Klompen->menu_header_contents()]),
    # Generate the list of categories
    $h->h1({'id' => 'categories'}, "Categories"),
    sidebar_category_list($h),
    $h->h1({'id' => 'links'}, "Links"),
    sidebar_links_list($h),
    $h->div({'id' => 'menu_footer'}, [Klompen->menu_footer_contents()])
}

=head2 sidebar_category_list ( $html_object )

Creates the HTML for the list of categories, including lining to each
category's archive page.

Returns the HTML for the (unordered) list.

=cut

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

=head2 sidebar_links_list ( $html_object )

Creates the HTML for the sidebar's list of links. Returns the HTML for
the (unordered) list.

=cut

sub sidebar_links_list {
    my $h = shift;

    my $src = "";
    foreach(@{Klompen::list_sidebar_links()}){
	$src = $src . $h->li($h->a({
	    'title' => $h->entity_encode($_->{'title'}),
	    'href' => $_->{'href'}}, 
	    $h->entity_encode($_->{'name'})));
    };
    $h->ul([
	$src]);
}

=head2 doctype ( )

Returns the doctype for the HTML output. (Fixed as HTML 4.01 strict.)

=cut

sub doctype {
    return '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">';
}

1;
