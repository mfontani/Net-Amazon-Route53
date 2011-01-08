use strict;
use warnings;

package Net::Amazon::Route53;
use LWP::UserAgent;
use Digest::HMAC_SHA1;
use MIME::Base64;
use XML::Bare;
use Mouse;

use Net::Amazon::Route53::HostedZone;

has 'id'  => ( is => 'rw', isa => 'Str', required => 1, );
has 'key' => ( is => 'rw', isa => 'Str', required => 1, );

has 'ua' => (
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

sub request {
    my $self   = shift;
    my $method = shift;
    my $uri    = shift;

    return unless $method;
    return unless ( $method eq 'get' or $method eq 'post' );
    return unless $uri;

    # Get amazon server's date
    my $date = do {
        my $rc = $self->ua->get('https://route53.amazonaws.com/date');
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

sub get_hosted_zones {
    my $self         = shift;
    my $start_marker = '';
    my @zones;
    while (1) {
        my $rc =
          $self->request( 'get', 'https://route53.amazonaws.com/2010-10-01/hostedzone?maxitems=100' . $start_marker );
        my $resp = XML::Bare::xmlin( $rc->decoded_content );
        push @zones, ( ref $resp->{HostedZones} eq 'ARRAY' ? @{ $resp->{HostedZones} } : $resp->{HostedZones} );
        last if $resp->{IsTruncated} eq 'false';
        $start_marker = '?marker=' . $resp->{NextMarker};
    }
    my @o_zones;
    for my $zone (@zones) {
        push @o_zones,
          Net::Amazon::Route53::HostedZone->new(
            route53 => $self,
            ( map { lc($_) => $zone->{HostedZone}{$_} } qw/Id Name CallerReference/ ),
            comment => $zone->{HostedZone}{Config}{Comment},
          );
    }
    return @o_zones;
}

1;
