# -*- perl -*-

use Test::Most;

use Test::DBIx::Class::Factory;
use Test::DBIx::Class {
            schema_class => 'Test::DBIx::Class::Example::Schema',
};

BEGIN { use_ok( 'Test::DBIx::Class::Factory' ); }

my $schema = Schema;
my $factory = Test::DBIx::Class::Factory->new ( schema => $schema );

subtest 'random_data()' => sub {
    my $data = $factory->random_data('text');
    like($data,qr/^[a-z ]+$/i);
    my $data1 = $factory->random_data('varchar');
    like($data1,qr/^[a-z ]+$/i);
    my $data2 = $factory->random_data('integer');
    like($data2,qr/^\d+$/i);
    my $data3 = $factory->random_data('tinyint');
    like($data3,qr/^\d+$/i);
    my $data4 = $factory->random_data('float');
    like($data4,qr/^\d+\.\d+$/i);
    throws_ok { $factory->random_data('unknown') } qr/Unknown data type/;
};

subtest 'random_datetime()' => sub {
    my $dt = $factory->random_datetime();
    is(ref($dt), 'DateTime');
};

subtest 'random_integer()' => sub {
    my $integer = $factory->random_integer(999);
    like($integer,qr/^\d+$/);
};

subtest 'random_real_number()' => sub {
    my $real = $factory->random_real_number(999);
    like($real,qr/^\d+\.\d+$/);
    my $real2 = $factory->random_real_number(999,2);
    like($real2,qr/^\d+\.\d\d$/);
};

subtest 'random_string()' => sub {
    my $string = $factory->random_string;
    like($string,qr/^[a-z ]+$/i);
    my $string2 = $factory->random_string(-1);
    like($string2,qr/^[a-z ]+$/i);
    my $string3 = $factory->random_string(0);
    like($string3,qr/^[a-z ]+$/i);
    my $string4 = $factory->random_string(5);
    like($string4,qr/^[a-z]+ [a-z]+ [a-z]+ [a-z]+ [a-z]+$/i);
};

subtest 'random_word()' => sub {
    my $word = $factory->random_word;

    like($word,qr/^[a-z]+$/i);
    ok(length($word) < 11,"All words should be less than 11 length");
};

done_testing;

