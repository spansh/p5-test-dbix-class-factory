package Test::DBIx::Class::Factory;

use strict;
use warnings;

use String::Random;
use DateTime::Event::Random;
use Carp qw( croak );
use Moose;

has schema => (
    is => 'rw',
    isa => 'DBIx::Class::Schema',
    required => 1,
);

has _already_created => (
    is => 'ro',
    isa => 'HashRef',
    writer => '_set_already_created',
);

sub create_record {
    my ($self,$model,%args) = @_;

    if (caller ne __PACKAGE__) {
        $self->_set_already_created({});
    }

    my $code = sub {
        return $self->_create($model,%args);
    };

    return $self->schema->txn_do($code);
}

sub _create {
    my ($self,$model,%args) = @_;

    my @parents = $self->get_belongs_to($model);

    my %unused_columns = %args;

    my %new_columns;
    foreach my $parent (@parents) {
        # Someone has passed in an existing object to use in the creation
        if (exists($args{$parent->{relationship}}) && $parent->{class} eq ref($args{$parent->{relationship}})) {
            delete $unused_columns{$parent->{relationship}};
            $new_columns{$parent->{relationship}} = $args{$parent->{relationship}};
            $self->_already_created->{$parent->{source}} = $args{$parent->{relationship}};
        } else {
            # We've already got a created object we can use for this
            if ( $self->_already_created->{$parent->{source}}) {
                $new_columns{$parent->{relationship}} = $self->_already_created->{$parent->{source}};
            } else {
                # We need to create a new object, lets see if we have any data passed to us
                my $args = $args{$parent->{relationship}} || {};
                if ($args) {
                    delete $unused_columns{$parent->{relationship}};
                }
                $new_columns{$parent->{relationship}} = $self->create_record($parent->{source},%$args);
                $self->_already_created->{$parent->{source}} = $new_columns{$parent->{relationship}};
            }
        }
    }
    # populate the remaining columns with data
    my $source = $self->schema->source($model);
    foreach my $column ($source->columns) {
        delete $unused_columns{$column};
        if (!exists($new_columns{$column})) {
            my $info = $source->column_info($column);
            if (!$info->{is_auto_increment}) {
                if (exists($args{$column})) {
                    $new_columns{$column} = $args{$column};
                } else {
                    $new_columns{$column} = $self->random_data($info->{'data_type'});
                }
            }
        }
    }

    if (scalar(%unused_columns)) {
        croak "Unknown fields [" . join(',', keys(%unused_columns)) . "]";
    }

    my $row = $self->schema->resultset($model)->new(\%new_columns);
    $row->insert;
    return $row;
}


sub get_belongs_to {
    my ($self,$source_name) = @_;

    my $schema = $self->schema;
    my $source = $schema->source($source_name);

    my @relationships = $source->relationships;

    my @belongs_to;
    foreach my $relationship (@relationships) {
        my $info = $source->relationship_info($relationship);
        # TODO: I'm unhappy about delving deep into the attrs class to pull out this 
        # information however there is no other way of getting this information currently.  
        # Therefore this has a set of tests cases specifically for it which will break 
        # if/when this changes in DBIx::Class
        if ($info->{'attrs'}{'is_foreign_key_constraint'}) {
            push @belongs_to,{
                class => $source->related_class($relationship),
                source => $source->related_source($relationship)->source_name, 
                relationship => $relationship,
            };
        }
    }

    return @belongs_to;
}


sub random_data {
    my ($self,$type) = @_;

    my $randomizer = $self->_data_type_randomizer->{$type};

    if ($randomizer) {
        return $self->$randomizer();
    } else {
        croak "Unknown data type $type detected, unable to generate random data";
    }
}

sub random_datetime {
    my $self = shift;

    my $dt = DateTime::Event::Random->datetime;
    return $dt;
}

sub random_integer {
    my $self = shift;
    my $size = shift || 100;

    return int(rand(10)) % 2 if $size==1;

    return int(rand($size));
}

sub random_real_number {
    my $self = shift;
    my $size = shift || 100;
    my $decimals = shift || 16;

    return sprintf('%.'.$decimals.'f', rand($size));
}

sub random_word {
    my $self = shift;

    my $rand = String::Random->new();
    return $rand->randregex('[a-z]{1,10}');
}

sub random_string {
    my $self = shift;

    my $string = '';
    my $words = shift || 0;
    if ($words <= 0) {
        $words = int(rand(10))+1;
    }

    for (my $i=$words;$i;$i--) {
        if ($i < $words) {
            $string .= ' ';
        }
        $string .= $self->random_word;
    }
    return $string;
};

