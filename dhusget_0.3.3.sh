#!/bin/bash

#-------------------------------------------------------------------------------------------	#
# Demo script illustrating some examples using the OData interface	#
# of the Data Hub Service (DHuS)                                                     	#
#-------------------------------------------------------------------------------------------	
# CHANGE LOG
# v0.3.1: 
#	- usage switch fixed
#	- usage text updated to include the download of Sentinel 2 products
# 	- introduction of parallel download with check of the server error messages (option -n)
#	- insertion of MD5 check 
#		
# Serco SpA 2015
# CHANGE LOG
# v0.3.2: 
#       - fixed "-f" option
#       - upgraded "-f" 
#       - added the following options described below: -s, -e, -S, -E, -F, -O, -L
#               
# Serco SpA 2015
                                                                             	#
#-------------------------------------------------------------------------------------------	#
export VERSION=0.3.2

WD=$HOME/.dhusget
PIDFILE=$WD/pid

test -d $WD || mkdir -p $WD 

#-


function print_usage 
{ 
 echo " "
 echo "---------------------------------------------------------------------------------------------------------------------------"
 echo " "
 echo "This is dhusget $VERSION, a non interactive Sentinel-1 and Sentinel-2 product (or manifest) retriever from a Data Hub instance."
 echo " " 
 echo "Usage: $1 [-d <DHuS URL>] [-u <username> ] [ -p <password>] [-t <time to search (hours)>] [-c <coordinates ie: x1,y1;x2,y2>] [-T <product type>] [-o <option>]"
 echo "Recommendation: If this script is run as a cronjob, to avoid traffic load, please do not schedule it exactly at on-the-clock hours (e.g 6:00, 5:00)"
 echo "---------------------------------------------------------------------------------------------------------------------------"
 echo " "
 echo "-u <username>         : data hub username provided after registration on <DHuS URL> ;"
 echo "-p <password>         : data hub password provided after registration on <DHuS URL> , (note: it's read from stdin, if isn't provided by commandline);"
 echo " "
 echo "-t <time to search (hours)>      : time interval expressed in hours (integer value) from NOW (time of the launch of the "
 echo "                                dhusget) to backwards (e.g. insert the value '24' if you would like to retrieve product "
 echo "                                ingested in the last day);"
 echo ""
 echo ' -s <ingestion_date_from>	: Search every products ingested after the <ingestion_date_from>. The date format shall be in ISO 8601 format (CCYY-MM-DDThh:mm[:ss[.cc]]Z)'
 echo "" 
 echo ' -e <ingestion_date_to>        : Search every products ingested before the <ingestion_date_to>. The date format shall be in ISO 8601 format (iCCYY-MM-DDThh:mm[:ss[.cc]]Z)'
 echo "" 
 echo ' -S <sensing_date_from>        : Search every products with sensing time greater than <sensing_date_from>. The date format shall be in ISO 8601 format (CCYY-MM-DDThh:mm[:ss[.cc]]Z)'
 echo "" 
 echo ' -E <sensing_date_to>          : Search every products with sensing time less than <sensing_date_to>. The date format shall be in ISO 8601 format (iCCYY-MM-DDThh:mm[:ss[.cc]]Z)'
 echo ""
 echo " -f <file>                     : Search every products ingested after the date inside the file. At the end of the process, the ingestion date inside the file will be update according to the downloaded products."
 echo ' 				The date format shall be in ISO 8601 format (iCCYY-MM-DDThh:mm[:ss[.cc]]Z)' 
 echo " "
 echo "-c <coordinates ie: lon1,lat1:lon2,lat2> : coordinates of two opposite vertices of the rectangular area of interest ; "
 echo " "
 echo "-T <product type>                : product type of the product to search (Sentinel -1 available values are:  SLC, GRD, OCN and RAW. Sentinel 2 available values are S2MSI1C) ;"
 echo " "
 echo "-o <option>                      : what to download, possible options are:"
 echo "                                   - 'manifest' to download the manifest of all products returned from the search or "
 echo "                                   - 'product' to download all products returned from the search "
 echo "                                   - 'all' to download both."
 echo "                                		N.B.: if this parameter is left blank, the dhusget will return the UUID and the names "
 echo " 			      					 of the products found in the DHuS archive."
 echo " "
 echo "-F <odata query>                 : free open query. The query will be appended after the other options" 
 echo " "
 echo "-R <file> 			: save the failled downloads in a file, this file can be used with the -r option to retry the download at the next run"
 echo " "
 echo "-r <file>			: try to download the failled products"
 echo " "
 echo "-O <folder>			: output Folder"
 echo " "
 echo "-L <file> 			: lock file"
 echo " "
 echo "-n <1...n> 			: number of threads: amount of items (products/manifests) to download in parallel"
 echo " "
 echo " "
 echo "'wget' is necessary to run the dhusget"
 echo " " 
 exit -1
}

