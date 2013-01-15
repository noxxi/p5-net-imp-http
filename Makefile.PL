use ExtUtils::MakeMaker;
require 5.10.0;
WriteMakefile(
    NAME => 'Net::IMP::HTTP',
    VERSION_FROM => 'lib/Net/IMP/HTTP.pm',
    LICENSE => 'perl',
    PREREQ_PM => {
	Net::IMP => 0.57,
	Net::Inspect => 0.25,
    },
    META_MERGE => {
	resources => {
	    repository => 'https://github.com/noxxi/p5-net-imp-http',
	},
   },
);
