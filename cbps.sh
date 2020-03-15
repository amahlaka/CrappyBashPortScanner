#!/bin/bash
# Crappy Bash port scanner
# Written by: Arttu Mahlakaarto
# https://github.com/amahlaka/CrappyBashPortScanner

usage() {
    echo "Crappy Bash Port Scanner v0.1  - Written by: Arttu Mahlakaarto
    $0 -i [Target IP addresses/hostname] {-m <Scan mode> | -p [Ports to scan]} -o <Output file name (Without extension)> -q -s
    -i [IP address list]            Comma seperated list of IP addresses (or hostname)to scan.
    -m <quick|full>                 Scanning mode, quick scans only most popular ports, full scans all ports (1-65535).
    -p [Port numbers]               Comma seperated list of ports to scan, can also be used with with -m quick.
    -q                              Quiet mode, prints no output to terminal.
    -s                              Skip ping scan of hosts
    -o <Output filename>            Scan results will be saved to <Output filename>.json in the current directory ($(pwd)).
                                    If not set, the output will be printed to the console in json format


    Examples:
    Scan ports 22 and 80 of 1.2.3.4 and save output to outputFile.json
    $0 -i 1.2.3.4 -p 22,80 -o outputFile 

    Scan both 1.2.3.4 and 127.0.0.1 for most common ports and print output to console
    $0 -i 1.3.4.5,127.0.0.1 -m q 

    Scan all for all possible ports on stackexchange.com and save to file stackexchange.json
    $0 -i stackexchange.com -m f -o stackexchange
    "
    exit 0
}

startTime=$(date --utc +%FT%TZ)
declare -A results
printOutput=true
skip=false
# Handle commandline arguments
while getopts ":i:p:o:m:h:qs" opt; do
    case $opt in
    i)
        targets=(${OPTARG//,/ })
        ;;
    p)
        ports+=(${OPTARG//,/ })
        mode="manual"
        manualPorts=$OPTARG
        ;;
    q)
        printOutput=false
        ;;
    s)
        skip=true
        ;;
    o)
        outputFile="$OPTARG"
        ;;
    m)
        case $OPTARG in
        q | quick)
            ports+=(20 21 22 23 25 80 443 3389 8080)
            mode="quick"
            ;;
        f | full)
            ports=({1..65535})
            mode="full"
            ;;
        esac
        ;;
    h)
        usage
        ;;
    *)
        echo "Invalid parameter"
        usage
        ;;

    esac
done


if [ -z $targets ] || [ -z $ports ]; then
usage
fi

function PingHosts()
{
    targetList=()
    for host in "${targets[@]}"; do
        ping -c 1 ${host} &> /dev/null
        if [[ $? != 0 ]]; then
            ( $printOutput ) && echo "Can't reach host ${host}!";
            unreachable+=${host}
        else
        ( $printOutput ) &&  echo "Response from ${host}!";
        targetList+=(${host})
        fi
    done
}


function Scan()
{
    for targetIP in "${targetList[@]}"; do
        ( $printOutput ) && echo "${targetIP}: ";
        openPorts=()
        for port in ${ports[@]}; do
            timeout 1 bash -c "echo >/dev/tcp/${targetIP}/$port " &>/dev/null
                if [[ $? == 0 ]]; then
                    ( $printOutput ) && echo "${port} Open";
                    openPorts+=${port}
                fi
            done
            results["${targetIP}"]=${openPorts[@]}
    done
    echo "Scan Done"
}

function Main()
{
    ( $skip ) && targetList=${targets} || PingHosts
    ((  ${#targetList[@]} )) &&  Scan || echo "No Hosts available" && exit 1;
}
Main

# Warning, rest of this code is nasty looking, but it works.
function Log(){
if [[ "$mode" == "manual" ]]; then
    extraData+="\t\"manualPorts\": [$manualPorts],\n"
fi
localIPs=$(hostname -I)
filteredIP=${localIPs// /\", \"}
outp=${filteredIP::-3}
extraData+="\t\"hostData\": {\n\t\t\"FQDN\": \"$(hostname -f)\",\n\t\t\"IPs\": [\"$outp],\n\t\t\"user\": \"$(whoami)\",\n"
extraData+="\t\t\"lastStartup\": \"$(uptime -s)\"\n\t}"
outputData="{\n\t\"scanResult\":{\n"
First=true
outStr=""
for ip in ${!results[@]}; do
    if [[ $First != true ]]; then
        outStr+=",\n"
    fi
    First=false
    portStr="${results[${ip}]// /,}"
    outStr+="\t\t\"$ip\": [$portStr]"
done
outputData+=$outStr
outputData+="\n\t},\n\t\"timeStarted\": \"$startTime\",\n\t\"timeFinished\": \"$(date --utc +%FT%TZ)\",\n\t\"scanMode\": \"$mode\",\n$extraData\n}"
if [[ -z ${outputFile} ]]; then
    echo -e $outputData
else
    outputDir=$(pwd)
    echo -e $outputData >>$outputDir/$outputFile.json
fi
}
Log