function print_version 
{ 
	echo "dhusget $VERSION"
	exit -1
}

#----------------------
#---  Load input parameter
#export DHUS_DEST="https://cophub.copernicus.eu/dhus"
#export DHUS_DEST="https://scihub.copernicus.eu/s2"
export DHUS_DEST="https://scihub.copernicus.eu/dhus"
export USERNAME=""
export PASSWORD=""
export TIME_SUBQUERY=""
export PRODUCT_TYPE=""
export INGEGESTION_TIME_FROM="1970-01-01T00:00:00.000Z"
export INGEGESTION_TIME_TO="NOW"
export SENSING_TIME_FROM="1970-01-01T00:00:00.000Z"
export SENSING_TIME_TO="NOW"
unset TIMEFILE


while getopts ":d:u:p:t:s:e:S:E:f:c:T:o:V:h:F:R:r:O:L:n" opt; do
 case $opt in
	d)
		export DHUS_DEST="$OPTARG"
		;;
	u)
		export USERNAME="$OPTARG"
		;;
	p)
		export PASSWORD="$OPTARG"
		;;
	t)
		export TIME="$OPTARG"
		export INGEGESTION_TIME_FROM="NOW-${TIME}HOURS"
		;;
        s)
                export TIME="$OPTARG"
		export INGEGESTION_TIME_FROM="$OPTARG"
                ;;
        e)
		export TIME="$OPTARG"
                export INGEGESTION_TIME_TO="$OPTARG"
                ;;	
        S)
		export SENSING_TIME="$OPTARG"
                export SENSING_TIME_FROM="$OPTARG"
                ;;
        E)
		export SENSING_TIME="$OPTARG"
                export SENSING_TIME_TO="$OPTARG"
                ;;
	f)
		export TIMEFILE="$OPTARG"
		if [ -s $TIMEFILE ]; then 		
			export INGEGESTION_TIME_FROM="`cat $TIMEFILE`"
		else
			export INGEGESTION_TIME_FROM="1970-01-01T00:00:00.000Z"
		fi
		;;
	c) 
		ROW=$OPTARG

		FIRST=`echo "$ROW" | awk -F\: '{print \$1}' `
		SECOND=`echo "$ROW" | awk -F\: '{print \$2}' `

		#--
		export x1=`echo ${FIRST}|awk -F, '{print $1}'`
		export y1=`echo ${FIRST}|awk -F, '{print $2}'`
		export x2=`echo ${SECOND}|awk -F, '{print $1}'`
		export y2=`echo ${SECOND}|awk -F, '{print $2}'`
		;;

	T)
		export PRODUCT_TYPE="$OPTARG"
		;;
	o)
		export TO_DOWNLOAD="$OPTARG"
		;;
	V)
		print_version $0
		;;	
	h)	
		print_usage $0
		;;
        F)
                FREE_SUBQUERY_CHECK="OK"
		FREE_SUBQUERY="$OPTARG"
		;;
	R)
                export FAILLED="$OPTARG"
		export check_save_failled='OK'
		;;
	r)
                export FAILLED_retry="$OPTARG"
		export check_retry='OK'
		;;
	O)
		export output_folder="$OPTARG"
		;;
	L)
		export lock_file="$OPTARG"
		;;
 	n)
                export THREAD_NUMBER="$OPTARG"
                ;;
	esac
done


if [ -z $lock_file ];then
        export lock_file="$WD/lock"
fi

mkdir $lock_file

if [ ! $? == 0 ]; then 
	echo -e "Error! An instance of \"dhusget\" retriever is running !\n Pid is: "`cat ${PIDFILE}` "if it isn't running delete the lockdir  ${lock_file}"
	
	exit 
