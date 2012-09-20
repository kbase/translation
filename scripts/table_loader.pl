#!/usr/bin/perl -w
use strict;
use DBI;
use DBD::mysql;
use Getopt::Long;


# CONFIG VARIABLES
use vars qw($database $host $port $user $pw
            $table_name $delimiter $file $num_cols);

GetOptions (
    'db=s'   => \$database,
    'h=s'    => \$host,
    'port=i' => \$port,
    'u=s'    => \$user,
    'p=s'    => \$pw,
    't=s'    => \$table_name,
    'd=s'    => \$delimiter,
    'f=s'    => \$file,
    'cols=i' => \$num_cols,
    );

# do some param validation
usage() unless (defined $database
    and defined $user
    and defined $pw
    and defined $file
    and defined $table_name
    and defined $file);
die "$file does not exist" unless -e $file;

# set some default param values
$delimiter = '\|' unless defined $delimiter;
$port = 3306 unless defined $port;
$host = 'db1.chicago.kbase.us' unless defined $host;

# connect to the database
my $dsn = "dbi:mysql:$database:$host:$port";
my $dbh = DBI->connect($dsn, $user, $pw)
    or die "could not connect\n$DBI::errstr\n";

open F, $file or die "could not open $file";
my $rownum = 0;
while(<F>) {
  s/\|\s*$//;
  s/\(/\\\(/g;
  s/\)/\\\)/g;
  s/\"/\\\"/g;
  s/footnote \|\|/footnote /g;
  my @a=split/$delimiter/;

  # validate number of fields parsed from the data file 
  # equals the number expected
  if (defined $num_cols) {
      die "wrong num columns parsed, found ", scalar @a,
      " expected ", $num_cols unless @a == $num_cols;
  }

  map(s/^\s+//, @a);
  map(s/\s+$//, @a);
  my $sql = "insert into $table_name values (";
  foreach my $value (@a) {
      #my $quoted_value = $dbh->quote($value);
      #$sql .= $quoted_value;
      $sql .= '?';
      $sql .= ','
  }
  $sql =~ s/,$//;
  $sql .= ")";
  
  # print $sql, "\n";
  my $rs = $dbh->prepare($sql) or die "could not prepare $sql\n$DBI::errstr\n";
  
  for (my $i = 1; $i <= @a; $i++) {
      $rs->bind_param($i, $a[$i-1]);
  }
  
  my $rv = $rs->execute() or warn "could not execute $sql\n$DBI::errstr\n";
  $rs->finish();
  
  $rownum++;
  # $dbh->commit() if $rownum%1000 == 0;
  
  print STDERR "$rownum\t.\n" unless $rownum%1000;

}
print "attemped inserts on $rownum records into $table_name\n";
close F;



sub usage {
    print<<'END';

        'db=s'   => \$database,
    'h=s'    => \$host,
    'port=i' => \$port,
    'u=s'    => \$user,
    'p=s'    => \$pw,
    't=s'    => \$table_name,
    'd=s'    => \$delimiter,
    'f=s'    => \$file,
    'cols=i' => \$num_cols,
    );

END
    exit;
}
