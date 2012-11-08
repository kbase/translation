/*
this module will translate KBase ids to MO locusIds
initially will use MD5s

should return as an <externalDb,externalId> tuple, using
MO for scaffolds and MOL:Feature for locusIds

the MOTranslation module will eventually be deprecated once all MO
data types are natively stored in KBase
*/


module MOTranslation {

	/* protein is an MD5 in KBase-that is what we will
	look up in MO -- the other methods should use the protein
	methods internally
	e.g., fids_to_moLocusIds will get the MD5 of each fid, then
	call proteins_to_moLocusIds */
        typedef string protein;
	/* kbaseId is meant to represent a contig */
        typedef string kbaseId;
	/* fid is a feature id */
        typedef string fid;
        typedef int moLocusId;
        typedef int moScaffoldId;
        typedef int moTaxonomyId;

        

        funcdef fids_to_moLocusIds(list<fid> fids) returns (mapping<fid,moLocusId>);
        funcdef proteins_to_moLocusIds(list<protein> proteins) returns (mapping<protein,moLocusId>);

        funcdef moLocusIds_to_fids(list<moLocusId> moLocusIds) returns (mapping<moLocusId,fid>);
        funcdef moLocusIds_to_proteins(list<moLocusId> moLocusIds) returns (mapping<moLocusId,protein>);

};
