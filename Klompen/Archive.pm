package Klompen::Archive;

use HTML::Tiny;

use Klompen;
use Klompen::Site;
use POSIX qw(strftime);
use Date::Parse qw(str2time);
our @post_stack;

sub push {
    my ($id, $ts, $title, $author, $path) = @_;

    push @post_stack, {'id' => $id, 'date' => $ts, 
		      'title' => $title, 'author' => $author,
		       'path' => $path}
}

my $tags = {
    'misc' => [],
};

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
    # Sort the posts in reverse chronological order.
    my @posts = sort { $b->{'date'} cmp $a->{'date'} } @post_stack;
    my $postH;

    open($postH, ">:encoding(UTF-8)", Klompen->conf_output_directory . Klompen->conf_path_archives() . "index" . Klompen->conf_output_extension())
	|| print STDERR "!! Could not create archive page " . Klompen->conf_output_directory . Klompen->conf_path_archives() . "index" . Klompen->conf_output_extension() . "\n" && return -1;

    print $postH $h->html([
	$h->head([
	    $h->meta ({'http-equiv' => 'Content-Type', 'content' => 'text/html; charset=UTF-8'}),
	    $h->title(Klompen->conf_site_name . " archive"),
	    $h->link ({'rel' => 'stylesheet', 'type' => 'text/css', 
		       'media' => 'screen', 'href' => Klompen->stylesheet_url})
		 ]),
	$h->body([
	    # include/header.txt should be here
	    $h->h1("Archive"),
	    $h->div({'id' => 'archive'},[create_links(@posts)]),
	    $h->div({'id' => 'menu'}, [Klompen::Site::sidebar_generate($h)]),
	    # include/footer.txt would be here.
		 ])]);
    close $postH;
}

sub generate_tag_archive {
    my $fileH;
    foreach my $tag (keys %{$tags}){
	# This gives us each tag in turn.
	my @posts = sort { $b->{'date'} cmp $a->{'date'} } @{$tags->{$tag}};
	open($fileH, '>:encoding(UTF-8)',
	     Klompen->conf_output_directory . Klompen->conf_path_tags . $tag . Klompen->conf_output_extension);
	print $fileH $h->html([ 
	    $h->head([
		$h->meta({'http-equiv' => 'Content-Type', 'content' => 'text/html; charset=UTF-8'}),
		$h->title(Klompen->conf_site_name . " tags || $tag"),
		$h->link ({'rel' => 'stylesheet', 'type' => 'text/css',
			   'media' => 'screen', 'href' => Klompen->stylesheet_url})
		     ]),
	    $h->body([
		$h->h1("All posts tagged $tag"),
		$h->div({'id' => 'archive'}, [create_links(0, @posts)]),
		$h->div({'id' => 'menu'}, [Klompen::Site::sidebar_generate($h)]),
		     ])]);
	close $fileH;
    }
}

# The creation of the list of links is handled here because we can't
# use a loop inside the HTML outputting functions, it seems.
sub create_links {
    my $postp = shift; # Do we include the first paragraph of the
		       # post? (1 to include it, 0 otherwise.)
    my @posts = @_;

    # This needs to be set to a value unlikely to ever happen for a
    # date.
    my $last_month = -1;
    my $str = '';
    foreach(@posts){
	{
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
	$str = $str . $h->tag('a',
			      {'href' => Klompen->conf_base_url() . '/archives/' . 
				   $_->{'id'},
				   'title' => "Read \"" . 
				   $h->entity_encode($_->{'title'}) . "\"."},
			      $h->entity_encode($_->{'title'}));
	$str = $str . "&nbsp&nbsp;" . $h->em({'class' => 'archive_date'}, strftime("%e %B %Y", localtime($_->{'date'})));
	$str = $str . $h->br();
    }
    return $str;
}

1;
