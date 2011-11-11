package Klompen;

use utf8;
use strict;
use warnings;

# Default data
our $config = {
    'posts' => {
	'extension' => '.htm',
	'output_dir' => 'test',
	'source_dir' => '',
    },
    'links' => [],
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

1;
