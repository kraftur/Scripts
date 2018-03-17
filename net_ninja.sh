#!/bin/bash
# Net_Ninja
# Kraftur
# www.kraftur@mail.com
# Created 03/15/2018
# Tested on Kali 4.12.0-kali2_686


VERSION="1.0"

# TODO: Make output easier to read

# TODO: Make all scans automated by configuring the scans at the start

# TODO: Version and Scripts Scan from Full TCP results.

# TODO: Option for Full UDP Scan

# TODO: Print Scan Results

# NOTES
#===============================================================================================================


#===============================================================================================================

# Script Starts

clear
echo -e "\e[00;32m=================================================================\e[00m"
echo ""
echo " ***  Net_Ninja - Internal network Nmap Script Version $VERSION    ***"
echo ""
echo -e "\e[00;32m=================================================================\e[00m"
echo ""
echo ""
echo -e "\e[01;32m[-]\e[00m All output, (hosts up, down, open ports, and an audit of each scans start stop times) can be found in the output directory."
echo ""
echo -e "\e[01;32m[-]\e[00m Press Enter to continue"
echo ""
read ENTERKEY
clear


# Check if root
if [[ $EUID -ne 0 ]]; then
    echo ""
    echo -e "\e[01;31m[!]\e[00m This program must be run as root. Run again with 'sudo'"
    echo ""
    exit 1
fi

echo ""
echo -e "\e[01;32m[-]\e[00m The following Interfaces are available"
echo ""
    ip link show | grep 'UP\|DOWN' | cut -d ":" -f 2 | grep -v -i lo | sed -e 's/^[ \t]*//'
echo ""
echo -e "\e[01;31m========================================================\e[00m"
echo -e "\e[01;31m[?]\e[00m Enter the interface to scan from as the source"
echo -e "\e[01;31m========================================================\e[00m"
read INT

ifconfig | grep -i -w $INT > /dev/null

if [ $? = 1 ]
then
    echo ""
    echo -e "\e[1;31m The interface you entered does not exist or is not up! - check and try again."
    echo ""
    exit 1
else
    echo ""
fi
LOCAL=$(ifconfig $INT | grep "inet " | cut -d "" -f 3 | awk '{print $2}')
MASK=$(ifconfig | grep $LOCAL | awk '{print $4}')
CIDR=$(ip addr show $INT | grep inet | grep -v inet6 | cut -d"/" -f 2 | awk '{print $1}')
clear
echo ""
echo ""
echo -e "\e[01;32m[-]\e[00m Your source IP address is set as follows \e[1;32m"$LOCAL"\e[00m with the mask of \e[1;32m"$MASK"(/"$CIDR")\e[00m"
echo ""
echo -e "\e[01;31m====================================================================================================\e[00m"
echo -e "\e[01;31m[?]\e[00m Do you want to change your source IP address or gateway? - Enter yes or no and press ENTER"
echo -e "\e[01;31m====================================================================================================\e[00m"
read IPANSWER
if [ $IPANSWER = yes ]
then
    echo ""
    echo -e "\e[01;31m==================================================================================================================\e[00m"
    echo -e "\e[01;31m[?]\e[00m Enter the IP address/subnet for the source interface you want to set. EX: 192.168.1.1/24 and press ENTER"
    echo -e "\e[01;31m==================================================================================================================\e[00m"
    read SETIPINT
    ifconfig $INT $SETIPINT up
    SETLOCAL=`ifconfig $INT | grep "inet " | cut -d"" -f 3 | awk '{print $2}'`
    SETMASK=`ifconfig | grep $SETLOCAL | awk '{print $4}'`
    SETCIDER=`ip addr show $INT | grep inet | grep -v inet6 | cut -d "/" -f 2 | awk '{print $1}'`
    echo ""
    echo -e " Your source IP address is set as follows \e[1;33m"$SETLOCAL"\e[00m with the mask of \e[1;33m"$SETMASK"(/"$SETCIDR")\e[00m"
    echo ""
    echo -e "\e[01;31m=======================================================================================\e[00m"
    echo -e "\e[01;31m[?]\e[00m Do you want to change your default gateway? - Enter yes or no and press ENTER"
    echo -e "\e[01;31m=======================================================================================\e[00m"
    read GATEWAYANSWER
    if [ $GATEWAYANSWER = yes ]
    then
        echo ""
        echo -e "\e[1;31m----------------------------------------------------------\e[00m"
		echo -e "\e[01;31m[?]\e[00m Enter the default gateway you want set and press ENTER"
		echo -e "\e[1;31m----------------------------------------------------------\e[00m"
        read SETGATEWAY
        route add default gw $SETGATEWAY
        echo ""
        clear
        echo ""
        ROUTEGW=`route | grep -i default`
        echo -e "\e[01;32m[+]\e[00m The default gateway has been changed to "$ROUTEGW
        echo ""
    fi
