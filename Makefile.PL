use ExtUtils::MakeMaker;
require 5.10.0;
WriteMakefile(
    NAME => 'Net::IMP',
    VERSION_FROM => 'lib/Net/IMP/HTTP.pm',
    LICENSE => 'perl',
    PREREQ_PM => {
	Net::IMP => 0.55,
	Net::Inspect => 0.25,
    },
);
