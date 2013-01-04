



use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::ERDB_Service::Client;
use Data::Dumper;



my $cdmi = Bio::KBase::CDMI::CDMIClient->new();
my $erdb = Bio::KBase::ERDB_Service::Client->new("http://localhost:7061");

my $target_genome = "kb|g.372";
my $fasta_file_name = substr($target_genome,3);
my $db_name = "db.".substr($target_genome,3);


# get all the feature ids

# check if a database for this genome exists

# if it does not exist, then create one

#my $$cdmi->genomes_to_fids([$target_genome]);
#print Dumper()





############################################
print " -> getting MO data\n";
use DBKernel;

my $dbms='mysql';
my $dbName='genomics';
#my $user='genomics';
#my $pass=undef;
#my $dbhost='db1.chicago.kbase.us';
my $port=3306;
my $user='guest';
my $pass=guest;
my $dbhost='pub.microbesonline.org';
my $sock='';
my $dbKernel = DBKernel->new($dbms, $dbName, $user, $pass, $port, $dbhost, $sock);
my $moDbh=$dbKernel->{_dbh};


my $tax_id = "211586";

my $query_sequences = [];
my $sql='SELECT Locus.locusId,Position.begin,Position.end,AASeq.sequence,Position.strand FROM AASeq,Locus,Scaffold,Position WHERE '.
            'Locus.priority=1 AND Locus.locusId=AASeq.locusId AND Locus.version=AASeq.version AND '.
            'Locus.posId=Position.posId AND Locus.scaffoldId=Scaffold.scaffoldId AND Scaffold.taxonomyId=?';
my $sth=$moDbh->prepare($sql);
$sth->execute($tax_id);
while (my $row=$sth->fetch) {
    # switch the start and stop if we are on the minus strand
    if (${$row}[4] eq '+') {
        push @$query_sequences, {id=>${$row}[0],start=>${$row}[1], stop=>${$row}[2], seq=>${$row}[3] };
    } else {
        push @$query_sequences, {id=>${$row}[0],start=>${$row}[2], stop=>${$row}[1], seq=>${$row}[3] };
    }
}
#print Dumper($query_sequences)."\n";
############################################



############################################
# typedef struct {
#    fid best_match;
#    status status;
#} result;
#
# typedef mapping<query_id,result> results;
#
# construct the return object
my $query_count = scalar @{$query_sequences};
my $results = {};
foreach my $query (@$query_sequences) {
    $results->{$query->{id}} = {fid=>'',status=>''};
}
############################################




############################################
print " -> mapping based on md5 values first\n";

#need a custom approach because the current cdmi methods don't limit the results based on genomes
my $objectNames = 'ProteinSequence IsProteinFor Feature IsOwnedBy IsLocatedIn';
my $filterClause = 'IsLocatedIn(ordinal)=0 AND IsOwnedBy(to-link)=?';
my $parameters = [$target_genome];
my $fields = 'Feature(id) ProteinSequence(id) IsLocatedIn(begin) IsLocatedIn(len) IsLocatedIn(dir)';
my $count = 0; #as per ERDB doc, setting to zero returns all results
my @feature_list = @{$erdb->GetAll($objectNames, $filterClause, $parameters, $fields, $count)};
my $target_feature_count = scalar @feature_list;

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
		    $results->{$query->{id}}->{fid} = $fid;
		    $results->{$query->{id}}->{status} = "exact MD5 and start position match";
                } else {
                    die "two exact matches for $fid!! ($query->{id} and $feature_match->{$fid}";
                }
                $found_match=1;
                $exact_match_count++;
            } elsif ( 30 > abs($query->{start} - $md5_2_feature_map->{$md5_value}->{$fid}->[0]) ) {
		if ($feature_match->{$fid} eq '') {
                    $feature_match->{$fid} = $query->{id};
		    $results->{$query->{id}}->{fid} = $fid;
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
        $no_match++;
    }
}

print " -> exactly matched: $exact_match_count of $query_count query sequences\n";
print " -> matched MD5 +- 30bp: $exact_md5_only_count of $query_count query sequences\n";
my $total = $exact_match_count +$exact_md5_only_count;
print " -> mapped: $total of $target_feature_count target genome features\n";