else
    echo ""
fi
echo ""
echo -e "\e[01;31m==============================================================\e[00m"
echo -e "\e[01;31m[?]\e[00m Enter the client name or reference name for the scan"
echo -e "\e[01;31m==============================================================\e[00m"
read REF
echo ""
echo -e "\e[01;31m=======================================================================\e[00m"
echo -e "\e[01;31m[?]\e[00m Enter the IP address/Range or the exact path to an input file"
echo -e "\e[01;31m=======================================================================\e[00m"
read -e RANGE
mkdir "$REF" >/dev/null 2>&1
cd "$REF"
echo "$REF" > REF
echo "$INT" > INT
echo ""
echo -e "\e[01;31m======================================================\e[00m"
echo -e "\e[01;31m[?]\e00m Do you want to exclude any IPs from the scan?"
echo -e "\e[01;31m======================================================\e[00m"
echo ""
echo -e "\e[01;32m[-]\e[00m NOTE - Your source IP address of "$LOCAL" will be excluded from the scan"
echo ""
-e "\e[01;31m=============================================\e[00m"
echo -e "\e[01;31m[?]\e00m Enter yes or no and press ENTER"
-e "\e[01;31m=============================================\e[00m"
echo ""
read EXCLUDEANS

if [ $EXCLUDEANS = yes ]
then
    echo ""
    echo -e "\e[01;31m==============================================================================================================\e[00m"
    echo -e "\e[01;31m[?]\e[00m Enter the IP addresses to exclude Ex: 192.168.0.1, 192.168.0.1-10 - or the exact path to an input file"
    echo -e "\e[01;31m==============================================================================================================\e[00m"
    echo ""
    read -e EXCLUDEDIPS
    echo $EXCLUDEDIPS | egrep '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.' >/dev/null 2>&1

    if [ $? = 0 ]
    then
        echo ""
        echo $EXCLUDEDIPS | tee excludeiplist
        echo "$LOCAL" >> excludeiplist
        echo ""
    else
        echo ""
        echo -e "\e[01;32m[-]\e[00m You entered a file as the input, I will check if I can read it"
        echo ""
        cat $EXCLUDEDIPS >/dev/null 2>&1
        if [ $? = 1 ]
        then 
            echo ""
            echo -e "\e[01;31m[!]\e[00m I can not read that file. Check the path and try again."
            exit 1
        else
            echo ""
            echo -e "\e[01;32m[+]\e[00m I can read the file and will exclude the additional IP addresses"
            echo ""
            cat $EXCLUDEDIPS | tee excludeiplist
            echo ""
            echo "$LOCAL" >> excludeiplist
        fi
    fi
    EXIP=$(cat excludeiplist)
    EXCLUDE="--excludefile excludeiplist"
    echo "$EXCLUDE" > excludetmp
    echo "$LOCAL" >> excludetmp
    echo -e "\e[01;33m[-]\e[00m The following IP addresses will be excluded from the scan --> "$EXIP"" > "$REF"_nmap_hosts_excluded.txt
    else
        EXCLUDE="--exclude "$LOCAL""
        echo "$LOCAL" > excludeiplist
fi

echo $RANGE | egrep '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}.' >/dev/null 2>&1
if [ $? = 0 ]
then
    echo ""
    echo -e "\e[01;32m[-]\e[00m You entered a manual IP or Range. The scan will start now."
    echo ""
    echo -e "\e[01;32m[-]\e[00m $REF - Scanning for Live hosts via $INT. Please wait..."
    echo ""
    nmap -e $INT -sn $EXCLUDE -n --stats-every 4 -PE -PM -PS21,22,23,25,26,53,80,81,110,111,113,135,139,143,179,199,443,445,465,514,548,554,587,993,995,1025,1026,1433,1720,1723,2000,2001,3306,3389,5060,5900,6001,8000,8080,8443,8888,10000,32768,49152 -PA21,80,443,13306 -vvv -oA "$REF"_nmap_PingScan $RANGE >/dev/null &
    sleep 6

    cat "$REF"_nmap_PingScan.gnmap 2>/dev/null | grep "Up" | awk '{print $2}' > "$REF"_hosts_Up.txt
    cat $REF_nmap_PingScan.gmap 2>/dev/null | grep "Down" | awk '{print $2}' > "$REF"_hosts_Down.txt

    echo ""
    echo -e "\e[1;32m[+]\e[00m Scan is 100% complete"
    echo ""