sub _data_type_randomizer {
    my $self = shift;
    return {
        'bfile' => undef,
        'bigint' => undef,
        'binary' => undef,
        'binary_double' => undef,
        'binary_float' => undef,
        'bit' => undef,
        'blob' => undef,
        'blob sub_type text' => undef,
        'blob sub_type text character set unicode_fss' => undef,
        'boolean' => undef,
        'box' => undef,
        'byte' => undef,
        'bytea' => undef,
        'char' => undef,
        'char for bit data' => undef,
        'char(x) character set unicode_fss' => undef,
        'cidr' => undef,
        'circle' => undef,
        'clob' => undef,
        'currency' => undef,
        'datalink' => undef,
        'date' => undef,
        'datetime' => \&random_datetime,
        'datetime year to fraction(5)' => undef,
        'datetime2' => undef,
        'datetimeoffset' => undef,
        'dbclob' => undef,
        'dec' => undef,
        'decimal' => undef,
        'double' => undef,
        'double precision' => undef,
        'enum' => undef,
        'float' => \&random_real_number,
        'graphic' => undef,
        'guid' => undef,
        'hierarchyid' => undef,
        'idssecuritylabel' => undef,
        'image' => undef,
        'inet' => undef,
        'int' => undef,
        'integer' => \&random_integer,
        'interval' => undef,
        'interval day to second' => undef,
        'interval year to month' => undef,
        'line' => undef,
        'list' => undef,
        'long' => undef,
        'long binary' => undef,
        'long nvarchar' => undef,
        'long raw' => undef,
        'long varbit' => undef,
        'long varchar' => undef,
        'long varchar for bit data' => undef,
        'long vargraphic' => undef,
        'longbinary' => undef,
        'longblob' => undef,
        'longchar' => undef,
        'longtext' => undef,
        'lseg' => undef,
        'lvarchar' => undef,
        'macaddr' => undef,
        'mediumblob' => undef,
        'mediumint' => undef,
        'mediumtext' => undef,
        'money' => undef,
        'multiset' => undef,
        'nchar' => undef,
        'nclob' => undef,
        'ntext' => undef,
        'number' => undef,
        'numeric' => undef,
        'nvarchar' => undef,
        'nvarchar2' => undef,
        'path' => undef,
        'point' => undef,
        'polygon' => undef,
        'raw' => undef,
        'real' => undef,
        'rowid' => undef,
        'rowversion' => undef,
        'set' => undef,
        'smalldatetime' => undef,
        'smallint' => undef,
        'smallmoney' => undef,
        'sql_variant' => undef,
        'text' => \&random_string,
        'time' => undef,
        'time with time zone' => undef,
        'timestamp' => \&random_datetime,
        'timestamp with local time zone' => undef,
        'timestamp with time zone' => undef,
        'tinyblob' => undef,
        'tinyint' => sub { $self->random_integer(1) },
        'tinytext' => undef,
        'unichar' => undef,
        'uniqueidentifier' => undef,
        'uniqueidentifierstr' => undef,
        'unitext' => undef,
        'univarchar' => undef,
        'urowid' => undef,
        'varbinary' => undef,
        'varbit' => undef,
        'varchar' => \&random_string,
        'varchar for bit data' => undef,
        'varchar(x) character set unicode_fss' => undef,
        'varchar2' => undef,
        'vargraphic' => undef,
        'xml' => undef,
        'year' => undef,
    };
}


=head1 NAME

Test::DBIx::Class::Factory - Automatically create test data for DBIx::Class

=head1 SYNOPSIS

    use Test::DBIx::Class::Factory;
    # Assuming you use Test::DBIx::Class to create your test data schema
    use Test::DBIx::Class {
        schema_class => 'Test::DBIx::Class::Example::Schema',
    };
    my $schema = Schema;

    my $factory = Test::DBIx::Class::Factory->new( schema => $schema );

    my $person = $factory->create_record( 'Person', name => 'Gareth Harper' );
    is($person->name,'Gareth Harper','Record was created correctly with appropriate name');

    # This *should* fail unless we get extremely lucky with random data
    my $person = $factory->create_record( 'Person' );
    is($person->name,'Gareth Harper','Record was created correctly with appropriate name');

    # If you create a record which has parents they will automatically be created with random data
    my $employee = $factory->create_record( 
        'Company::Employee',
        employee => {
            person => {
                name => "Gareth Harper",
            }
        }
    );
    is($employee->employee->person->name,'Gareth Harper','Record was created correctly with appropriate name');

    # If you have an existing object you would like to use in the heiarchy
    my $person = $factory->create_record( 'Person', name => 'Gareth Harper' );
    my $employee = $factory->create_record( 
        'Company::Employee',
        employee => {
            person => $person,
        }
    );
    is($employee->employee->person->name,'Gareth Harper','Record was created correctly with appropriate person');
  
