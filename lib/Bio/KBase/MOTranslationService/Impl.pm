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




=head2 map_to_fid

  $return_1, $log = $obj->map_to_fid($query_sequences, $genomeId)

=over 4

=item Parameter and return types

=begin html

<pre>
$query_sequences is a reference to a list where each element is a query_sequence
$genomeId is a genomeId
$return_1 is a reference to a hash where the key is a protein_id and the value is a result
$log is a status
query_sequence is a reference to a hash where the following keys are defined:
	id has a value which is a protein_id
	seq has a value which is a protein_sequence
	start has a value which is a position
	stop has a value which is a position
protein_id is a string
protein_sequence is a string
position is an int
genomeId is a kbaseId
kbaseId is a string
result is a reference to a hash where the following keys are defined:
	best_match has a value which is a fid
	status has a value which is a status
fid is a string
status is a string

</pre>

=end html

=begin text

$query_sequences is a reference to a list where each element is a query_sequence
$genomeId is a genomeId
$return_1 is a reference to a hash where the key is a protein_id and the value is a result
$log is a status
query_sequence is a reference to a hash where the following keys are defined:
	id has a value which is a protein_id
	seq has a value which is a protein_sequence
	start has a value which is a position
	stop has a value which is a position
protein_id is a string
protein_sequence is a string
position is an int
genomeId is a kbaseId
kbaseId is a string
result is a reference to a hash where the following keys are defined:
	best_match has a value which is a fid
	status has a value which is a status
fid is a string
status is a string


=end text



=item Description

A general method to lookup the best matching feature id in a specific genome for a given protein sequence.
The intended use of this method is to map identical genomes
This method allows an incremental approach, for instance, exact MD5 is checked first, then
some heuristics, possibly ending with a blast run...  Could start out simply using Gavin's heuristic
matching algorithm if additional options are passed in, such as start and stop sites, or other genome
context information such as ordering in an operon.

=back

=cut

sub map_to_fid
{
    my $self = shift;
    my($query_sequences, $genomeId) = @_;

    my @_bad_arguments;
    (ref($query_sequences) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"query_sequences\" (value was \"$query_sequences\")");
    (!ref($genomeId)) or push(@_bad_arguments, "Invalid type for argument \"genomeId\" (value was \"$genomeId\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to map_to_fid:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'map_to_fid');
    }

    my $ctx = $Bio::KBase::MOTranslationService::Service::CallContext;
    my($return_1, $log);
    #BEGIN map_to_fid
    #END map_to_fid
    my @_bad_returns;
    (ref($return_1) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return_1\" (value was \"$return_1\")");
    (!ref($log)) or push(@_bad_returns, "Invalid type for return variable \"log\" (value was \"$log\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to map_to_fid:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'map_to_fid');
    }
    return($return_1, $log);
}




=head2 moLocusIds_to_fid_in_genome

  $return = $obj->moLocusIds_to_fid_in_genome($moLocusIds)

=over 4

=item Parameter and return types

=begin html

<pre>
$moLocusIds is a reference to a list where each element is a moLocusId
$return is a reference to a hash where the key is a moLocusId and the value is a result
moLocusId is an int
result is a reference to a hash where the following keys are defined:
	best_match has a value which is a fid
	status has a value which is a status
fid is a string
status is a string

</pre>

=end html

=begin text

$moLocusIds is a reference to a list where each element is a moLocusId
$return is a reference to a hash where the key is a moLocusId and the value is a result
moLocusId is an int
result is a reference to a hash where the following keys are defined:
	best_match has a value which is a fid
	status has a value which is a status
fid is a string
status is a string


=end text



=item Description

the less general method that we want for simplicity

=back

=cut

sub moLocusIds_to_fid_in_genome
{
    my $self = shift;
    my($moLocusIds) = @_;

    my @_bad_arguments;
    (ref($moLocusIds) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"moLocusIds\" (value was \"$moLocusIds\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to moLocusIds_to_fid_in_genome:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'moLocusIds_to_fid_in_genome');
    }

    my $ctx = $Bio::KBase::MOTranslationService::Service::CallContext;
    my($return);
    #BEGIN moLocusIds_to_fid_in_genome
    #END moLocusIds_to_fid_in_genome
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to moLocusIds_to_fid_in_genome:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'moLocusIds_to_fid_in_genome');
    }
    return($return);
}




=head2 moTaxonomyId_to_genomes

  $return = $obj->moTaxonomyId_to_genomes($moTaxonomyId)

=over 4

=item Parameter and return types

=begin html

<pre>
$moTaxonomyId is a moTaxonomyId
$return is a reference to a list where each element is a genomeId
moTaxonomyId is an int
genomeId is a kbaseId
kbaseId is a string

</pre>

=end html

=begin text

$moTaxonomyId is a moTaxonomyId
$return is a reference to a list where each element is a genomeId
moTaxonomyId is an int
genomeId is a kbaseId
kbaseId is a string


=end text



=item Description

A method to map MO identical genomes.

=back

=cut

sub moTaxonomyId_to_genomes
{
    my $self = shift;
    my($moTaxonomyId) = @_;

    my @_bad_arguments;
    (!ref($moTaxonomyId)) or push(@_bad_arguments, "Invalid type for argument \"moTaxonomyId\" (value was \"$moTaxonomyId\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to moTaxonomyId_to_genomes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'moTaxonomyId_to_genomes');
    }

    my $ctx = $Bio::KBase::MOTranslationService::Service::CallContext;
    my($return);
    #BEGIN moTaxonomyId_to_genomes
    #END moTaxonomyId_to_genomes
    my @_bad_returns;
    (ref($return) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to moTaxonomyId_to_genomes:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'moTaxonomyId_to_genomes');
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



=head2 genomeId

=over 4



=item Description

genomeId is a kbase id of a genome


=item Definition

=begin html

<pre>
a kbaseId
</pre>

=end html

=begin text

a kbaseId

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



=head2 protein_sequence

=over 4



=item Description

AA sequence of a protein


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



=head2 protein_id

=over 4



=item Description

internally consistant and unique id of a protein (could just be integers 0..n), necessary
for returning results


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



=head2 position

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



=head2 query_sequence

=over 4



=item Description

struct for input for constructing the sequence to fid mapping


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a protein_id
seq has a value which is a protein_sequence
start has a value which is a position
stop has a value which is a position

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a protein_id
seq has a value which is a protein_sequence
start has a value which is a position
stop has a value which is a position


=end text

=back



=head2 status

=over 4



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



=head2 result

=over 4



=item Description

indicates how the best match was found, or other details


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
best_match has a value which is a fid
status has a value which is a status

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
best_match has a value which is a fid
status has a value which is a status


=end text

=back



=cut

1;
