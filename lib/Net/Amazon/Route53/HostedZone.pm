use strict;
use warnings;

package Net::Amazon::Route53::HostedZone;
use Mouse;
use XML::Bare;

has 'route53' => ( is => 'rw', isa => 'Net::Amazon::Route53', required => 1, );

has 'id'              => ( is => 'rw', isa => 'Str', required => 1, default => '' );
has 'name'            => ( is => 'rw', isa => 'Str', required => 1, default => '' );
has 'callerreference' => ( is => 'rw', isa => 'Str', required => 1, default => '' );
has 'comment'         => ( is => 'rw', isa => 'Str', required => 1, default => '' );

has 'nameservers' => ( is => 'rw', isa => 'ArrayRef[Str]', required => 1, default => sub { [] } );

sub BUILD
{
    my $self = shift;

    my $rc = $self->route53->request('get','https://route53.amazonaws.com/2010-10-01/' . $self->id);
    my $resp = XML::Bare::xmlin($rc->decoded_content);

    my @nameservers = @{ $resp->{DelegationSet}{NameServers}{NameServer} };
    print "  nameserver: $_\n" for @nameservers;
    $self->nameservers(\@nameservers);
}

no Mouse;
1;
