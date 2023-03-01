
#/bin/bash!
UNATTENDED="";
DIR_1=$1;
DIR_2=$2;
DIR_3=$3;
DIR_4=$4;
UNATTENDED=$5;
DIR=pippo;
COUNTER=0;



function wait_inbox_empty {

DIR=${1};
COUNTER=0;
echo "Waiting for Inbox " $DIR " to be empty"
	while [ "$(ls "$DIR" |grep ".zip")" != "" ]; 
		do    echo `date -u +"%Y-%m-%d %H:%M:%S UTC"` "Not Processing; waiting for " $DIR " to be empty  [ `find $DIR/ -name *.zip |wc -l` ]" ;
		let COUNTER=COUNTER+1;
		if ! (( $COUNTER % 6 )) ; then
			
			echo "$DIR is still not empty after 20 minutes...aborting reboot";
			exit 1;		
		else
		sleep 2;
	done

}

function Start_DHuS {

echo "Starting DHuS instance" && systemctl --user start dhus.service;
#while [ "$(grep "Server is ready" /data/dhus-current/logs/dhus-s2rep-dhus-master??.log)" = "" ]; do    echo `date -u +"%Y-%m-%d %H:%M:%S UTC"` "Waiting for DHuS Ready" ; sleep 5; done

echo "Waiting for DHuS instance going up"
	( tail -f -n0 /data/dhus-current/logs/dhus-s2rep-dhus-master??.log & ) | grep -q "Server is ready";
echo "DHuS started at `date -u +"%Y-%m-%d %H:%M:%S UTC"`";

}


function Stop_DHuS {

STATUS_DHUS="";

echo "";
echo "Stopping DHuS instance with a 120s timeout";

timeout 120 systemctl --user stop dhus.service;
 
STATUS_DHUS=`ps -ef | grep java | grep -v grep`;

if [ -z "$STATUS_DHUS" ]; then
		echo "";
		echo "DHuS has been STOPPED";
		echo "";
	else
		echo "";
		echo "ERROR!!!! DHuS did not STOP correctly";
		echo "";
		exit 1;
				

fi


}



function mainmenu {
	
echo ""	
echo "Press y to start DHuS"
echo "Press q to exit script"
echo ""

read -n 1 -p "Input Selection:" menuinput

 if [ "$menuinput" = "y" ]; then

		Start_DHuS;
	
	elif [ "$menuinput" = "q" ]; then
	
		exit 0

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





if [ -z "$DIR_1" ] || [ -z "$DIR_2" ] || [ -z "$DIR_3" ] || [ -z "$DIR_4" ];
	    then
	        echo "ERROR: Usage: ./This_Script and four DHuS_Inbox_Dirs  Exiting...";
	    exit 1;
fi




echo "Commenting crontab file";
	crontab -l > ~/crontab.bak; crontab -l | sed "s/^\(.*ingestion_regulator.*\)$/#MAINTENANCE\1/g" | crontab -; 
#crontab -l > ~/crontab.bak; grep -v ingestion_regulator ~/crontab.bak | crontab -;

sleep 5;

wait_inbox_empty $DIR_1;
wait_inbox_empty $DIR_2;
wait_inbox_empty $DIR_3;
wait_inbox_empty $DIR_4;

sleep 5;

echo "Stopping DHuS instance `date -u +"%Y-%m-%d %H:%M:%S UTC"`";

Stop_DHuS;


if [ "$UNATTENDED" = "UNATTENDED" ]; then

		Start_DHuS;
	
	elif [ "$UNATTENDED" = "INTERACTIVE" ]; then
	
		mainmenu;
	
	else 
	
		echo ""
		echo "You did not specify if UNATTENDED or INTERACTIVE"
        echo ""
        echo "Assuming INTERACTIVE...."
		echo ""
        mainmenu
fi

echo "";
echo "Decommenting Crontab file";
	cat ~/crontab.bak | crontab -;
echo "Done!";

exit 0;
