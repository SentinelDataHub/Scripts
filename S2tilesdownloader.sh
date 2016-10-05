#!/bin/bash
# This script allows to download Sentinel-2 granules (last 10 products, configurable) for a given input tile
# Serco S.p.A.
#--------------------------------------------------------------
# Before launching the script, please fill the following fields 
# 	DHUS_SERVER_URL= DHuS instance address
# 	DHUS_USER= DHuS username
# 	DHUS_PASSWD= DHuS user password
# How to launch it:
# - download the kml file S2A_OPER_GIP_TILPAR_MPC__20151209T095117_V20150622T000000_21000101T000000_B00.kml from https://sentinel.esa.int/web/sentinel/missions/sentinel-2/data-products
# - upload the kml file in the same folder where this script is located 
# - launch this script using the following command:
# 		/bin/bash ./S2tilesdownloader.sh <tileID>		
#
#----------------------------------------------------------------


DHUS_SERVER_URL="https://scihub.copernicus.eu/apihub"
DHUS_USER=""
DHUS_PASSWD=""


# Set variables depending to optional command line arguments
ROOT_URL_ODATA="$DHUS_SERVER_URL/odata/v1"
ROOT_URL_SEARCH="$DHUS_SERVER_URL/search"

# Create folders for XML and logs
mkdir -p ./XML
mkdir -p ./output


# Retrieve polygon starting from the tile ID
tileID=$1
polygon=$(grep "description.*${tileID}" ./S2A_OPER_GIP_TILPAR_MPC__20151209T095117_V20150622T000000_21000101T000000_B00.kml | sed 's/MULTIPOLYGON/app/'| sed 's/^.*MULTIPOLYGON(((\(.*\)))).*$/\1/' | sed 's/ /%20/g')

echo "The selected tile corresponds to the polygon: ($polygon)"

query_server="${ROOT_URL_SEARCH}?q=filename:%20S2A*%20AND%20footprint:%22Intersects(POLYGON(($polygon)))%22"
#echo $query_server
curl --silent -u ${DHUS_USER}:${DHUS_PASSWD} "$query_server">query-result

# Product IDs and Names extraction
cat $PWD/query-result | grep '<id>' | tail -n +2 | cut -f2 -d'>' | cut -f1 -d'<' | cat -n > .product_id_list
cat $PWD/query-result | grep '<title>' | tail -n +2 | cut -f2 -d'>' | cut -f1 -d'<' | cat -n > .product_title_list
cat .product_id_list .product_title_list | sort -nk 1 | sed 's/[",:]/ /g' > product_list

rm -f .product_id_list .product_title_list
cat product_list |  while read line ; do 
	UUID=`echo $line | awk '{print $2}'`
	read line 
	PRODUCT_NAME=`echo $line | awk '{print $2}'`
	xmlpartname=$(echo ${PRODUCT_NAME} | cut -c20-78)
	xmlname="S2A_OPER_MTD_SAFL1C${xmlpartname}"
	wget --user=${DHUS_USER} --password=${DHUS_PASSWD} --no-check-certificate --output-file=./output/.log.${PRODUCT_NAME}.log "${ROOT_URL_ODATA}/Products('${UUID}')/Nodes(%27${PRODUCT_NAME}.SAFE%27)/Nodes(%27${xmlname}.xml%27)/\$value" -O ->./XML/${xmlname}.xml
	sleep 5

	echo 'cat //IMAGE_ID/text()' | xmllint --shell "./XML/${xmlname}.xml" | grep "$tileID">/dev/null 
	if [ $? -eq 0 ]; then 
		tileprefix=$(echo 'cat //IMAGE_ID/text()' | xmllint --shell "./XML/${xmlname}.xml" | grep "$tileID" | grep B01 | cut -c1-56)
		mkdir -p "${PRODUCT_NAME}-tiles"

# Downloading the product tiles
	echo "------------ Downloading tile from ${PRODUCT_NAME} --------------"
	for i in {01..11}; do 
		wget --user=${DHUS_USER} --password=${DHUS_PASSWD} --no-check-certificate --output-file=./output/log.${tileprefix}N02.01.log  "${ROOT_URL_ODATA}/Products('${UUID}')/Nodes(%27${PRODUCT_NAME}.SAFE%27)/Nodes('GRANULE')/Nodes('${tileprefix}N02.01')/Nodes('IMG_DATA')/Nodes('${tileprefix}B${i}.jp2')/\$value" -O ->./${PRODUCT_NAME}-tiles/${tileprefix}B${i}.jp2
	done
		wget --user=${DHUS_USER} --password=${DHUS_PASSWD} --no-check-certificate --output-file=./output/log.${tileprefix}N02.01.log  "${ROOT_URL_ODATA}/Products('${UUID}')/Nodes(%27${PRODUCT_NAME}.SAFE%27)/Nodes('GRANULE')/Nodes('${tileprefix}N02.01')/Nodes('IMG_DATA')/Nodes('${tileprefix}B8A.jp2')/\$value" -O ->./${PRODUCT_NAME}-tiles/${tileprefix}B8A.jp2
	
	else echo "In the product ${PRODUCT_NAME} there is not the requested tile"
	fi
	
done
rm ./query-result