package Klompen::Post;
use utf8;
use strict;
use warnings;

use HTML::Tiny;
use Text::Markdown 'markdown';
use Date::Parse qw(strptime str2time);
use POSIX qw(strftime);
use Klompen qw(output_directory post_extension);
use Klompen::Site;

my $h = HTML::Tiny->new( 'mode' => 'html' );

sub generate {
    my $path = shift;
    my $metadata;
    my $post_fh;
    open($post_fh, '<:encoding(UTF-8)', $path)
	|| die "Could not open file $path";

    # Read through the file, chunking the meta-data until a line
    # containing only: "--text follows this line--" is reached.
    my $line;
    my $pos = 0;
    while (<$post_fh>){
	$line = $_;
	if($line =~ m/^--text follows this line--/){
	    $pos = tell($post_fh);
	    last;
	}
	my @tmp = split(/:/, $line, 2);
	$metadata->{lc($tmp[0])} = $tmp[1];
    }
    # Now, slurp in the article's text. (The markdown source needs to
    # be parsed all in one go for some parts to be parsed properly.)
    my $article_src;
    {
	local $/=undef;
	seek $post_fh, $pos, 0;
	$article_src = <$post_fh>;
	close($post_fh);
    }

    if(!defined($article_src)){
	print "Post $path is blank!";
	return -1;
    }

    if(!defined($metadata->{'id'})){
	$metadata->{'id'} = Klompen::next_id;
	Klompen::write_id($path, $metadata->{'id'});
    } else {
	$metadata->{'id'} =~ s/^\s//;
	$metadata->{'id'} =~ s/\s$//;
	Klompen::read_id($metadata->{'id'});
    }

    Klompen::Archive::push($metadata->{'id'},
    Date::Parse::str2time($metadata->{'date'}), $metadata->{'title'},
    $metadata->{'author'});

    # Now, output what we can, because we must.
    open($post_fh, '>:encoding(UTF-8)', post_output_path($metadata)) || die "Could not write out to " . post_output_path($metadata);
    print $post_fh $h->html([
	$h->head([
	    $h->title($h->entity_encode($metadata->{'title'})),
	    $h->link ({'rel' => 'stylesheet', 'type' => 'text/css', 'media' => 'screen', 'href' => Klompen::stylesheet_url}),
	    $h->meta ({'http-equiv' => 'Content-Type', 'content' => 'text/html; charset=UTF-8'}),
		 ]),
	$h->body([
	    # We'd include include/header.txt here, I think.
	    $h->h1({'id' => 'post_title'}, $h->entity_encode($metadata->{'title'})),
	    $h->div({'id' => 'meta'}, [
			"Filed under: " . 
			$h->span({'id' => 'post-tags'}, linkify_tags($metadata->{'tags'})) . " by " . 
			$h->span({'id' => 'post-author'}, linkify_author($metadata->{'author'})),
			$h->br(),
			$h->span({'id' => 'post-date'}, $h->entity_encode((POSIX::strftime "%a, %e %B %Y @ %R", strptime($metadata->{'date'})))),
			]),
	    $h->div({'id' => 'content'}, markdown($article_src)),
	    $h->div({'id' => 'menu'}, [Klompen::Site::sidebar_generate($h)]),
	    # Here, we'd include include/footer.txt
		 ])]);
    Klompen::Archive::push_tags($metadata->{'id'}, str2time($metadata->{'date'}), $metadata->{'title'}, $metadata->{'author'}, $metadata->{'tags'});
}

sub linkify_author {
    # Turns the author info from a string resembling: 
    # "Name <email@host>" into a link to their info page.

    my $author = shift;
    my @author = split(/</, $author);
    $author[0] =~ s/^\s//g;
    $author[0] =~ s/\s$//g;
    return $h->tag('a',
		   {'href'  => '/author/' . lc($h->url_encode($author[0])),
		    'title' => "See " . $h->entity_encode($author[0]) . "'s profile page."},
		   $h->entity_encode($author[0]));
}

sub linkify_tags {
    # Need to create a link to each tag's correspondig archive page,
    # then output the list in a nice, human-readable format.
    # ("tagA, tagB, tagC")
    my $tagline = shift;
    $tagline =~ s/\s//g; # Rip out whitespace.
    my @tags = split(/,/, $tagline);
    my @tagl;
    my $i=0;
    foreach(@tags){
	$tagl[$i] = $h->tag('a', 
			      { 'href' => Klompen->tag_url() . lc($h->url_encode($_)) . Klompen->post_extension(),
				'title' => "See all posts in category \"" . $h->entity_encode($_) . "\""}, 
			      $h->entity_encode($_));
	$i++;
    }
    undef $i;
    return join(', ', @tagl);
}

sub post_output_path {
    # Produces the output path for the post in question.
    # %outputdir%/%pathspec%/%postid%.%ext%
    # (Extension may not be .htm(l))
    my $metadata = shift;
    my $id = $metadata->{'id'};
    $id =~ s/^\s//;
    $id =~ s/\s$//;
    return Klompen::output_directory() . "/archives/$id" . Klompen::post_extension();
}

1;
