package NameTranslationImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

NameTranslation

=head1 DESCRIPTION

'genbank acronym', 'common name', 'misnomer', 'teleomorph'

=cut

#BEGIN_HEADER
use DBI;
use Storable qw(dclone);
#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 get_all_translations

  $translations = $obj->get_all_translations($name)

=over 4

=item Parameter and return types

=begin html

<pre>
$name is a Name
$translations is a Translations
Name is a string
Translations is a reference to a hash where the key is a Tax_id and the value is a Names
Tax_id is an int
Names is a reference to a hash where the following keys are defined:
	scientific_name has a value which is a string
	common_names has a value which is a reference to a list where each element is a string
	synonyms has a value which is a reference to a list where each element is a string
	misspellings has a value which is a reference to a list where each element is a string
	equivalent_names has a value which is a reference to a list where each element is a string
	in_parts has a value which is a reference to a list where each element is a string
	anamorphs has a value which is a reference to a list where each element is a string
	includes has a value which is a reference to a list where each element is a string
	acronyms has a value which is a reference to a list where each element is a string
	authorities has a value which is a reference to a list where each element is a string
	misnomers has a value which is a reference to a list where each element is a string
	teleomorphs has a value which is a reference to a list where each element is a string
	blast_names has a value which is a reference to a list where each element is a string
	genbank_synonyms has a value which is a reference to a list where each element is a string
	genbank_anamorphs has a value which is a reference to a list where each element is a string
	genbank_acronyms has a value which is a reference to a list where each element is a string
	genbank_common_names has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$name is a Name
$translations is a Translations
Name is a string
Translations is a reference to a hash where the key is a Tax_id and the value is a Names
Tax_id is an int
Names is a reference to a hash where the following keys are defined:
	scientific_name has a value which is a string
	common_names has a value which is a reference to a list where each element is a string
	synonyms has a value which is a reference to a list where each element is a string
	misspellings has a value which is a reference to a list where each element is a string
	equivalent_names has a value which is a reference to a list where each element is a string
	in_parts has a value which is a reference to a list where each element is a string
	anamorphs has a value which is a reference to a list where each element is a string
	includes has a value which is a reference to a list where each element is a string
	acronyms has a value which is a reference to a list where each element is a string
	authorities has a value which is a reference to a list where each element is a string
	misnomers has a value which is a reference to a list where each element is a string
	teleomorphs has a value which is a reference to a list where each element is a string
	blast_names has a value which is a reference to a list where each element is a string
	genbank_synonyms has a value which is a reference to a list where each element is a string
	genbank_anamorphs has a value which is a reference to a list where each element is a string
	genbank_acronyms has a value which is a reference to a list where each element is a string
	genbank_common_names has a value which is a reference to a list where each element is a string


=end text



=item Description

Returns all possible name translations for a given name.

=back

=cut