############################################


############################################
if (-e $fasta_file_name) {
 print " -> blast database for target genome already exists.\n";
} else { 
    print "-> building BLAST database for the target genome\n";
    # get all the features with a protein coding sequence, and also get that protein sequence and MD5
    my $objectNames = 'ProteinSequence IsProteinFor Feature IsOwnedBy';
    my $filterClause = 'IsOwnedBy(to-link)=?';
    my $parameters = [$target_genome];
    my $fields = 'Feature(id) ProteinSequence(id) ProteinSequence(sequence)';
    my $count = 0; #as per ERDB doc, setting to zero returns all results
    my @feature_list = @{$erdb->GetAll($objectNames, $filterClause, $parameters, $fields, $count)};
    
    # put each feature in a fasta file that we can convert to a BLAST DB
    open (FASTA_DB, ">$fasta_file_name");
    foreach my $feature (@feature_list) {
        my $fid_simple = substr(${$feature}[0],3);
        print FASTA_DB ">".$fid_simple."\n"; # the feature ID is pos 0
        print FASTA_DB ${$feature}[2]."\n"; # the feature protein sequence in pos 0
    }
    close (FASTA_DB);
    
    # convert the fasta file to a blast DB
    system("formatdb","-p","T","-l","formatdb.log","-i",$fasta_file_name);
}
#############################################



############################################
# first create the temporary input file
use File::Temp;

my $scratch_space = "/kb/dev_container/modules/translation/queries/"; #$self->{'scratch_space'}
#$File::Temp::KEEP_ALL = 1; # FOR DEBUGGING ONLY, WE DON't WANT TO KEEP ALL FILES IN PRODUCTION
my $tmp_file = File::Temp->new( TEMPLATE => 'queryXXXXXXXXXX',
	    DIR => $scratch_space,
	    SUFFIX => '.fasta.tmp');
# save all the files that we couldn't match (note, this step could be rolled into the loop of the md5 matching...)
my $blast_query_count=0;
foreach my $query (@$query_sequences) {
    if($results->{$query->{id}}->{fid} eq '') {
        print $tmp_file ">".$query->{id}."\n";
	print $tmp_file $query->{seq}."\n";
	$blast_query_count++;
    }
}
print " -> blasting $blast_query_count sequences against the target genome\n";



# options for blasting:
#  we expect the genomes to be identical for now, so we do not expect gapped alignments, but we do not
#      enforce this because we might want to extend this method in the future for similar genomes
#  (note that if we turn off gaps, we must also turn off comp_based_stats
#  we set the evalue threshold to be 0.01 (since really, for now, we are looking for exact matches)
#  we set the output format to 6, which is simple tabular format with the specified ordering
open(RESULTS,"blastp ".
     #"-ungapped ".
     #"-comp_based_stats F ".
     "-evalue 0.01 ".
     # Fields: query id, subject id, evalue, bit score, identical, alignment length, query length, subject length
     "-outfmt='6 qseqid sseqid evalue bitscore nident length qlen slen' ".
     "-db $fasta_file_name ".
     "-query ".$tmp_file->filename." |") || die "Failed: $!\n";

# compile the results
my $last_query = '';
my $last_hit = [];
my $c=0;
while(my $line=<RESULTS>) {
    chomp($line);
    my @hit = split("\t",$line);
    
    
    if( $hit[0] ne $last_query ) {
	print "----";
	$last_query=$hit[0];
    }
    
    
    # compute number of identical matches over the query and subject sequences
    my $query_coverage = $hit[4] / $hit[6];
    my $subject_coverage = $hit[4] / $hit[7];
    
    # coverage must be (arbitrarily) over 50% bidirectional
    my $min_coverage = 0.5;
    if( $query_coverage>=$min_coverage  &&  $subject_coverage>=$min_coverage ) {
	print "q:".$hit[0]." h:".$hit[1]." cq:".$query_coverage." cs:".$subject_coverage."\n";
	$c++;
    }
}
print "went through $c total hits\n";
close(RESULTS);
############################################