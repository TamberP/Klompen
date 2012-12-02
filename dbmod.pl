#!/bin/env perl

# Utility to create and modify the blog metadata database.  Requires
# that the database itself be created, and configured, then creates
# the tables for klompen.
#
# Usage: dbmod.pl -f <config file>

use common::sense;
use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
use File::Slurp;
use JSON;
use DBI;

my $VERSION = 2012120101;
my $VNAME   = 'fruitcake';

sub HELP_MESSAGE {
    my $fd = shift;

    print $fd "Options:\n";
    print $fd "-f\t Klompen config file\n";
    print $fd "!! Specify only one of a, c or d !!\n";
    print $fd "-a\t Add author.\t Args: 'username' 'realname' 'email' 'www address'\n";
    print $fd "-c\t Add category.\t Args: 'category name' 'category description'\n";
    print $fd "-d\t Create database. (default)\n"
}

sub VERSION_MESSAGE {
    my $fd = shift;
    print $fd "Klompen Database Modification Tool $VERSION ($VNAME)\n";
}

my %options;

getopts('acdf:', \%options);
if(!defined($options{'f'})){
    $options{'f'} = './klompen.cfg';
}

my $conf = decode_json(File::Slurp::read_file($options{'f'}));

if(!defined($conf->{'db'}) || !defined($conf->{'db'}->{'name'})){
    die "No database configured.\n";
}

# Default to using SQLite if no database type is specified.
$conf->{'db'}->{'type'} = 'sqlite' if(!defined($conf->{'db'}->{'type'}));

my $db = DBI->connect('dbi:' . $conf->{'db'}->{'type'} . ':' . $conf->{'db'}->{'name'});

die "Database connection failed: " . DBI::errstr . "\n" if(!defined($db));

if(defined($options{'d'})){
    $db->do("CREATE TABLE authors (id TEXT PRIMARY KEY ASC ON CONFLICT ABORT, email TEXT," .
	    "www TEXT, name TEXT)");
    die "Can't create authors table: $db->errstr\n" if(defined($db->errstr));
    $db->do("CREATE TABLE posts (id PRIMARY KEY ASC ON CONFLICT ABORT, title TEXT NOT NULL," .
	    "author TEXT NOT NULL, path TEXT NOT NULL, FOREIGN KEY(author) " .
	    "REFERENCES authors(id))");
    die "Can't create posts table: $db->errstr\n" if(defined($db->errstr));
    $db->do("CREATE TABLE categories (id INTEGER PRIMARY KEY ASC AUTOINCREMENT," .
	    "name TEXT NOT NULL, desc TEXT NOT NULL)");
    die "Can't create categories table: $db->errstr\n" if(defined($db->errstr));
    $db->do("CREATE TABLE dates (post INTEGER NOT NULL, creation BOOLEAN, ts DATETIME " .
	    "NOT NULL, FOREIGN KEY(post) REFERENCES post(id))");
    die "Can't create dates table: $db->errstr\n" if(defined($db->errstr));
    $db->do("CREATE TABLE p2c ( post INTEGER NOT NULL, cat INTEGER NOT NULL, FOREIGN " .
	    "KEY(post) REFERENCES post(id), FOREIGN key(cat) REFERENCES categories(id))");
    die "Can't create p2ctable: $db->errstr\n" if(defined($db->errstr));

    print "Database created successfully.\n";
    goto END;
}

if(defined($options{'c'}) && !defined($options{'a'})){
    # Defining a category
    # ARGV
    #      0: category name
    #      1: category description
    die "Usage for -c: ./dbmod.pl -c <category name> <category description>\n" if(!defined($ARGV[0]) || !defined($ARGV[1]));
    my $row = $db->selectrow_hashref("SELECT id FROM categories WHERE name = ?", undef, $ARGV[0]);
    if(!defined($row)){
	die "Check for existing category failed: $db->errstr\n" if(defined($db->errstr));

	# This category doesn't exist, create it.
	$db->do("INSERT INTO categories VALUES (NULL, ?, ?)", undef, @ARGV[0 .. 1]);
	die "Creating category $ARGV[0] failed: $db->errstr\n" if(defined($db->errstr));

	print "Category $ARGV[0] created.\n";
    } else {
	# This category exists. Update it with a new description.
	$db->do("UPDATE categories SET desc = ? WHERE name = ?", undef, reverse(@ARGV[0 .. 1]));
	die "Updating category $ARGV[0] failed: $db->errstr\n" if(defined($db->errstr));

	print "Category $ARGV[0] updated.\n";
    }

    goto END;
}

if(defined($options{'a'}) && !defined($options{'c'})){
    # Adding an author
    # ARGV
    #      0: Simple user-name to refer to the author.
    #      1; Author's human-readable name.
    #      2: [Optional] Author's email address.
    #      3: [Optional] Author's web address. (At least 'null' must
    #         be specified for the email address, if this is
    #         specified, and you don't want to set an email address.)
    die "Usage for -a: ./dbmod.pl -a <author refname> <author realname> [<author email address>] [<author www address>]\n" if(!defined($ARGV[0]) || !defined($ARGV[1]));

    my $row = $db->selectrow_hashref("SELECT id FROM authors WHERE id = '$ARGV[0]'");

    if(!defined($row)){
	die "Check for existing author failed: $db->errstr\n" if(defined($db->errstr));

	$ARGV[2] = 'null' if(!defined($ARGV[2]));
	$ARGV[3] = 'null' if(!defined($ARGV[3]));

	$db->do("INSERT INTO authors VALUES (?, ?, ?, ?)", undef, @ARGV[0 .. 3]);
	die "Creating author $ARGV[0] failed: $db->errstr\n" if(defined($db->errstr));

	print "Author $ARGV[0] created.\n";
    } else {
	my @vals = ($ARGV[1], $ARGV[2], $ARGV[3], $ARGV[0]);

	$db->do("UPDATE authors SET name = ?, email = ?, www = ? WHERE id = ?", undef, @vals);
	die "Updating author $ARGV[0] failed: $db->errstr\n" if(defined($db->errstr));

	print "Author $ARGV[0] updated.\n";
    }


}

END:
    1;
