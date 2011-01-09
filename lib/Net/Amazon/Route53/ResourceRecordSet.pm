use strict;
use warnings;

package Net::Amazon::Route53::ResourceRecordSet;
use Mouse;
use XML::Bare;

=head2 SYNOPSIS

    my $resource = Net::Amazon::Route53::ResourceRecordSet->new(...);
    # use methods on $resource

=head2 ATTRIBUTES

=head3 route53

A L<Net::Amazon::Route53> object, needed and used to perform requests
to Amazon's Route 53 service

=head3 hostedzone

The L<Net::Amazon::Route53::HostedZone> object this hosted zone refers to

=cut

has 'route53'    => ( is => 'rw', isa => 'Net::Amazon::Route53',             required => 1, );
has 'hostedzone' => ( is => 'rw', isa => 'Net::Amazon::Route53::HostedZone', required => 1 );

=head3 name

The name for this resource record

=head3 ttl

The TTL associated with this resource record

=head3 type

The type of this resource record (C<A>, C<AAAA>, C<NS>, etc)

=head3 values

The values associated with this resource record.

=cut

has 'name'   => ( is => 'rw', isa => 'Str',      required => 1 );
has 'ttl'    => ( is => 'rw', isa => 'Int',      required => 1 );
has 'type'   => ( is => 'rw', isa => 'Str',      required => 1 );
has 'values' => ( is => 'rw', isa => 'ArrayRef', required => 1, default => sub { [] } );

no Mouse;
1;
