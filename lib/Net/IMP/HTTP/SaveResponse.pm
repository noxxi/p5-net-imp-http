
use strict;
use warnings;
package Net::IMP::HTTP::SaveResponse;
use base 'Net::IMP::HTTP::Request';
use fields qw(root fh filename);

use Net::IMP;
use Net::IMP::Debug;
use File::Path 'make_path';
use Carp;

sub RTYPES { (IMP_PREPASS) }

sub new_factory {
    my ($class,%args) = @_;
    my $dir = $args{root} or croak("no root directory given");
    -d $dir && -r _ && -x _ or croak("cannot use base dir $dir: $!");
    return $class->SUPER::new_factory(%args);
}

sub validate_cfg {
    my ($class,%cfg) = @_;
    my $dir = delete $cfg{root};
    my @err = $class->SUPER::validate_cfg(%cfg);
    push @err, "no or non-existing root dir given" 
	if ! defined $dir or ! -d $dir;
    return @err;
}

sub new_analyzer {
    my ($factory,%args) = @_;
    my $self = $factory->SUPER::new_analyzer(%args);
    # we don't modify
    $self->run_callback(
	[ IMP_PREPASS,0,IMP_MAXOFFSET ],
	[ IMP_PREPASS,1,IMP_MAXOFFSET ]
    );
    return $self;
}


sub request_hdr {
    my ($self,$hdr) = @_;

    my ($page) = $hdr =~m{\A\w+ +(\S+)};
    my $host = $page =~s{^\w+://([^/]+)}{} && $1;
    $host ||= $hdr =~m{\nHost: *(\S+)}i && $1 or goto IGNORE;
    my $port = 
	$host=~s{^(?:\[(\w._\-:)+\]|(\w._\-))(?::(\d+))?$}{ $1 || $2 }e ? 
	$3:80;

    my $dir = $self->{factory_args}{root};
    my $fname = "$dir/$host:$port/$page";
    $fname =~s{\?.*}{}; # strip query string
    $fname =~m{^(.*/)([^/]*)$};
    $fname .= "INDEX.html" if $2 eq '';
    if  ( ! -d $1 ) {
	my $err;
	make_path($1, { error => \$err  });
    }
    open($self->{fh},'>',"$fname.tmp") or do {
	# making only selected dirs writable can be used as a way to save
	# only selected hosts, but it could also be, that name is too long
	debug("cannot write to $dir/$host:$port/$page: $!");
	goto IGNORE;
    };

    $self->{filename} = $fname;
    debug("save http://$host:$port$page into $fname");
    # no need to get request body
    $self->run_callback( [ IMP_PASS,0,IMP_MAXOFFSET ]);
    return;

    IGNORE:
    # pass thru
    debug("no save http://$host:$port$page");
    $self->{fh} = undef;
    $self->run_callback( 
	# pass thru everything 
	[ IMP_PASS,0,IMP_MAXOFFSET ], 
	[ IMP_PASS,1,IMP_MAXOFFSET ], 
    );

}

sub response_hdr {
    my ($self,$hdr) = @_;
    $self->{fh} or return;
    debug("response hdr %d $self->{filename}",length($hdr));
    print {$self->{fh}} $hdr;
}

sub response_body {
    my ($self,$data) = @_;
    $self->{fh} or return;
    debug("response body %d $self->{filename}",length($data));
    if ( $data ne '' ) {
	print {$self->{fh}} $data;
    } else {
	# eof, move file to final place
	close($self->{fh});
	rename( $self->{filename}.'.tmp', $self->{filename});
    }
}

# will not be called
sub request_body {}
sub any_data {}

1;

__END__

=head1 NAME 

Net::IMP::HTTP::SaveResponse - save response data to file system

=head1 SYNOPSIS

  # use App::HTTP_Proxy_IMP to listen on 127.0.0.1:8000 and save all data 
  # in myroot/
  $ perl bin/imp_http_proxy --filter SaveResponse=root=myroot 127.0.0.1:8000


=head1 DESCRIPTION

This module is used to save response data into the file system.
The format is the same used by L<App::HTTP_Proxy_IMP::FakeResponse>.

The module has a single argument C<root> for C<new_analyzer>. 
C<root> specifies the base directory, where the data get saved.
Filenames are C<root/host:port/path>, the query string is excluded from the 
name.
It will not croak if it cannot save a file.
This can be used to make only selected directories writable and this save only
selected hosts.

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>
