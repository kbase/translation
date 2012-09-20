/* names.dmp
 * ------
 * taxonomy names file has these fields:
 * 
 *      tax_id                                  -- the id of node associated with this name
 *      name_txt                                -- name itself
 *      unique name                             -- the unique variant of this name if name not unique
 *      name class                              -- (synonym, common name, ...)
 */


 create table taxonomy_names ( 
	tax_id int, name_txt varchar (4000),
	unique_name varchar(512),
	name_class varchar(4000)
); 

show errors;
exit;
