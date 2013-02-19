use strict;
use warnings;

package Net::IMP::HTTP::Example::FlipImg;
use base 'Net::IMP::HTTP::Request';
use fields qw(ignore image);

use Net::IMP;
use Net::IMP::Debug;
use Graphics::Magick;
use File::Temp 'tempfile';

sub new_analyzer {
    my ($factory,%args) = @_;
    my $self = $factory->SUPER::new_analyzer(%args);
    # request data does not matter
    $self->run_callback([ IMP_PASS,0,IMP_MAXOFFSET ]);
    return $self;
}

sub request_hdr {}
sub request_body {}
sub any_data {}

sub response_hdr {
    my ($self,$hdr) = @_;
    my $ignore;
    # we only want selected image/ content types and not too big
    debug("header=$hdr");
    my ($ct) = $hdr =~m{\nContent-type:[ \t]*([^\s;]+)}i;
    my ($clen) = $hdr =~m{\nContent-length:[ \t]*(\d+)}i;
    my ($code) = $hdr =~m{\AHTTP/1\.[01][ \t]+(\d+)};
    if ( $code != 200 ) {
	debug("will not rotate code=$code");
	$ignore++;
    } elsif ( ! $ct or $ct !~m{^image/(png|gif|jpeg)$} ) {
	debug("will not rotate content type $ct");
	$ignore++;
    } elsif ( $clen and $clen > 2**16 ) {
	debug("image is too big: $clen" );
	$ignore++;
    }
    
    if ( $ignore ) {
	$self->run_callback([ IMP_PASS,1,IMP_MAXOFFSET ]);
	$self->{ignore} = 1;
	return;
    }

    # pass header
    $self->run_callback([ IMP_PASS,1,$self->offset(1) ]);
}

sub response_body {
    my ($self,$data) = @_;
    $self->{ignore} and return;
    $self->{image} .= $data;

    my $off = $self->offset(1);
    if ( $data ne '' ) {
	# remove from buffer of data provider
	# we have it all buffered here
	# but keep 1 byte for the final replace
	debug("replace up to $off-1 with ''");
	$self->run_callback([ IMP_REPLACE,1,$off-1,'' ]) if $off>1;

	# on chunked encoding we don't get a length up front, so check now
	if ( length($self->{image}) > 2**16 ) {
	    debug("image too big (chunked?)");
	    $self->run_callback([ IMP_REPLACE,1,$off,$self->{image} ]);
	    $self->run_callback([ IMP_PASS,1,IMP_MAXOFFSET ]);
	    $self->{ignore} = 1;
	}

	return;
    }

    # end of image reached
    debug("flop image size=%d",length($self->{image}));
    my ($fh,$file) = tempfile();
    print $fh $self->{image};
    close($fh);
    my $img = Graphics::Magick->new;
    debug("read image size=".( -s $file ));
    $img->Read($file);
    debug("flip image");
    $img->Flip;
    debug("write image");
    $img->Write($file);
    debug("rereading image size=".( -s $file));
    open( $fh,'<',$file );
    unlink($file);
    $self->{image} = do { local $/; <$fh> };
    close($fh);

    debug("replace with ".length($self->{image})." bytes");
    $self->run_callback(
	[ IMP_REPLACE,1,$self->offset(1),$self->{image} ],
	[ IMP_PASS,1,IMP_MAXOFFSET ],
    );
}

sub data {
    my ($self,$dir,$data,$offset,$type) = @_;
    debug("$self $dir,".length($data).",$offset,$type");
    return $self->SUPER::data($dir,$data,$offset,$type);
}

1;
__END__

=head1 NAME

Net::IMP::HTTP::Example::FlipImg - sample IMP plugin to flip images

=head1 SYNOPSIS

    # use proxy from App::HTTP_Proxy_IMP to flip images
    http_proxy_imp --filter Example::FlipImg listen_ip:port

=head1 DESCRIPTION

This is a sample plugin to flip PNG, GIF and JPEG with a size less than 32k.
