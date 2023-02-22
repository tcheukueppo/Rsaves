package Rsaves::Util;

use strict;
use warnings;
use List::Util qw(sum);
use Carp q(croak);

use parent 'Exporter';

our @EXPORT_OK = qw(humanize_section dehumanize_section hihalf_u32 lowhalf_u32 valid_section_data access_field xcode_string);

use Data::Dumper;
use feature qw(say);
open my $test, '>>', "/tmp/dumper";

my @SECTION_KEYS   = qw(data data_pad id checksum signature save_index);
my @CHECKSUM_BYTES = ( hex 'F80', (3968) x 12, 2000 );
my @SECTION_SPEC   = (
    [ sub { $CHECKSUM_BYTES[ shift() ] } ],
    [ sub { 4084 - $CHECKSUM_BYTES[ shift() ] } ],
    ( [ 2, 'v' ] ) x 2,
    ( [ 4, 'V' ] ) x 2,
);

sub hihalf_u32 {
    my $n = shift;
    return ( $n & 0xFFFF0000 ) >> 16;
}

sub lowhalf_u32 {
    my $n = shift;
    return $n & 0xFFFF;
}

sub xcode_string {
    my @chars   = @_ > 1 ? @_ : split '', shift;
    my $count   = hex 'BB';
    my $unknown = 255;

    # this translation table is incomplete!
    my %map = map { $_ => $count++ } ( 'A' .. 'Z', 'a' .. 'z' );

    if ( not exists $map{ $chars[0] } ) {
        %map     = reverse %map;
        $unknown = '';
    }

    return map { $map{$_} // $unknown } @chars;
}

sub humanize_section {
    my ( $section, $id ) = @_;
    my ( $hu_section, $offset );

    foreach my $index ( 0 .. 5 ) {
        my @args;
        my $spec = $SECTION_SPEC[$index];

        push @args, $offset // 0;
        push @args, ref( $spec->[0] ) eq 'CODE' ? $spec->[0]->($id) : $spec->[0];
        push @args, $spec->[1] if @$spec == 2;

        $hu_section->{ $SECTION_KEYS[$index] } = access_field( $section, @args );
        $offset += $args[1];
    }

    #say $test Dumper [ $hu_section, _cal_checksum($hu_section) ];
    return $hu_section;
}

sub _cal_checksum {
    my $hu_section = shift;
    my $checksum   = 0;

    open my $fh, '<', \$hu_section->{data};
    for ( my $i = 0 ; $i < $CHECKSUM_BYTES[ $hu_section->{id} ] ; $i += 4 ) {
        read $fh, my $readed, 4;
        my $to_add = unpack 'V', $readed;
        $checksum = 0xffffffff & ( $checksum + $to_add );
    }

    return ( hihalf_u32($checksum) + lowhalf_u32($checksum) ) & 0xffffffff;
}

sub dehumanize_section {
    my $hu_section = shift;

    $hu_section->{checksum} = _cal_checksum($hu_section);
    return join '', (
        $hu_section->@{qw/ data data_pad /},
        map { pack 'v', $hu_section->{$_} } @SECTION_KEYS[ 2 .. 3 ],
        map { pack 'V', $hu_section->{$_} } @SECTION_KEYS[ 4 .. 5 ],
    );
}

sub access_field {
    my ( $data, $offset, $len, @rest ) = @_;

    #say $test Dumper [$data];
    open my $fh, '<', \$data;
    read $fh, my ($read), $offset;
    my $new_data = $read;
    read $fh, $read, $len;

    #say $test "see: ", join '-', map { unpack 'C', $_ } (split '', $read) if $len == 8;
    return $read if @rest == 0;
    return unpack $rest[0], $read if @rest == 1;

    croak "template needed to pack data" unless @rest == 2;

    #say $test "see now: ", Dumper [ map { length } @{$rest[1]} ];
    $new_data .= pack $rest[0], ref $rest[1] eq 'ARRAY' ? @{ $rest[1] } : $rest[1];
    $new_data .= <$fh>;

    return $new_data;
}

sub valid_section_data {
    my $hu_section = shift;
    return _cal_checksum($hu_section) == $hu_section->{checksum} ? 1 : 0;
}

=head1 NAME

RSaves::Util - Some utility functions

=head1 SYNOPSIS

   use RSaves::Util qw/ humanize_section dehumanize_section /;
   ...
   my $hs = humanize_section($section, 1);
   $hs->{player} = "whatever";
   $section = dehumanize_section($hs);
   ...
   
=head1 DESCRIPTION

C<Rsaves::Util> provide utility functions for C<Rsaves>

=head1 FUNCTIONS

=head2 hihalf_u32

   my $hi = hihalf_u32($n);

Returns the first 16 bits the unsigned integer C<$n>.

=head2 lowhalf_u32

   my $low = lowhalf_u32($n);

Returns the lower 16 bits the unsigned integer C<$n>.

=head2 humanize_section

   my $hs = humanize_section($section, $index);

Turn a section into a simplified human readable hash data structure

=head2 dehumanize_section

   my $section = dehumanize_section($hs);

Turn a humanized section into its original format

=head2 valid_section_data

   my $boolean = valid_section_data($hs);

Check if the data field of a section is valid by computing it checksum
and comparing with the stored one.

=head2 access_field

   my $data = access_field($data, $offset, $len, $template, $replacement);

C<access_field> does two things, it either write or retrieve data at a specified
location.

   # Retrieve packed data of length $len, start at $offset.
   access_field($data, $offset, $len);

   # Retrieve data of length $len at $offset unpacked via $template
   access_field($data, $offset, $len, $template);

   # Replace data of length $len at $offset with $replacement packed in $template
   access_field($data, $offset, $len, $template, $replacement);

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
