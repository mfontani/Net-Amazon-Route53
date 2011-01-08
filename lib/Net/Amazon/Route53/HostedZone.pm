use strict;
use warnings;

package Net::Amazon::Route53::HostedZone;
use Mouse;

has 'route53' => ( is => 'rw', isa => 'Net::Amazon::Route53', required => 1, );

has 'id'              => ( is => 'rw', isa => 'Str', required => 1, default => '' );
has 'name'            => ( is => 'rw', isa => 'Str', required => 1, default => '' );
has 'callerreference' => ( is => 'rw', isa => 'Str', required => 1, default => '' );
has 'comment'         => ( is => 'rw', isa => 'Str', required => 1, default => '' );

no Mouse;
1;