sub get_all_translations
{
    my $self = shift;
    my($name) = @_;

    my @_bad_arguments;
    (!ref($name)) or push(@_bad_arguments, "Invalid type for argument \"name\" (value was \"$name\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to get_all_translations:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_all_translations');
    }

    my $ctx = $NameTranslationServer::CallContext;
    my($translations);
    #BEGIN get_all_translations


    my $db_connection = DBI->connect('DBI:mysql:naming_dev:db1.chicago.kbase.us', 'namingselect', '',
				     { RaiseError => 1, ShowErrorStatement => 1 }
    );


    my $query_string = "SELECT A.tax_id, A.name_txt, A.unique_name, A.name_class FROM taxonomy_names AS A, taxonomy_names as B WHERE A.tax_id = B.tax_id AND B.name_txt = ?";    
    my $db_query_handler = $db_connection->prepare($query_string) or die "Could not prepare " . $query_string . " " . $db_connection->errstr();
    $db_query_handler->execute($name) or die "Could not execute " . $query_string . " " . $db_query_handler->errstr();

    my %all_translations;

    while (my ($tax_id, $name_txt, $unique_name, $name_class) = $db_query_handler->fetchrow_array()) {
        if (exists $all_translations{$tax_id}) {
            ;
        }
        else {
            $all_translations{$tax_id} = {
                                          "scientific_name", "",
                                          "common_names", [],
                                          "synonyms", [],
                                          "misspellings", [],
                                          "equivalent_names", [],
                                          "in_parts", [],
                                          "anamorphs", [],
                                          "includes", [],
                                          "acronyms", [],
                                          "authorities", [],
                                          "misnomers", [],
                                          "teleomorphs", [],
                                          "blast_names", [],
                                          "genbank_synonyms", [],
                                          "genbank_anamorphs", [],
                                          "genbank_acronyms", [],
                                          "genbank_common_names", []};
        }
        
        if ($name_class eq "scientific name") {
            $all_translations{$tax_id}{"scientific_name"} = $name_txt;
	}
        elsif ($name_class eq "common name") {
            push @{$all_translations{$tax_id}{"common_names"}}, $name_txt;
	}
        elsif ($name_class eq "synonym") {
            push @{$all_translations{$tax_id}{"synonyms"}}, $name_txt;
        }
        elsif ($name_class eq "misspelling") {
            push @{$all_translations{$tax_id}{"misspellings"}}, $name_txt;
	}
        elsif ($name_class eq "equivalent name") {
            push @{$all_translations{$tax_id}{"equivalent_names"}}, $name_txt;
	}
        elsif ($name_class eq "in-part") {
            push @{$all_translations{$tax_id}{"in_parts"}}, $name_txt;
	}
        elsif ($name_class eq "anamorph") {
            push @{$all_translations{$tax_id}{"anamorphs"}}, $name_txt;
	}
        elsif ($name_class eq "includes") {
            push @{$all_translations{$tax_id}{"includes"}}, $name_txt;
	}
        elsif ($name_class eq "acronym") {
            push @{$all_translations{$tax_id}{"acronyms"}}, $name_txt;
	}
        elsif ($name_class eq "authority") {
            push @{$all_translations{$tax_id}{"authorities"}}, $name_txt;
	}
        elsif ($name_class eq "misnomer") {
            push @{$all_translations{$tax_id}{"misnomers"}}, $name_txt;
	}
        elsif ($name_class eq "teleomorph") {
            push @{$all_translations{$tax_id}{"teleomorphs"}}, $name_txt;
	}
        elsif ($name_class eq "blast name") {
            push @{$all_translations{$tax_id}{"blast_names"}}, $name_txt;
	}
        elsif ($name_class eq "genbank synonym") {
            push @{$all_translations{$tax_id}{"genbank_synonyms"}}, $name_txt;
	}
        elsif ($name_class eq "genbank anamorph") {
            push @{$all_translations{$tax_id}{"genbank_anamorphs"}}, $name_txt;
	}
        elsif ($name_class eq "genbank acronym") {
            push @{$all_translations{$tax_id}{"genbank_acronyms"}}, $name_txt;
	}
        elsif ($name_class eq "genbank common name") {
            push @{$all_translations{$tax_id}{"genbank_common_names"}}, $name_txt;
	}
        else {
	}
    }

    $translations = \%all_translations;
    #do a lookup for all items that at least partially match this string

    #END get_all_translations
    my @_bad_returns;
    (ref($translations) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"translations\" (value was \"$translations\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to get_all_translations:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_all_translations');
    }
    return($translations);
}




=head2 get_scientific_names_by_name

  $return = $obj->get_scientific_names_by_name($name)

=over 4

=item Parameter and return types

=begin html

<pre>
$name is a Name
$return is a reference to a hash where the key is a Tax_id and the value is a string
Name is a string
Tax_id is an int

</pre>

=end html

=begin text

$name is a Name
$return is a reference to a hash where the key is a Tax_id and the value is a string
Name is a string
Tax_id is an int


=end text



=item Description

Returns a mapping between tax_id and scientific name for a given name.

=back

=cut

