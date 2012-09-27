package NameTranslationClient;

use JSON::RPC::Client;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

NameTranslationClient

=head1 DESCRIPTION



=cut

sub new
{
    my($class, $url) = @_;

    my $self = {
	client => NameTranslationClient::RpcClient->new,
	url => $url,
    };
    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 $result = get_all_translations(name)

Returns all possible name translations for a given name.

=cut

sub get_all_translations
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_all_translations (received $n, expecting 1)");
    }
    {
	my($name) = @args;

	my @_bad_arguments;
        (!ref($name)) or push(@_bad_arguments, "Invalid type for argument 1 \"name\" (value was \"$name\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_all_translations:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_all_translations');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "NameTranslation.get_all_translations",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_all_translations',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_all_translations",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_all_translations',
				       );
    }
}



=head2 $result = get_scientific_names_by_name(name)

Returns a mapping between tax_id and scientific name for a given name.

=cut

sub get_scientific_names_by_name
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_scientific_names_by_name (received $n, expecting 1)");
    }
    {
	my($name) = @args;

	my @_bad_arguments;
        (!ref($name)) or push(@_bad_arguments, "Invalid type for argument 1 \"name\" (value was \"$name\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_scientific_names_by_name:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_scientific_names_by_name');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "NameTranslation.get_scientific_names_by_name",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_scientific_names_by_name',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_scientific_names_by_name",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_scientific_names_by_name',
				       );
    }
}



=head2 $result = get_all_names_by_name(name)

Returns a mapping between tax_id and a list of all associated names for a given name.

=cut

sub get_all_names_by_name
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_all_names_by_name (received $n, expecting 1)");
    }
    {
	my($name) = @args;

	my @_bad_arguments;
        (!ref($name)) or push(@_bad_arguments, "Invalid type for argument 1 \"name\" (value was \"$name\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_all_names_by_name:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_all_names_by_name');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "NameTranslation.get_all_names_by_name",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_all_names_by_name',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_all_names_by_name",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_all_names_by_name',
				       );
    }
}



=head2 $result = get_scientific_name_by_tax_id(tax_id)

Returns the scientific name for a given tax id.

=cut

sub get_scientific_name_by_tax_id
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_scientific_name_by_tax_id (received $n, expecting 1)");
    }
    {
	my($tax_id) = @args;

	my @_bad_arguments;
        (!ref($tax_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"tax_id\" (value was \"$tax_id\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_scientific_name_by_tax_id:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_scientific_name_by_tax_id');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "NameTranslation.get_scientific_name_by_tax_id",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_scientific_name_by_tax_id',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_scientific_name_by_tax_id",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_scientific_name_by_tax_id',
				       );
    }
}



=head2 $result = get_tax_id_by_scientific_name(name)

Returns the tax id for a given scientific name.

=cut

sub get_tax_id_by_scientific_name
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_tax_id_by_scientific_name (received $n, expecting 1)");
    }
    {
	my($name) = @args;

	my @_bad_arguments;
        (!ref($name)) or push(@_bad_arguments, "Invalid type for argument 1 \"name\" (value was \"$name\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_tax_id_by_scientific_name:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_tax_id_by_scientific_name');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "NameTranslation.get_tax_id_by_scientific_name",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_tax_id_by_scientific_name',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_tax_id_by_scientific_name",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_tax_id_by_scientific_name',
				       );
    }
}



=head2 $result = get_tax_ids_by_name(name)

Returns a list of tax ids for a given name.

=cut

sub get_tax_ids_by_name
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_tax_ids_by_name (received $n, expecting 1)");
    }
    {
	my($name) = @args;

	my @_bad_arguments;
        (!ref($name)) or push(@_bad_arguments, "Invalid type for argument 1 \"name\" (value was \"$name\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_tax_ids_by_name:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_tax_ids_by_name');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "NameTranslation.get_tax_ids_by_name",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_tax_ids_by_name',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_tax_ids_by_name",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_tax_ids_by_name',
				       );
    }
}



=head2 $result = get_all_names_by_tax_id(tax_id)

Returns a list of names for a given tax id.

=cut

sub get_all_names_by_tax_id
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_all_names_by_tax_id (received $n, expecting 1)");
    }
    {
	my($tax_id) = @args;

	my @_bad_arguments;
        (!ref($tax_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"tax_id\" (value was \"$tax_id\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_all_names_by_tax_id:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_all_names_by_tax_id');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "NameTranslation.get_all_names_by_tax_id",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_all_names_by_tax_id',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_all_names_by_tax_id",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_all_names_by_tax_id',
				       );
    }
}



sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, {
        method => "NameTranslation.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'get_all_names_by_tax_id',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method get_all_names_by_tax_id",
            status_line => $self->{client}->status_line,
            method_name => 'get_all_names_by_tax_id',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for NameTranslationClient\n";
    }
    if ($sMajor == 0) {
        warn "NameTranslationClient version is $svr_version. API subject to change.\n";
    }
}

package NameTranslationClient::RpcClient;
use base 'JSON::RPC::Client';

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $obj) = @_;
    my $result;

    if ($uri =~ /\?/) {
       $result = $self->_get($uri);
    }
    else {
        Carp::croak "not hashref." unless (ref $obj eq 'HASH');
        $result = $self->_post($uri, $obj);
    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}

1;
