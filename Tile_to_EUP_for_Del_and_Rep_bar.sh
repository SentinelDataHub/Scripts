#!/usr/bin/bash

#This Script takes as input a list of tiles and outputs 2 files: inputfile_4deletion.txt (containing the EUP and the corresponding UUID separate by a pipe) and inputfile_4reporting.csv (containing the tile filename, the EUP and the uuid) 
INPUT="";
FORCE="";
INPUT=$1;
FORCE=$2;
OK=1;
COUNTER=0;


function ProgressBar {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"

}



#Check if input file has been given


if [ -z "$INPUT" ];
	then
	echo "ERROR: Usage: ./This_Script Inputfilename containg the list of tiles separeted by /n Exiting...";
	exit 1;
fi

#Check if input file exists

if [ ! -f "$INPUT" ];
	then
	echo "ERROR: $INPUT does not exist! Exiting...";
	exit 1;
fi

OUTPUT1=${INPUT%.*}\_4deletion.txt;
OUTPUT2=${INPUT%.*}\_deletionreport.csv;
N_inputtiles=`grep -c '.' $INPUT`;


#Check if force is being used, if not cheks if output file already exists and raises error

if [ -z "$FORCE" ];
	then
	[ -f $OUTPUT1 ] && { echo "WARNING: $OUTPUT1 exist please remove or launch script with force after input file to append results. Exiting..."; exit 1; };
	[ -f $OUTPUT2 ] && { echo "WARNING: $OUTPUT2 exist please remove or launch script with force after input file to append results. Exiting..."; exit 1; };
fi

echo -e "Processing $N_inputtiles Tiles \n";

for TILE in `cat $INPUT`;
do
	RESPONSE=`curl -s "http://localhost:8983/solr/dhus/select?q=granuleidentifier:$TILE&wt=json" | jq -r '.response.docs | .[] | .identifier,.uuid'`;
	EUP=`echo $RESPONSE | cut -d' ' -f1`;
	UUID=`echo $RESPONSE | cut -d' ' -f2`;
	echo $EUP"|"$UUID >> $OUTPUT1;
	echo $TILE","$EUP","$UUID >> $OUTPUT2;		
	let COUNTER=COUNTER+1;
	ProgressBar ${COUNTER} ${N_inputtiles};

done

N_EUP=`grep -c '.' $OUTPUT1`;

echo -e "\n";
echo "Found $N_EUP End User Products, created $OUTPUT1 and $OUTPUT2 files";

exit 0;
