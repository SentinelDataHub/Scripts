#!/usr/bin/bash

#Export the variables needed to login

export DHOST=localhost:8081;
export DLOGIN=root;
export DPASS=.\$up3rN0v4;
COUNTER=0;
SKIP=FALSE;
FORCE=FALSE;
FORCE_2=FALSE;
COUNTER_2=0;
SKIP_2=FALSE;
MASTERSKIP=FALSE;
PROCEEDTOSTOP=YES;

#Checks if the variables are set

if [ -z "${DHOST+x}" -o -z "${DLOGIN+x}" -o -z "${DPASS+x}" ]; then
  echo 'Error: environment variables are not set'
  exit 1
fi

#Define the file containing the list of synchronizer IDs of the Master, one for each line of the file.

Synch_List=/home/luca/WORK/SyncList.txt;


#Cheks if the DHuS is running

DHuS_Port_Test=`netstat -an | grep 8081 | grep LISTEN | awk '{print $6}'`;

if [ -z "$DHuS_Port_Test" ]; then 
	
	echo "ERROR!! Are you sure DHuS is running? Aborting...";
	exit 1;
fi


#Definition of the function that allows to interact with the synchronizer (start or stop it)

function Alter_Synchronizer {

ID=${1};

REQUEST=${2};

STATUS=`. /data/tools/dhus_restarter/getSynchronizer $ID | grep "<d:Status>" | grep -oP '(?<=>).*(?=<)'`;

echo "";
echo "Status of Synchronizer " $ID "is " $STATUS ;
echo "";

if [ "$REQUEST" = "STOP" ];

then

	SKIP=FALSE;
	SKIP_2=FALSE;
	FORCE=FALSE;
	FORCE_2=FALSE;
	COUNTER=0;
	echo "";
	echo "Waiting for Synchronizer " $ID " to be PENDING";

			while [[ "$STATUS" != "PENDING" && "$STATUS" != "STOPPED" && "$SKIP" != "YES" && "$FORCE" != "YES" ]];
					do  echo `date -u +"%Y-%m-%d %H:%M:%S UTC"` "Not Processing; waiting for PENDING or STOPPED" ;
						let COUNTER=COUNTER+1;
						if ! (( $COUNTER % 12 )) ; then
							
							skipmenu;
						
							else
								sleep 5;
								STATUS=`. /data/tools/dhus_restarter/getSynchronizer $ID | grep "<d:Status>" | grep -oP '(?<=>).*(?=<)'`;
						
						fi
					done
		
	if [ "$STATUS" = "PENDING" ] || [ "$FORCE" = "YES" ]; then
	
		echo "Synchronizer " $ID " is in state " $STATUS ", stopping it...";
	
		. /data/tools/dhus_restarter/stopSync $ID;
	
		STATUS=`. /data/tools/dhus_restarter/getSynchronizer $ID | grep "<d:Status>" | grep -oP '(?<=>).*(?=<)'`;
	
		echo "Waiting for Synchronizer " $ID " to be STOPPED"
				while [[ "$STATUS" != "STOPPED" && "$SKIP_2" != "YES" ]];
					do  echo `date -u +"%Y-%m-%d %H:%M:%S UTC"` "Not Processing; waiting for STOPPED" ;
						let COUNTER_2=COUNTER_2+1;
						if ! (( $COUNTER_2 % 12 )) ; then
						
							skipmenu2;

							else
						
								sleep 5;
								STATUS=`. /data/tools/dhus_restarter/getSynchronizer $ID | grep "<d:Status>" | grep -oP '(?<=>).*(?=<)'`;
						fi
					done
	
		echo "Synchronizer " $ID " is in state " $STATUS;
	fi
fi

if [ "$REQUEST" = "START" ];

then

	echo "";
	echo "Starting Synchronizer " $ID;

	. /data/tools/dhus_restarter/startSync $ID;

	STATUS=`. /data/tools/dhus_restarter/getSynchronizer $ID | grep "<d:Status>" | grep -oP '(?<=>).*(?=<)'`;

	echo "Waiting for Synchronizer " $ID " to START"
	
        while [[ "$STATUS" != "PENDING" && "$STATUS" != "RUNNING" ]];
                do  echo `date -u +"%Y-%m-%d %H:%M:%S UTC"` "Waiting for START" ;
					STATUS=`. /data/tools/dhus_restarter/getSynchronizer $ID | grep "<d:Status>" | grep -oP '(?<=>).*(?=<)'`;
					sleep 2;
				done

	echo "Synchronizer " $ID " is " $STATUS;

fi



}

#Definition of the function that allows to stop the DHuS

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
		KillMenu;
		

fi


}

#Definition of the function that allows to interact start the DHuS

function Start_DHuS {

echo "";

echo "";

echo "Starting DHuS instance" && systemctl --user start dhus.service;

echo "Waiting for DHuS instance to startup"
        ( tail -f -n0 /data/dhus-current/logs/dhus-master0?.log & ) | grep -q "Server is ready";
echo "DHuS started at `date -u +"%Y-%m-%d %H:%M:%S UTC"`";


}

