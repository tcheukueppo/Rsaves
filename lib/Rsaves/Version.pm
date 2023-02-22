package Rsaves::Version;

use Moo::Role;
use Carp qw(croak);

use Data::Dumper;
use feature 'say';

my %versions = (
    sapphire  => 1,
    ruby      => 2,
    emerald   => 3,
    firered   => 4,
    leafgreen => 5,
);

has version => (
    is  => 'rw',
    isa => sub {
        my $vers = shift;
        croak "You must specify a pokemon version" unless $vers;
        croak "Unsupported version"                unless exists $versions{$vers};
    },
    trigger => sub {
        my $self = shift;
        if ( defined $self->objects ) {
            $self->objects->{$_}->version( $self->version ) foreach keys $self->objects->%*;
        }
    },
);

sub is_emerald              { ( $versions{ shift->version } // 0 ) == 3       ? 1 : 0 }
sub is_ruby_or_sapphire     { ( $versions{ shift->version } // 0 ) =~ m/[12]/ ? 1 : 0 }
sub is_leafgreen_or_firered { ( $versions{ shift->version } // 0 ) =~ m/[45]/ ? 1 : 0 }

1;