else
	echo $$ > $PIDFILE
fi

trap "rm -fr ${lock_file}" EXIT

export TIME_SUBQUERY="ingestiondate:[$INGEGESTION_TIME_FROM TO $INGEGESTION_TIME_TO]  "

export SENSING_SUBQUERY="beginPosition:[$SENSING_TIME_FROM TO $SENSING_TIME_TO]  "

if [ -z $THREAD_NUMBER ];then
        export THREAD_NUMBER="2"
fi

if [ -z $output_folder ];then
        export output_folder="PRODUCT"
fi

export WC="wget --no-check-certificate"
export AUTH="--user=${USERNAME} --password=${PASSWORD}"

mkdir -p './output/'

if [ ! -z $check_retry ] && [ -s $FAILLED_retry ]; then
	 cp $FAILLED_retry .failed.control.retry.now.txt
   	 export INPUT_FILE=.failed.control.retry.now.txt


	mkdir -p $output_folder/


cat ${INPUT_FILE} | xargs -n 4 -P ${THREAD_NUMBER} sh -c ' while : ; do
        echo "Downloading product ${3} from link ${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/\$value"; 
        ${WC} ${AUTH} --output-file=./output/.log.${3}.log -O ./$output_folder/${3}".zip" "${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/\$value";
        test=$?;
        if [ $test -eq 0 ]; then
                echo "Product ${3} successfully downloaded at " `tail -2 ./output/.log.${3}.log | head -1 | awk -F"(" '\''{print $2}'\'' | awk -F")" '\''{print $1}'\''`;
                remoteMD5=$( ${WC} -qO- ${AUTH} "${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/Checksum/Value/$value" | awk -F">" '\''{print $3}'\'' | awk -F"<" '\''{print $1}'\'');
                localMD5=$( md5sum ./$output_folder/${3}".zip" | awk '\''{print $1}'\'');
                localMD5Uppercase=$(echo "$localMD5" | tr '\''[:lower:]'\'' '\''[:upper:]'\'');
                if [ "$remoteMD5" == "$localMD5Uppercase" ]; then
                        echo "Product ${3} successfully MD5 checked";
                else
                echo "Checksum for product ${3} failed, attempting to download";
                echo "${0} ${1} ${2} ${3}" >> .failed.control.now.txt;
		rm ./$output_folder/${3}".zip"
                fi; 
        else
                echo "${0} ${1} ${2} ${3}" >> .failed.control.now.txt;
		./$output_folder/${3}".zip"
        fi;
        break;
done '
rm .failed.control.retry.now.txt
fi
	
if [ -z $USERNAME ];then
        read -s -p "Enter password ..." VAL
        export PASSWORD=${VAL}
fi

if [ -z $PASSWORD ];then
	read -s -p "Enter password ..." VAL
	export PASSWORD=${VAL}
fi


#-----

if [ -z $TIME ] && [ -z $TIMEFILE ] && [ -z $ROW ] && [ -z $PRODUCT_TYPE ] && [ -z $FREE_SUBQUERY_CHECK ] && [ -z $SENSING_TIME ]; then
	export QUERY_STATEMENT="*"
fi

if [ ! -z $PRODUCT_TYPE ];then
	if [ ! -z $QUERY_STATEMENT_CHECK ]; then
		export QUERY_STATEMENT="$QUERY_STATEMENT AND "	
	fi
	export QUERY_STATEMENT="$QUERY_STATEMENT producttype:$PRODUCT_TYPE"
	QUERY_STATEMENT_CHECK='OK'	
fi 
if [ ! -z $TIME ];then
	if [ ! -z $QUERY_STATEMENT_CHECK ]; then
		export QUERY_STATEMENT="$QUERY_STATEMENT AND "	
	fi
	export QUERY_STATEMENT="$QUERY_STATEMENT ${TIME_SUBQUERY}"
	QUERY_STATEMENT_CHECK='OK'
fi

if [ ! -z $SENSING_TIME ];then
        if [ ! -z $QUERY_STATEMENT_CHECK ]; then
                export QUERY_STATEMENT="$QUERY_STATEMENT AND "
        fi
        export QUERY_STATEMENT="$QUERY_STATEMENT ${SENSING_SUBQUERY}"
	QUERY_STATEMENT_CHECK='OK'
