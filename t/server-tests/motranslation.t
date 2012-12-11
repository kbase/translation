#!/usr/bin/perl

#update 11/29/2012 - landml

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Bio::KBase::MOTranslationService::Client;
use lib "t/server-tests";
use TranslationTestConfig qw(getHost getPort);

# MAKE A CONNECTION (DETERMINE THE URL TO USE BASED ON THE CONFIG MODULE)
my $host=getHost(); my $port=getPort();
print "-> attempting to connect to:'".$host.":".$port."'\n";
my $kbClient  = Bio::KBase::MOTranslationService::Client->new($host.":".$port);


my $p2locusId=$kbClient->proteins_to_moLocusIds(["cf87188c893421a9a13c9300b1c3cd68","a13c9b9f465cbb30682448c255b27d3d","bork"]);
warn Dumper($p2locusId);

#my $f2locusId=$kbClient->fids_to_moLocusIds(['kb|g.20029.peg.3202','bork']);
#warn Dumper($f2locusId);

my $locusId2md5=$kbClient->moLocusIds_to_proteins([208945,7704787]);
warn Dumper($locusId2md5);

my $locusId2fids=$kbClient->moLocusIds_to_fids([208945,7704787]);
warn Dumper($locusId2fids);

