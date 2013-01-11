use strict;
use warnings;

package Net::IMP::HTTP;
use Net::IMP qw(:DEFAULT IMP_DATA );
use Exporter 'import';

our $VERSION = '0.1';
our @EXPORT;

# create and export NET_IMP_HTTP* constants
push @EXPORT, IMP_DATA( 'http',
    'header'     => +1,
    'body'       => -2, # message body: streaming
    'chkhdr'     => +3,
    'chktrailer' => +4,
    'data'       => -5, # encapsulated data (websocket etc): streaming
    'junk'       => -6, # junk data (leading empty lines..): streaming
);

push @EXPORT, IMP_DATA( 'httprq[http+10]',
    'header'     => +1,
    'content'    => -2, # unchunked, uncompressed content: streaming
    'data'       => -3, # encapsulated data (websocket etc): streaming
);