fi

if [ ! -z $TIMEFILE ];then
        if [ ! -z $QUERY_STATEMENT_CHECK ]; then
                export QUERY_STATEMENT="$QUERY_STATEMENT AND "
        fi
        export QUERY_STATEMENT="$QUERY_STATEMENT ${TIME_SUBQUERY}"
 #       date +%Y-%m-%dT%T.%NZ > $TIMEFILE
	QUERY_STATEMENT_CHECK='OK'
fi

if [ ! -z $FREE_SUBQUERY_CHECK ];then
        if [ ! -z $QUERY_STATEMENT_CHECK ]; then
                export QUERY_STATEMENT="$QUERY_STATEMENT AND "
        fi
        export QUERY_STATEMENT="$QUERY_STATEMENT $FREE_SUBQUERY"
	QUERY_STATEMENT_CHECK='OK'
fi


#--- Prepare query statement
#export QUERY_STATEMENT="${DHUS_DEST}/search?q=${TIME_SUBQUERY} ${PRODUCT_TYPE}"
#export QUERY_STATEMENT="${DHUS_DEST}/search?q=ingestiondate:[NOW-${TIME}DAYS TO NOW] AND producttype:${PRODUCT_TYPE}"

#--- 
#export QUERY_STATEMENT=`echo "${QUERY_STATEMENT}"|sed 's/ /+/g'`

#---- Prepare query polygon statement
if [ ! -z $x1 ];then
	if [[ ! -z $QUERY_STATEMENT ]]; then
		export QUERY_STATEMENT="$QUERY_STATEMENT AND "	
	fi
	export GEO_SUBQUERY=`LC_NUMERIC=en_US.UTF-8; printf "( footprint:\"Intersects(POLYGON((%.13f %.13f,%.13f %.13f,%.13f %.13f,%.13f %.13f,%.13f %.13f )))\")" $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2 $x1 $y1 `
	export QUERY_STATEMENT=${QUERY_STATEMENT}" ${GEO_SUBQUERY}"
else
	export GEO_SUBQUERY=""
fi
#- ... append on query (without repl
export QUERY_STATEMENT="${DHUS_DEST}/search?q="${QUERY_STATEMENT}"*&rows=9999&start=0"
#export QUERY_STATEMENT=${QUERY_STATEMENT}"&rows=10000&start=0"
#--- Select output format
#export QUERY_STATEMENT+="&format=json"

#--- Execute query statement
/bin/rm -f query-result
${WC} ${AUTH} --output-file=./output/.log_query.log -O query-result "${QUERY_STATEMENT}"
LASTDATE=`date -u +%Y-%m-%dT%H:%M:%S.%NZ`
sleep 5

echo ""
cat $PWD/query-result | grep '<id>' | tail -n +2 | cut -f2 -d'>' | cut -f1 -d'<' | cat -n > .product_id_list
cat $PWD/query-result | grep '<title>' | tail -n +2 | cut -f2 -d'>' | cut -f1 -d'<' | cat -n > .product_title_list
if [ ! -z $TIMEFILE ];then
if [ `cat query-result | grep '="ingestiondate"' |  head -n 1 | cut -f2 -d'>' | cut -f1 -d'<' | wc -l` -ne 0 ];
#	then	cat $PWD/query-result | grep '="ingestiondate"' |  head -n 1 | cut -f2 -d'>' | cut -f1 -d'<' > $TIMEFILE
then
	lastdate=`cat $PWD/query-result | grep '="ingestiondate"' |  head -n 1 | cut -f2 -d'>' | cut -f1 -d'<'`;
	years=`echo $lastdate | tr "T" '\n'|head -n 1`;
	hours=`echo $lastdate | tr "T" '\n'|tail -n 1`;
	echo `date +%Y-%m-%d --date="$years"`"T"`date +%T.%NZ -u --date="$hours + 0.001 seconds"`> $TIMEFILE
fi 
fi
##cat $PWD/query-result | xmlstarlet sel -T -t -m '/_:feed/_:entry/_:title/text()' -v '.' -n | cat -n | tee  .product_title_list

cat .product_id_list .product_title_list| sort -nk 1 | sed 's/[",:]/ /g' > product_list