sub get_scientific_names_by_name
{
    my $self = shift;
    my($name) = @_;

    my @_bad_arguments;
    (!ref($name)) or push(@_bad_arguments, "Invalid type for argument \"name\" (value was \"$name\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to get_scientific_names_by_name:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_scientific_names_by_name');
    }

    my $ctx = $NameTranslationServer::CallContext;
    my($return);
    #BEGIN get_scientific_names_by_name
    my $db_connection = DBI->connect('DBI:mysql:naming_dev;host=db1.chicago.kbase.us', 'namingselect', '',
				     { RaiseError => 1, ShowErrorStatement => 1 }
    );


    my $query_string = "SELECT A.tax_id, A.name_txt FROM taxonomy_names AS A, taxonomy_names AS B WHERE A.name_class = 'scientific name' AND A.tax_id = B.tax_id AND B.name_txt = ?";    
    my $db_query_handler = $db_connection->prepare($query_string) or die "Could not prepare " . $query_string . " " . $db_connection->errstr();
    $db_query_handler->execute($name) or die "Could not execute " . $query_string . " " . $db_query_handler->errstr();


    my %db_result;

    while (my ($tax_id, $name_txt) = $db_query_handler->fetchrow_array()) {
        $db_result{$tax_id} = $name_txt;
    }

    $return = \%db_result;

    #END get_scientific_names_by_name
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to get_scientific_names_by_name:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_scientific_names_by_name');
    }
    return($return);
}




=head2 get_all_names_by_name

  $return = $obj->get_all_names_by_name($name)

=over 4

=item Parameter and return types

=begin html

<pre>
$name is a Name
$return is a reference to a hash where the key is a Tax_id and the value is a reference to a list where each element is a Name
Name is a string
Tax_id is an int

</pre>

=end html

=begin text

$name is a Name
$return is a reference to a hash where the key is a Tax_id and the value is a reference to a list where each element is a Name
Name is a string
Tax_id is an int


=end text



=item Description

Returns a mapping between tax_id and a list of all associated names for a given name.

=back

=cut

sub get_all_names_by_name
{
    my $self = shift;
    my($name) = @_;

    my @_bad_arguments;
    (!ref($name)) or push(@_bad_arguments, "Invalid type for argument \"name\" (value was \"$name\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to get_all_names_by_name:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_all_names_by_name');
    }

    my $ctx = $NameTranslationServer::CallContext;
    my($return);
    #BEGIN get_all_names_by_name
    my $db_connection = DBI->connect('DBI:mysql:naming_dev;host=db1.chicago.kbase.us', 'namingselect', '',
				     { RaiseError => 1, ShowErrorStatement => 1 }
    );


    my $query_string = "SELECT A.tax_id, A.name_txt FROM taxonomy_names AS A, taxonomy_names AS B WHERE A.tax_id = B.tax_id AND B.name_txt = ?";    
    my $db_query_handler = $db_connection->prepare($query_string) or die "Could not prepare " . $query_string . " " . $db_connection->errstr();
    $db_query_handler->execute($name) or die "Could not execute " . $query_string . " " . $db_query_handler->errstr();

    my %db_result;

    while (my ($tax_id, $name_txt) = $db_query_handler->fetchrow_array()) {
        if (exists $db_result{$tax_id}) {
            push(@{$db_result{$tax_id}}, $name_txt);
        } 
        else {
            $db_result{$tax_id} = [$name_txt]; 
        }
    }

    $return = \%db_result;

    #END get_all_names_by_name
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to get_all_names_by_name:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_all_names_by_name');
    }
    return($return);
}




=head2 get_scientific_name_by_tax_id

  $name = $obj->get_scientific_name_by_tax_id($tax_id)

=over 4

=item Parameter and return types

=begin html

<pre>
$tax_id is a Tax_id
$name is a Name
Tax_id is an int
Name is a string

</pre>

=end html

=begin text

$tax_id is a Tax_id
$name is a Name
Tax_id is an int
Name is a string


=end text



=item Description

Returns the scientific name for a given tax id.

=back

=cut

sub get_scientific_name_by_tax_id
{
    my $self = shift;
    my($tax_id) = @_;

    my @_bad_arguments;
    (!ref($tax_id)) or push(@_bad_arguments, "Invalid type for argument \"tax_id\" (value was \"$tax_id\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to get_scientific_name_by_tax_id:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_scientific_name_by_tax_id');
    }

    my $ctx = $NameTranslationServer::CallContext;
    my($name);
    #BEGIN get_scientific_name_by_tax_id
    my $db_connection = DBI->connect('DBI:mysql:naming_dev;host=db1.chicago.kbase.us', 'namingselect', '',
				     { RaiseError => 1, ShowErrorStatement => 1 }
    );


    my $query_string = "SELECT name_txt FROM taxonomy_names WHERE name_class = 'scientific name' AND tax_id = ?";    
    my $db_query_handler = $db_connection->prepare($query_string) or die "Could not prepare " . $query_string . " " . $db_connection->errstr();
    $db_query_handler->execute($tax_id) or die "Could not execute " . $query_string . " " . $db_query_handler->errstr();

    ($name) = $db_query_handler->fetchrow_array();

    #END get_scientific_name_by_tax_id
    my @_bad_returns;
    (!ref($name)) or push(@_bad_returns, "Invalid type for return variable \"name\" (value was \"$name\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to get_scientific_name_by_tax_id:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_scientific_name_by_tax_id');
    }
    return($name);
}




