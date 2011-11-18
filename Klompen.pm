package Klompen;

use utf8;
use strict;
use warnings;
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


=head1 Config accessors

These are functions to get at the information contained within the
configuration.  B<It is highly recommended you use these, if you are
modifying the code and need a value from the configuration; that way,
any changes to the configuration file format will not break your
code.> I<(I have already changed the layout of the configuration file
once, don't rely on me not changing it again.)>

=cut

sub conf_input_extension {
=head3 C<conf_input_extension()>

Gives the extension one should expect input files to have.  (Can be
undef, in which case input files have I<no> extension.)

=cut

    return $config->{'posts'}->{'input'}->{'extension'}; 
}

=head3 C<conf_output_extension()>

Gives the extension that output files will be created with. (Can be
undef, in which case the output files have I<no> extension.

=cut

sub conf_output_extension { 
    return $config->{'posts'}->{'output'}->{'extension'}; 
}

=head3 C<conf_input_directory()>

Returns directory that will be searched for input files.

=cut

sub conf_input_directory {
    die "Source directory not configured" if(!defined($config->{'posts'}->{'input'}->{'directory'}));
    return $config->{'posts'}->{'input'}->{'directory'} . "/";
}

=head3 C<conf_output_directory()>

Returns directory that generated output will be placed in.
(Will be created at output if it does not exist.)

=cut

sub conf_output_directory {
    die "Output directory not configured" if(!defined($config->{'posts'}->{'output'}->{'directory'}));
    return $config->{'posts'}->{'output'}->{'directory'} . "/";
}

=head3 C<conf_input_encoding()>

Character encoding input should be expected to be in.  (Defaults to
B<UTF-8>.)

=cut

sub conf_input_encoding {
    return $config->{'posts'}->{'input'}->{'encoding'};
}

=head3 C<conf_output_encoding()>

Character encoding input will be generated in. (Defaults to B<UTF-8>.)

=cut

sub conf_output_encoding {
    return $config->{'posts'}->{'output'}->{'encoding'};
}

=head3 C<conf_base_url()>

The URL that all relative-in-codebase URLs are appended to.  I<Please
use proper URL-get function for whatever you're trying to link to,
rather than constructing it yourself. It will probably work better.>

=cut

sub conf_base_url {
    return $config->{'base_url'};
}


=head3 C<conf_site_name()>

This returns the line used to name the blog (e.g. "Joe Bloggs Blog")

=cut

sub conf_site_name {
    return $config->{'site_name'};
}

=head2 Path functions

Return the paths, relative to the output directory, where various
files are held.

=head3 C<conf_path_style()>

Returns the path of the stylesheet file.

=cut

sub conf_path_style {
    return $config->{'posts'}->{'output'}->{'urls'}->{'stylesheet'};
}

=head3 C<conf_path_tags()>

Location (relative to output directory) where the tag folder will be
created.

=cut

sub conf_path_tags {
    return $config->{'posts'}->{'output'}->{'urls'}->{'tags'} . "/";
}

=head3 C<conf_path_archives()>

Similar to C<conf_path_tags()>, but for the folder where the archives
will be created.

=cut

sub conf_path_archives {
    return $config->{'posts'}->{'output'}->{'urls'}->{'archives'} . "/";
}

=head3 C<conf_path_author()>

Similar to C<conf_path_tags()>, but for the folder where author
profile pages will be created.

=cut

sub conf_path_author {
    return $config->{'posts'}->{'output'}->{'urls'}->{'author_info'};
}

=head1 URL functions

These functions are here to properly create URLs for things used in
Klompen.

=head2 C<stylesheet_url()>

    Return URL of stylesheet

=cut

sub stylesheet_url {
    my $str = conf_base_url();
    $str = $str . "/" if($str !~ /\/$/);
    return $str . conf_path_style();
}

=head2 C<post_archive_url($post_ID)>

    Return URL of given post

=cut

sub post_archive_url($) {
    my $post_num = shift;
    return conf_base_url . conf_path_archives . $post_num . conf_output_extension;
}

=head2 C<tag_url($tag)>

    Return URL of given tag

=cut

sub tag_url($) {
    my $tag = shift;
    return conf_base_url(). conf_path_tags() . lc($tag) . conf_output_extension;
}

=head2 C<author_url($author_name)>

Return the URL to the author's profile page. 

=cut

sub author_url($) {
    my $author_name = shift;
    return conf_base_url . conf_path_author . lc($author_name) . conf_output_extension;
}

=head1 Other Functions

See following:

=head2 C<list_available_posts()>

Returns an B<unsorted> list of the posts in the source directory.

=cut

sub list_available_posts {
    opendir my($dh), conf_input_directory() || return -1;

    my $extension = conf_input_extension();
    my @posts;
    if(!defined($extension)){
	# Get everything except . and ..
	@posts = grep{ !/^\.+/ } readdir $dh;
    } else {
	@posts = grep{ /($extension)$/ } readdir $dh;
    }
    closedir($dh);
    return @posts;
}

=head2 C<list_menu_links()>

Returns a list of links to add to the sidebar.

=cut

sub links_list {
    return @{$config->{'links'}};
}

=head2 C<read_state()>

Read in our little generated file that lets us maintain our state
across runs. (Contains things like the highest ID seen, so we can
autoincrement it for newer non-ID'd posts, etc.)

=cut

sub read_state {
    my $stateH;
    open($stateH, '<:encoding(UTF-8)', "state.jsn") || return -1;
    local $/=undef;
    my $state = <$stateH>;
    close($stateH);
    $_state = decode_json($state);
}

=head2 C<write_state()>

Write out a small JSON file (state.jsn) containing our state; so we
can correctly deal with things like non-ID'd posts, etc.

=cut

sub write_state {
    my $stateH;
    open($stateH, '>:encoding(UTF-8)', "state.jsn") || printf "Can't write state. (state.jsn)\n";
    print $stateH encode_json($_state);
    close($stateH);
}

sub next_id {
    # Get the next (i.e. highest + 1) post-ID.
    $_state->{'id'} += 1;
    return ($_state->{'id'});
}

# If the current ID is higher than the stored one, set the latter to
# the former.
sub read_id {
    my $id = shift;
    if($id > $_state->{'id'}){
	$_state->{'id'} = $id;
    }
}

=head2 C<write_id($path, $id)>

Add an ID to a post without one. (The ID given is usually the one
returned from next_id)

B<TODO>: Make this correctly handle a post with a blank ID in
it. (That is, a line with "ID: ") Need to replace that line with the
correct one.

=cut

sub write_id {
    # Add/update the ID to the given post.
    my $path = shift;
    my $id   = shift;
    open(postIN, '<:encoding(UTF-8)', $path);
    open(postOUT, '>:encoding(UTF-8)', $path . ".new");
    # Prepend the new ID to the top of the file.
    print postOUT "ID: $id\n";
    while(<postIN>){
	print postOUT $_;
    }
    close(postIN);
    close(postOUT);
    rename "$path.new","$path";
}

sub config_set {
    $config = shift;
}

1;
