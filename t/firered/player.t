#!perl

use strict;
use Test::More;

BEGIN { use_ok('Rsaves') }

my $rs = Rsaves->new(file => './t/firered/ruby.sav', version => 'ruby');

# Extract name and change it!
isa_ok($rs, 'Rsaves');
isa_ok($rs->player, 'Rsaves::Player');
is($rs->player->name, 'AABBCC');
isa_ok($rs->player->name('KuEpPo'), 'Rsaves::Player');
is($rs->player->name, 'KuEpPo');

# Turn 'KuEpPo' into a female
is($rs->player->gender, 0);
isa_ok($rs->player->gender(1), 'Rsaves::Player');
is($rs->player->gender, 1);

# Set number of coins to its max value
#is($rs->player->coins, k);

done_testing(4);
