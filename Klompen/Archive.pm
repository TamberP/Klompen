package Klompen::Archive;

use HTML::Tiny;
use XML::RSS::SimpleGen;
use Klompen;
use Klompen::Site;
use POSIX qw(strftime ceil);
use Date::Parse qw(str2time);
use File::Slurp;
use File::Path;
use Carp;
our @post_stack;

=head1 Klompen::Archive

Functions for creating indexes of posts.

=head2 push ( $id, $timestamp, $title, $author, $file_path, $preview_text )

Adds the given post to the internal stack of posts to process.

=cut

sub push {
    my ($id, $ts, $title, $author, $path, $snippet) = @_;

    push @post_stack, {'id' => $id, 'date' => $ts,
		      'title' => $title, 'author' => $author,
		       'path' => $path, 'preview' => $snippet};
}

my $tags = {};

=head2 push_tags( $id, $timestamp, $title, $author, $tags )

Given post metadata, splits out the list of tags in the metadata and
adds the post to the relevant tag lists.

=cut

sub push_tags {
    my ($id, $ts, $title, $author, $tags) = @_;
    $tags =~ s/\s+//g;
    my @tags = split(/,/, $tags);

    foreach(@tags){
	tag_push($id, $ts, $title, $author, $_);
    }
}

=head2 tag_list ( )

Return a list of all the known tags.

=cut

sub tag_list {
    return (keys %{$tags});
}

=head2 tag_load( @tags )

To re-create the list of tags from the state file, so we don't have to
rediscover them every run.

=cut

sub tag_load {
    my @tags = @_;
    foreach (@tags){
	$tags->{lc($_)} = [];
    }
}

=head2 tag_push( $post_id, $post_timestamp, $post_title, $post_author, $tag )

Include a post in the list of tags.

=cut

sub tag_push {
    my ($id, $ts, $title, $author, $tag) = @_;

    $tag =~ s/^\s+//;
    $tag =~ s/\s+$//;
    push @{$tags->{lc($tag)}}, {'id' => $id, 'date' => $ts,
			     'title' => $title, 'author' => $author};
}

my $h = HTML::Tiny->new('mode' => 'html');

=head2 generate ( $mode )

Creates a page (or series of pages, depending on number of posts) of
posts listed in reverse chronological order, with a snippet of preview
text along with links to the post's full page.

C<$mode> options are:

=over

=item C<index>

    Produces main index page(s) in the output directory, to be used as
    the front page(s) of the blog.

=item I<anything else>

    Produces archive indexes... which is pretty much identical to the
    index pages, except being in the archive path (alongside the posts
    themselves) and having 'Archive' appended to the page title.

    No, I have no idea why there's this apparent distinction between
    the two. There is no difference other than the location, and
    having the word 'archive' in them.

    I<Maybe there was a difference, at one time, but now there isn't.>

=back


=cut