#Definition of the function that creates the menu from wich you can start the DHuS once the synchronizers have been stopped

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


#Definition of the function that creates the menu from wich you can skip or force stop a synchronizer in case it doesn't enter the state PENDING

function skipmenu {
echo ""	
echo "Synchronizer seems to be stuck would you like to skip or try to stop it anyway?"
echo "Press s to skip this synchronizer"
echo "Press f to try and stop it"
echo "Press w to wait another minute"
echo ""

read -n 1 -p "Input Selection:" skipinput

if [ "$skipinput" = "s" ]; then

		echo "";
		echo "Skipping synchronizer " $ID;
		SKIP=YES;
		MASTERSKIP=YES;
	
	elif [ "$skipinput" = "w" ]; then
		
		echo "";
		echo "Ok waiting another minute..."
		
	elif [ "$skipinput" = "f" ]; then
		
		echo "";
		echo "Tryng to stop it..."
		FORCE=YES;

	else
		echo ""
		echo "You have entered an invalid selection!"
		echo "Please try again!"
		echo ""
		echo "Press any key to continue..."
		read -n 1
		skipmenu
	fi
	
}


#Definition of the function that creates the menu in case the synchronizer doesn't want to stop and from wich you can try to stop it again or skip it

function skipmenu2 {
echo ""	
echo "Synchronizer doesn't want to stop, would you like to skip it, try and stop it again or wait?"
echo "Press s to skip this synchronizer"
echo "Press f to try and stop it again"
echo "Press w to wait another minute"
echo ""

read -n 1 -p "Input Selection:" skipinput

if [ "$skipinput" = "s" ]; then

		echo "";
		echo "Skipping synchronizer " $ID;
		SKIP_2=YES;
		MASTERSKIP=YES;
		PROCEEDTOSTOP=FALSE;
	
	elif [ "$skipinput" = "w" ]; then
		
		echo "";
		echo "Ok waiting another minute..."

	elif [ "$skipinput" = "f" ]; then
	
		echo "";
		echo "Sending stop request again for synchronizer " $ID;
		. /data/tools/dhus_restarter/stopSync $ID;

	else
		echo ""
		echo "You have entered an invalid selection!"
		echo "Please try again!"
		echo ""
		echo "Press any key to continue..."
		read -n 1
		skipmenu2
	fi						

}


#Definition of the function that creates the menu in case you skipped one or more synchronizers from wich you can decide to stop the DHuS anyway or not

function StopMenu {
echo ""	
echo "WARNING! You have skipped one or more synchronizers"
echo ""
echo "Do you want to stop DHuS anyway?"
echo "Press y to stop DHuS"
echo "Press n to exit script without stopping DHuS"
echo ""

read -n 1 -p "Input Selection:" stopinput

if [ "$stopinput" = "y" ]; then

		PROCEEDTOSTOP=YES;
	
	elif [ "$stopinput" = "n" ]; then
		
		exit 0

	else
		echo ""
		echo "You have entered an invalid selection!"
		echo "Please try again!"
		echo ""
		echo "Press any key to continue..."
		read -n 1
		stopmenu
	fi						

}

#Definition of the function that creates the menu in case the DHuS does not want to stop and from wich you can kill it

function KillMenu {
echo ""	
echo "Do you want to kill -9 the DHuS process, exit or try gentle stop again"
echo ""
echo "Do you want to stop DHuS anyway?"
echo "Press k to kill -9 DHuS"
echo "Press s to try and stop it again gently"
echo "Press n to exit script without stopping DHuS"
echo ""

read -n 1 -p "Input Selection:" killinput

if [ "$killinput" = "k" ]; then

		echo "";
		echo "Killing DHuS..."
		pid=`ps -ef | grep java | grep -v grep | awk '{print $2}'`;
		kill -9 $pid;
		sleep 5;
		STATUS_DHUS=`ps -ef | grep java | grep -v grep`;

		if [ -z "$STATUS_DHUS" ]; then
				echo "";
				echo "DHuS has been KILLED";
				echo "";
			else
				echo "";
				echo "ERROR!!!! DHuS is UNKILLABLE consider calling an exorcist";
				echo "";
				KillMenu
		fi
	
	elif [ "$killinput" = "n" ]; then
		
		exit 0
	
	elif [ "$killinput" = "s" ]; then
		
		Stop_DHuS;


	else
		echo ""
		echo "You have entered an invalid selection!"
		echo "Please try again!"
		echo ""
		echo "Press any key to continue..."
		read -n 1
		KillMenu
	fi				

}

#EXECUTE FUNCTIONS

for SYNCHRONIZER in `cat $Synch_List`;

	do
	
		Alter_Synchronizer ${SYNCHRONIZER} STOP;
		sleep 2;
		
	done
	
if	[ "$MASTERSKIP" = "YES" ]; then

	StopMenu;
	
fi
	
if	[ "$PROCEEDTOSTOP" = "YES" ]; then

	Stop_DHuS;
	mainmenu;

fi




for SYNCHRONIZER in `cat $Synch_List`;

	do
	
		Alter_Synchronizer ${SYNCHRONIZER} START;
		sleep 2;
		
	done
	

exit 0