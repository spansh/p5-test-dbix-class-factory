# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;
use Test::DBIx::Class {
        schema_class => 'Test::DBIx::Class::Example::Schema',
};

BEGIN { use_ok( 'Test::DBIx::Class::Factory' ); }

my $schema = Schema;
my $object = Test::DBIx::Class::Factory->new ( schema => $schema );
isa_ok ($object, 'Test::DBIx::Class::Factory');


