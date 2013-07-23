package Klompen::Archive;

use HTML::Tiny;
use XML::RSS::SimpleGen;
use Klompen;
use Klompen::Site;
use POSIX qw(strftime);
use Date::Parse qw(str2time);
use File::Slurp;
use File::Path;
use Carp;
our @post_stack;

sub push {
    my ($id, $ts, $title, $author, $path, $snippet) = @_;

    push @post_stack, {'id' => $id, 'date' => $ts, 
		      'title' => $title, 'author' => $author,
		       'path' => $path, 'preview' => $snippet};
}

my $tags = {};

sub push_tags {
    my ($id, $ts, $title, $author, $tags) = @_;
    $tags =~ s/\s+//g;
    my @tags = split(/,/, $tags);

    foreach(@tags){
	tag_push($id, $ts, $title, $author, $_);
    }
}

sub tag_list {
    return (keys %{$tags});
}

sub tag_push {
    my ($id, $ts, $title, $author, $tag) = @_;

    $tag =~ s/^\s+//;
    $tag =~ s/\s+$//;
    push @{$tags->{lc($tag)}}, {'id' => $id, 'date' => $ts,
			     'title' => $title, 'author' => $author};
}

my $h = HTML::Tiny->new('mode' => 'html');

sub generate {
    my $mode = shift;
    # Sort the posts in reverse chronological order.
    my @posts = sort { $b->{'date'} cmp $a->{'date'} } @post_stack;
    my $postH;
    my $title;

    if($mode eq 'index'){
	open($postH, ">:encoding(UTF-8)", Klompen::output_dir() . "/index" . Klompen::output_ext()) || print STDERR "!! Could not create index page " . Klompen::output_dir() . 
	     "/index" . Klompen::output_ext() && return -1;
	$title = Klompen::site_name();
    } else {
	open($postH, ">:encoding(UTF-8)", Klompen::archive_path("index")) || croak "Could not create archive path:" . Klompen::archive_path("index");
	$title = Klompen::site_name() . " Archive";
    }

    print $postH Klompen::Site::doctype() . "\n";

    print $postH $h->html([
	$h->head([
	    $h->meta ({'http-equiv' => 'Content-Type', 'content' => 'text/html; charset=UTF-8'}),
	    $h->title($title),
	    $h->link ({'rel' => 'stylesheet', 'type' => 'text/css', 
		       'media' => 'screen', 'href' => Klompen::style_url()})
		 ]),
	$h->body([
	    Klompen::header_contents(),
	    $h->h1($title),
	    $h->div({'id' => 'archive'},[create_links(0, undef, @posts)]),
	    $h->div({'id' => 'menu'}, [Klompen::Site::sidebar_generate($h)]),
	    $h->div({'id' => 'footer'}, [
			Klompen::footer_contents(),
			$h->p({'id' => 'credit'}, "Proudly powered by " . $h->tag('a', {'href' => 'https://github.com/TamberP/Klompen',	'title' => 'Klompen on GitHub'}, 'Klompen') . "."),
		    ])])]);
    close $postH;
}

sub generate_rss {
    my $rss = XML::RSS::SimpleGen->new(Klompen->base_url(),
				       Klompen->site_name());
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

# The creation of the list of links is handled here because we can't
# use a loop inside the HTML outputting functions, it seems.
sub create_links {
    my $postp = shift; # Do we include the first paragraph of the
		       # post? (1 to include it, 0 otherwise.)
    my $rss   = shift; # The XML generation object. undef if we're not
		       # generating a feed.
    my @posts = @_;

    # This needs to be set to a value unlikely to ever happen for a
    # date.
    my $last_month = -1;
    my $str = '';
    foreach(@posts){
	{

	    # Add this item to the RSS feed.
	    if($rss){
		$rss->item(Klompen::archive_url($_->{'id'}), $_->{'title'});
		return "";
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
	$_->{'title'} =~ s/^\s+|\s+$//;
	$str = $str . $h->tag('a', {'class' => 'post-link',
				    'href' => Klompen::archive_url($_->{'id'}),
				    'title' => "Read \"" . 
					$h->entity_encode($_->{'title'}) . "\"."},
			      $h->entity_encode($_->{'title'}));
	$str = $str . "&nbsp&nbsp;" . $h->em({'class' => 'archive_date'}, strftime("%e %B %Y", localtime($_->{'date'})));
	$str = $str . $h->br();
	if(defined($_->{'preview'})){
	    $str = $str . $h->p({'class' => 'snippet'}, [
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

1;
