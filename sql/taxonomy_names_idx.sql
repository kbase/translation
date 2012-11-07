ALTER TABLE taxonomy_names
	ADD INDEX name_txt_idx (name_txt);

ALTER TABLE taxonomy_names
	ADD INDEX tax_id_idx (tax_id);

show errors;
exit;