else
    echo ""
    echo -e "\e[01;32m[-]\e[00m You entered a file as the input. I will check if I can read it."
    cat $RANGE >/dev/null 2>&1
        if [ $? = 1 ]
        then
            echo ""
            echo -e "\e[01;31m[!]\e[00m I cannot read that file. Check the path and try again."
            echo ""
            exit 1
        else
            echo ""
            echo -e "\e[01;32m[+]\e[00m I can read the file. Scan will start now."
            echo ""
            echo -e "\e[01;32m[-]\e[00m Scanning for Live hosts vis $INT. Please wait..."
            echo ""
            nmap -e $INT -sn $EXCLUDE -n --stats-every 4 -PE -PM -PS21,22,23,25,26,53,80,81,110,111,113,135,139,143,179,199,443,445,465,514,548,554,587,993,995,1025,1026,1433,1720,1723,2000,2001,3306,3389,5060,5900,6001,8000,8080,8443,8888,10000,32768,49152 -PA21,80,443,13306 -vvv -oA "$REF"_nmap_PingScan -iL $RANGE >/dev/null &
            sleep 6

            cat "$REF"_nmap_PingScan.gnmap 2>/dev/null | grep "Up" |awk '{print $2}' > "$REF"_hosts_Up.txt
            cat "$REF"_nmap_PingScan.gnmap 2>/dev/null | grep  "Down" |awk '{print $2}' > "$REF"_hosts_Down.txt  

            echo ""
            echo -e "\e[01;32m[+]\e[00m The scan is 100% complete"
            echo ""
        fi
fi
echo ""
HOSTSCOUNT=$(cat "$REF"_hosts_Up.txt | wc -l)
HOSTSUPCHK=$(cat "$REF"_hosts_Up.txt)
if [ -z "$HOSTSUPCHK" ]
then
    echo ""
    echo -e "\e[01;31m[!]\e[00m There are no live hosts present in the range specified. I will run an arp-scan to double check"
    echo ""
    sleep 4
    arp-scan --interface $INT --file "$REF"_hosts_Down.txt > "$REF"_arp_scan.txt 2>&1
    arp-scan --interface $INT --file "$REF"_hosts_Down.txt | grep -i "0 responded" >/dev/null 2>&1
        if [ $? = 0 ]
        then
            echo -e "\e[01;32m[!]\e[00m No live hosts were found using arp-scan. Check IP address/range and try again."
            echo ""
            rm "INT" 2>/dev/null
            rm "REF" 2>/dev/null
            rm "excludetmp" 2>/dev/null
            touch "$REF"_no_live_hosts.txt
            exit 1
        else
            arp-scan --interface $INT --file "$REF"_hosts_Down.txt > "$REF"_arp_scan.txt 2>&1
            ARPUP=$(cat "$REF"_arp_scan.txt)
            echo ""
            echo -e "\e[01;33m[-]\e[00m Nmap did not find any live hosts, but arp-scan found the following hosts within the range. Try adding these to the host list to scan. This script will exit."
            echo ""
            rm "INT" 2>/dev/null
            rm "REF" 2>/dev/null
            rm "excludetmp" 2>/dev/null
            echo "$ARPUP"
            echo ""
            exit 1
        fi
fi
echo -e "\e[01;32m=============================================================\e[00m"
echo -e "\e[01;32m[+]\e[00m A total of $HOSTSCOUNT hosts were found up for $REF"
echo -e "\e[01;32m=============================================================\e[00m"
HOSTSUP=$(cat "$REF"_hosts_Up.txt)
echo -e "\e[01;32m$HOSTSUP\e[00m"
echo ""
echo -e "\e[01;32m[-]\e[00m Press Enter to perform a full scan of the hosts, or CTRL C to cancel"
read ENTER

'''Port Scans - 
Full TCP, 
Fast UDP, 
Version and Scripts Scan on Full TCP results,
Full UDP - Option
'''

# TCP and UDP Scans

