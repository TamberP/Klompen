use strict;
use warnings;
use utf8;

use Klompen::Post;

my $test_metadata = {
    'title'  => '"A test post&!"',
    'author' => {
	'name' => 'Tamber',
	'email' => 'foo@bar'
    },
    'date'   => "2011/11/11 07:30:30 +0000",
    'id'     => "6",
    'tags'   => ["test", "foo", "bar"]
};

Klompen::Post::generate($ARGV[0]);
