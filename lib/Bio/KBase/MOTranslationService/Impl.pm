package Bio::KBase::MOTranslationService::Impl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

MOTranslation

=head1 DESCRIPTION

this module will translate KBase ids to MO locusIds
initially will use MD5s

should return as an <externalDb,externalId> tuple, using
MO for scaffolds and MOL:Feature for locusIds

the MOTranslation module will eventually be deprecated once all MO
data types are natively stored in KBase, so in general should
not be publicized, and mainly used internally by other KBase services

=cut

#BEGIN_HEADER

use Bio::KBase;
use Bio::KBase::CDMI::CDMIClient;
use DBI;

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
	my $moDbh=DBI->connect("DBI:mysql:genomics:pub.microbesonline.org",'guest','guest');
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

	my $cdmi=$self->{cdmi};
	my $f2proteins=$cdmi->fids_to_proteins($fids);
	my @proteins=values %{$f2proteins};
	my $p2mo=$self->proteins_to_moLocusIds(\@proteins);

	foreach my $fid (keys ${$f2proteins})
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

	my $moDbh=$self->{moDbh};

	my $sql='SELECT DISTINCT aaMD5,locusId FROM Locus2MD5 WHERE aaMD5 IN (';
	my $placeholders='?,' x (scalar @$proteins);
	chop $placeholders;
	$sql.=$placeholders.')';

	$return={};
	my $sth=$moDbh->prepare($sql);
	$sth->execute(@$proteins);
	while (my $row=$sth->fetch)
	{
		push @{$return->{$row->[0]}},$row->[1];
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

	my $moDbh=$self->{moDbh};

	my $sql='SELECT DISTINCT locusId,aaMD5 FROM Locus2MD5 WHERE locusId IN (';
	my $placeholders='?,' x (scalar @$moLocusIds);
	chop $placeholders;
	$sql.=$placeholders.')';

	$return={};
	my $sth=$moDbh->prepare($sql);
	$sth->execute(@$moLocusIds);
	while (my $row=$sth->fetch)
	{
		$return->{$row->[0]}=$row->[1];
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

protein is an MD5 in KBase-that is what we will
look up in MO -- the other methods should use the protein
methods internally
e.g., fids_to_moLocusIds will get the MD5 of each fid, then
call proteins_to_moLocusIds


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

kbaseId is meant to represent a contig


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

fid is a feature id


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
