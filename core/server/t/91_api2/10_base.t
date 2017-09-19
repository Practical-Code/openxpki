#!/usr/bin/perl
use strict;
use warnings;

# Core modules
use English;
use FindBin qw( $Bin );

# CPAN modules
use Test::More;
use Test::Deep;
use Test::Exception;
use DateTime;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level => $ENV{TEST_VERBOSE} ? $DEBUG : $OFF,
    layout  => '# %-5p %m%n',
});

# Project modules
use lib "$Bin/lib";


plan tests => 7;


use_ok "OpenXPKI::Server::API2";

my $api;
lives_ok {
    $api = OpenXPKI::Server::API2->new(
        namespace => "OpenXPKI::TestCommands",
        log => Log::Log4perl->get_logger(),
    );
} "instantiate";

lives_and {
    cmp_deeply [ keys %{ $api->commands } ], ['givetheparams'];
} "query available commands";

TODO: {
    local $TODO = "Implement strict constructor check for parameter objects";
    dies_ok {
        $api->dispatch("givetheparams", name => "Max", test => 1);
    } "complain about unknown parameter";
};

throws_ok {
    $api->dispatch("iamnothere");
} "OpenXPKI::Exception", "complain about unknown API command";

throws_ok {
    $api->dispatch("givetheparams", name => "Max", size => "blah");
} "Moose::Exception::ValidationFailedForTypeConstraint", "complain about wrong parameter type";

lives_and {
    my $result = $api->dispatch("givetheparams", name => "Max", size => 5 );
    cmp_deeply $result, { name => "Max", size => 5 };
} "correctly execute command";

1;
