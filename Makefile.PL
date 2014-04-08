

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'Test::DBIx::Class::Factory',
    VERSION_FROM        => 'lib/Test/DBIx/Class/Factory.pm', # finds \$VERSION
    AUTHOR              => 'Gareth Harper (cpan@spansh.co.uk)',
    ABSTRACT            => 'Automatically create test data for DBIx::Class',
    PREREQ_PM           => {
        'String::Random'            => 0.22,
        'DateTime::Event::Random'   => 0.03,
        'Moose'                     => 2.1,
    },
    TEST_REQUIRES       => {
        'Test::Most'                => 0.33,
        'Test::DBIx::Class'         => 0.40,
        'Test::Pod::Coverage'       => 1.08,
    },
    MIN_PERL_VERSION    => '5.010001',
);