if [ $FULLTCP = "on" ]
then
# Full TCP Port Scan
gnome-terminal --title="$REF - Full TCP Port Scan - $INT" -x bash -c 'REF=$(cat REF);INT=$(cat INT);EXCLUDE=$(cat excludeiplist); echo "" ; echo "" ; echo -e "\e[01;32m[-]\e[00m Starting Full TCP Scan " ; echo "" ; nmap -e $INT -sS $EXCLUDE -Pn -T4 -p- -n -vvv -oA "$REF"_nmap_FullPorts -iL "$REF"_hosts_Up.txt ; echo  -e "\e[01;32m[+]\e[00m ----- Full TCP Port Scan Complete. Press ENTER to Exit" ; echo "" ; read ENTERKEY ;'
else
echo ""
echo -e "\e[01;33m[-]\e[00m Skipping Full TCP Port Scan as it's turned off in the options"
fi

if [ $TOPUDP = "on" ]
then
i# Top UDP Port Scan
gnome-terminal --title="$REF - Fast UDP Scan - $INT" -x bash -c 'REF=$(cat REF);INT=$(cat INT);EXCLUDE=$(cat excludeiplist); echo "" ; echo "" ; echo -e "\e[01;32m[-]\e[00m Starting Fast UDP Scan - Scanning Top (1,000) Ports " ; echo "" ; sleep 3 ; nmap -e $INT -sU $EXCLUDE -Pn -T4 --top-ports 1000 -n -vvv -oA "$REF"_nmap_Fast_UDP -iL "$REF"_hosts_Up.txt 2>/dev/null ; echo "" ; echo  -e "\e[01;32m[+]\e[00m $REF - Fast UDP Scan Complete. Press ENTER to Exit" ; echo "" ; read ENTERKEY ;'
else
    echo ""
    echo -e "\e[01;33m[-]\e[00m Skipping Top UDP Scan as it's turned off in the options"
fi

if [ $TOPTCP = "on" ]
then
# Top 1000 TCP Port Scan
gnome-terminal --title="$REF - Top 1,000 TCP Scan - $INT" -x bash -c 'REF=$(cat REF);INT=$(cat INT);EXCLUDE=$(cat excludeiplist); echo "" ; echo "" ; echo -e "\e[01;32m[-]\e[00m Starting Top 1,000 TCP Scan" ; echo "" ; sleep 3 ; nmap -e $INT -sS $EXCLUDE -Pn -T4 --top-ports 1000 -n -vvv -oA "$REF"_nmap_Top_1k_TCP -iL "$REF"_hosts_Up.txt 2>/dev/null ; echo "" ; echo -e "\e[01;32m[+]\e[00m $REF - Top 1,000 TCP Scan Complete. Press ENTER to Exit" ; echo "" ; read ENTERKEY ;'
else
    echo ""
    echo -e "\e[01;33m[-]\e[00m Skipping Top TCP Scan as it's turned off in the options"
fi

# clear temp files
sleep 5
rm "INT" 2>/dev/null
rm "REF" 2>/dev/null

clear
echo ""
echo -e "\e[01;32m[-]\e[00m Once all Scans are complete, press ENTER on this window to list all unique ports found and continue - $REF"
read ENTERKEY
clear
echo ""
echo -e "\e[01;32m======================================================================\e[00m"
echo -e "\e[01;32m[+]\e[00m The following scan start/finish times were recorded for $REF"
echo -e "\e[01;32m======================================================================\e[00m"
echo ""

PINGTIMESTART=`cat "$REF"_nmap_PingScan.nmap 2>/dev/null | grep -i "scan initiated" | awk '{print $6, $7, $8, $9, $10}'`
PINGTIMESTOP=`cat "$REF"_nmap_PingScan.nmap 2>/dev/null | grep -i "nmap done" | awk '{print $5, $6, $7, $8, $9}'`
FULLTCPTIMESTART=`cat "$REF"_nmap_FullPorts.nmap 2>/dev/null | grep -i "scan initiated" | awk '{print $6, $7, $8, $9, $10}'`
FULLTCPTIMESTOP=`cat "$REF"_nmap_FullPorts.nmap 2>/dev/null | grep -i "nmap done" | awk '{print $5, $6, $7, $8, $9}'`
FASTUDPTIMESTART=`cat "$REF"_nmap_Fast_UDP.nmap 2>/dev/null | grep -i "scan initiated" | awk '{print $6, $7, $8, $9, $10}'`
FASTUDPTIMESTOP=`cat "$REF"_nmap_Fast_UDP.nmap 2>/dev/null | grep -i "nmap done" | awk '{print $5, $6, $7, $8, $9}'`

