use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'Rsaves',
    license             => 'artistic_2',
    dist_author         => q{Kueppo Tcheukam <tcheukueppo@tutanota.com>},
    dist_version_from   => 'lib/Rsaves.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    add_to_cleanup     => [ 'Rsaves-*' ],
    recursive_test_files => '1',
);

$builder->create_build_script();
