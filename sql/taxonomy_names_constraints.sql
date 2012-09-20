ALTER TABLE taxonomy_names
	ADD INDEX name_txt_idx (name_txt);

show errors;
exit;
