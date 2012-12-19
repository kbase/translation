/*
This module will translate KBase ids to MicrobesOnline ids and
vice-versa. For features, it will initially use MD5s to perform
the translation.

The MOTranslation module will ultimately be deprecated, once all
MicrobesOnline data types are natively stored in KBase. In general
the module and methods should not be publicized, and are mainly intended
to be used internally by other KBase services (specifically the protein
info service).
*/


module MOTranslation {

	/*
	protein is an MD5 in KBase. It is the primary lookup between
	KBase fids and MicrobesOnline locusIds.
	*/
        typedef string protein;
	/*
	kbaseId can represent any object with a KBase identifier. 
	In the future this may be used to translate between other data
	types, such as contig or genome.
	*/
        typedef string kbaseId;
	/*
	genomeId is a kbase id of a genome
	*/
        typedef kbaseId genomeId;
	
	
	/*
	fid is a feature id in KBase.
	*/
        typedef string fid;
	/*
	moLocusId is a locusId in MicrobesOnline. It is analogous to a fid
	in KBase.
	*/
        typedef int moLocusId;
	/*
	moScaffoldId is a scaffoldId in MicrobesOnline.  It is analogous to
	a contig kbId in KBase.
	*/
        typedef int moScaffoldId;
	/*
	moTaxonomyId is a taxonomyId in MicrobesOnline.  It is somewhat analogous
	to a genome kbId in KBase.  It generally stores the NCBI taxonomy ID,
	though sometimes can store an internal identifier instead.
	*/
        typedef int moTaxonomyId;

	/*
	fids_to_moLocusIds translates a list of fids into MicrobesOnline
	locusIds. It uses proteins_to_moLocusIds internally.
	*/
        funcdef fids_to_moLocusIds(list<fid> fids) returns (mapping<fid,list<moLocusId>>);
	/*
	proteins_to_moLocusIds translates a list of proteins (MD5s) into
	MicrobesOnline locusIds.
	*/
        funcdef proteins_to_moLocusIds(list<protein> proteins) returns (mapping<protein,list<moLocusId>>);

	/*
	moLocusIds_to_fids translates a list of MicrobesOnline locusIds
	into KBase fids. It uses moLocusIds_to_proteins internally.
	*/
        funcdef moLocusIds_to_fids(list<moLocusId> moLocusIds) returns (mapping<moLocusId,list<fid>>);
	/*
	moLocusIds_to_proteins translates a list of MicrobesOnline locusIds
	into proteins (MD5s).
	*/
        funcdef moLocusIds_to_proteins(list<moLocusId> moLocusIds) returns (mapping<moLocusId,protein>);






	/* NEW METHODS ***************************************************************************** */
	
	
	/* AA sequence of a protein */
	typedef string protein_sequence;
	
	/* internally consistant and unique id of a protein (could just be integers 0..n), necessary
	for returning results */
	typedef string protein_id;
	
	typedef int position;
	
	/* struct for input for constructing the sequence to fid mapping */
	typedef structure {
		protein_id id;
		protein_sequence seq;
		position start;
		position stop;
	} query_sequence;
	
	
	typedef string status;
	
	/* simple struct to return the best match so that we can also return details about how the match was made (in status string) */
	typedef structure {
	    fid best_match;
	    status status; /* indicates how the best match was found, or other details */
	} result;
	
	
	/*
	A general method to lookup the best matching feature id in a specific genome for a given protein sequence.
	The intended use of this method is to map identical genomes
	This method allows an incremental approach, for instance, exact MD5 is checked first, then
	some heuristics, possibly ending with a blast run...  Could start out simply using Gavin's heuristic
	matching algorithm if additional options are passed in, such as start and stop sites, or other genome
	context information such as ordering in an operon.
	*/
	funcdef map_to_fid(list<query_sequence>query_sequences, genomeId genomeId)
	                           returns (mapping<protein_id,result>);
	
	
	/* the less general method that we want for simplicity */
	funcdef moLocusIds_to_fid_in_genome(list<moLocusId> moLocusIds) returns (mapping<moLocusId,result>);
	
	
	
	
	/* A method to map MO identical genomes. */
	funcdef moTaxonomyId_to_genomes(moTaxonomyId moTaxonomyId) returns (list<genomeId>);
	
	
};
