package OpenXPKI::Test::QA::Role::Workflows::Instance;
use Moose;
use utf8;

# Core modules
use Test::More;
use Test::Exception;

# Project modules
use OpenXPKI::Server::Context;

=head1 NAME

OpenXPKI::Test::QA::Role::Workflows::Instance - represents an instance
of a workflow that can be tested

=head1 METHODS

=cut

################################################################################
# Constructor attributes
#

=head2 new

Constructor: creates a new workflow instance using API command
L<create_workflow_instance|OpenXPKI::Server::API2::Plugin::Workflow::create_workflow_instance>.

Named parameters:

=over

=item * C<oxitest> I<OpenXPKI::Test> - instance of the test object

=item * C<type> I<Str> - workflow type (i.e. name)

=item * C<params> I<HashRef> - workflow parameters. Default: {}

=back

=cut

has oxitest => (
    is => 'rw',
    isa => 'OpenXPKI::Test',
    required => 1,
);

has type => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has params => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
);

=head2 id

Returns the workflow ID.

=cut
has id => (
    is => 'rw',
    init_arg => undef,
);

=head2 last_wf_state

Returns the workflow status I<HashRef> as returned by the last execution of the
C<execute_workflow_activity> API command.

=cut
has last_wf_state => (
    is => 'rw',
    isa => 'Any',
    init_arg => undef,
    predicate => 'has_last_wf_state',
);

#
#
#
sub BUILD {
    my $self = shift;

    my $data = $self->oxitest->api2_command(
        create_workflow_instance => {
            workflow => $self->type,
            params => $self->params,
        }
    );
    $self->last_wf_state($data->{workflow}) if $data->{workflow};

    my $id = $data->{workflow}->{id} or die explain $data;
    $self->id($id);
    note "Created workflow #$id (".$self->type.")";
}

=head2 start_activity

Executes the API command I<execute_workflow_activity> as a test.

Example:

    $wf->start_activity(
        "csr_ask_client_password",
        { _password => "m4#bDf7m3abd" },
    );

B<Positional Parameters>

=over

=item * C<$activity> I<Str> - workflow activity name

=item * C<$params> I<HashRef> - parameters

=back

=cut
sub start_activity {
    my ($self, $activity, $params) = @_;

    my $result;
    lives_ok {
        $result = $self->oxitest->api2_command(
            execute_workflow_activity => {
                id => $self->id,
                activity => $activity,
                params => $params // {},
            }
        );
        $self->last_wf_state($result->{workflow}) if $result->{workflow};
    } "Executing workflow activity $activity";

    return $result;
}

=head2 execute_fails

Executes the API command I<execute_workflow_activity> as a test and expect
it to fail with the given exception.

Example:

    $wf->execute_fails(
        "csr_ask_client_password",
        { _password => "m4#bDf7m3abd" },
        qr/MyException/,
    );

B<Positional Parameters>

=over

=item * C<$activity> I<Str> - workflow activity name

=item * C<$params> I<HashRef> - parameters

=item * C<$failure> I<Regex> - Regular expression that the exceptions is matched agains

=back

=cut
sub execute_fails {
    my ($self, $activity, $params, $failure) = @_;

    my $result;
    throws_ok {
        $self->oxitest->api2_command(
            execute_workflow_activity => {
                id => $self->id,
                activity => $activity,
                params => $params // {},
            }
        );
    } $failure, "Executing workflow activity $activity should fail";
}

=head2 state_is

Checks the state of the workflow (with a L<Test::More> test).

This command only works if the workflow has previously been modified by this
classes methods.

B<Positional Parameters>

=over

=item * C<$expected_state> I<Str> - expected current workflow state

=back

=cut
sub state_is {
    my ($self, $expected_state) = @_;
    if ($self->has_last_wf_state) {
        is $self->last_wf_state->{state}, $expected_state, "workflow state is '$expected_state'";
    }
    else {
        fail "workflow state is '$expected_state'";
    }
}

=head2 change_user

Change the user that is seen by the workflow actions and conditions.

B<Positional Parameters>

=over

=item * C<$user> I<Str> - username

=item * C<$role> I<Str> - role

=back

=cut
sub change_user {
    my ($self, $user, $role) = @_;

    # set current user to: normal user
    OpenXPKI::Server::Context::CTX('session')->data->user($user);
    OpenXPKI::Server::Context::CTX('session')->data->role($role);

    # reset condition cache so e.g. user role checks are re-evaluated
    my $wf = OpenXPKI::Server::Context::CTX('workflow_factory')->get_factory->fetch_workflow($self->type, $self->id);
    $wf->_get_workflow_state->clear_condition_cache;
}

__PACKAGE__->meta->make_immutable;
