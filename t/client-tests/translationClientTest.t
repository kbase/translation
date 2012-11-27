#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper;
use lib "../lib";

use FindBin;
use lib "$FindBin::Bin/..";

my $num_tests = 0;

##########
# Make sure we locally load up the client library and JSON RPC
use_ok("Bio::KBase::MOTranslationService::Client");
use_ok("JSON::RPC::Client");

$num_tests += 2;

##########
# Make an automatically started service.
use lib "$FindBin::Bin/.";
use Server;
my ($pid, $url) = Server::start('MOTranslationService');
print "-> attempting to connect to:'" . $url . "'\n";
my $client = Bio::KBase::MOTranslationService::Client->new($url);

ok(defined($client), "instantiating MOTranslationService client");
$num_tests++;

##########
# Set up variables and data inputs for happy tests.
my @kb_protein_md5s = qw(cf87188c893421a9a13c9300b1c3cd68 a13c9b9f465cbb30682448c255b27d3d);
my @kb_fids = qw(kb|g.20029.peg.3202 kb|g.20029.peg.2255);
my @mo_locus_ids = qw(208945 7704787);

my $happy_calls = {
	fids_to_moLocusIds => \@kb_fids,
	proteins_to_moLocusIds => \@kb_protein_md5s,
	moLocusIds_to_fids => \@mo_locus_ids,
	moLocusIds_to_proteins => \@mo_locus_ids
	};


##########
# Run happy tests.
print "Running tests with valid data.\n";

foreach my $call (keys %{ $happy_calls }) {
	my $result;
	print "calling function \"$call\"\n";
	{
		no strict "refs";
		eval { $result = $client->$call($happy_calls->{$call}); };
	}
	if ($@) { print "ERROR = $@\n"; }
	ok($result, "Got a response from \"$call\"");
	$num_tests++;	
	# this works because we're only passing an array ref for each method,
	# so don't copy this bit to other modules...

	ok(scalar(@{ $happy_calls->{$call} }) == scalar(keys %{ $result }), "\"$call\" returned the same number of elements that was passed");
	$num_tests++;
	
	my @keys = keys %{ $result };
	cmp_set(\@keys, $happy_calls->{$call}, "\"$call\" returned the correct set of elements");
	$num_tests++;
}

#my $prot_locus_ids = $client->proteins_to_moLocusIds(\@kb_protein_md5s);
#my $fid_locus_ids = $client->fids_to_moLocusIds(\@kb_fids);
#my $locus_id_fids = $client->moLocusIds_to_fids(\@mo_locus_ids);
#my $locus_id_prots = $client->moLocusIds_to_proteins(\@mo_locus_ids);

##########
# Shut down the service at the end.
Server::stop($pid);
print "Shutting down client\n";

done_testing($num_tests);

__END__

my $kbClient=Bio::KBase::MOTranslationService::Client->new("http://localhost:7061");

my $p2locusId=$kbClient->proteins_to_moLocusIds(["cf87188c893421a9a13c9300b1c3cd68","a13c9b9f465cbb30682448c255b27d3d","bork"]);
warn Dumper($p2locusId);

#my $f2locusId=$kbClient->fids_to_moLocusIds(['kb|g.20029.peg.3202','bork']);
#warn Dumper($f2locusId);

my $locusId2md5=$kbClient->moLocusIds_to_proteins([208945,7704787]);
warn Dumper($locusId2md5);

my $locusId2fids=$kbClient->moLocusIds_to_fids([208945,7704787]);
warn Dumper($locusId2fids);

