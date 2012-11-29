package Bio::KBase::MOTranslationService::Impl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

MOTranslation

=head1 DESCRIPTION

This module will translate KBase ids to MicrobesOnline ids and
vice-versa. For features, it will initially use MD5s to perform
the translation.

The MOTranslation module will ultimately be deprecated, once all
MicrobesOnline data types are natively stored in KBase. In general
the module and methods should not be publicized, and are mainly intended
to be used internally by other KBase services (specifically the protein
info service).

=cut

#BEGIN_HEADER

use Bio::KBase;
use Bio::KBase::CDMI::CDMIClient;
use DBKernel;

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

#	my $kb = Bio::KBase->new();
	my $cdmi = Bio::KBase::CDMI::CDMIClient->new;

#	my $moDbh=DBI->connect("DBI:mysql:genomics:db1.chicago.kbase.us",'genomics');
        my $dbms='mysql';
        my $dbName='genomics';
        my $user='genomics';
        my $pass=undef;
        my $port=3306;
        my $dbhost='db1.chicago.kbase.us';
        my $sock='';
        my $dbKernel = DBKernel->new($dbms, $dbName, $user, $pass, $port, $dbhost, $sock);
        my $moDbh=$dbKernel->{_dbh};

	$self->{moDbh}=$moDbh;
	$self->{cdmi}=$cdmi;

    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 fids_to_moLocusIds

  $return = $obj->fids_to_moLocusIds($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is a reference to a list where each element is a moLocusId
fid is a string
moLocusId is an int

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is a reference to a list where each element is a moLocusId
fid is a string
moLocusId is an int


=end text



=item Description

fids_to_moLocusIds translates a list of fids into MicrobesOnline
locusIds. It uses proteins_to_moLocusIds internally.

=back

=cut

sub fids_to_moLocusIds
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_moLocusIds:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_moLocusIds');
    }

    my $ctx = $Bio::KBase::MOTranslationService::Service::CallContext;
    my($return);
    #BEGIN fids_to_moLocusIds

	$return={};
	my $cdmi=$self->{cdmi};
	my $f2proteins=$cdmi->fids_to_proteins($fids);
	my @proteins=values %{$f2proteins};
	my $p2mo=$self->proteins_to_moLocusIds(\@proteins);

	foreach my $fid (keys %{$f2proteins})
	{
		$return->{$fid}=$p2mo->{$f2proteins->{$fid}};
	}

    #END fids_to_moLocusIds
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_moLocusIds:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_moLocusIds');
    }
    return($return);
}




=head2 proteins_to_moLocusIds

  $return = $obj->proteins_to_moLocusIds($proteins)

=over 4

=item Parameter and return types

=begin html

<pre>
$proteins is a reference to a list where each element is a protein
$return is a reference to a hash where the key is a protein and the value is a reference to a list where each element is a moLocusId
protein is a string
moLocusId is an int

</pre>

=end html

=begin text

$proteins is a reference to a list where each element is a protein
$return is a reference to a hash where the key is a protein and the value is a reference to a list where each element is a moLocusId
protein is a string
moLocusId is an int


=end text



=item Description

proteins_to_moLocusIds translates a list of proteins (MD5s) into
MicrobesOnline locusIds.

=back

=cut

sub proteins_to_moLocusIds
{
    my $self = shift;
    my($proteins) = @_;

    my @_bad_arguments;
    (ref($proteins) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"proteins\" (value was \"$proteins\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to proteins_to_moLocusIds:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'proteins_to_moLocusIds');
    }

    my $ctx = $Bio::KBase::MOTranslationService::Service::CallContext;
    my($return);
    #BEGIN proteins_to_moLocusIds

	$return={};

	if (scalar @$proteins)
	{
		my $moDbh=$self->{moDbh};

		my $sql='SELECT DISTINCT aaMD5,locusId FROM Locus2MD5 WHERE aaMD5 IN (';
		my $placeholders='?,' x (scalar @$proteins);
		chop $placeholders;
		$sql.=$placeholders.')';

		my $sth=$moDbh->prepare($sql);
		$sth->execute(@$proteins);
		while (my $row=$sth->fetch)
		{
			push @{$return->{$row->[0]}},$row->[1];
		}
	}

    #END proteins_to_moLocusIds
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to proteins_to_moLocusIds:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'proteins_to_moLocusIds');
    }
    return($return);
}




=head2 moLocusIds_to_fids

  $return = $obj->moLocusIds_to_fids($moLocusIds)

=over 4

=item Parameter and return types

=begin html

