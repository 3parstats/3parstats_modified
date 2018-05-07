# Usage Directions

Here is some info on the showinservstats-local command. Currently it is saved in \\ftchome.us.rdlabs.hpecorp.net\ftchome\kburke\stats. If it is run for a long time, it can take up lots of space, so I usually place it somewhere on /common/ on the 3PAR and point the output somewhere on /common/ as well, since it usually has lots of free space. You have to be logged in as root to use it.

You can choose the number of iterations (-i) and the duration between iterations (-d), as well as the save location for the data (-l). The following example will record stats every 5 seconds for 10 intervals and saves the files in ./outputdir:
`./showinservstats-local -i 10 -d 5 -l outputdir`

The data can be sorted into CSV format by using another script, where -d is the location of the data and -c saves it in CSV format. Example:
`./reportstats -d outputdir/ -c > output.csv`

## This is the list of files it saves to:

root@MXN550253E-0 Fri Apr 28 07:56:46:/common/fsvc/stats/outputdir# ls -lh  
total 328M  
-rw-r--r-- 1 root root  20M Apr 27 08:11 cachestat.txt  
-rw-r--r-- 1 root root  70M Apr 27 08:11 cachevstat.txt  
-rw-r--r-- 1 root root  17M Apr 27 08:11 cmpstat.txt  
-rw-r--r-- 1 root root  14M Apr 27 08:11 cpustat.txt  
-rw-r--r-- 1 root root 3.7M Apr 27 08:11 informmemory.txt  
-rw-r--r-- 1 root root  11M Apr 27 08:11 linkstat.txt  
-rw-r--r-- 1 root root 314M Apr 27 08:11 pdhist.txt  
-rw-r--r-- 1 root root 103M Apr 27 08:11 pdstat.txt  
-rw-r--r-- 1 root root  37M Apr 27 08:11 portdiskhist.txt  
-rw-r--r-- 1 root root  22M Apr 27 08:11 portdiskstat.txt  
-rw-r--r-- 1 root root  35M Apr 27 08:11 porthosthist.txt  
-rw-r--r-- 1 root root  20M Apr 27 08:11 porthoststat.txt  
-rw-r--r-- 1 root root  11M Apr 27 08:11 portrcipstat.txt  
-rw-r--r-- 1 root root 602M Apr 27 08:11 vlunhist.txt  
-rw-r--r-- 1 root root 304M Apr 27 08:11 vlunstat.txt  
-rw-r--r-- 1 root root 118M Apr 27 08:11 vvhist.txt  
-rw-r--r-- 1 root root  57M Apr 27 08:11 vvstat.txt  

## These are the commands run for each file:  

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


## Usage for showinserv-stats:  
showinservstats-local -i nunber_of_iterations -d duration_of_iteration [-h nfs_host] [-l location_dir]  
The location directory of the stat files must include the mount point (e.g., perf) without 1st slash  
If no -h and -l are specified, the default location is /net/sequoia1.boi.storage.hpecorp.net/perf/{inserv_name}/tmp  
If only -h is provided then default location is /net/{nfs_host}.boi.storage.hpecorp.net/{inserv_name}/tmp  
If only -l is provided then default location is /net/sequoia1.boi.storage.hpecorp.net/{location_dir}  
If -h and -l are specified, then location is /net/{nfs_host}.boi.storage.hpecorp.net/perf/{location_dir}  
Example of use: showinservstats-local -n newton -i 60 -d 5 -h newton -l perf/r1results  


## Usage for reportstats:  

reportstats [-w num_iterations] [-m num_iterations] [-b tod_begin -e tod_end] [-d directory] [-f input_file_name] [-c | -s]  
Example: reportstats -s  
Example: reportstats -c  
The first example gives a summary including all samples. The second example gives a csv output including all samples  
The following examples show the options to gather a subset of the sampsles:  
Example: reportstats -w 30 -m 30 -s  
Example: reportstats -w 30 -m 30 -f file_with_stats  
Example: reportstats -b 15:30:11 -e 15:35:55  
You can only use one of -w,-m or the -b,-e options for specifying the range of samples to process  
If no -w,-m or -b,-e are used, then assume '-w 0 -m 524288' all samples in file_with_stats will be processed  
If no -f input_file_with_stats is provided then reportstats will look for 6 files with the following keywords in their names:  
cpustat, porthoststat, portdiskstat, vlunstat, pdstat, cmpstat, vvstat, informmemory, kvmmemory  
-s provides a short summary.  -c provides a csv output that can be used with Excel for time series  
if you dont specify either -s or -c then the default is -s  
one parameter has to be provided at least. Otherwise you'll get this usage statement only  
