package Rsaves::Player;

use Moo;
use Rsaves::Util qw(humanize_section dehumanize_section valid_section_data access_field hihalf_u32 lowhalf_u32 xcode_string);

use Carp    qw(croak carp);
use feature qw(lexical_subs);

use Data::Dumper;
open my $test, ">", "/tmp/none";

with 'Rsaves::Version';

my %FIELD_SPEC = (
    name        => [ 0, [ 0x0000, 8, '(C)8' ] ],
    gender      => [ 0, [ 0x0008, 1, 'C' ] ],
    time_played => [ 0, [ 0x000E, 5, '(S)(C)(C)' ] ],
    rival_name  => [ 1, [ 0x0008, 1, 'C' ] ],
    trainer_id  => [ 0, [ 0x000A, 4, 'V' ] ],
    money       =>
        [ 1, { firered_leafgreen => [ 0x0290, 4, 'V' ], emerald => [ 0x0490, 4, 'V' ], ruby_sapphire => [ 0x0490, 4, 'V' ] } ],
    coins =>
        [ 1, { firered_leafgreen => [ 0x0294, 2, 'v' ], emerald => [ 0x0494, 2, 'v' ], ruby_sapphire => [ 0x0494, 2, 'v' ] } ],
    security_key => [ 0, { firered_leafgreen => [ 0x0F20, 4, 'V' ], emerald => [ 0x01F4, 4, 'V' ] } ],
);

has objects => ( is => 'ro' );
has sections => (
    is      => 'rw',
    trigger => sub { my $id = 0; $_ = humanize_section( $_, $id++ ) foreach shift->sections->@* },
    isa     => sub { ref shift ne 'ARRAY' and croak "should be an ARRAY ref" },
);

# Return an 'Rsaves::Player::Items' object
sub items { shift->objects->{items} }

# Return an 'Rsaves::Player::Team' object
sub team { shift->objects->{team} }

# Getter and Setter
sub _gset {
    my ( $self, $method ) = ( shift, shift );

    my $spec = $FIELD_SPEC{$method};
    croak "$method is unimplemented" unless defined $spec;

    my $read_args = $spec->[1];
    my $section   = $self->sections->[ $spec->[0] ];
    if ( ref $read_args eq 'HASH' ) {
        my ($key) = grep { $_ =~ m/(??{$self->version})/ } keys %$read_args;
        croak "$method is unimplemented" unless defined $key;
        $read_args = $read_args->{$key};
    }

    return access_field( $section->{data}, @$read_args ) if @_ == 0;
    my $new = shift;
    $section->{data} = access_field( $section->{data}, @$read_args, $new );
    return $self;
}

sub security_key {
    my $self = shift;
    croak "Pokemon ruby/sapphire doesn't implement a security key" if $self->is_ruby_or_sapphire;
    $self->_gset('security_key');
}

sub _gset_coins_money {
    my ( $self, $method ) = ( shift, shift );

    croak 'invalid number of argument' if @_ > 1;
    my %max = ( coins => 9999, money => 99999 );
    my $key = $self->security_key if not $self->is_ruby_or_sapphire;

    if ( @_ == 1 ) {
        my $new = shift;
        croak "max amount of $method is $max{$method}, min is 0" unless 0 <= $new <= $max{$method};
        return $self->_gset( $method, $self->is_ruby_or_sapphire ? $new : $key ^ $new );
    }

    return $self->_gset($method) if $self->is_ruby_or_sapphire;
    return $key ^ $self->_gset($method);
}

sub coins { shift->_gset_coins_money( 'coins', @_ ) }
sub money { shift->_gset_coins_money( 'money', @_ ) }

sub _name {
    my ( $self, $method ) = ( shift, shift );

    croak 'invalid number of argument' if @_ > 1;
    if ( @_ == 1 ) {
        my $name = shift;
        croak "max $method length is 8, min is 1" unless 1 <= length($name) <= 8;
        return $self->_gset( $method, [ xcode_string($name) ] );
    }

    return join '', xcode_string( $self->_gset($method) );
}

sub name       { shift->_name( 'name',       @_ ) }
sub rival_name { shift->_name( 'rival_name', @_ ) }