=head1 DESCRIPTION

The goal of this distribution is to make creation of test data for L<DBIx::Class> based 
applications/libraries much simpler, so your test cases can focus on the actual tests
rather than creating the test data that they run on.  It does this by allowing you to
create objects in the database and automatically creating the object heiarchy (any 
parent objects required) for you.  It will fill any unspecified columns with randomised
data so that you do not rely on it in your tests and they will/should break if that data
is relied upon.

=head1 METHODS

=head2 new
    
This instantiates a new factory object, you need to pass in a L<DBIx::Class::Schema> 
object for it to perform its work on.

    my $factory = Test::DBIx::Class::Factory->new( schema => $schema );

=head2 create_record

This is the main method for this factory.  This creates you a L<DBIx::Class::Row> 
object of your specified type and will automatically create any required parent 
objects for you.  

    $factory->create_record( 'Person' );

If you want any specific data in the record you can pass those in as secondary 
arguments

    $factory->create_record( 'Person', name => 'Gareth Harper' );

If you want specific data in a parent record for this entry you can do so by 
specifying it in the parent relationship name for that record.

    $factory->create_record( 'Person::Employee', person => { name => 'Gareth Harper' } );

This also works at arbitrary nested levels.

    $factory->create_record( 'Company::Employee', 
        employee => {
            person => { name => 'Gareth Harper' },
        }
    );

If you have an already created object of the appropriate type you would like to use 
instead you can also use that.

    my $person = $factory->create_record( 'Person', name => 'Gareth Harper' );
    $factory->create_record( 'Person::Employee', person => $person );

=head2 get_belongs_to

Given a source name this function will return all of the parent sources (belongs_to)
of the source.  It is used by create_record to determine which extra sources need 
creating.  It returns an array of hashes of the following format.

    my @parents = ({
        class => 'Test::DBIx::Class::Example::Schema::Person',
        source => 'Person',
        relationship => 'person',
    });

It can be used as follows.

    my @parents = $factory->get_belongs_to('Person');

=head2 random_data

This method will create some randomised data of the specified type (varchar, float, 
timestamp etc).  It is used internally to fill in the unspecified fields

    # This will return a random string  of the format 'fds fdsdfas edqw nakqw'
    my $random_data = $factory->random_data('varchar');
    # This will return a datetime object set to a random time/date
    my $random_data = $factory->random_data('timestamp');

=head2 random_datetime

This method will create a randomised datetime. It is internally used by
random_data.

    # This will return a random DateTime object
    my $random_data = $factory->random_datetime()

=head2 random_integer

This method will create a randomised integer. You can optionally specify the size
of the integer. The size is passed as an argument to C<rand()>.

    # This will return a random integer of the format '12'
    my $random_data = $factory->random_integer();
    # This will return a random integer between 0 and 1
    my $random_data = $factory->random_integer(1);

=head2 random_real_number

This method will create a randomised real number. You can optionally specify the
size and number of decimal places for the number. The size is passed as an argument
to C<rand()>.

    # This will return a random integer of the format '42.3176626981334'
    my $random_data = $factory->random_real_number();
    # This will return a random integer of the format '128.750934900508'
    my $random_data = $factory->random_real_number(999);
    # This will return a random integer of the format '128.75'
    my $random_data = $factory->random_real_number(999,2);

=head2 random_string

This method will create a randomised string.  It is used internally to by 
random_word.  You can optionally specify how many words you would like.

    # This will return a random word of the format 'fdsdfas fdsfs erwq da'
    my $random_data = $factory->random_string();
    # This will return a random word of the format 'fdsdfas fdsfs'
    my $random_data = $factory->random_string(2);

=head2 random_word

This method will create a randomised word.  It is used internally to by
random_data.

    # This will return a random word of the format 'fdsdfas'
    my $random_data = $factory->random_word();

=head1 SEE ALSO

The following modules or resources may be of interest.

L<DBIx::Class>, L<Test::DBIx::Class>

=head1 AUTHOR

    Gareth Harper
    CPAN ID: GHARPER
    cpan@spansh.co.uk

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;