if [ -z "$PINGTIMESTOP" ]
    then
        echo ""
        echo "" >> "$REF"_nmap_scan_times.txt
        echo -e "\e[01;31m[!]\e[00m Ping sweep started $PINGTIMESTART\e[00m - \e[01;31mscan did not complete or was interrupted!"
        echo " Ping sweep started $PINGTIMESTART - scan did not complete or was interrupted!" >> "$REF"_nmap_scan_times.txt
    else
        echo ""
        echo "" >> "$REF"_nmap_scan_times.txt
        echo -e "\e[01;32m[+]\e[00m Ping sweep started $PINGTIMESTART\e[00m - \e[00;32mfinished successfully $PINGTIMESTOP"
        echo " Ping sweep started $PINGTIMESTART - finished successfully $PINGTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
if [ -z "$FULLTCPTIMESTOP" ]
    then
        echo ""
        echo "" >> "$REF"_nmap_scan_times.txt
        echo -e "\e[01;31m[!]\e[00m Full TCP Port Scan started $FULLTCPTIMESTART\e[00m - \e[01;31mscan did not complete of was interupted!"
        echo " Full TCP Port Scan started $FULLTCPTIMESTART - scan did not complete of was interupted!" >> "$REF"_nmap_scan_times.txt
    else
        echo ""
        echo "" >> "$REF"_nmap_scan_times.txt
        echo -e "\e[01;32m[+]\e[00m Full TCP Port Scan started $FULLTCPTIMESTART\e[00m - \e[00;32mfinished successfully $FULLTCPTIMESTOP"
        echo " Full TCP Port Scan started $FULLTCPTIMESTART - finished successfully $FULLTCPTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
if [ -z "$FASTUDPTIMESTOP" ]
    then
        echo ""
        echo "" >> "$REF"_nmap_scan_times.txt
        echo -e "\e[01;31m[!]\e[00m Fast UDP Port Scan started $FASTUDPTIMESTART\e[00m - \e[01;31mscan did not complete of was interupted!"
        echo " Fast UDP Port Scan started $FASTUDPTIMESTART - scan did not complete of was interupted!" >> "$REF"_nmap_scan_times.txt
    else
        echo ""
        echo "" >> "$REF"_nmap_scan_times.txt
        echo -e "\e[01;32m[+]\e[00m Fast UDP Port Scan started $FASTUDPTIMESTART\e[00m - \e[00;32mfinished successfully $FASTUDPTIMESTOP"
        echo " Fast UDP Port Scan started $FASTUDPTIMESTART - finished successfully $FASTUDPTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
echo ""
echo -e "\e[01;32m===============================================\e[00m"
echo -e "\e[01;32m[+]\e[00m TCP and UDP Open Ports Summary - $REF"
echo -e "\e[01;32m===============================================\e[00m"
echo ""
OPENPORTS=$(cat *.xml | grep -i 'open"' | grep -i "portid=" | cut -d'"' -f 4,5,6 | grep -o '[0-9]*' | sort --unique | sort -k1n | paste -s -d, 2>&1)
echo $OPENPORTS > "$REF"_nmap_open_ports.txt
if [ -z "$OPENPORTS" ]
    then
        echo -e "\e[01;31m[!]\e[00m No open ports were found on any of the scans"
    else
        echo -e "\e[01;31m[!]\e[00m $OPENPORTS\e[00m"
        echo ""
fi
echo ""
echo -e "\e[01;32m======================================================================\e[00m"
echo -e "\e[01;32m[+]\e[00m The following $HOSTSCOUNT hosts were up and scanned for $REF"
echo -e "\e[01;32m======================================================================\e[00m"
echo ""
HOSTSUP=$(cat "$REF"_hosts_Up.txt)
echo -e "\e[00;32m$HOSTSUP\e[00m"
echo ""
echo ""
# Check for excluded IPs
ls "$REF"_nmap_hosts_excluded.txt >/dev/null 2>&1
if [ $? = 0 ]
    then
        echo -e "\e[01;32m===================================================================\e[00m"
        echo -e "\e[01;32m[+]\e[00m The following hosts were excluded from the scans for $REF"
        echo -e "\e[01;32m===================================================================\e[00m"
        EXFIN=$(cat excludeiplist)
        echo -e "\e[01;32m$EXFIN\e[00m"
        echo ""
    else
        echo ""
fi
echo -e "\e[01;33m[-]\e[00m Output files have all been saved to the \e[00;32m"$REF"\e[00m directory"
echo ""

rm "excludeiplist" 2>/dev/null
rm "excludetmp" 2>/dev/null
exit 0
