package Klompen;

use utf8;
use strict;
use warnings;
use File::Spec;
use JSON qw(decode_json encode_json);

=head1 Klompen

This module contains general support functions for the rest of
Klompen.

=cut

# Default data

my $config = {
    'posts' => {
	'output' => { 'extension' => '.htm', 'encoding' => 'utf-8' },
	'input'  => { 'extension' => '.txt', 'encoding' => 'utf-8' },
    },
    'links' => [],
};

my $_state = {
    'id'   => 0,
};

###############################################################################
## TRACTOR'd
###############################################################################

=head2 source_ext( )

Returns the extension one should expect source files to have. (May be
an empty string, in which case there is no extension.)

=cut

sub source_ext {
    return $config->{'posts'}->{'input'}->{'extension'} || '';
}

=head2 output_ext( )

Returns the extension for output files. May I<also> be an empty
string.

=cut

sub output_ext {
    return $config->{'posts'}->{'output'}->{'extension'} || '';
}


=head2 source_dir( )

Returns the directory that will be searched for source files; with
B<no> trailing slash.

=cut

sub source_dir {
    croak("Source directory not configured. Nowhere to look for source files") if(!defined($config->{'posts'}->{'input'}->{'directory'}));
    return File::Spec->canonpath($config->{'posts'}->{'input'}->{'directory'});
}

=head2 output_dir( )

Returns the directory that the generated content will be output to;
again, with B<no> trailing slash.

=cut

sub output_dir {
    croak("Output directory not configured. Nowhere to put the output files") if(!defined($config->{'posts'}->{'output'}->{'directory'}));

    return File::Spec->canonpath($config->{'posts'}->{'output'}->{'directory'});
}

=head2 source_path(source_filename)

Return the path of the given source file (e.g. returned from scanning
the source directory.)

=cut

sub source_path {
    my $fn = shift;
    return File::Spec->catdir(source_dir(),  $fn);
}

=head2 source_encoding( )

Returns the character encoding the input should be expected to be
in. (Defaults to B<UTF-8>).

=cut

sub source_encoding {
    return $config->{'posts'}->{'input'}->{'encoding'} || 'UTF-8';
}

=head2 output_encoding( )

Returns the character encoding the output should be generated
as. (Defaults to B<UTF-8>)

=cut

sub output_encoding {
    return $config->{'posts'}->{'output'}->{'encoding'} || 'UTF-8';
}

=head2

Returns the URL that all other internal URLs are based off.

=cut

sub base_url {
    my $url = $config->{'base_url'};
    $url =~ s/\/$//g;
    return $url;
}

=head2 site_name( )

This returns the line used to name the blog (e.g. "Joe Bloggs Blog")

=cut

sub site_name {
    return $config->{'site_name'};
}

=head2 style_url( )

This returns the fully-qualified URL to the stylesheet.

=cut

sub style_url {
    my $style = $config->{'posts'}->{'output'}->{'urls'}->{'stylesheet'};
    if($style =~ m/^https?:\/\//i){
	# Full URL
	return $style;
    } else {
	# Relative URL
	return base_url() . "/$style";
    }
}

=head2 Tags

=head3 tag_path_rel( )

Returns the relative path of the tag output folder.

=cut

sub tag_path_rel {
    my $tag = shift;
    my $tagbase = File::Spec->canonpath($config->{'posts'}->{'output'}->{'urls'}->{'tags'});

    # If we're given a tag, we need to provide the path to that output
    # file.
    return File::Spec->catfile($tagbase, $tag . output_ext()) if(defined($tag));
    return $tagbase;
}

=head3 tag_path( )

Returns the full path of the tag output folder.

=cut

sub tag_path {
    return File::Spec->catfile(output_dir(), tag_path_rel(shift));
}

=head3 tag_url( )

Return the full URL of the tag folder, or the given tag.

=cut

sub tag_url {
    return base_url() . "/" . tag_path_rel(shift);
}

=head3 archive_path_rel($archive)

Return the path of the archive folder, or the given archive number,
relative to the output directory.

=cut

sub archive_path_rel {
    my $archive = shift;
    my $archivebase = File::Spec->canonpath($config->{'posts'}->{'output'}->{'urls'}->{'archives'});
    return "$archivebase/$archive" . output_ext() if(defined($archive));
    return $archivebase;
}

=head3 archive_path($archive)

Similar to the above, but returns the path to the archive folder (or
given archive file), including that of the output directory.

=cut

sub archive_path {
    return output_dir() . "/" . archive_path_rel(shift);
}

=head3 archive_url($archive)

Returns the full URL of the archive folder (or the given archive ID).

=cut

sub archive_url {
    return base_url() . "/" . archive_path_rel(shift);
}

=head3 author_path_rel($author)

Returns the relative path to the author profile page directory, or to
the given author's profile page.

=cut

sub author_path_rel {
    my $author = shift;
    my $authorbase = File::Spec->canonpath($config->{'posts'}->{'output'}->{'urls'}->{'author_info'});
    return File::Spec->catfile($authorbase, ($author . Klompen::output_ext())) if(defined($author));
    return $authorbase;
}

=head3 author_path($author)

Return path to the author profile folder (or author page), including
output directory.

=cut

sub author_path {
    return File::Spec->catfile(output_dir(), author_path_rel(shift));
}

=head3 author_url($author)

Return full URL of the author folder, or given author's profile page.

