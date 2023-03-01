#!/usr/bin/bash

source $HOME/.bash_profile;
DOWNLOAD_FOLDER=/mnt/s2bl2a_rep/CHECKSUM_TEST/;
RUNFILE=/data/tools/Checksum_check_checker/run.lock;

LIST=$DOWNLOAD_FOLDER/LISTS/DownloadList.txt;
ERROR_FOLDER=$DOWNLOAD_FOLDER/ERROR_FOLDER/;
CALCULATE_CHECKSUM_FOLDER=$DOWNLOAD_FOLDER/CALCULATE_CHECKSUM_FOLDER/;
LIST_TO_CALCULATE=$DOWNLOAD_FOLDER/LISTS/list_to_calculate.zip
LASTDATETIME=`cat $DOWNLOAD_FOLDER/LISTS/LASTDATETIME.txt`
NOW=`date -u +"%Y-%m-%d %H:%M:%S UTC"`;
TODAY=`date -u +"%Y%m%d"`;
LASTDATETIME_TEMP=$DOWNLOAD_FOLDER/LISTS/lastdatetime_temp.txt;
CHECKSUM_VALUES_ERROR=$DOWNLOAD_FOLDER/LISTS/checksums_error.txt;
CHECKSUM_VALUES=$DOWNLOAD_FOLDER/LISTS/checksums.txt;
SYSMA=$DOWNLOAD_FOLDER/SYSMA;
LOG_ZIP=/data/tools/Checksum_check_checker/log/log_zip_$TODAY.txt


function mainmenu {
echo ""
echo "Do you want to delete zip files in $CALCULATE_CHECKSUM_FOLDER ?"
ls -ltr $CALCULATE_CHECKSUM_FOLDER/*.zip;
echo ""
echo "Press y to delete"
echo "Press q to exit script without deleting"
echo ""
read -n 1 -p "Input Selection:" menuinput
 if [ "$menuinput" = "y" ]; then
        rm -f $CALCULATE_CHECKSUM_FOLDER/*.zip;
	echo "";
    elif [ "$menuinput" = "q" ]; then
	echo "";
    else
            echo ""
            echo "You have entered an invalid selection!"
            echo "Please try again!"
            echo ""
            echo "Press any key to continue..."
            read -n 1
            clear
            mainmenu
    fi
}

function download_product {

LINE=${1};
CONTAINER=`echo $LINE | cut -d';' -f2`;
NAME=`echo $LINE | cut -d';' -f3`;
cd $DOWNLOAD_FOLDER;
/usr/local/bin/swift download $CONTAINER $NAME;

}

function test_zip {

ZIP=${1};
ZIPNAME=`basename $ZIP`;
unzip -t $ZIP >> $LOG_ZIP;
retVal=$?;
if [ $retVal -ne 0 ]; then
	mv $ZIP $ERROR_FOLDER;
else
	mv $ZIP $CALCULATE_CHECKSUM_FOLDER;
	echo $CALCULATE_CHECKSUM_FOLDER/$ZIPNAME >> $LIST_TO_CALCULATE;
fi
}

function calculate_checksum {

FILE=${1};
FILENAME=`basename $FILE`
md5=`md5sum $FILE |awk '{print $1'}`;
retVal=$?;
product_id=`grep $FILENAME $LIST | cut -d',' -f1`;
if [ $retVal -ne 0 ]; then
	echo $FILENAME","$product_id >> ${CHECKSUM_VALUES_ERROR%.*}\_$TODAY.txt;
else
	echo $FILENAME","$md5","$product_id >> ${CHECKSUM_VALUES%.*}\_$TODAY.txt;
	touch $SYSMA/${FILENAME%.*}\.txt;
fi
}


if [ -f "$RUNFILE" ];
	then
	echo "ERROR: Script is still running Exiting...";
	exit 1;
fi

touch $RUNFILE;


source /data/tools/swift_env.sh;
retVal=$?;
if [ $retVal -ne 0 ]; then
	echo "ERROR in source /data/tools/swift_env.sh"
	exit $retVal;
fi

psql -h s2rep-pg-01.s2rep.local s2rephub -c "copy(select id,value from products p left join checksums c on (p.id=product_id) join keystoreentries k on k.entrykey=p.uuid where created > '$LASTDATETIME' and c.download_checksum_value is null and tag='unaltered' and keystore like 'datastore-s%')to stdout with delimiter ','" > $LIST;

echo $NOW > $LASTDATETIME_TEMP;

for PROD in `cat $LIST`; 
	
	do 
	
		download_product $PROD;
		
	done
	
for FILE in `ls $DOWNLOAD_FOLDER/*.zip`;

	do
	
		test_zip $FILE;
	
	done
	
for FILE_CHECKSUM in `cat $LIST_TO_CALCULATE`;

	do
	
		calculate_checksum $FILE_CHECKSUM;
		
	done


rm $LIST_TO_CALCULATE;
mv $LASTDATETIME_TEMP $DOWNLOAD_FOLDER/LISTS/LASTDATETIME.txt;
rm -f $CALCULATE_CHECKSUM_FOLDER/*.zip;
rm $RUNFILE;

#mainmenu;

echo "";
echo "Created ${CHECKSUM_VALUES%.*}_$TODAY.txt containing checksums"
echo "";
echo "Created ${CHECKSUM_VALUES_ERROR%.*}_$TODAY.txt containing list of corrupted ZIP files"
echo "";
echo "To insert checksum value into the DB please run Checksum_inserter.sh ${CHECKSUM_VALUES%.*}_$TODAY.txt";

exit 0