sub gender {
    croak 'invalid number of argument'                if @_ > 2;
    croak 'either set gender to 0(male) or 1(female)' if @_ == 2 && $_[1] !~ m/^[01]$/;
    shift->_gset( 'gender', @_ );
}

sub time_played {
    my $self = shift;
    croak 'invalid number of argument' if @_ % 2 != 0;

    my @gtime = $self->_gset('time_played');
    if (@_) {
        my @time = {@_}->@{qw(hours minutes seconds)};

        croak 'invalid time' if grep { not !defined($_) || 0 <= $_ <= 59 } @time[ 1 .. 2 ];
        @time = map { $time[$_] // $gtime[$_] } 0 .. 2;
        return $self->_gset( 'time_played', [@time] );
    }

    return join ':', @gtime;
}

sub options {
    my $ret = shift->_gset( 'options', @_ );
}

sub pok_version { shift->_gset( 'pok_version', @_ ) }

sub trainer_id { shift->_gset( 'tainer_id', @_ ) }
sub secret_id  { hihalf_u32( shift->trainer_id ) }
sub public_id  { lowhalf_u32( shift->trainer_id ) }

sub save {
    join '', map { dehumanize_section($_) } shift->sections->@*;
}

=head1 NAME

RSaves::Player - interface player specific information

=head1 SYNOPSIS

   use RSaves::Player;
   
   my $pl = RSaves::Player->new(
      data    => $array_ref_of_sections,
      version => RUBY,
   );
   
   # Enable EON TICKET
   $pl->eon_ticket(1);

   # Disable rematch gain legendary
   $pl->rematch_gain_legendary(0);
   
   # Change player's gender
   $pl->gender('F');

   # Get player's name
   my $name = $pl->name;

   # How much time elapsed since the gameplay?
   my ($hr, $min, $sec) = $pl->time();
   
   # Get Player's Rival name
   my $rname = $pl->rival_name;

=head1 DESCRIPTION

Use C<Rsaves::Player> to retrieve and modify player specific data from a save file, this
class is composed into C<Rsaves> and shouldn't be used out of C<Rsaves> itself.

=head1 METHODS

=head2 eon_ticket

   $pl->eon_ticket($bool);

Enable/Disable eon ticket.

=head2 rematch_gain_legendary

   $pl->rematch_gain_legendary($bool);

Enable/Disable rematch gain legendary.

=head2 items

   my $items = $pl->items();

Return an C<Rsaves::Player::Items> object, see C<Rsaves::Player::Items> for
more information.

=head2 team

   my $team = $pl->team();

Return an C<Rsaves::Player::Team> object, see C<Rsaves::Player::Team> for
more information.

=head2 name

   my $name = $pl->name();
   $pl->name("new_name");

Get or set the name of the player.

=head2 gender

   my $gender = $pl->gender();
   $pl->gender('F');

Get or set the gender of the player.

=head2 rival_name

   my $rival_name = $pl->rival_name;
   $pl->rival_name('new_name');

Get or set rival name.

=head2 publicçid

   my $id = $pl->public_id;
   $pl->publicçid();

Get or set trainer's public id.

=head2 secret_id

   my $id = $pl->secret_id;
   $pl->secret_id();

Get or set trainer's secret id.

=head2 time_played

   my ($hr, $min, $sec, $frame) = $pl->time_played;

Get or set time played.

=head2 security_key

   my $key = $pl->security_key();

Get security key.

=head2 options

   my IDK = $pl->options;
   $pl->options(IDK)

=head2 pok_version

   # Game Code
   my $version = $pl->pok_version;
   $pl->pok_version(RUBY);

Get or set pokemon version.

=head1 AUTHOR

sergiotarxz - Sergio, C<< <sergiotarxz at domain.com> >>

=head1 CONTRIBUTORS

tcheukueppo - Kueppo Tcheukam, C<< <tcheukueppo at tutanota.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rsaves at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=RSaves>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RSaves

You can also look for information at: L<https://git.owlcode.tech/sergiotarxz/Rsaves>

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=RSaves>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/RSaves>

=item * Search CPAN

L<https://metacpan.org/release/RSaves>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Sergio.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
