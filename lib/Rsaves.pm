package Rsaves;

use Moo;

use Rsaves::Util qw(access_field);
use Rsaves::Player;
use Rsaves::Boxes;
use Exporter;

use Carp    qw(croak);
use feature qw(lexical_subs state say);

our $VERSION = '0.01';

use Data::Dumper;
use List::Util qw(sum);

open my $test, '>', "/tmp/rsaves";

with 'Rsaves::Version';

my ( @SAVES, $EXTRA, $INDEX );

has objects => ( is => 'ro', default => sub { {} } );
has file => (
    is      => 'rw',
    trigger => \&_trigger_file,
    isa     => sub {
        my $file = shift;
        $file = -l $file ? readlink $file : $file;
        -f $file or croak "$file: regular file doesn't exist";
        -r $file or croak "$file: file isn't readable";
    },
);

my sub find_section {
    my ( $section_id, $save )         = @_;
    my ( $offset,     $section_size ) = ( 0, 4096 );

    my $section;
    while ( not defined $section ) {
        last if 14 == $offset / 4096;
        my $data = substr $save, $offset, $section_size;
        $section = $data if access_field( $data, 4084, 2, 'v' ) == $section_id;
        $offset += $section_size;
    }

    return $section;
}

my sub read_saves {
    my $file = shift;
    open my $fh, '<', $file or croak "Unable to read $file";

    my ( @saves, $save );
    my $save_size = 57344;
    local $/;
    my $contents = <$fh>;
    push @saves, $save while length( $save = substr $contents, 0, $save_size, '' ) != 0;

    return @saves;
}

sub _trigger_file {
    my $self = shift;

    croak $self->file . ': incorrect size for specified version' if ( -s $self->file ) / 1024 != 128;
    ( $EXTRA, @SAVES ) = reverse read_saves( $self->file );
    $INDEX = ( sort { $b->[0] <=> $a->[0] } map { [ access_field( $SAVES[$_], 4092, 4, 'V' ), $_ ] } ( 0 .. $#SAVES ) )[0][1];
}

sub _build_object {
    my ( $self, $name, @id ) = @_;
    return $self->objects->{$name} if defined $self->objects->{$name};

    my $data = [ map { find_section( $_, $SAVES[$INDEX] ) } @id ];
    say $test Dumper $data;
    eval '$self->objects->{$name} = Rsaves::' . ucfirst($name) . '->new(sections => $data, version => $self->version)';
    croak $@ if $@;

    return $self->objects->{$name};
}

sub player { shift->_build_object( 'player', 0 .. 4 ) }
sub boxes  { shift->_build_object( 'boxes',  5 .. 13 ) }

sub save {
    my $self = shift;
    my $file = shift // $self->file;

    open my $fh, '>', $file or croak $!;
    my $content = join '', $self->player->section, $self->boxes->section, $SAVES[ !$INDEX ], $EXTRA;

    # Checking size is probably not useful but let's do this anyway!
    croak 'save size is incorrect' unless length($content) / 1024 == 128;
    print $fh $content;
}

sub save_to {
    my ( $self, $file ) = @_;
    croak 'path to save file is needed' unless defined $file;
    $self->save($file);
}

=head1 NAME

RSaves - Headless Pokemon saves editor

=head1 SYNOPSIS

   use RSaves;
   
   my $rs = RSaves->new(
      save    => '/path/to/pokemon_save.sav', 
      version => 'RUBY',
   );
   
   # Enable EON TICKET
   $rs->player->eon_ticket(1);
   # Disable rematch gain legendary
   $rs->player->rematch_gain_legendary(0);
   
   # Change player's gender
   $rs->player->gender('F');
   # Get player's name
   my $name = $rs->player->name;
   # How much time elapsed since the gameplay?
   my ($hr, $min, $sec) = $rs->player->time();
   
   # Add an item to the player
   $rs->player->items->add(name => 'item_name', quantity => 1);
   
   # Get a list of pokemons in the player's team
   $rs->player->team->get;
   
   # Get Player's Rival name
   my $rname = $rs->player->rival_name;
   
   # Make 'PIKACHU' shiny
   $rs->boxes->set_shiny('PIKACHU');
   # Make all pokemons shiny
   $rs->boxes->all_shiny();
   
   # Save the edited Pokemon save
   $rs->save();
   # or save it to a new file
   $rs->save_to('/path/to/new_save.sav');

=head1 DESCRIPTION

C<Rsaves> is full featured generation III Pokemon save editor, currently supported 
versions are Ruby, Sapphire, FireRed, Leafgreen and Emerald. Rsaves proxies C<Rsaves::Player>
and C<Rsaves::Boxes> which provides context in save edition.

=head1 EXPORT

Rsave exports by default 5 subroutines which aids in specifying which
Pokemon version is associated to the save file when instanciating a new
Rsave class.

These subroutines are SAPPHIRE, RUBY, EMERALD, LEAFGREEN, COLOSSEUM which
return 1, 2, 3, 4, 5 and 15 respectively.

=head1 METHODS

=head2 player

   my $player = $rs->player();

This method returns C<Rsave::Player> object.
Read C<Rsave::Player> documentation for more information.

=head2 boxes

   my $boxes = $rs->boxes();

This method returns C<Rsave::Boxes> object.
Read C<Rsave::Boxes> documentation for more information.

=head2 save

   $rs->save();

Save changes to the currently opened Pokemon save file.

=head2 save_to

   $rs->save_to('/path/to/new_save.sav');

Generate a new Pokemon save from the currently edited save and save it
to the specified path.

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
