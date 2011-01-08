use strict;
use warnings;

package Net::Amazon::Route53::HostedZone;
use Mouse;
use XML::Bare;

use Net::Amazon::Route53::ResourceRecordSet;

has 'route53' => ( is => 'rw', isa => 'Net::Amazon::Route53', required => 1, );

has 'id'              => ( is => 'rw', isa => 'Str', required => 1, default => '' );
has 'name'            => ( is => 'rw', isa => 'Str', required => 1, default => '' );
has 'callerreference' => ( is => 'rw', isa => 'Str', required => 1, default => '' );
has 'comment'         => ( is => 'rw', isa => 'Str', required => 1, default => '' );

has 'nameservers' => ( is => 'rw', isa => 'ArrayRef[Str]', required => 1, default => sub { [] } );

has 'resource_record_sets' => ( is => 'rw', isa => 'ArrayRef', required => 1, default => sub { [] } );

sub BUILD {
    my $self = shift;

    my $rc = $self->route53->request( 'get', 'https://route53.amazonaws.com/2010-10-01/' . $self->id );
    my $resp = XML::Bare::xmlin( $rc->decoded_content );

    my @nameservers = @{ $resp->{DelegationSet}{NameServers}{NameServer} };
    print "  nameserver: $_\n" for @nameservers;
    $self->nameservers( \@nameservers );

    my @resource_record_sets;
    $rc = $self->route53->request( 'get', 'https://route53.amazonaws.com/2010-10-01/' . $self->id . '/rrset' );
    $resp = XML::Bare::xmlin( $rc->decoded_content );
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
    $self->resource_record_sets( \@resource_record_sets );
    $self;
}

no Mouse;
1;
