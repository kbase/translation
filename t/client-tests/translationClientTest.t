#!/usr/bin/perl

###############################################################################
# Client tests for the MicrobesOnline Translation Service
#
# This sets up a server using Server.pm, runs a series of both happy (good,
# well-formed data) and unhappy tests, then shuts down the server.
#
# Bill Riehl
# wjriehl@lbl.gov
# November 27, 2012
# November Build Meeting @ Argonne
###############################################################################

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper;
use Getopt::Long;
use lib "../lib";

use FindBin;
use lib "$FindBin::Bin/..";

my $num_tests = 0;
my $debug=0;
my $localServer=0;
# use this URI for testing test deployments from outside Magellan
my $uri='http://kbase.us/services/translation';
# use this URI for testing test deployments on deploy host
#my $uri='http://localhost:7061/';
# use this URI for testing production deployment
#my $uri='http://kbase.us/services/translation';
my $serviceName='MOTranslationService';

my $getoptResult=GetOptions(
	'debug' =>      \$debug,
	'localServer'   =>      \$localServer,
	'uri=s'         =>      \$uri,
	'serviceName=s' =>      \$serviceName,
);


##########
# Make sure we locally load up the client library and JSON RPC
use_ok("Bio::KBase::MOTranslationService::Client");
use_ok("JSON::RPC::Client");

$num_tests += 2;

##########
# Make an automatically started service.
use lib "$FindBin::Bin/.";
use Server;
my ($url,$pid);
# would be good to extract the port from a config file or env variable
$url=$uri unless ($localServer);
# Start a server on localhost if desired
($pid, $url) = Server::start($serviceName) unless ($url);
print "-> attempting to connect to:'" . $url . "'\n";
my $client = Bio::KBase::MOTranslationService::Client->new($url);

ok(defined($client), "instantiating MOTranslationService client");
$num_tests++;

##########
# Set up variables and data inputs for tests.
my @kb_protein_md5s = qw(cf87188c893421a9a13c9300b1c3cd68 a13c9b9f465cbb30682448c255b27d3d);
my @kb_fids = qw(kb|g.3405.peg.674);
my @mo_locus_ids = qw(208945 7704787);

my $method_calls = {
	fids_to_moLocusIds => {
		happy => [\@kb_fids],
		empty => [[]],
		bad => [['bad data']]
		},
	proteins_to_moLocusIds => {
		happy => [\@kb_protein_md5s],
		empty => [[]],
		bad => [['bad data']]
		},
	moLocusIds_to_fids => {
		happy => [\@mo_locus_ids],
		empty => [[]],
		bad => [['bad data']]
		},
	moLocusIds_to_proteins => {
		happy => [\@mo_locus_ids],
		empty => [[]],
		bad => [['bad data']]
		},
	moTaxonomyId_to_genomes => {
		happy => [882],
		empty => [''],
		bad => ['bad data']
		},
	# for now rely on implicit testing for these
	# inputs for happy are a nested structure
#	map_to_fid => {
#		happy => [[208926,208945],'kb|g.3562'],
#		empty => [[],''],
#		bad => [['bad data'],'really bad']
#		},
#	map_to_fid_fast => {
#		happy => [[208926,208945],'kb|g.3562'],
#		empty => [[],''],
#		bad => [['bad data'],'really bad']
#		},
	moLocusIds_to_fid_in_genome => {
		happy => [[208926,208945],'kb|g.3562'],
		empty => [[],''],
		bad => [['bad data'],'really bad']
		},
	moLocusIds_to_fid_in_genome_fast => {
		happy => [[208926,208945],'kb|g.3562'],
		empty => [[],''],
		bad => [['bad data'],'really bad']
		},
	};

###############################################################################
# Run tests.
print "Running tests with valid data.\n";

my @method_calls=keys %$method_calls;
#@method_calls=qw(
#moLocusIds_to_fid_in_genome_fast
#moLocusIds_to_proteins
#);
#moTaxonomyId_to_genomes

foreach my $call (@method_calls) {
	my $result;
	print "Testing function \"$call\"\n";
	{
		no strict "refs";
		eval { $result = $client->$call(@{$method_calls->{$call}->{happy}}); };
	}
	
	if ($@) { print "ERROR = $@\n"; }
	
	## 1. Test if we got a result of any kind from the method call.
	ok($result, "Got a response from \"$call\" with happy data");
	$num_tests++;	
	# this works because we're only passing an array ref for each method,
	# so don't copy this bit to other modules...

#	warn Dumper($result);

	## 2. Test that we got the number of elements in the result that we expect.
	# (this works because we're only passing an array ref for each method,
        # so don't copy this bit to other modules...)
#	is(scalar(@{ $method_calls->{$call}->{happy} }), scalar(keys %{ $result }), "\"$call\" returned the same number of elements that was passed");
	#$num_tests++;
	
	## 3. Test that the elements returned are the correct values.
	# (we don't really care about the actual values of the calls)
#	my @keys = keys %{ $result };
#	cmp_set(\@keys, $method_calls->{$call}->{happy}, "\"$call\" returned the correct set of elements");
	#$num_tests++;

	## 4. Test with empty (but correctly formatted) values.
	{
		no strict "refs";
		eval { $result = $client->$call(@{$method_calls->{$call}->{empty}}); }
	}
	if ($@) { print "ERROR = $@\n"; }
	ok($result, "Got a response from \"$call\" with empty input");
	$num_tests++;

	## 5. Test with bad (but correctly formatted) data.
	{
		no strict "refs";
		eval { $result = $client->$call(@{$method_calls->{$call}->{bad}}); }
	}
	if ($@) { print "ERROR = $@\n"; }
	ok($result, "Got a response from \"$call\" with bad input");
	$num_tests++;
}

###############################################################################
# Shut down the service at the end.
Server::stop($pid) if ($pid);
print "Shutting down client\n";

done_testing($num_tests);