#cat .product_id_list .product_title_list .product_ingestion_time_list| sort -nk 1 | sed 's/[",:]/ /g' > product_list

rm -f .product_id_list .product_title_list .product_ingestion_time_list

echo ""
NROW=`cat product_list |wc -l`
NPRODUCT=`echo ${NROW}/2 | bc -q `


echo -e "done... product_list contain results \n ${NPRODUCT} products"

echo ""

if [ "${NPRODUCT}" == "0" ]; then exit 1; fi

cat product_list
export rv=0
if [ "${TO_DOWNLOAD}" == "manifest" -o "${TO_DOWNLOAD}" == "all" ]; then
	#if [ -z $9 ] ; then
	export INPUT_FILE=product_list
#	else
	#export INPUT_FILE=$9
#	fi

	if [ ! -f ${INPUT_FILE} ]; then
	 echo "Error: Input file ${INPUT_FILE} not present "
	 exit
	fi

	mkdir -p MANIFEST/


cat ${INPUT_FILE} | xargs -n 4 -P ${THREAD_NUMBER} sh -c 'while : ; do
	echo "Downloading manifest ${3} from link ${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/Nodes('\''"$3".SAFE'\'')/Nodes('\'manifest.safe\'')/\$value"; 
	${WC} ${AUTH} --output-file=./output/.log.${3}.log -O ./MANIFEST/manifest.safe-${3} "${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/Nodes('\''"$3".SAFE'\'')/Nodes('\'manifest.safe\'')/\$value" ;
	test=$?;
	if [ $test -eq 0 ]; then
		echo "Manifest ${3} successfully downloaded at " `tail -2 ./output/.log.${3}.log | head -1 | awk -F"(" '\''{print $2}'\'' | awk -F")" '\''{print $1}'\''`;
	fi;
	[[ $test -ne 0 ]] || break;
done ' 
fi

if [ "${TO_DOWNLOAD}" == "product" -o "${TO_DOWNLOAD}" == "all" ];then

    export INPUT_FILE=product_list


mkdir -p $output_folder/

#Xargs works here as a thread pool, it launches a download for each thread (P 2), each single thread checks 
#if the download is completed succesfully.
#The condition "[[ $? -ne 0 ]] || break" checks the first operand, if it is satisfied the break is skipped, instead if it fails 
#(download completed succesfully (?$=0 )) the break in the OR is executed exiting from the intitial "while".
#At this point the current thread is released and another one is launched.

cat ${INPUT_FILE} | xargs -n 4 -P ${THREAD_NUMBER} sh -c ' while : ; do
	echo "Downloading product ${3} from link ${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/\$value"; 
	${WC} ${AUTH} --output-file=./output/.log.${3}.log -O ./$output_folder/${3}".zip" "${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/\$value";
	test=$?;
	if [ $test -eq 0 ]; then
		echo "Product ${3} successfully downloaded at " `tail -2 ./output/.log.${3}.log | head -1 | awk -F"(" '\''{print $2}'\'' | awk -F")" '\''{print $1}'\''`;
		remoteMD5=$( ${WC} -qO- ${AUTH} "${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/Checksum/Value/$value" | awk -F">" '\''{print $3}'\'' | awk -F"<" '\''{print $1}'\'');
		localMD5=$( md5sum ./$output_folder/${3}".zip" | awk '\''{print $1}'\'');
		localMD5Uppercase=$(echo "$localMD5" | tr '\''[:lower:]'\'' '\''[:upper:]'\'');
		#localMD5Uppercase=1;
		if [ "$remoteMD5" == "$localMD5Uppercase" ]; then
			echo "Product ${3} successfully MD5 checked";
		else
		echo "Checksum for product ${3} failed, attempting to download";
		echo "${0} ${1} ${2} ${3}" >> .failed.control.now.txt;
		rm ./$output_folder/${3}".zip"
		fi; 
	else
                echo "${0} ${1} ${2} ${3}" >> .failed.control.now.txt;
		rm ./$output_folder/${3}".zip"
	fi;
        break;
done '
fi
echo "$check_save_failled"

if [ ! -z $check_save_failled ]; then
    mv .failed.control.now.txt $FAILLED
fi

echo 'the end'