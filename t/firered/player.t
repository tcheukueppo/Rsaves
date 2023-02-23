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
is($rs->player->money, 400);
isa_ok($rs->player->money(9999), 'Rsaves::Player');
is($rs->player->money, 9999);
is($rs->player->coins, 0);

# Augment time
is($rs->player->time_played, '1:14:23');
isa_ok($rs->player->time_played(hours => 4, seconds => 90), 'Rsaves::Player');
is($rs->player->time_played, '4:14:25');



done_testing();
