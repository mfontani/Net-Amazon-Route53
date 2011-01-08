use strict;
use warnings;

package Net::Amazon::Route53;
use LWP::UserAgent;
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

1;
