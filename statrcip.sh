#!/bin/bash
#This script is intended to be just a statport -rcip but printing out a date since
#for some reason statport -rcip does not print out the date and time as the other 
#statport options (-host, -disk) do.

u1="`basename $0` -i count_of_iterations -d duration_of_iteration\n"
u2="Example: `basename $0` -i 60 -d 5\n"
USAGE=$u1$u2

#Parse command line options.
while getopts i:d: OPT; do
    case "$OPT" in
        i)
            count=$OPTARG
            ;;
        d)
            duration=$OPTARG
            ;;
        \?)
            # getopts issues an error message
            echo -e $USAGE >&2
            exit 1
            ;;
    esac
done

if [ $# -lt 4 ] ; then
	echo -e $USAGE
	exit 1
fi

#For now duration will be ignored and fixed to 2.7 seconds
#The statport -rcip was timed to take 2.3 seconds
#That means that for now the fixed duration is 5 seconds 
#between iterations
while [ $count -gt 0 ]
do
	date +"%T %D"
	statport -iter 1 -rcip -rw -ni
	count=$(($count - 1))
	sleep 2.7
done