=cut

sub author_url {
    return base_url() . "/" . author_path_rel(shift);
}

=head3 author_src_path_rel($author)

Return the path of the author profile input files directory, relative
to the input directory; or the path of the given author's profile
source.

=cut

sub author_src_path_rel {
    my $author = shift;
    my $authorbase = File::Spec->canonpath($config->{'input'}->{'author_info'});
    $authorbase = 'profile' if(!defined($authorbase));

    return File::Spec->catfile($authorbase, ($author . source_ext())) if(defined($author));
    return $authorbase;
}

=head3 author_src_path($author)

Returns full path to author profile input files, or to the given
author's profile page source.

=cut

sub author_src_path {
    return File::Spec->catdir(source_path(), author_src_path_rel(shift));
}

=head2 list_source_posts( )

Returns an array containing the names of all the posts in the source
directory. (This is filtered by the configured file extension, so
files with a different extension will not be listed.)

=cut

sub list_source_posts {
    my @tmp = File::Slurp::read_dir(source_dir());
    my $extension;
    if(defined($extension = source_ext())){
	return grep{ /($extension)$/ } @tmp;
    } else {
	return @tmp;
    }
}

sub list_sidebar_links {
    return $config->{'links'};
}

=head2 write_state( )

Write out a small JSON file (state.jsn) containing our state; so we
can correctly deal with things like non-ID'd posts, etc.

=cut

sub write_state {
    File::Slurp::write_file('state.jsn', {'atomic' => 1}, encode_json($_state));
}

=head2 read_state( )

Read in our little generated file that lets us maintain our state
across runs. (Contains things like the highest ID seen, so we can
autoincrement it for newer non-ID'd posts, etc.)

=cut

sub read_state {
    my $state = File::Slurp::read_file('state.jsn', {err_mode => 'quiet'});
    if($state){
	# The state file doesn't exist, or it wasn't read. This isn't
	# a big problem.
	$_state = decode_json($state);
    }
}

=head2 next_id( )

Get the next post-ID, for a post that does not have an
ID. (i.e. Highest seen ID + 1)

=cut

sub next_id {
    $_state->{'id'} += 1;
    return ($_state->{'id'});
}

=head2 read_id( )

If the current ID is higher than the one stored in our state as the
highest, update it. Else, ignore it. (This wouldn't be needed, except
for the directory read occurring out of order.)

=cut

sub read_id {
    my $id = shift;
    $_state->{'id'} = $id if($id > $_state->{'id'});
}

=head2 write_id($path, $id)

Add an ID to a post withut one. (Normally, this is usually the output
from next_id)

B<TODO>: Make this handle a post with a blank ID line, rather than
just a non-existant one.

=cut

sub write_id {
    my $path = shift;
    my $id   = shift;

    File::Slurp::prepend_file($path, "ID: " . $id . "\n");
}

=head2 include_src_path( )

Return the configured path of the location to search for includes.

=cut

sub include_src_path {
    return $config->{'includes'};
}

=head2 header_path( )

The path of the header include file. (FIXME: This and the footer
include file have yet to be changed to be configurable values. This
change will be transparent to the rest of the code, which is
happiness.)

=cut

sub header_path {
    return File::Spec->catfile(include_src_path(), 'header.txt');
}

=head2 footer_path( )

Path of the footer include file.

=cut

sub footer_path {
    return File::Spec->catfile(include_src_path(), 'footer.txt');
}

=head2 header_contents( )

Return the (UTF-8 encoded) contents of the header file. (Not cacheing
it in a variable like last time; the OS's filesystem cacheing will
most likely do a better job that I can.)

=cut

sub header_contents {
    if(defined(header_path())){
	return File::Slurp::read_file(header_path());
    } else {
	return "";
    }
}

=head2 footer_contents( )

=cut

sub footer_contents {
    if(defined(footer_path())){
	return File::Slurp::read_file(footer_path());
    } else {
	return "";
    }
}

=head2 rss_path_rel( )

Returns the relative path of the RSS file.

=cut

sub rss_path_rel {
    return File::Spec->canonpath($config->{'posts'}->{'output'}->{'urls'}->{'rss'});
}

=head2 rss_path( )

Returns the full path of the RSS file.

=cut

sub rss_path {
    my $rel = rss_path_rel();
    if(defined($rel)){
	return File::Spec->catdir(output_dir(),  $rel);
    } else {
	return undef;
    }
}

=head2 rss_url( )

Returns the URL of the RSS file

=cut

sub rss_url {
    my $rel = rss_path_rel();
    if(defined($rel)){
	return base_url() . $rel;
    } else {
	return undef;
    }
}

=head2 rss_limit( )

Returns either the configured limit on the number of items in the RSS
feed, or the default of 10.

=cut

sub rss_limit {
    if(defined($config->{'output'}->{'rss'}->{'limit'})){
	return $config->{'output'}->{'rss'}->{'limit'};
    } else {
	return 10;
    }

}

=head2 config_set( $ )

Used so the config-reading code in the main file can write to the
config variable in this module. (i.e. Setter for configuration data.)

=cut

sub config_set {
    $config = shift;
}

=head2 fragment_length( )

Returns the number of lines long a fragment should be. This is either the value from the configuration file, or 9.

=cut

sub fragment_length {
    return $config->{'posts'}->{'output'}->{'snippet_length'} || 9;
}

1;
