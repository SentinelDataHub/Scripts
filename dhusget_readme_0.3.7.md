`dhusget.sh`  is a simple demo script illustrating how to use OData and OpenSearch APIs to query and download the products from any Data Hub Service. It allows:

1.  Search products over a pre-defined AOI
2.  Filter the products by ingestion time, sensing time
3.  Filter the products by mission (Sentinel-1, Sentinel-2, Sentinel-3), instrument and product type
4.  Save the list of results in CSV and XML files
5.  Download the products
6.  Download the manifest files only
7.  Perform the MD5 integrity check of the downloaded products

It requires the installation of  `wget`.

Usage:

###   
dhusget.sh [LOGIN OPTIONS]... [SEARCH QUERY OPTIONS]... [SEARCH RESULT OPTIONS]... [DOWNLOAD OPTIONS]...

LOGIN OPTIONS:

-   `-d <DHuS URL>`  : URL of the Data Hub Service to be polled
-   `-u <username>`  : data hub username
-   `-p <password>`  : data hub password provided after registration;

SEARCH QUERY OPTIONS:

-   `-m <mission name>`  : sentinel mission name
-   `-i <instrument name>`  : instrument name
-   `-t <time in hours>`  : search for products ingested in the last 
-   `<time in hours>`  (integer) from the time of execution of the script. (e.g. '=-t 24=' to search for products ingested in the last 24 Hours)
-   `-s <ingestion_date_FROM>`  : search for products ingested after the date and time specified by  <ingestion_date_FROM>.  The date format is  `ISO 8601:YYYY-MM-DDThh:mm:ss.cccZ`  (e.g.  `-s 2016-10-02T06:00:00.000Z`)
-   `-e <ingestion_date_TO>`  : search for products ingested before the date specified by  <ingestion_date_TO>. The date format is  `ISO 8601: YYYY-MM-DDThh:mm:ss.cccZ`  (e.g.  `-e 2016-10-10T12:00:00.000Z`)
-   `-S <sensing_date_FROM>`  : search for products with sensing date greater than the date and time specified by  `<sensing_date_FROM>`.  The date format is ISO 8601:  `YYYY-MM-DDThh:mm:ss.cccZ`  (e.g.  `-S 2016-10-02T06:00:00.000Z`)
-   `-E <sensing_date_TO>`  : search for products with sensing date less than the date and time specified by
-   `<sensing_date_TO>`. The date format is ISO 8601:  `YYYY-MM-DDThh:mm:ss.cccZ`  (e.g.  `-E 2016-10-10T12:00:00.000Z`)
-   `-f <file>`  : search for products ingested after the date and time provided through the input  <file>. The file is updated at the end of the script execution with the ingestion date of the last successful downloaded product.
-   `-c <coordinates i.e.: lon1,lat1:lon2,lat2>`  : coordinates of two opposite vertices of the rectangular area of interest
-   `-T <product type>`  : product type of the product to search (available values are: SLC, GRD, OCN, RAW, S2MSI1C)
-   `-F <free OpenSearch query>`  : free text OpenSearch query. The query must be written enclosed by single apexes  `'<query>'`  (e.g.  `-F 'platformname:Sentinel-1 AND producttype:SLC'`  ). Note: the free text OpenSearch query can be combined with the other possible specified search options.

SEARCH RESULT OPTIONS:

-   `-l <results>`  : maximum number of results per page [1,2,3,4,..]; default value = 25
    
-   `-P <page>`  : page number [1,2,3,4,..]; default value = 1
    
-   `-q <XMLfile>`  : write the OpenSearch query results in a specified XML file. Default file is './OSquery-result.xml'
    
-   `-C <CSVfile>`  : write the list of product results in a specified CSV file. Default file is './products-list.csv'

DOWNLOAD OPTIONS:

-   `-o <option>`  : what to download; possible options are:
    -   `'manifest'`  to download the manifest of all products returned from the search or
    -   `'product'`  to download all products returned from the search
    -   `'all'`  to download both
        

-   `-O <folder>`  : save the Product ZIP files in a specified folder
-   `-N <1...n>`  : set number of wget download retries. Default value is 5. Fatal errors like 'connection refused' or 'not found' (404) are not retried
-   `-R <file>`  : write in the specified file the list of products that have failed the MD5 integrity check. By default the list is written in  `./failed_MD5_check_list.txt.`  The format of the output file is compatible with option -r
-   `-D`  : if specified, remove the products that have failed the MD5 integrity check from disk. By deafult products are not removed
-   `-r <file>`  : download the products listed in an input file written according to the following format:
    -   one product per line
    -   <space><one character><space><UUID><space><one character><space><filename>

-   `-L <lock folder>`  : by default only one instance of dhusget can be executed at a time. This is ensured by the creation of a temporary lock folder  `$HOME/dhusget_tmp/lock`  which is removed a the end of each run. In order to run more than one dhusget instance at a time is sufficient to assign different lock folders using the -L option (e.g. '-L foldername') to each dhusget instance
-   `-n <1...n>`  : number of concurrent downloads (either products or manifest files). Default value is 2; this value doesn't override the quota limit set on the server side for the user.

**NOTE:**  dhusget functionality is guaranteed in Linux environment. Linux emulators can cause failures.