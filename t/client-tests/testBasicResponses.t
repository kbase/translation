#!/usr/bin/perl
#  
#  The purpose of this test is to make sure we recieve some response from the server for the list of functions
#  given.  Each of these functions listed should return some value, but the actual value is not checked here.
#  Thus, this test is ideal for making sure you are actually recieving something from a service call even if
#  that service is not yet implemented yet.
#
#  If you add functionality to the MOTranslation service API, you should add an appropriate test here.
#
#  author:  landml
#  created: 11/21/2012
#  updated :

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use lib "../lib/";

use FindBin;
use lib "$FindBin::Bin/..";

#############################################################################
# HERE IS A LIST OF METHODS AND PARAMETERS THAT WE WANT TO TEST
# NOTE THAT THE PARAMETERS ARE JUST MADE UP AT THE MOMENT
my $func_calls = {
       fids_to_moLocusIds  => ["((a,b)c);"],
       proteins_to_moLocusIds => ["((a,b)c);"],
       moLocusIds_to_fids     => ["((a,b)c);"],
       moLocusIds_to_proteins => ["((a,b)c);"],
                 };
#############################################################################
my $n_tests = (scalar(keys %$func_calls)+3); # set this to be the number of function calls + 3


# MAKE SURE WE LOCALLY HAVE JSON RPC LIBS
#  NOTE: for initial testing, you may have to modify MOTranslationService.pm to also
#        point to the legacy interface
use_ok("JSON::RPC::Client");
use_ok("Bio::KBase::MOTranslationService::Client");

# MAKE A CONNECTION (DETERMINE THE URL TO USE BASED ON THE CONFIG MODULE)
#my $host=getHost(); my $port=getPort();
#print "-> attempting to connect to:'".$host.":".$port."'\n";
#my $client = Bio::KBase::MOTranslationService::Client->new($host.":".$port);

#NEW VERSION WITH AUTO START / STOP SERVICE
use lib "$FindBin::Bin/.";
use Server;
my ($pid, $url) = Server::start('MOTranslationService');
print "-> attempting to connect to:'".$url."'\n";
my $client = Bio::KBase::MOTranslationService::Client->new($url);

ok(defined($client),"instantiating MOTranslationService client");





# LOOP THROUGH ALL THE REMOTE CALLS AND MAKE SURE WE GOT SOMETHING
my $method_name;
for $method_name (keys %$func_calls) {
        #print "==========\n$method_name => @{ $func_calls->{$method_name}}\n";
        #my $n_args = scalar @{ $func_calls->{$method_name}};
        my $result;
        print "calling function: \"$method_name\"\n";
        {
            no strict "refs";
            $result = $client->$method_name(@{ $func_calls->{$method_name}});
        }
        ok($result,"looking for a response from \"$method_name\"");
}

done_testing($n_tests);
