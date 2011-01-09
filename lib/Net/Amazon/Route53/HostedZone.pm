use strict;
use warnings;

package Net::Amazon::Route53::HostedZone;
use Mouse;

use Net::Amazon::Route53::Change;

=head2 SYNOPSIS

    my $hostedzone = Net::Amazon::Route53::HostedZone->new(...);
    # use methods on $hostedzone

=cut

=head2 ATTRIBUTES

=cut

=head3 route53

A L<Net::Amazon::Route53> object, needed and used to perform requests
to Amazon's Route 53 service

=cut

has 'route53' => ( is => 'rw', isa => 'Net::Amazon::Route53', required => 1, );

=head3 id

The hosted zone's id

=head3 name

The hosted zone's name; ends in a dot, i.e.

    example.com.

=head3 callerreference

The CallerReference attribute for the hosted zone

=head3 comment

Any Comment given when the zone is created

=cut

has 'id'              => ( is => 'rw', isa => 'Str', required => 1, default => '' );
has 'name'            => ( is => 'rw', isa => 'Str', required => 1, default => '' );
has 'callerreference' => ( is => 'rw', isa => 'Str', required => 1, default => '' );
has 'comment'         => ( is => 'rw', isa => 'Str', required => 1, default => '' );

=head3 nameservers

Lazily loaded, returns a list of the nameservers authoritative for this zone

=cut

has 'nameservers' => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub {
        my $self        = shift;
        my $resp        = $self->route53->request( 'get', 'https://route53.amazonaws.com/2010-10-01/' . $self->id );
        my @nameservers = @{ $resp->{DelegationSet}{NameServers}{NameServer} };
        \@nameservers;
    }
);

=head3 resource_record_sets

Lazily loaded, returns a list of the resource record sets
(L<Net::Amazon::Route53::ResourceRecordSet> objects) for this zone.

=cut

has 'resource_record_sets' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $resp =
          $self->route53->request( 'get', 'https://route53.amazonaws.com/2010-10-01/' . $self->id . '/rrset' );
        my @resource_record_sets;
        for my $res ( @{ $resp->{ResourceRecordSets}{ResourceRecordSet} } ) {
            push @resource_record_sets,
              Net::Amazon::Route53::ResourceRecordSet->new(
                route53    => $self->route53,
                hostedzone => $self,
                name       => $res->{Name},
                ttl        => $res->{TTL},
                type       => $res->{Type},
                values     => [
                    map { $_->{Value} } @{
                        ref $res->{ResourceRecords}{ResourceRecord} eq 'ARRAY'
                        ? $res->{ResourceRecords}{ResourceRecord}
                        : [ $res->{ResourceRecords}{ResourceRecord} ]
                      }
                ],
              );
        }
        \@resource_record_sets;
    }
);

=head2 METHODS

=cut

=head3 create

Creates a new zone. Needs all the attributes (name, callerreference and comment).

Takes an optional boolean parameter, C<wait>, to indicate whether the request should
return straightaway (default, or when C<wait> is C<0>) or it should wait until the
request is C<INSYNC> according to the Change's status.

Returns a L<Net::Amazon::Route53::Change> object representing the change requested.

=cut

sub create
{
    my $self = shift;
    my $wait = shift;
    $wait = 0 if !defined $wait;
    $self->name =~ /\.$/ or die "Zone name needs to end in a dot, to be created\n";
    my $request_xml_str = <<'ENDXML';
<?xml version="1.0" encoding="UTF-8"?>
<CreateHostedZoneRequest xmlns="https://route53.amazonaws.com/doc/2010-10-01/">
    <Name>%s</Name>
    <CallerReference>%s</CallerReference>
    <HostedZoneConfig>
        <Comment>%s</Comment>
    </HostedZoneConfig>
</CreateHostedZoneRequest>
ENDXML
    my $request_xml = sprintf( $request_xml_str, $self->name, $self->callerreference, $self->comment );
    my $resp = $self->route53->request(
        'post',
        'https://route53.amazonaws.com/2010-10-01/hostedzone',
        'content-type' => 'text/xml; charset=UTF-8',
        Content => $request_xml,
    );
    $self->id( $resp->{HostedZone}{Id} );
    my $change = Net::Amazon::Route53::Change->new(
        route53 => $self->route53,
        ( map { lc($_) => $resp->{ChangeInfo}{$_} } qw/Id Status SubmittedAt/ ),
    );
    $change->refresh();
    return $change if !$wait;

    while ( lc( $change->status ) ne 'insync' ) {
        sleep 2;
        $change->refresh();
    }
    return $change;
}

=head3 delete

Deletes the zone. A zone can only be deleted by Amazon's Route 53 service if it
contains no records other than a SOA or NS.

Takes an optional boolean parameter, C<wait>, to indicate whether the request should
return straightaway (default, or when C<wait> is C<0>) or it should wait until the
request is C<INSYNC> according to the Change's status.

Returns a L<Net::Amazon::Route53::Change> object representing the change requested.

=cut

sub delete
{
    my $self = shift;
    my $wait = shift;
    $wait = 0 if !defined $wait;
    my $resp = $self->route53->request( 'delete', 'https://route53.amazonaws.com/2010-10-01/' . $self->id, );
    my $change = Net::Amazon::Route53::Change->new(
        route53 => $self->route53,
        ( map { lc($_) => $resp->{ChangeInfo}{$_} } qw/Id Status SubmittedAt/ ),
    );
    $change->refresh();
    return $change if !$wait;
    while ( lc( $change->status ) ne 'insync' ) {
        sleep 2;
        $change->refresh();
    }
    return $change;
}

no Mouse;
1;
