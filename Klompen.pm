package Klompen;

use utf8;
use strict;
use warnings;
use JSON qw(decode_json encode_json);

# Default data
our $config = {
    'posts' => {
	'extension' => '.htm',
	'output_dir' => 'test',
	'source_dir' => '',
	'date_display' => "%a %e/%m/%y @ %R",
    },
    'links' => [],
};

my $_state = {
    'id'   => 0,
};

sub list_available_posts {
    my $dirp = shift;
    $dirp = source_directory() if(!defined($dirp));

    opendir my($dh), $dirp || return -1;

    my @available_posts = grep{ /\.txt$/} readdir $dh;
    closedir($dh);

    return @available_posts;
}

sub post_extension {
    return $config->{'posts'}->{'extension'};
}

sub source_directory {
    return $config->{'posts'}->{'source_dir'};
}

sub output_directory {
    return $config->{'posts'}->{'output_dir'};
}

sub stylesheet_url {
    return $config->{'posts'}->{'stylesheet'};
}

sub links_list {
    # Returns the list of links to be added to the sidebar.
    return @{$config->{'links'}};
}

# Read in our little generated file that lets us maintain our state
# across runs. (Contains things like the highest ID seen, so we can
# autoincrement it for newer non-ID'd posts, etc.)
sub read_state {
    my $stateH;
    open($stateH, '<:encoding(UTF-8)', "state.jsn") || return -1;
    local $/=undef;
    my $state = <$stateH>;
    close($stateH);
    $_state = decode_json($state);
}

# Save our state. It's not the end of the world if we can't, though.
sub write_state {
    my $stateH;
    open($stateH, '>:encoding(UTF-8)', "state.jsn") || printf "Can't write state. (state.jsn)\n";
    print $stateH encode_json($_state);
    close($stateH);
}

sub next_id {
    # Get the next (i.e. highest + 1) post-ID; also update the
    # state. (So we don't create the same post ID for the next post.)
    $_state->{'id'} += 1;
    return ($_state->{'id'});
}

# If the current ID is higher than the stored one, set the latter to
# the former.
sub read_id {
    my $id = chomp(shift);
    if($id > $_state->{'id'}){
	$_state->{'id'} = $id;
    }
}

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

sub date_format {
    return $config->{'date_display'};
}
1;
