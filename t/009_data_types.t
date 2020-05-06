# -*- perl -*-

use Test::Most;

use Test::DBIx::Class::Factory;
use Test::DBIx::Class {
            schema_class => 'Test::DBIx::Class::Example::Schema',
};

BEGIN { use_ok( 'Test::DBIx::Class::Factory' ); }

my $schema = Schema;
my $factory = Test::DBIx::Class::Factory->new ( schema => $schema );

subtest 'data type support' => sub {
    my $randomizers = $factory->_data_type_randomizer();

    foreach my $randomizer (keys %$randomizers) {
        is(ref($randomizers->{$randomizer}), 'CODE', "supports $randomizer");
    }
};

done_testing();
