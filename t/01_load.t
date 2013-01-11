use strict;
use warnings;
use Test::More tests => 4;

for (
    'Net::IMP::HTTP',
    'Net::IMP::HTTP::Connection',
    'Net::IMP::Adaptor::STREAM2HTTPConn',
    'Net::IMP::HTTP::Request',
    #'Net::IMP::Adaptor::STREAM2HTTPReq',
) {
    ok( eval "require $_",$_ );
}
	