sub generate {
    my $mode = shift;
    # Sort the posts in reverse chronological order.
    my @posts = sort { $b->{'date'} cmp $a->{'date'} } @post_stack;
    my $postH;
    my $title;
    my $filename;
    my $pagecount = 1;

    # While the number of pages is less than the number of posts
    # divided by however many posts are fit to a page, keep generating
    # pages.
    do{

	if($mode eq 'index'){
	    $filename = Klompen::output_dir() . "/index";
	    # We don't want our default index to be 'index1', we want it
	    # to just be 'index'.
	    $filename = $filename . $pagecount if($pagecount > 1);
	    print STDERR "Creating index page $pagecount.\n" if(Klompen::verbose_p());
	    $filename = $filename . Klompen::output_ext();
	    $title = Klompen::site_name();
	} else {
	    my $pageno;
	    # As above, default (page 0) indexes don't get a number.
	    if($pagecount > 1){
		$pageno = $pagecount;
	    } else {
		$pageno = "";
	    }
	    $filename = Klompen::archive_path("index" . $pageno);
	    $title = Klompen::site_name() . " Archive";
	}

	open($postH, ">:encoding(UTF-8)", $filename) || croak "Could not create archive/index: " . $filename;

	print $postH Klompen::Site::doctype() . "\n";

	print $postH $h->html([
	    $h->head([
		$h->meta ({'http-equiv' => 'Content-Type', 'content' => 'text/html; charset=UTF-8'}),
		$h->meta ({'name' => 'Description', 'content' => "Archive of " . Klompen::site_name() . " posts."}),
		$h->meta ({'name' => 'og:title', 'content' => $title }),
		$h->meta ({'name' => 'og:site_name', 'content' => Klompen::site_name() }),
		$h->meta ({'name' => 'twitter:card', 'content' => 'summary'}),
		$h->meta ({'name' => 'twitter:description', 'content' => "Archive of " . Klompen::site_name() . " posts."}),
		$h->title($title),
		$h->link ({'rel' => 'stylesheet', 'type' => 'text/css',
			   'media' => 'screen', 'href' => Klompen::style_url()})
		     ]),
	    $h->body([
		Klompen::header_contents(),
		$h->h1($title),
		# Add links and preview text for posts (pagecount+0) to (pagecount + number of posts on a page)
		$h->div({'id' => 'archive'},[create_links(0, undef, @posts[(($pagecount-1) * 10) .. ((($pagecount-1) * 10) + 9) ])]),
		# Add in a set of links to jump between pages.
		$h->div({'id' => 'pageselect'}, [create_pagejump($pagecount, (scalar @posts))]),
		$h->div({'id' => 'menu'}, [Klompen::Site::sidebar_generate($h)]),
		$h->div({'id' => 'footer'}, [
			    Klompen::footer_contents(),
			    $h->p({'id' => 'credit'}, "Proudly powered by " . $h->tag('a', {'href' => 'https://github.com/TamberP/Klompen',	'title' => 'Klompen on GitHub'}, 'Klompen') . "."),
			])])]);
	close $postH;

	# On to the next page.
	$pagecount = $pagecount + 1;
    } while($pagecount < ((scalar @posts) / 10));
}

=head2 generate_rss ( )

Takes the global list of posts, sorts it in reverse chronological
order, and creates an RSS feed from C<rss_limit> of them.

=cut

sub generate_rss {
    my $rss = XML::RSS::SimpleGen->new(Klompen->base_url(),
				       Klompen->site_name());
    # Sort posts in reverse chronological order
    my @posts = sort { $b->{'date'} cmp $a->{'date'} } @post_stack;
    $rss->item_limit(Klompen->rss_limit());

    create_links(1, $rss, @posts);

    $rss->save(Klompen->rss_path());
}


sub generate_tag_archive {
    my $fileH;
    File::Path::make_path(Klompen::tag_path());
    foreach my $tag (keys %{$tags}){
	# This gives us each tag in turn.
	my @posts = sort { $b->{'date'} cmp $a->{'date'} } @{$tags->{$tag}};
	open($fileH, '>:encoding(UTF-8)', Klompen::tag_path($tag));

	print $fileH $h->html([
	    $h->head([
		$h->meta({'http-equiv' => 'Content-Type', 'content' => 'text/html; charset=UTF-8'}),
		$h->title(Klompen::site_name . " tags || $tag"),
		$h->link ({'rel' => 'stylesheet', 'type' => 'text/css',
			   'media' => 'screen', 'href' => Klompen::style_url}),
		$h->link ({'rel' => 'alternate', 'type' => 'application/rss+xml',
			   'title' => 'RSS', 'href' => Klompen::rss_url()})
		     ]),
	    $h->body([
		Klompen::header_contents(),
		$h->h1("All posts tagged $tag"),
		$h->div({'id' => 'archive'}, [create_links(0, undef, @posts)]),
		$h->div({'id' => 'menu'}, [Klompen::Site::sidebar_generate($h)]),
		Klompen::footer_contents(),
		$h->p({'id' => 'credit'}, "Proudly powered by " . $h->tag('a', {'href' => 'https://github.com/TamberP/Klompen',
										'title' => 'Klompen on GitHub'}, 'Klompen') . "."),
		     ])]);
	close $fileH;
    }
}