<pre>
$moLocusIds is a reference to a list where each element is a moLocusId
$return is a reference to a hash where the key is a moLocusId and the value is a reference to a list where each element is a fid
moLocusId is an int
fid is a string

</pre>

=end html

=begin text

$moLocusIds is a reference to a list where each element is a moLocusId
$return is a reference to a hash where the key is a moLocusId and the value is a reference to a list where each element is a fid
moLocusId is an int
fid is a string


=end text



=item Description

moLocusIds_to_fids translates a list of MicrobesOnline locusIds
into KBase fids. It uses moLocusIds_to_proteins internally.

=back

=cut

sub moLocusIds_to_fids
{
    my $self = shift;
    my($moLocusIds) = @_;

    my @_bad_arguments;
    (ref($moLocusIds) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"moLocusIds\" (value was \"$moLocusIds\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to moLocusIds_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'moLocusIds_to_fids');
    }

    my $ctx = $Bio::KBase::MOTranslationService::Service::CallContext;
    my($return);
    #BEGIN moLocusIds_to_fids

	$return={};
	my $cdmi=$self->{cdmi};
	my $mo2proteins=$self->moLocusIds_to_proteins($moLocusIds);
	my @proteins=values %{$mo2proteins};
	my $proteins2fids=$cdmi->proteins_to_fids(\@proteins);

	foreach my $moLocusId (keys %{$mo2proteins})
	{
		$return->{$moLocusId}=$proteins2fids->{$mo2proteins->{$moLocusId}};
	}

    #END moLocusIds_to_fids
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to moLocusIds_to_fids:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'moLocusIds_to_fids');
    }
    return($return);
}




=head2 moLocusIds_to_proteins

  $return = $obj->moLocusIds_to_proteins($moLocusIds)

=over 4

=item Parameter and return types

=begin html

<pre>
$moLocusIds is a reference to a list where each element is a moLocusId
$return is a reference to a hash where the key is a moLocusId and the value is a protein
moLocusId is an int
protein is a string

</pre>

=end html

=begin text

$moLocusIds is a reference to a list where each element is a moLocusId
$return is a reference to a hash where the key is a moLocusId and the value is a protein
moLocusId is an int
protein is a string


=end text



=item Description

moLocusIds_to_proteins translates a list of MicrobesOnline locusIds
into proteins (MD5s).

=back

=cut

sub moLocusIds_to_proteins
{
    my $self = shift;
    my($moLocusIds) = @_;

    my @_bad_arguments;
    (ref($moLocusIds) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"moLocusIds\" (value was \"$moLocusIds\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to moLocusIds_to_proteins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'moLocusIds_to_proteins');
    }

    my $ctx = $Bio::KBase::MOTranslationService::Service::CallContext;
    my($return);
    #BEGIN moLocusIds_to_proteins

	$return={};

	if (scalar @$moLocusIds)
	{
		my $moDbh=$self->{moDbh};

		my $sql='SELECT DISTINCT locusId,aaMD5 FROM Locus2MD5 WHERE locusId IN (';
		my $placeholders='?,' x (scalar @$moLocusIds);
		chop $placeholders;
		$sql.=$placeholders.')';

		my $sth=$moDbh->prepare($sql);
		$sth->execute(@$moLocusIds);
		while (my $row=$sth->fetch)
		{
			$return->{$row->[0]}=$row->[1];
		}
	}

    #END moLocusIds_to_proteins
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to moLocusIds_to_proteins:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'moLocusIds_to_proteins');
    }
    return($return);
}




=head2 version 

  $return = $obj->version()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module version. This is a Semantic Versioning number.

=back

=cut

sub version {
    return $VERSION;
}

=head1 TYPES



=head2 protein

=over 4



=item Description

protein is an MD5 in KBase. It is the primary lookup between
KBase fids and MicrobesOnline locusIds.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 kbaseId

=over 4



=item Description

kbaseId can represent any object with a KBase identifier. 
In the future this may be used to translate between other data
types, such as contig or genome.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 fid

=over 4



=item Description

fid is a feature id in KBase.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 moLocusId

=over 4



=item Description

moLocusId is a locusId in MicrobesOnline. It is analogous to a fid
in KBase.


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 moScaffoldId

=over 4



=item Description

moScaffoldId is a scaffoldId in MicrobesOnline.  It is analogous to
a contig kbId in KBase.


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 moTaxonomyId

=over 4



=item Description

moTaxonomyId is a taxonomyId in MicrobesOnline.  It is somewhat analogous
to a genome kbId in KBase.  It generally stores the NCBI taxonomy ID,
though sometimes can store an internal identifier instead.


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=cut

1;
