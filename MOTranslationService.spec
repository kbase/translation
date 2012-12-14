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


        /*
	proposed additions: (msneddon)
	
	A general method to lookup the best matching feature id in a specific genome for a given protein sequence.
	This method should allow an incremental approach, for instance, exact MD5 is checked first, then
	some heuristics, possibly ending with a blast run...  Could start out simply using Gavin's heuristic
	matching algorithm if additional options are passed in, such as start and stop sites, or other genome
	context information such as ordering in an operon.
	
	/* AA sequence of a protein */
	typedef string protein_sequence;
	/* internally consistant id of a protein (could just be integers 0..n)
	typedef string protein_id;
	typedef struct { protein_id id; protein_sequence seq; } query_sequences;
	typedef struct { ??? to match exact only? to match with some parameters? provide additional data such as start positions ??? } options;
	funcdef translate_to_fid(list<query_sequences>query_sequences, genome_id genome_id, options options) returns (mapping<protein_id,fid>);
	
	
	A second method to get identical genomes.
	funcdef find_identical_genome(string MD5) return (list <genome_id>);
	
	So the idea is first we map an external (or MO) genome to an identical genome.  If we can do that, then we can, by sequence,
	map each protein sequence to a feature ID.
	
	
	*/



};
