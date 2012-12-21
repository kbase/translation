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
use Bio::KBase::ERDB_Service::Client;
use DBKernel;
use Data::Dumper;

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

        # do we need this call to KBase->new anymore?  can we remove this dependency? -mike
#	my $kb = Bio::KBase->new();
	my $cdmi = Bio::KBase::CDMI::CDMIClient->new;

#	my $moDbh=DBI->connect("DBI:mysql:genomics:db1.chicago.kbase.us",'genomics');
        my $dbms='mysql';
        my $dbName='genomics';
        my $user='genomics';
        my $pass=undef;
        my $port=3306;
        my $dbhost='db1.chicago.kbase.us';
	# switch to public microbes online
        #$user='guest';
        #$pass='guest';
        #$dbhost='pub.microbesonline.org';
        my $sock='';
        my $dbKernel = DBKernel->new($dbms, $dbName, $user, $pass, $port, $dbhost, $sock);
        my $moDbh=$dbKernel->{_dbh};

	# need to use config file here to get the url!!!!! 
	my $erdb = Bio::KBase::ERDB_Service::Client->new("http://localhost:7999");
	
	$self->{moDbh}=$moDbh;
	$self->{cdmi}=$cdmi;
	$self->{erdb}=$erdb;

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
    
    # construct the return objects
    $return_1 = {}; $log = '';
    my $query_count = scalar @{$query_sequences};
    my $results = {};
    foreach my $query (@$query_sequences) {
	$results->{$query->{id}} = {best_match=>'',status=>''};
    }
    
    
    $log.=" -> mapping based on md5 values first\n";
    $log.=" -> looking up CDM data for your target genome\n";
    #need a custom approach because the current cdmi methods don't limit the results based on genomes
    my $erdb = $self->{erdb};
    my $objectNames = 'ProteinSequence IsProteinFor Feature IsOwnedBy IsLocatedIn';
    my $filterClause = 'IsLocatedIn(ordinal)=0 AND IsOwnedBy(to-link)=?';
    my $parameters = [$genomeId];
    my $fields = 'Feature(id) ProteinSequence(id) IsLocatedIn(begin) IsLocatedIn(len) IsLocatedIn(dir)';
    my $count = 0; #as per ERDB doc, setting to zero returns all results
    my @feature_list = @{$erdb->GetAll($objectNames, $filterClause, $parameters, $fields, $count)};
    my $target_feature_count = scalar @feature_list;
    
    $log.=" -> found $target_feature_count features with protein sequences for your target genome\n";
    
    # create a hash for faster lookups
    my $md5_2_feature_map = {};
    my $feature_match = {};
    foreach my $feature (@feature_list) {
	my $start_pos; # the start position of the gene!  in the cds, start stores the left most position
	if(${$feature}[4] eq '+') {
	    $start_pos = ${$feature}[2];
	} else {
	    $start_pos = ${$feature}[2] + ${$feature}[3] - 1;
	}
	$md5_2_feature_map->{${$feature}[1]}->{${$feature}[0]}=[$start_pos,${$feature}[3]];
	$feature_match->{${$feature}[0]} = '';
    }
    #print Dumper($md5_2_feature_map)."\n";
    
    
    # actually try to do the mapping
    my $exact_match_count = 0;
    my $exact_md5_only_count = 0;
    my $no_match_count = 0;
    use Digest::MD5  qw(md5_hex);
    foreach my $query (@$query_sequences) {
	my $md5_value = md5_hex($query->{seq});
	if(exists($md5_2_feature_map->{$md5_value})) {
	    my $found_match = 0;
	    my @keys = keys %{$md5_2_feature_map->{$md5_value}};
	    foreach my $fid (@keys) {
		if($query->{start} == $md5_2_feature_map->{$md5_value}->{$fid}->[0]) {
		    if ($feature_match->{$fid} eq '') {
			$feature_match->{$fid} = $query->{id};
			$results->{$query->{id}}->{best_match} = $fid;
			$results->{$query->{id}}->{status} = "exact MD5 and start position match";
		    } else {
			die "two exact matches for $fid!! ($query->{id} and $feature_match->{$fid}";
		    }
		    $found_match=1;
		    $exact_match_count++;
		} elsif ( 30 > abs($query->{start} - $md5_2_feature_map->{$md5_value}->{$fid}->[0]) ) {
		    if ($feature_match->{$fid} eq '') {
			$feature_match->{$fid} = $query->{id};
			$results->{$query->{id}}->{best_match} = $fid;
			$results->{$query->{id}}->{status} = "exact MD5; start position within 30bp";
		    } else {
			die "two overlapping matches for $fid!! ($query->{id} and $feature_match->{$fid}";
		    }
		    $exact_md5_only_count++;
		}
	    }
	    if($found_match==0) {
		# we may still be able to match if we get an exact md5 match AND there is only one matching feature,
		# but we have to make sure that the feature is not mapped to anything closer
		if( scalar(@keys) == 1) {
		    #if( abs($md5_2_feature_map->{$md5_value}->{@keys[0]}-$query->{start}->[0]) < 30 ) {
		    #    if ($feature_match->{$fid} eq '') {
		    #	$feature_match->{$fid} = $query->{id};
		    #} else {
		    #    die "two exact matches for $fid!! ($query->{id} and $feature_match->{$fid}";
		    #}
		    #    $results->{$query->{id}}->{fid} = $fid;
		    #    $results->{$query->{id}}->{status} = "exact MD5 match; start positions within 20bp";
		    #    $counter++;
		    #}
		}
		#}
		#print "query: ".$query->{id}." md5: ".$md5_value." start: ".$query->{start}." end: ".$query->{end}."\n";
		#print "match: ".Dumper($md5_2_feature_map->{$md5_value})."\n";
		#if( scalar(@keys) == 1) {
		#    my $fid = $md5_2_feature_map->{$md5_value}->{@keys[0]};
		#    print "only one feature, which has been mapped to: '$feature_match->{$fid}'\n";
		#}
	    }
	} else {
	    $no_match_count++;
	}
    }
    
    $log.= " -> exactly matched: $exact_match_count of $query_count query sequences\n";
    $log.= " -> matched MD5 +- 30bp: $exact_md5_only_count of $query_count query sequences\n";
    my $total = $exact_match_count +$exact_md5_only_count;
    $log.= " -> mapped: $total of $target_feature_count target genome features\n";
	
    
    foreach my $query (@$query_sequences) {
	if($results->{$query->{id}}->{fid} eq '') {
	    $results->{$query->{id}}->{status} = "could not find a match"
	}
    }
    
    
    $return_1 = $results;
    
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

  $return_1, $log = $obj->moLocusIds_to_fid_in_genome($moLocusIds, $genomeId)

