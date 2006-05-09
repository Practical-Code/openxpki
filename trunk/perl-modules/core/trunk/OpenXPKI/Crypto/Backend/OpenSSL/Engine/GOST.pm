## OpenXPKI::Crypto::Backend::OpenSSL::Engine::GOST 
## Written 2006 by Julia Dubenskaya for the OpenXPKI project
## (C) Copyright 2006 by The OpenXPKI Project 
## $Revision$

use strict;
use warnings;

package OpenXPKI::Crypto::Backend::OpenSSL::Engine::GOST;

use base qw(OpenXPKI::Crypto::Backend::OpenSSL::Engine);
use OpenXPKI::Debug 'OpenXPKI::Crypto::Backend::OpenSSL::Engine::GOST';
use OpenXPKI::Exception;
use English;
use OpenXPKI::Server::Context qw( CTX );
use OpenXPKI::Crypto::Backend::OpenSSL::Config;

sub new {
    my $that = shift;
    my $class = ref($that) || $that;

    my $self = {};

    my $keys = { @_ };

    bless ($self, $class);
    ##! 2: "new: class instantiated"

    ## token mode will be ignored
    foreach my $key (qw{OPENSSL
                        NAME
                        KEY
                        PASSWD
                        PASSWD_PARTS
                        CERT
                        INTERNAL_CHAIN
                        ENGINE_SECTION
                        ENGINE_USAGE
                        KEY_STORE
                       }) {
        if (exists $keys->{$key}) {
            $self->{$key} = $keys->{$key};
        }
    }
    $self->__check_engine_usage();
    $self->__check_key_store();

    return $self;
}

sub is_dynamic
{
    return 1;
}

sub get_engine
{
    return "gost";
}

sub filter_stdout
{
    my $self = shift;
    my $stdout = $_[0];
    $stdout =~ s{ \n }{}xmsg;
    $stdout =~ s{ \(dynamic\)\ Dynamic\ engine\ loading\ support }{}xms;
    $stdout =~ s{ \[Success\]:\ ID:gost }{}xms;
    return $stdout;
}

1;

__END__

=head1 Description

This class is the base class and the interface of all other engines.
This defines the interface how HSMs are supported by OpenXPKI.

=head1 Functions

=head2 new

is a constructor.

=head2 is_dynamic

returns true if a dynamic OpenSSL engine is used.

=head2 get_engine

returns the used OpenSSL engine or the empty string if no engine
is used.

=head2 filter_stdout

expects a scalar with the complete output inside. It returns
the output but without the noise which is generated by
the used engine. The function is used to filter engine specific
messages from STDOUT.
