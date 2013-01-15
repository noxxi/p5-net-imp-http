use strict;
use warnings;
use Test::More tests => 6;

for my $pkg (
    'Net::IMP::HTTP',
    'Net::IMP::HTTP::Connection',
    'Net::IMP::Adaptor::STREAM2HTTPConn',
    'Net::IMP::HTTP::Request',
    [ 'Net::IMP::HTTP::LogFormData', 'HTTP::Request' => 0 ],
    'Net::IMP::HTTP::Example::AddXFooHeader',
    #'Net::IMP::Adaptor::STREAM2HTTPReq',
) {
    if ( ! ref $pkg) {
	ok( eval "require $pkg",$pkg );
    } else {
	SKIP: {
	    ($pkg, my @dep) = @$pkg;
	    while (@dep) {
		my ($p,$v) = splice(@dep,0,2);
		skip "cannot load $p",1 if ! eval "require $p";
		if ($v) { 
		    no strict 'refs';
		    skip "$p wrong version",1 if ${ "${p}::VERSION" } <= $v; 
		}
	    }
	    ok( eval "require $pkg",$pkg );
	}
    }
}
	
