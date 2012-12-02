#!/bin/env perl

# (ideal) Post creation process:
#
# Read in all the options the user's given us. (This could include:
# post title, post author, post tags, post ID, and the path to the
# file containing the Markdown source of this post.)
#
# Default values for options:
# ID:          increment previous post's ID.
# author:      use $USER
# tags:        ['misc']
# title:       "Untitled Post"
# sourcedir:   "./"
#
# If no post path is given, open $EDITOR on a temp. file. When the
# user's finished editing the temporary file (signified by them
# closing their editor, proceed.
#
# Copy post source file to blog's source directory, and create a
# database entry for this post.

use common::sense;
use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
use DBI;
use JSON;
use File::Slurp;
use File::Copy;
use File::Spec;
use Time::localtime;

my $VERSION = 2012112301;
my $VNAME   = 'fruitbasket';

sub HELP_MESSAGE {
    my $fd = shift;

    print $fd "Options:\n";
    print $fd "-a\t author username\n";
    print $fd "-i\t post ID\n";
    print $fd "-t\t post title\n";
    print $fd "-s\t post source file\n";
    print $fd "-n\t Only create post (Don't update an existing one.)\n";
    print $fd "-f\t Blog configuration file to use\n";
    print $fd "-c\t Post categories. (Comma separated list)\n";
}

sub VERSION_MESSAGE {
    my $fd = shift;
    print $fd "Klompen Post Creator $VERSION ($VNAME)\n";
}

sub create_fn {
    my $p_id = shift;
    my $title = shift;

    $title =~ s/[\s\W]/_/g;

    return "$p_id-$title.md";
}

my %options;

getopts('a:d:i:t:s:nc:f:', \%options);

my $conf_filepath = $options{'f'};
if(!defined($conf_filepath)){
    $conf_filepath = './klompen.cfg';
}

######## 1. Read configuration for database location, username and
#  password. (If applicable)

my $conf = decode_json(File::Slurp::read_file($conf_filepath));

if(!defined($conf->{'db'}) || !defined($conf->{'db'}->{'name'})){
    die "No database specified.\n";
}

# We default to using SQLite if no database type is specified.
$conf->{'db'}->{'type'} = 'sqlite' if(!defined($conf->{'db'}->{'type'}));

# TODO: if any other DB type than SQLite is specified, have a check
# (and warning) for username and password where appropriate.

######## 2. Connect to the database.

my $db = DBI->connect('dbi:' . $conf->{'db'}->{'type'} . ':' . $conf->{'db'}->{'name'});

if(!defined($db)){
    # DB Connection failed.
    die "Database connection failed: " . $DBI::errstr . "\n";
}

######## 3. If we're autoincrementing the post-ID, grab the latest,
#           and set our post ID to it + 1;

my $post_id;

if(!defined($options{'i'})){
    # No post ID specified, grab the one from the last-created post,
    # and increment it.

    my $result = $db->selectrow_hashref('SELECT id FROM posts ORDER BY id ASC LIMIT 1');
    if(!defined($result)){
	if(!defined($db->errstr)){
	    # Virgin DB. Create post 0.
	    $result->{'id'} = -1;
	} else {
	    die "Could not get latest post ID: " . $db->errstr . "\n";
	}
    }


    $post_id = ($result->{'id'} + 1);
} else {
    $post_id = $options{'i'};
}

######## 4. Check the given author exists.

{
    my $result = $db->selectrow_hashref('SELECT id FROM authors WHERE id = "' . $options{'a'} . '"');

    if(!defined($result)){
	if(defined($db->errstr)){
	    die "Database error when trying to find author $options{'a'}: " . $db->errstr . "\n";
	}
	die "Could not find author $options{'a'} in database. \n";
    }
}

######## 5. Check specified post ID doesn't already exist.
#
# If it does, then we're updating a post. If, of course, -n is
# specified; then refuse to create the post.

my $f_create = 1;

{
    my $result = $db->selectrow_hashref('SELECT title,author FROM posts WHERE id = "' . $post_id . '"');
    if(!defined($result)){
	if(defined($db->errstr)){
	    # Aw, crap.
	    die "Database error when sanity checking post ID: $db->errstr\n";
	}

	# Hooray, we can be reasonably sure that the specified post doesn't exist.
    } else {
	# Post-ID conflict.
	if(defined($options{'n'})){
	    die "Post ID not unique, and creation specified. Conflicting post: \"$result->{'title'}\" by $result->{'author'}\n";
	}

	# Updating post
	$f_create = 0;
    }
}

######## 6. Copy specified source-file into blog source directory.
# New filename is of format: [id]-[title].md
#
# This should ensure no conflicts, due to non-conflicting ID
# requirement.

# TODO: If no source file is specified, start the user's $EDITOR on a
# tempfile; then, when the editor is closed, use the tempfile as the
# source.

my $post_fn = File::Spec->catfile($conf->{'src'}->{'dir'}, create_fn($post_id, $options{'t'}));

if(defined($conf->{'src'}) && defined($conf->{'src'}->{'dir'})){
    if(defined($options{'s'})){
	File::Copy::copy(File::Spec->rel2abs($options{'s'}), $post_fn) or die "Cannot copy file " . File::Spec->rel2abs($options{'s'}) . ": $!\n";
    } else {
	die "No source file given. What the hell, user?\n";
    }
} else {
    die "No source directory configured. Can't copy file.\n";
}

######## 7. Add metadata to the DB, for the blog to use.

my @categories = split(',', $options{'c'});

{
    $db->do("BEGIN TRANSACTION");
    die $db->errstr . "\n" if(defined($db->errstr));

    if($f_create){
	$db->do("INSERT INTO posts VALUES (?, ?, ?, ?)", undef, ($post_id, $options{'t'}, $options{'a'}, $post_fn));
    } else {
	$db->do("UPDATE posts SET title = ?, author = ?, path = ? WHERE id = ?", undef, ($options{'t'}, $options{'a'}, $post_fn, $post_id));
    }

    die $db->errstr . "\n" if(defined($db->errstr));

    if((!$f_create) && defined($options{'c'})){
	# We're updating a post, and a new set of categories have been
	# defined; delete the existing categories, so that the post
	# can be removed from a category that hasn't been specified in
	# the update.
	$db->do("DELETE FROM p2c WHERE post = ?", undef, ($post_id));
	die $db->errstr . "\n" if(defined($db->errstr));
    }

    # Add all the categories _o/
    foreach(@categories){
	$db->do("INSERT INTO p2c VALUES (?, ?)", undef, ($post_id, $_));
	die $db->errstr . "\n" if(defined($db->errstr));
    }

    # Add a timestamp.
    $db->do("INSERT INTO dates VALUES (?, ?, ?)", undef, ($post_id, $f_create ? 'true' : 'false', ctime()));
    die $db->errstr . "\n" if(defined($db->errstr));

    $db->do("COMMIT");
    die $db->errstr . "\n" if(defined($db->errstr));
}

print "Post created.\n";
