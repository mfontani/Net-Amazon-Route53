use strict;
use warnings;

package Net::Amazon::Route53::ResourceRecordSet;
use Mouse;
use XML::Bare;

has 'route53'    => ( is => 'rw', isa => 'Net::Amazon::Route53',             required => 1, );
has 'hostedzone' => ( is => 'rw', isa => 'Net::Amazon::Route53::HostedZone', required => 1 );

has 'name'   => ( is => 'rw', isa => 'Str',      required => 1 );
has 'ttl'    => ( is => 'rw', isa => 'Int',      required => 1 );
has 'type'   => ( is => 'rw', isa => 'Str',      required => 1 );
has 'values' => ( is => 'rw', isa => 'ArrayRef', required => 1, default => sub { [] } );

no Mouse;
1;
