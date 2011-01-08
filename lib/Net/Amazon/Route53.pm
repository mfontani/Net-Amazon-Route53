use strict;
use warnings;

package Net::Amazon::Route53;
use LWP::UserAgent;
use Digest::HMAC_SHA1;
use MIME::Base64;
use Mouse;

has 'id'  => ( is => 'ro', isa => 'Str', required => 1, );
has 'key' => ( is => 'ro', isa => 'Str', required => 1, );

has 'ua'  => (
    is       => 'rw',
    isa      => 'LWP::UserAgent',
    required => 1,
    default  => sub {
        my $self = shift;
        LWP::UserAgent->new(
            keep_alive            => 10,
            requests_redirectable => [qw(GET HEAD DELETE PUT)],
        );
    },
);

sub BUILD {
    my $self = shift;
}

sub request
{
    my $self   = shift;
    my $method = shift;
    my $uri    = shift;

    return unless $method;
    return unless ( $method eq 'get' or $method eq 'post' );
    return unless $uri;

    # Get amazon server's date
    my $date = do {
        my $rc = $self->ua->get( 'https://route53.amazonaws.com/date' );
        $rc->header('date');
    };

    # Create signed request
    my $hmac = Digest::HMAC_SHA1->new( $self->key );
    $hmac->add($date);
    my $signature = encode_base64( $hmac->digest, '' );

    $self->ua->$method(
        $uri,
        'Date' => $date,
        'X-Amzn-Authorization' =>
          sprintf( "AWS3-HTTPS AWSAccessKeyId=%s,Algorithm=HmacSHA1,Signature=%s", $self->id, $signature ),
    );
}

1;
