#!/bin/bash
#This script is intended to be run by the 'getinservstats'

u1="`basename $0` -i nunber_of_iterations -d duration_of_iteration [-h nfs_host] [-l location_dir]\n"
u2="The location directory of the stat files must include the mount point (e.g., perf) without 1st slash\n"
u3="If no -h and -l are specified, the default location is /net/sequoia1.boi.storage.hpecorp.net/perf/{inserv_name}/tmp\n"
u4="If only -h is provided then default location is /net/{nfs_host}.boi.storage.hpecorp.net/{inserv_name}/tmp\n"
u5="If only -l is provided then default location is /net/sequoia1.boi.storage.hpecorp.net/{location_dir}\n"
u6="If -h and -l are specified, then location is /net/{nfs_host}.boi.storage.hpecorp.net/perf/{location_dir}\n"
u7="Example of use: `basename $0` -n newton -i 60 -d 5 -h newton -l perf/r1results\n"
USAGE=$u1$u2$u3$u4$u5$u6$u7

#Parse command line options.
while getopts i:d:h:l: OPT; do
    case "$OPT" in
        i)
            iterations=$OPTARG
            ;;
        d)
            duration=$OPTARG
            ;;
        h)
            nfshost=$OPTARG
            ;;
        l)
            locdir=$OPTARG
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

inserv=`hostname | sed "s/-.*//"`
stats_file="showstats_"$inserv".txt"
hists_file="showhists_"$inserv".txt"

if [ -z $nfshost ] ; then
	nfshost=sequoia1
fi

if [ -z $locdir ] ; then
	locdir=perf/$inserv/tmp
fi

#WDIR=/net/${nfshost}.boi.storage.hpecorp.net/${locdir}
#NFSBIN=/net/sequoia1.boi.storage.hpecorp.net/perf/bin
WDIR=$(pwd)/${locdir}
#WDIR=/home/perfshare/Unity/3PAR/block-tools-ftc-new/${locdir}
#NFSBIN=/home/perfshare/Unity/Sizing_RM/
NFSBIN=/common/fsvc/stats/


mkdir -p -m 777 $WDIR

statpd -iter $iterations -d $duration -ni -rw > $WDIR/pdstat.txt &
statvv -iter $iterations -d $duration -ni -rw > $WDIR/vvstat.txt &
statvlun -iter $iterations -d $duration -ni -rw > $WDIR/vlunstat.txt &
statport -host -iter $iterations -d $duration -rw > $WDIR/porthoststat.txt &
statport -disk -iter $iterations -d $duration -rw > $WDIR/portdiskstat.txt &
statcpu -iter $iterations -d $duration > $WDIR/cpustat.txt &
statcmp -iter $iterations -d $duration > $WDIR/cmpstat.txt &
$NFSBIN/statrcip -i $iterations -d $duration > $WDIR/portrcipstat.txt &
statcache -iter $iterations -d $duration > $WDIR/cachestat.txt &
statcache -v -iter $iterations -d $duration > $WDIR/cachevstat.txt &
statlink -detail -iter $iterations -d $duration > $WDIR/linkstat.txt &

histpd -iter $iterations -d $duration -ni -rw > $WDIR/pdhist.txt &
histvv -iter $iterations -d $duration -ni -rw > $WDIR/vvhist.txt &
histvlun -iter $iterations -d $duration -ni -rw > $WDIR/vlunhist.txt &
histport -host -iter $iterations -d $duration -rw > $WDIR/porthosthist.txt &
histport -disk -iter $iterations -d $duration -rw > $WDIR/portdiskhist.txt &

$NFSBIN/freememory -i $iterations -d $duration > $WDIR/informmemory.txt &

sleep_time=$(($iterations*$duration))
sleep_time=$(($sleep_time+1))
sleep $sleep_time

echo > $WDIR/$stats_file
echo "#CPUSTAT" >> $WDIR/$stats_file
cat $WDIR/cpustat.txt >> $WDIR/$stats_file
echo "#CMPSTAT" >> $WDIR/$stats_file
cat $WDIR/cmpstat.txt >> $WDIR/$stats_file
echo "#CACHESTAT" >> $WDIR/$stats_file
cat $WDIR/cachestat.txt >> $WDIR/$stats_file
echo "#CACHEVSTAT" >> $WDIR/$stats_file
cat $WDIR/cachevstat.txt >> $WDIR/$stats_file
echo "#PORTHOSTSTAT" >> $WDIR/$stats_file
cat $WDIR/porthoststat.txt >> $WDIR/$stats_file
echo "#VVSTAT" >> $WDIR/$stats_file
cat $WDIR/vvstat.txt >> $WDIR/$stats_file
echo "#VLUNSTAT" >> $WDIR/$stats_file
cat $WDIR/vlunstat.txt >> $WDIR/$stats_file
echo "#PORTRCIPSTAT" >> $WDIR/$stats_file
cat $WDIR/portrcipstat.txt >> $WDIR/$stats_file
echo "#PORTDISKSTAT" >> $WDIR/$stats_file
cat $WDIR/portdiskstat.txt >> $WDIR/$stats_file
echo "#PDSTAT" >> $WDIR/$stats_file
cat $WDIR/pdstat.txt >> $WDIR/$stats_file
echo "#FREEMEMORY" >> $WDIR/$stats_file
cat $WDIR/informmemory.txt >> $WDIR/$stats_file
echo >> $WDIR/$stats_file

echo > $WDIR/$hists_file
echo "#PORTHOSTHIST" >> $WDIR/$hists_file
cat $WDIR/porthosthist.txt >> $WDIR/$hists_file
echo "#VLUNHIST" >> $WDIR/$hists_file
cat $WDIR/vlunhist.txt >> $WDIR/$hists_file
echo "#VVHIST" >> $WDIR/$hists_file
cat $WDIR/vvhist.txt >> $WDIR/$hists_file
echo "#PORTDISKHIST" >> $WDIR/$hists_file
cat $WDIR/portdiskhist.txt >> $WDIR/$hists_file
echo "#PDHIST" >> $WDIR/$hists_file
cat $WDIR/pdhist.txt >> $WDIR/$hists_file
echo >> $WDIR/$hists_file