=head2 create_links( $postp, $rss, @posts )

Creates a page of posts, linking to the full page of the post,
optionally including preview text, and adding the post item to the RSS
feed.

=over

=item C<$postp>: 1 if including the preview text for the post, 0 otherwise.

=item C<$rss>: RSS XML generation object, or undef if not generating an RSS feed.

=item C<@posts>: List of posts & metadata.

=back

=cut

# The creation of the list of links is handled here because we can't
# use a loop inside the HTML outputting functions, it seems.
sub create_links {
    my $postp = shift; # Do we include the first paragraph/preview
		       # text of the post? (1 to include it, 0
		       # otherwise.)
    my $rss   = shift; # The RSS XML generation object. undef if we're not
		       # generating a feed.
    my @posts = @_;    # List of posts we're generating output for.

    # This needs to be set to a value unlikely to ever happen for a
    # date.
    my $last_month = -1;
    my $str = '';
    foreach(@posts){
	{
	    if($rss){
		# RSS feed mode: Add this item to the RSS feed, then
		# skip to the next item without doing any other
		# generation.
		$rss->item(Klompen::archive_url($_->{'id'}), $_->{'title'}, Klompen::format($_->{'preview'}));
		next;
	    }

	    my @postdate = localtime($_->{'date'});
	    # If the month of this post is different to the last one
	    # we saw, print a nice little header to separate the
	    # posts.
	    # e.g. "Posts for November, 2011"
	    if($postdate[4] != $last_month){
		$str = $str . $h->h2("Posts for " . strftime("%B, %Y", localtime($_->{'date'})));
		$last_month = $postdate[4];
	    }
	}

	# Strip leading & trailing whitespace
	$_->{'title'} =~ s/^\s+|\s+$//;

	# Add the link to the post, using the post title...
	$str = $str . $h->tag('a', {'class' => 'post-link',
				    'href' => Klompen::archive_url($_->{'id'}),
				    'title' => "Read \"" .
					$h->entity_encode($_->{'title'}) . "\"."},
			      $h->entity_encode($_->{'title'}));

	# ...and stick the date after it.
	$str = $str . "&nbsp&nbsp;" . $h->em({'class' => 'archive_date'}, strftime("%e %B %Y", localtime($_->{'date'})));
	$str = $str . $h->br();

	# If any preview text exists for this post, include it, and
	# follow up with a "Read more" link.
	if(defined($_->{'preview'})){
	    $str = $str . $h->div({'class' => 'snippet'}, [
				    Klompen::format($_->{'preview'}),
				    $h->tag('a', {
					'class' => 'readmore',
					'href' => Klompen::archive_url($_->{'id'}),
					'title' => "Read \"" . $h->entity_encode($_->{'title'}). "\"."},
					    "Read more&hellip;")
				]);
	    $str = $str . $h->br() . $h->br();
	}
    }
    return $str;
}

=head2 create_pagejump ( $pagenumber, $totalposts )

Create the row of buttons for jumping between pages.

Returns a string of HTML.

=cut

sub create_pagejump {
    my $pagenumber = shift;
    my $totalposts = shift;
    my $totalpages = (ceil($totalposts) / 10);

    my $str = '';
    for(my $i=1; $i < $totalpages; $i++){
	if($i eq $pagenumber){
	    # Jump box for the current page isn't linkified.
	    $str = $str . "$i";
	} else {
	    if($i eq 1){
		# Page 1 doesn't have a number suffix.
		$str = $str . $h->tag('a', {'class' => 'nav-link',
					    'href' => Klompen::archive_url('index'),
					    'title' => "Go to page 1"}, 1);
	    } else {
		$str = $str . $h->tag('a', {'class' => 'nav-link',
					    'href' => Klompen::archive_url('index' . $i),
					    'title' => "Go to page $i"}, $i);
	    }
	}
	$str = $str . " ";
    }
    return $str;
}

1;
