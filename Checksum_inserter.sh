#!/usr/bin/bash



LIST=$1;
NOW=`date -u +"%Y-%m-%d %H:%M:%S UTC"`;

for LINE in `cat $LIST`;
	do
	prod=`echo $LINE | cut -d',' -f1`;
	prodid=`echo $LINE | cut -d',' -f3`;
	md5=`echo $LINE | cut -d',' -f2`;
	psql -h s2rep-pg-01.s2rep.local s2rephub -c "insert into checksums (product_id,download_checksum_value,download_checksum_algorithm) values ($prodid,'$md5','MD5')";
	psql -h s2rep-pg-01.s2rep.local s2rephub -c "UPDATE PRODUCTS SET updated=now()::timestamp(3) WHERE id=$prodid";
	echo "";
	echo "$NOW - Inserted ID:$prodid and checksum:$md5 for product:$prod" |tee -a /data/tools/Checksum_check_checker/log/insertion_log.txt;
	psql -h s2rep-pg-01.s2rep.local s2rephub -c "copy(select id,updated,value from products p left join checksums c on (p.id=product_id) join keystoreentries k on k.entrykey=p.uuid where product_id=$prodid and tag='unaltered' and keystore like 'datastore-s%') to stdout with delimiter ','";
	echo "";
	done


exit 0


