NAME
 
  DHuSget 0.3.4 - The non interactive Sentinels product retriever from the Sentinels Data Hubs
 
USAGE
 
  dhusget.sh [LOGIN OPTIONS]... [SEARCH QUERY OPTIONS]... [SEARCH RESULT OPTIONS]... [DOWNLOAD OPTIONS]... 
 
DESCRIPTION
 
  This script allows to get products from Sentinels Data Hubs executing query with different filter. The products can be visualized on shell and saved in list file
  or downloaded in a zip file.
  Recommendation: If this script is run as a cronjob, to avoid traffic load, please do not schedule it exactly at on-the-clock hours (e.g 6:00, 5:00).
 
OPTIONS
 
  LOGIN OPTIONS:
 
   -d <DHuS URL>		      : Specify the URL of the Data Hub Service.
   -u <username>		      : Data hub username.
   -p <password>		      : Data hub password (note: if not provided by command line it is read by stdin).
 
 
  SEARCH QUERY OPTIONS:
 
   -m <mission name>		  : Sentinel mission name. Possible options are: Sentinel-1, Sentinel-2, Sentinel-3).

   -i <instrument name>		  : Instrument name. Possible options are: SAR, MSI, OLCI, SLSTR, SRAL).

   -t <time in hours>		  : Search for products ingested in the last <time in hours> (integer) from the time of
 				                execution of the script.
   				                (e.g. '-t 24' to search for products ingested in the last 24 Hours).

   -s <ingestion_date_FROM>	  : Search for products ingested after the date and time specified by <ingestion_date_FROM>.
   				                The date format is ISO 8601, YYYY-MM-DDThh:mm:ss.cccZ (e.g. -s 2016-10-02T06:00:00.000Z).

   -e <ingestion_date_TO>	  : Search for products ingested before the date specified by <ingestion_date_TO>.
   				                The date format is ISO 8601, YYYY-MM-DDThh:mm:ss.cccZ (e.g. -e 2016-10-10T12:00:00.000Z).

   -S <sensing_date_FROM>	  : Search for products with sensing date greater than the date and time specified by <sensing_date_FROM>.
   				                The date format is ISO 8601, YYYY-MM-DDThh:mm:ss.cccZ (e.g. -S 2016-10-02T06:00:00.000Z).

   -E <sensing_date_TO>		  : Search for products with sensing date less than the date and time specified by <sensing_date_TO>.
   				                The date format is ISO 8601, YYYY-MM-DDThh:mm:ss.cccZ (e.g. -E 2016-10-10T12:00:00.000Z).

   -f <ingestion_date_file>	  : Search for products ingested after the date and time provided through an input file. This option overrides option -s
							    The date format shall be ISO 8601 (YYYY-MM-DDThh:mm:ss.cccZ).
							    <ingestion_date_file> is automatically updated at the end of the script execution
							    with the ingestion date of the last sucessfully downloaded product.
 
   -c <lon1,lat1:lon2,lat2>   : Search for products intersecting a rectangular Area of Interst (or Bounding Box)
							    by providing the geographical coordinates of two opposite vertices. 
   				                Coordinates need to be provided in Decimal Degrees and with the following syntax:
 
   				                   - lon1,lat1:lon2,lat2
 
							    where lon1 and lat1 are respectively the longitude and latitude of the first vertex and
  				                lon2 and lat2 the longitude and latitude of the second vertex.
   				                (e.g. '-c -4.530,29.850:26.750,46.800' is a bounding box enclosing the Mediterranean Sea).
 
   -T <product type>		  : Search products according to the specified product type.
   				                Sentinel-1 possible options are:  SLC, GRD, OCN and RAW. 
   				                Sentinel-2 posiible option is: S2MSI1C.
 
   -F <free OpenSearch query> : Free text OpenSearch query. The query must be written enclosed by single apexes '<query>'. 
   				                (e.g. -F 'platformname:Sentinel-1 AND producttype:SLC'). 
   				                Note: the free text OpenSearch query is in AND with the other possible sspecified search options.
 
 
  SEARCH RESULT OPTIONS:
 
   -l <results>			      : Maximum number of results per page [1,2,3,4,..]; default value = 25.
 
   -P <page>			      : Page number [1,2,3,4,..]; default value = 1.
 
   -q <XMLfile>			      : Write the OpenSearch query results in a specified XML file. Default file is './OSquery-result.xml'.
 
   -C <CSVfile>			      : Write the list of product results in a specified CSV file. Default file is './products-list.csv'.
 
 
  DOWNLOAD OPTIONS:
 
   -o <download>		      : THIS OPTION IS MANDATORY FOR DOWNLOADING. Accepted values for <download> are:
   				  	               -  product : download the Product ZIP files (manifest file included)
   				  	               -  manifest : download only the manifest files
   				  	               -  all : download both the Product ZIP files and the manifest files, and provide them in separate folders.
                                By default the Product ZIP files are stored in ./product unless differently specified by option -O. 
								By default the manifest files are stored in ./manifest.
 
 
   -O <folder>			      : Save the Product ZIP files in a specified folder. 
 
   -N <1...n>			      : Set number of wget download retries. Default value is 5. Fatal errors like 'connection refused'
   				                or 'not found' (404), are not retried.
 
   -R <file>			      : Write in <file> the list of products that have failed the MD5 integrity check.
   				                By default the list is written in ./failed_MD5_check_list.txt.
   				                The format of the output file is compatible with option -r.
 
   -D  				          : If specified, remove the products that have failed the MD5 integrity check from disk.
   				                By deafult products are not removed.
 
   -r <file>			      : Download the products listed in an input <file> written according to the following format:
	   				               - One product per line.
	   				               - <space><one character><space><UUID><space><one character><space><filename>.
   			                    Examples:
   			                    ' x 67c7491a-d98a-4eeb-9ca0-8952514c7e1e x S1A_EW_GRDM_1SSH_20160411T113221_20160411T113257_010773_010179_7BE0'
   			                    ' 0 67c7491a-d98a-4eeb-9ca0-8952514c7e1e 0 S1A_EW_GRDM_1SSH_20160411T113221_20160411T113257_010773_010179_7BE0'
 
   -L <lock folder>		      : By default only one instance of dhusget can be executed at a time. This is ensured by the creation
   				                of a temporary lock folder /root/dhusget_tmp/lock which is removed a the end of each run.
   				                For running more than one dhusget instance at a time is sufficient to assign different lock folders
   				                using the -L option (e.g. '-L foldername') to each dhusget instance.
 
   -n <1...n>			      : Number of concurrent downloads (either products or manifest files). Default value is 2; this value
   				                doesn't override the quota limit set on the server side for the user.
 
 
 
   'wget' is necessary to run the dhusget
