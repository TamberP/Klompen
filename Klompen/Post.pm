package Klompen::Post;

use utf8;
use strict;
use warnings;

use HTML::Tiny;
use Date::Parse qw(strptime str2time);
use POSIX qw(strftime);
use Klompen qw(output_directory post_extension);
use Klompen::Site;
use Klompen::Author;

my $h = HTML::Tiny->new( 'mode' => 'html' );

sub generate {
    my $path = shift;
    my $metadata;
    my $post_fh;
    open($post_fh, '<:encoding(UTF-8)', $path)
	|| die "Could not open file $path";

    # Grab the modification time of the source file, for later.
    my $modtime = (stat($post_fh))[9];

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
    # Now, slurp in the article's text. (The document source needs to
    # be parsed all in one go for some parts to be parsed properly.)
    # NOTE: We cannot use: «my $article_src =
    # File::Slurp::read_file($path);», since that does not allow us to
    # skip the header.

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

    # If this post has no id number, grab the next one in the sequence
    # and write it back to the post file; otherwise, strip whitespace
    # and read it in.
    if(!defined($metadata->{'id'})){
	$metadata->{'id'} = Klompen::next_id;
	Klompen::write_id($path, $metadata->{'id'});
    } else {
	$metadata->{'id'} =~ s/^\s//;
	$metadata->{'id'} =~ s/\s$//;
	Klompen::read_id($metadata->{'id'});
    }

    # Grab text from the file, either until we hit a snip line, or
    # reach the maximum length of the preview snippet.
    my $i = 0;
    my $snippet = "";
    for(split /\n/, $article_src){
	if(($_ =~ m/^\s+/) | ($i == Klompen::fragment_length()) | ($_ eq "<!-- snip -->")){
	    last;
	}

	$snippet = $snippet . " $_";
	$i = $i + 1;
    }

    # Push the ID, post date (parsed from human-readable string),
    # title, author, path and preview snippet onto the post stack; so
    # that all useful data is relatively easily accessible.
    Klompen::Archive::push($metadata->{'id'},
    Date::Parse::str2time($metadata->{'date'}), $metadata->{'title'},
    $metadata->{'author'}, $path, $snippet);

    # Add this post's data to the tag records, so that it can be
    # listed by tag.
    Klompen::Archive::push_tags($metadata->{'id'}, str2time($metadata->{'date'}), $metadata->{'title'}, $metadata->{'author'}, $metadata->{'tags'});

    # Check whether or not we need to re-generate this post's output
    # file. If not, then we won't bother formatting the whole
    # document; but all the metadata and snippet should still exist,
    # for indexes.
    if((Klompen::output_incremental() eq 'true') and ($modtime <= (Klompen::last_run()))){
	close($post_fh);
	return 0;
    }

    # Now, output what we can, because we must.

    my $post_buf = Klompen::Site::doctype() . "\n" . $h->html([
	$h->head([
	    $h->title($h->entity_encode($metadata->{'title'}) . " | " . $h->entity_encode(Klompen::site_name())),
	    $h->link ({'rel' => 'stylesheet', 'type' => 'text/css', 'media' => 'screen', 'href' => Klompen::style_url()}),
	    $h->meta ({'http-equiv' => 'Content-Type', 'content' => 'text/html; charset=UTF-8'}),
		 ]),
	$h->body([
	    Klompen->header_contents(),
	    $h->tag('a', {'href' => Klompen::base_url(),
			  'title' => "Back to " . Klompen::site_name() . '.'}, 
		    $h->h1({'id' => 'post_title'}, $h->entity_encode($metadata->{'title'}))),
	    $h->div({'id' => 'meta'}, [
			"Filed under: " . 
			$h->span({'id' => 'post-tags'}, linkify_tags($metadata->{'tags'})) . " by " . 
			$h->span({'id' => 'post-author'}, Klompen::Author::linkify($metadata->{'author'})),
			$h->br(),
			$h->span({'id' => 'post-date'}, $h->entity_encode((POSIX::strftime "%e %B %Y @ %R", strptime($metadata->{'date'})))),
			]),
	    $h->div({'id' => 'content'}, Klompen::format($article_src, $metadata->{'format'})),
	    $h->div({'id' => 'menu'}, [Klompen::Site::sidebar_generate($h)]),
	    $h->div({'id' => 'footer'}, [
			Klompen->footer_contents(),
			$h->p({'id' => 'credit'}, "Proudly powered by " . $h->tag('a', {'href' => 'https://github.com/TamberP/Klompen',
											'title' => 'Klompen on GitHub'}, 'Klompen') . "."),
		    ])])]);

    File::Slurp::write_file(Klompen::archive_path($metadata->{'id'}), {'atomic' => 1, binmode => ':utf8'}, $post_buf);


    # Generate the Author's profile page, if it hasn't been done
    # already; and if we have author source path configured..
    Klompen::Author::generate(Klompen::Author::printify($metadata->{'author'}))
	if(!(Klompen::Author::gen_p(Klompen::Author::printify($metadata->{'author'}))) && defined(Klompen::author_path_rel()));
    1;
}

sub linkify_tags {
    # Need to create a link to each tag's correspondig archive page,
    # then output the list in a nice, human-readable format.
    # ("tagA, tagB, tagC")
    my $tagline = shift;
    return "" if(!defined($tagline));

    $tagline =~ s/\s//g; # Rip out whitespace.
    my @tags = split(/,/, $tagline);
    my @tagl;
    my $i=0;
    foreach(@tags){
	push @tagl, $h->tag('a', 
			      { 'href' => Klompen::tag_url(lc($h->entity_encode($_))),
				'title' => "See all posts in category \"" . $h->entity_encode($_) . "\""}, 
			      $h->entity_encode($_));
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
    return Klompen->conf_output_directory() . Klompen->conf_path_archives() . $id . Klompen->conf_output_extension();
}

1;
