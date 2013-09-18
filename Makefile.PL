

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Test::DBIx::Class::Factory',
    VERSION_FROM => 'lib/Test/DBIx/Class/Factory.pm', # finds \$VERSION
    AUTHOR       => 'Gareth Harper (cpan@spansh.co.uk)',
    ABSTRACT     => 'Automatically create test data for DBIx::Class',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
