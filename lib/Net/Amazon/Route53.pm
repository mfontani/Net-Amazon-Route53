use strict;
use warnings;

package Net::Amazon::Route53;
use LWP::UserAgent;
use HTTP::Request;
use Digest::HMAC_SHA1;
use MIME::Base64;
use XML::Bare;
use Mouse;

use Net::Amazon::Route53::HostedZone;

# ABSTRACT: Interface to Amazon's Route 53

=head2 SYNOPSIS

    use strict;
    use warnings;
    use Net::Amazon::Route53;
    my $route53 = Net::Amazon::Route53->new( id => '...', key => '...' );
    my @zones = $route53->get_hosted_zones;
    for my $zone ( @zones ) {
        # use the Net::Amazon::Route53::HostedZone object
    }

=cut

=head2 ATTRIBUTES

=cut

=head3 id

The Amazon id, needed to contact Amazon's Route 53.

=head3 key

The Amazon key, needed to contact Amazon's Route 53.

=cut

has 'id'  => ( is => 'rw', isa => 'Str', required => 1, );
has 'key' => ( is => 'rw', isa => 'Str', required => 1, );

=head3 ua

Internal user agent object used to perform requests to
Amazon's Route 53

=cut

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

=head2 METHODS

=cut

=head3 C<request>

    my $hr_xml_response = $self->request( $method, $url );

Requests something from Amazon Route 53, signing the request.  Uses
L<LWP::UserAgent> internally, and returns the hashref obtained from the
request. Dies on error, showing the request's error given by the API.

=cut

sub request
{
    my $self   = shift;
    my $method = shift;
    my $uri    = shift;

    return unless $method;
    return unless ( $method eq 'get' or $method eq 'post' or $method eq 'delete' );
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

    my %options = (
        'Date' => $date,
        'X-Amzn-Authorization' =>
          sprintf( "AWS3-HTTPS AWSAccessKeyId=%s,Algorithm=HmacSHA1,Signature=%s", $self->id, $signature ),
        @_
    );
    my $content = delete $options{Content};
    my $request = HTTP::Request->new(
        uc $method,
        $uri,
        [ map { $_ => $options{$_} } keys %options],
        $content ? $content : undef,
    );
    my $rc = $self->ua->request( $request );
    my $resp = XML::Bare::xmlin( $rc->decoded_content );
    die "Error: $resp->{Error}{Code}\n" if ( exists $resp->{Error} );
    return $resp;
}

=head3 C<get_hosted_zones>

    my $route53 = Net::Amazon::Route53->new( key => '...', id => '...' );
    my @zones = $route53->get_hosted_zones();
    my $zone = $route53->get_hosted_zones( 'example.com.' );

Gets one or more L<Net::Amazon::Route53::HostedZone> objects,
representing the zones associated with the account.

Takes an optional parameter indicating the name of the wanted hosted zone.

=cut

sub get_hosted_zones
{
    my $self         = shift;
    my $which        = shift;
    my $start_marker = '';
    my @zones;
    while (1) {
        my $resp =
          $self->request( 'get', 'https://route53.amazonaws.com/2010-10-01/hostedzone?maxitems=100' . $start_marker );
        push @zones, ( ref $resp->{HostedZones}{HostedZone} eq 'ARRAY' ? @{ $resp->{HostedZones}{HostedZone} } : $resp->{HostedZones}{HostedZone} );
        last if $resp->{IsTruncated} eq 'false';
        $start_marker = '?marker=' . $resp->{NextMarker};
    }
    my @o_zones;
    for my $zone (@zones) {
        push @o_zones,
          Net::Amazon::Route53::HostedZone->new(
            route53 => $self,
            ( map { lc($_) => $zone->{$_} } qw/Id Name CallerReference/ ),
            comment => $zone->{Config}{Comment},
          );
    }
    @o_zones = grep { $_->name eq $which } @o_zones if $which;
    return @o_zones;
}

=head1 SEE ALSO

L<Net::Amazon::Route53::HostedZone>
L<http://docs.amazonwebservices.com/Route53/latest/APIReference/>

=cut

1;
