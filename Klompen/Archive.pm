package Klompen::Archive;

use HTML::Tiny;

use Klompen;
use Klompen::Site;
use POSIX qw(strftime);
use Date::Parse qw(str2time);
my @post_stack;

sub push {
    my ($id, $ts, $title, $author) = @_;

    push @post_stack, {'id' => $id, 'date' => $ts, 
		      'title' => $title, 'author' => $author}
}

my $tags = {
    'misc' => [],
};

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

    open($postH, ">:encoding(UTF-8)", Klompen->output_directory()
    . "/archives/index" . Klompen->post_extension())
	|| print "!! Could not create archive page " . Klompen->output_directory() . "/archives/index" . Klompen->post_extension() . "\n" && return -1;

    print $postH $h->html([
	$h->head([
	    $h->meta ({'http-equiv' => 'Content-Type', 'content' => 'text/html; charset=UTF-8'}),
	    $h->title(Klompen->site_name . " archive"),
	    $h->link ({'rel' => 'stylesheet', 'type' => 'text/css', 
		       'media' => 'screen', 'href' => Klompen->stylesheet_url})
		 ]),
	$h->body([
	    # include/header.txt should be here
	    $h->h1("Archive"),
	    create_links(@posts),
	    $h->div({'id' => 'menu'}, [Klompen::Site::sidebar_generate($h)]),
	    # include/footer.txt would be here.
		 ])]);
    close $postH;
}

# The creation of the list of links is handled here because we can't
# use a loop inside the HTML outputting functions, it seems.
sub create_links {
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
	$str = $str . $h->tag('a',
			      {'href' => Klompen->base_url() . '/archives/' . 
				   $_->{'id'} . Klompen->post_extension(),
				   'title' => "Read &quot;" . $h->entity_encode($_->{'title'}) . 
				   "&quot;."},
			      $h->entity_encode($_->{'title'}));
	$str = $str . "&nbsp&nbsp" . $h->em({'class' => 'archive_date'}, strftime("%e %B %Y", localtime($_->{'date'})));
	$str = $str . $h->br();
    }
    return $str;
}

1;
