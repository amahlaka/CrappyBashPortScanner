# CrappyBashPortScanner
A simple port scanner in bash, for when you dont have nmap available.


## Usage

```
cbps.sh -i [Target IP addresses/hostnames] {-m <Scan mode> | -p [Ports to scan]} -o <Output file name (Without extension)>
-i [IP address list]            Comma seperated list of IP addresses (or hostnames) to scan.
-m <quick|full>                 Scanning mode, quick scans only most popular ports, full scans all ports (1-65535).
-p [Port numbers]               Comma seperated list of ports to scan, can also be used with with -m quick.
-o <Output filename>            Scan results will be saved to <Output filename>.json in the current directory.
                                If not set, the output will be printed to the console in json format


Examples:
    Scan ports 22 and 80 of 1.2.3.4 and save output to outputFile.json
    cbps.sh -i 1.2.3.4 -p 22,80 -o outputFile 

    Scan both 1.2.3.4 and 127.0.0.1 for most common ports and print output to console
    cbps.sh -i 1.3.4.5,127.0.0.1 -m q 

    Scan all for all possible ports on stackexchange.com and save to file stackexchange.json
    cbps.sh -i stackexchange.com -m f -o stackexchange
    
```
