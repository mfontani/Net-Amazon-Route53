use strict;
use warnings;

package Net::Amazon::Route53::HostedZone;
use Mouse;
use XML::Bare;

use Net::Amazon::Route53::ResourceRecordSet;

=head2 SYNOPSIS

    my $hostedzone = Net::Amazon::Route53::HostedZone->new(...);
    # use methods on $hostedzone

=head2 ATTRIBUTES

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
        my $rc          = $self->route53->request( 'get', 'https://route53.amazonaws.com/2010-10-01/' . $self->id );
        my $resp        = XML::Bare::xmlin( $rc->decoded_content );
        die "Error: $resp->{Error}{Code}" if ( exists $resp->{Error} );
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
        my @resource_record_sets;
        my $rc = $self->route53->request( 'get', 'https://route53.amazonaws.com/2010-10-01/' . $self->id . '/rrset' );
        my $resp = XML::Bare::xmlin( $rc->decoded_content );
        die "Error: $resp->{Error}{Code}" if ( exists $resp->{Error} );
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

no Mouse;
1;