=over 4

=item Parameter and return types

=begin html

<pre>
$moLocusIds is a reference to a list where each element is a moLocusId
$genomeId is a genomeId
$return_1 is a reference to a hash where the key is a moLocusId and the value is a result
$log is a status
moLocusId is an int
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

$moLocusIds is a reference to a list where each element is a moLocusId
$genomeId is a genomeId
$return_1 is a reference to a hash where the key is a moLocusId and the value is a result
$log is a status
moLocusId is an int
genomeId is a kbaseId
kbaseId is a string
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
    my($moLocusIds, $genomeId) = @_;

    my @_bad_arguments;
    (ref($moLocusIds) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"moLocusIds\" (value was \"$moLocusIds\")");
    (!ref($genomeId)) or push(@_bad_arguments, "Invalid type for argument \"genomeId\" (value was \"$genomeId\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to moLocusIds_to_fid_in_genome:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'moLocusIds_to_fid_in_genome');
    }

    my $ctx = $Bio::KBase::MOTranslationService::Service::CallContext;
    my($return_1, $log);
    #BEGIN moLocusIds_to_fid_in_genome
    
    # first go to MO and get the locus inforamation
    my $moDbh = $self->{moDbh};
    my $sql='SELECT Locus.locusId,Position.begin,Position.end,AASeq.sequence,Position.strand FROM AASeq,Locus,Scaffold,Position WHERE '.
            'Locus.priority=1 AND Locus.locusId=AASeq.locusId AND Locus.version=AASeq.version AND '.
            'Locus.posId=Position.posId AND Locus.scaffoldId=Scaffold.scaffoldId AND Locus.locusId IN (';
    my $placeholders='?,' x (scalar @$moLocusIds);
    chop $placeholders;
    $sql.=$placeholders.')';
    my $sth=$moDbh->prepare($sql);
    $sth->execute(@$moLocusIds);
    
    # process the query results and store them in an object we can pass to the map_to_fid method
    my $query_sequences = [];
    while (my $row=$sth->fetch) {
	# switch the start and stop if we are on the minus strand
	if (${$row}[4] eq '+') {
	    push @$query_sequences, {id=>${$row}[0],start=>${$row}[1], stop=>${$row}[2], seq=>${$row}[3] };
	} else {
	    push @$query_sequences, {id=>${$row}[0],start=>${$row}[2], stop=>${$row}[1], seq=>${$row}[3] };
	}
    }
    
    # then we can call the method and save the results
    my ($res, $l) = $self->map_to_fid($query_sequences,$genomeId);
    $return_1 = $res;
    $log = $l;
    
    
    #END moLocusIds_to_fid_in_genome
    my @_bad_returns;
    (ref($return_1) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return_1\" (value was \"$return_1\")");
    (!ref($log)) or push(@_bad_returns, "Invalid type for return variable \"log\" (value was \"$log\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to moLocusIds_to_fid_in_genome:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'moLocusIds_to_fid_in_genome');
    }
    return($return_1, $log);
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

    # setup the return array ref
    $return = [];
    
    # make sure we have some input
    if ($moTaxonomyId ne "") {
        my $mo_genome_md5s = [];

        # query the Genome2MD5 table for matches
        my $moDbh=$self->{moDbh};
        my $sql = 'SELECT DISTINCT genomeMD5 FROM Genome2MD5 WHERE taxonomyId=?';
        my $query_handle=$moDbh->prepare($sql);
        $query_handle->execute($moTaxonomyId);

        # get each matching row
        while (my $row=$query_handle->fetch()) {
            push(@$mo_genome_md5s, $row->[0]);
        }
       
        # check if we didn't find any results
        if( scalar @{$mo_genome_md5s} > 0 ) {
	    #my $test_mo_genome_md5s = ['4138384cbf747edbde549398d1e123d0'];
	    # call KBase cdmi api to fetch genomes that match these MD5s
	    my $cdmi = $self->{cdmi};
	    my $genomes = $cdmi->md5s_to_genomes($mo_genome_md5s);
    
	    # transform results into a single list of KBase genome ids
	    foreach my $genome_id_list (values %{$genomes}) {
		foreach my $gid (@{$genome_id_list}) {
		    push @$return, $gid;
		}
	    } 
	}
    }

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