=head2 get_tax_id_by_scientific_name

  $tax_id = $obj->get_tax_id_by_scientific_name($name)

=over 4

=item Parameter and return types

=begin html

<pre>
$name is a Name
$tax_id is a Tax_id
Name is a string
Tax_id is an int

</pre>

=end html

=begin text

$name is a Name
$tax_id is a Tax_id
Name is a string
Tax_id is an int


=end text



=item Description

Returns the tax id for a given scientific name.

=back

=cut

sub get_tax_id_by_scientific_name
{
    my $self = shift;
    my($name) = @_;

    my @_bad_arguments;
    (!ref($name)) or push(@_bad_arguments, "Invalid type for argument \"name\" (value was \"$name\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to get_tax_id_by_scientific_name:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_tax_id_by_scientific_name');
    }

    my $ctx = $NameTranslationServer::CallContext;
    my($tax_id);
    #BEGIN get_tax_id_by_scientific_name
    my $db_connection = DBI->connect('DBI:mysql:naming_dev;host=db1.chicago.kbase.us', 'namingselect', '',
				     { RaiseError => 1, ShowErrorStatement => 1 }
    );


    my $query_string = "SELECT tax_id FROM taxonomy_names WHERE name_txt = ? AND name_class = 'scientific name'";    
    my $db_query_handler = $db_connection->prepare($query_string) or die "Could not prepare " . $query_string . " " . $db_connection->errstr();
    $db_query_handler->execute($name) or die "Could not execute " . $query_string . " " . $db_query_handler->errstr();

    ($tax_id) = $db_query_handler->fetchrow_array();

    #END get_tax_id_by_scientific_name
    my @_bad_returns;
    (!ref($tax_id)) or push(@_bad_returns, "Invalid type for return variable \"tax_id\" (value was \"$tax_id\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to get_tax_id_by_scientific_name:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_tax_id_by_scientific_name');
    }
    return($tax_id);
}




=head2 get_tax_ids_by_name

  $tax_ids = $obj->get_tax_ids_by_name($name)

=over 4

=item Parameter and return types

=begin html

<pre>
$name is a Name
$tax_ids is a reference to a list where each element is a Tax_id
Name is a string
Tax_id is an int

</pre>

=end html

=begin text

$name is a Name
$tax_ids is a reference to a list where each element is a Tax_id
Name is a string
Tax_id is an int


=end text



=item Description

Returns a list of tax ids for a given name.

=back

=cut

sub get_tax_ids_by_name
{
    my $self = shift;
    my($name) = @_;

    my @_bad_arguments;
    (!ref($name)) or push(@_bad_arguments, "Invalid type for argument \"name\" (value was \"$name\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to get_tax_ids_by_name:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_tax_ids_by_name');
    }

    my $ctx = $NameTranslationServer::CallContext;
    my($tax_ids);
    #BEGIN get_tax_ids_by_name
    my $db_connection = DBI->connect('DBI:mysql:naming_dev;host=db1.chicago.kbase.us', 'namingselect', '',
				     { RaiseError => 1, ShowErrorStatement => 1 }
    );


    my $query_string = "SELECT DISTINCT(A.tax_id) FROM taxonomy_names AS A, taxonomy_names AS B WHERE A.tax_id = B.tax_id AND B.name_txt = ?";    
    my $db_query_handler = $db_connection->prepare($query_string) or die "Could not prepare " . $query_string . " " . $db_connection->errstr();
    $db_query_handler->execute($name) or die "Could not execute " . $query_string . " " . $db_query_handler->errstr();

    my @db_result;

    while(my ($tax_id) = $db_query_handler->fetchrow_array()) {
        push @db_result, $tax_id;        
    }

    $tax_ids = \@db_result;

    #END get_tax_ids_by_name
    my @_bad_returns;
    (ref($tax_ids) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"tax_ids\" (value was \"$tax_ids\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to get_tax_ids_by_name:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_tax_ids_by_name');
    }
    return($tax_ids);
}




