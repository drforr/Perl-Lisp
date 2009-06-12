use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Perl::Lisp',
    AUTHOR              => 'Jeffrey Goff <jgoff@cpan.org>',
    VERSION_FROM        => 'lib/Perl/Lisp.pm',
    ABSTRACT_FROM       => 'lib/Perl/Lisp.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Perl-Lisp-*' },
);
