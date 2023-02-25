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
#is($rs->player->time_played, '1:15:0');
#isa_ok($rs->player->time_played(hours => 4, seconds => 59), 'Rsaves::Player');
#is($rs->player->time_played, '4:15:59');

# Modify game options
my $valid_option = { 
   txt_speed => 'medium',
   bat_scene => 'on',
   bat_style => 'shift',
   button_mode => 'normal',
   frame => 'frame_1',
   sound => 'mono',
};

is_deeply($rs->player->options, $valid_option);

done_testing();