=head2 get_all_names_by_tax_id

  $names = $obj->get_all_names_by_tax_id($tax_id)

=over 4

=item Parameter and return types

=begin html

<pre>
$tax_id is a Tax_id
$names is a reference to a list where each element is a Name
Tax_id is an int
Name is a string

</pre>

=end html

=begin text

$tax_id is a Tax_id
$names is a reference to a list where each element is a Name
Tax_id is an int
Name is a string


=end text



=item Description

Returns a list of names for a given tax id.

=back

=cut

sub get_all_names_by_tax_id
{
    my $self = shift;
    my($tax_id) = @_;

    my @_bad_arguments;
    (!ref($tax_id)) or push(@_bad_arguments, "Invalid type for argument \"tax_id\" (value was \"$tax_id\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to get_all_names_by_tax_id:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_all_names_by_tax_id');
    }

    my $ctx = $NameTranslationServer::CallContext;
    my($names);
    #BEGIN get_all_names_by_tax_id
    my $db_connection = DBI->connect('DBI:mysql:naming_dev;host=db1.chicago.kbase.us', 'namingselect', '',
				     { RaiseError => 1, ShowErrorStatement => 1 }
    );


    my $query_string = "SELECT name_txt FROM taxonomy_names WHERE tax_id = ?";    
    my $db_query_handler = $db_connection->prepare($query_string) or die "Could not prepare " . $query_string . " " . $db_connection->errstr();
    $db_query_handler->execute($tax_id) or die "Could not execute " . $query_string . " " . $db_query_handler->errstr();

    my @db_result;

    while( my ($name_txt) = $db_query_handler->fetchrow_array()) {
        push @db_result, $name_txt;
    }

    $names = \@db_result;
    
    #END get_all_names_by_tax_id
    my @_bad_returns;
    (ref($names) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"names\" (value was \"$names\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to get_all_names_by_tax_id:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_all_names_by_tax_id');
    }
    return($names);
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



=head2 Name

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



=head2 Tax_id

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



=head2 Names

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
scientific_name has a value which is a string
common_names has a value which is a reference to a list where each element is a string
synonyms has a value which is a reference to a list where each element is a string
misspellings has a value which is a reference to a list where each element is a string
equivalent_names has a value which is a reference to a list where each element is a string
in_parts has a value which is a reference to a list where each element is a string
anamorphs has a value which is a reference to a list where each element is a string
includes has a value which is a reference to a list where each element is a string
acronyms has a value which is a reference to a list where each element is a string
authorities has a value which is a reference to a list where each element is a string
misnomers has a value which is a reference to a list where each element is a string
teleomorphs has a value which is a reference to a list where each element is a string
blast_names has a value which is a reference to a list where each element is a string
genbank_synonyms has a value which is a reference to a list where each element is a string
genbank_anamorphs has a value which is a reference to a list where each element is a string
genbank_acronyms has a value which is a reference to a list where each element is a string
genbank_common_names has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
scientific_name has a value which is a string
common_names has a value which is a reference to a list where each element is a string
synonyms has a value which is a reference to a list where each element is a string
misspellings has a value which is a reference to a list where each element is a string
equivalent_names has a value which is a reference to a list where each element is a string
in_parts has a value which is a reference to a list where each element is a string
anamorphs has a value which is a reference to a list where each element is a string
includes has a value which is a reference to a list where each element is a string
acronyms has a value which is a reference to a list where each element is a string
authorities has a value which is a reference to a list where each element is a string
misnomers has a value which is a reference to a list where each element is a string
teleomorphs has a value which is a reference to a list where each element is a string
blast_names has a value which is a reference to a list where each element is a string
genbank_synonyms has a value which is a reference to a list where each element is a string
genbank_anamorphs has a value which is a reference to a list where each element is a string
genbank_acronyms has a value which is a reference to a list where each element is a string
genbank_common_names has a value which is a reference to a list where each element is a string


=end text

=back



=head2 Translations

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the key is a Tax_id and the value is a Names
</pre>

=end html

=begin text

a reference to a hash where the key is a Tax_id and the value is a Names

=end text

=back



=cut

1;
