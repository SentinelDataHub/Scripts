
# DHuS Ingest Scripts

Upload/Ingest scripts for DHuS

## HowTo use

### Set the environment variables that configure the DHuS:

+ **DHOST** DHuS Host address eg: localhost:8080, scihub.copernicus.eu/dhus/
+ **DLOGIN** DHuS login username to connect to the $DHOST DHuS
+ **DPASS** DHuS login password to connect to the $DHOST DHuS

### Use a command:

Parameters between angle brackets (chevrons) are mandatory.

Parameters between brackets ([]) are optional.

Upload / ingest a new product:  
```./ingest <path/to/data.zip>```

List ingests / print an ingest:  
```./getIngest [ingest id]```

Delete an ingest:  
```./deleteIngest <ingest id>```

## Author
 [jobayle](https://github.com/jobayle)
