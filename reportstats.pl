#!/usr/bin/perl -w
use Getopt::Std;

#This script is based on the 'nproc_titan' script written by Bill McCormack
#This script post processes 6 type of stas from an Inserv node: cpu, porthost, portdisk, vlun, pd and cmp
#Parameter -w num_iterations is number of iterations of warmup to skip before gathering stats
#Parameter -m num_iterations is number of iterations of measurement to process for stats results
#Parameter -b tod_begin is the time of day to start collecting data
#Parameter -e tod_end is the time of day to stop collecting data
#Parameter -d is the directory where the files with stats are located. Default is current dir
#Parameter -f is the name of the file with the stats. It can have the 6 stats results (cpu,hp,dp,vl,pd,cmp) in it.
#Parameter -c is to produce a comma separated values file (a .csv file to be used with Excel)
#Parameter -s is to produce a short summary of the results
#The correct usage is to use just -w,-m or -b,-e but not both.

@command=split ("/",$0);
$num_paths=@command;
$basename=$command[$num_paths-1];

$dates_used=0;
$skip_used=0;

$single_file=0;
$multiple_files=0;

$max_num_samples=524288;
$min_node=0;
$max_node=7;
$min_core=0;
$max_core=31;

$u1="$basename [-w num_iterations] [-m num_iterations] [-b tod_begin -e tod_end] [-d directory] [-f input_file_name] [-c | -s]\n";
$u2="Example: $basename -s\n";
$u3="Example: $basename -c\n";
$u4="The first example gives a summary including all samples. The second example gives a csv output including all samples\n";
$u5="The following examples show the options to gather a subset of the sampsles:\n";
$u6="Example: $basename -w 30 -m 30 -s\n";
$u7="Example: $basename -w 30 -m 30 -f file_with_stats\n";
$u8="Example: $basename -b 15:30:11 -e 15:35:55\n";
$u9="You can only use one of -w,-m or the -b,-e options for specifying the range of samples to process\n";
$u10="If no -w,-m or -b,-e are used, then assume '-w 0 -m $max_num_samples' all samples in file_with_stats will be processed\n";
$u11="If no -f input_file_with_stats is provided then $basename will look for 6 files with the following keywords in their names:\n";
$u12="cpustat, porthoststat, portdiskstat, vlunstat, pdstat, cmpstat, vvstat, informmemory, kvmmemory\n";
$u13="-s provides a short summary.  -c provides a csv output that can be used with Excel for time series\n";
$u14="if you dont specify either -s or -c then the default is -s\n";
$u15="one parameter has to be provided at least. Otherwise you'll get this usage statement only\n";
$usage=join("",$u1,$u2,$u3,$u4,$u5,$u6,$u7,$u8.$u9,$u10,$u11,$u12,$u13,$u14,$u15);

getopts('w:m:b:e:d:f:cs');

$parameter_flag=0;

if (defined $opt_w) { $skip_used=1; $num_to_skip=$opt_w; $parameter_flag=1; }
else { $num_to_skip=0; } #skip zero and process right from the first sample in stats file

if (defined $opt_m) { $skip_used=1; $num_to_process=$opt_m; $parameter_flag=1; }
else { $num_to_process=$max_num_samples; } 

if (defined $opt_b) { $dates_used=1; $tstart=$opt_b; $parameter_flag=1; }
else { $tstart=""; }

if (defined $opt_e) { $dates_used=1; $tstop=$opt_e; $parameter_flag=1; }
else { $tstop=""; }

if (defined $opt_f) { $single_file=1; $stats_file=$opt_f; $parameter_flag=1; }
else { $multiple_files=1; }

if (defined $opt_d) { $wdir=$opt_d; $parameter_flag=1; }
else { $wdir="."; }

if (defined $opt_c) { $csv=$opt_c; $summ=0; $parameter_flag=1; }
else { $csv=0; $summ=1; }

if (defined $opt_s) { $summ=$opt_s; $csv=0; $parameter_flag=1; }
else { $summ=0; $csv=1; }

if ($parameter_flag == 0) { print $usage; exit 1; }

if ((defined $opt_b) && (! defined $opt_e)) { print "Error: '-b tod' specified but not '-e tod'\n"; exit 1; }
if ((! defined $opt_b) && (defined $opt_e)) { print "Error: '-e tod' specified but not '-b tod'\n"; exit 1; }
if ((defined $opt_c) && (defined $opt_s)) { print "Error: just one of -c or -s can be specified\n"; exit 1; }
if (($skip_used == 1) && ($dates_used == 1)) { print $usage; exit 1; }
if (($skip_used == 0) && ($dates_used == 0)) { $skip_used=1; }
if ((substr $wdir,-1,1) eq "/") { $wdir=substr $wdir,0,length($wdir)-1; } #remove last "/" from $wdir
if ((! defined $opt_c) && (! defined $opt_s)) { $summ=1; $csv=0; } #default is summary

if ($single_file == 1) {
    if (defined $opt_d) { $stats_file=join("/",$wdir,$stats_file); }
    if (! -e $stats_file) { printf "Error - File: %s not found!\n",$stats_file; exit 1; }
}

if ($multiple_files == 1) {
    #These files should be in the directory specified by -d or if no -d option used, then current dir
    #These files are expected to have stats gathered from an Inserv system
    @files=<$wdir/*cpustat*>; $cpustats_file=$files[0]; #use only the first file with the keyword
    @files=<$wdir/*porthoststat*>; $porthoststats_file=$files[0]; #use only the first file with the keyword
    @files=<$wdir/*portdiskstat*>; $portdiskstats_file=$files[0]; #use only the first file with the keyword
    @files=<$wdir/*vlunstat*>; $vlunstats_file=$files[0]; #use only the first file with the keyword
    @files=<$wdir/*vvstat*>; $vvstats_file=$files[0]; #use only the first file with the keyword
    @files=<$wdir/*pdstat*>; $pdstats_file=$files[0]; #use only the first file with the keyword
    @files=<$wdir/*cmpstat*>; $cmpstats_file=$files[0]; #use only the first file with the keyword
    @files=<$wdir/*informmemory*>; $memstats_file=$files[0]; #use only the first file with the keyword
    @files=<$wdir/*kvmmemory*>; $kvmmstats_file=$files[0]; #use only the first file with the keyword
    @files=<$wdir/*portrcipstat*>; $portrcipstats_file=$files[0]; #use only the first file with the keyword
    @files=<$wdir/*cachestat*>; $cachestats_file=$files[0]; #use only the first file with the keyword
    @files=<$wdir/*cachevstat*>; $cachevstats_file=$files[0]; #use only the first file with the keyword
}

if ( ($tstop lt $tstart)  )  {
    $hh=substr($tstop, 0, 2);
    if ($hh == "00")  { substr($tstop,0,2) = "24" }
}

####Start of Subroutine section###########################################################
sub cpustats_init {
    $flag=$cpcnt=0; 
    $num_samples=0;$s=-1;
    $user_sum=$sys_sum=$intrs_sum=$ctxts_sum=0;
    for $i ($min_node..$max_node) { $nodes_flag[$i]=0; }
    for $n ($min_node..$max_node) { 
	for $c ($min_core..$max_core) { $cores_flag[$n][$c]=0; $user_core_sum[$n][$c]=0; $sys_core_sum[$n][$c]=0; $idle_core_sum[$n][$c]=0; } 
    }
    %cpus=(); # initialize empty hash to be populated with cpu stats later, hash of array of arrays
    %cputotals=(); # initialize empty hash to be populated with interrupt and context switch cpu stats later, hash of array of arrays
}

sub cpustats_gather {
    chomp;
    if (index($_,":") >= 0) { 
	$flag=0;
	$num_samples+=1;
	($thetod,$thedate) = split; 
	if ($dates_used == 1) { if ( ($thetod gt $tstart) && ($thetod lt $tstop) ) { $flag=1; } }
	if ($skip_used == 1) { if (($num_samples > $num_to_skip) && ($num_samples <= ($num_to_skip+$num_to_process))) {$flag=1;} }
	if ($flag == 1) { $s++; $date[$s]=$thedate; $tod[$s]=$thetod; }
    }
    # Get per core entries
    if ( ($flag == 1) && (index($_,"total") < 0) && (index($_,"node") < 0)  && (index($_,",") >= 0) )  {
	@field=split;
	@node_core=split(",",$field[0]);
	$n=$node_core[0];
	$c=$node_core[1];
	if ( ($n >= $min_node) && ($n <= $max_node) && ($c >= $min_core) && ($c <= $max_core) )  {
	    # Check if the name of node-core is already in the hash, if not create an entry for it
	    if ( ! exists $cpus{"$n-$c"}) {
		# %cpus{node-core}=(util user sys)
		$cpus{"$n-$c"}=[[],[],[]];
	    }
	    $cores_flag[$n][$c]=1; 

	    $cpus{"$n-$c"}[0][$s]=100-$field[3];
	    $cpus{"$n-$c"}[1][$s]=$field[1];
	    $cpus{"$n-$c"}[2][$s]=$field[2];

	    $user_core_sum[$n][$c]+=$field[1]; 
	    $sys_core_sum[$n][$c]+=$field[2];
	    $idle_core_sum[$n][$c]+=$field[3]; 
	}
    }

    # Get totals
    if ( ($flag == 1) && (index($_,",total") >= 0) )  {
	$n=substr($_,1,1); 
	if ( ( $n >= $min_node) && ($n <= $max_node) )  {
	    $nodes_flag[$n]=1;
	    @vals=split;
	    # Check if the name of node-total is already in the hash, if not create an entry for it
	    if ( ! exists $cputotals{"n$n"}) {
		# %cputotals{node-total}=( util user sys intr/s ctxt/s)
		$cputotals{"n$n"}=[[],[],[],[],[]];
	    }

	    $user_sum+=$vals[1];
	    $sys_sum+=$vals[2];
	    $intrs_sum+=$vals[4];
	    $ctxts_sum+=$vals[5];

	    $cputotals{"n$n"}[0][$s]=100-$vals[3];
	    $cputotals{"n$n"}[1][$s]=$vals[1];
	    $cputotals{"n$n"}[2][$s]=$vals[2];
	    $cputotals{"n$n"}[3][$s]=$vals[4];
	    $cputotals{"n$n"}[4][$s]=$vals[5];

	    $cpcnt++;
	}
    }
}
sub cpustats_process {
    if (($cpcnt > 0) && ($summ == 1)) {
	$ts=$s+1;  #ts is total samples. $s is an index for the zero based array of samples so the value of $s is one less than the actual number of samples
	printf "Core n,c: user  sys  idle  Util\n",$n,$c;
	for $n ($min_node..$max_node) { for $c ($min_core..$max_core) { if ($cores_flag[$n][$c] == 1) {
	    printf "%d,%d:    %.1f  %.1f  %.1f   %.1f\n",$n,$c,
	    $user_core_sum[$n][$c]/$ts,$sys_core_sum[$n][$c]/$ts,$idle_core_sum[$n][$c]/$ts,(100-$idle_core_sum[$n][$c]/$ts); 
									} } }
	printf "\n";
    }
    if (($cpcnt > 0) && ($csv == 1)) {
	# process CPU stats per core
	@cpuStats=("CPUutil","CPUuser","CPUsys",);
	@cpuSums=("CPUutil","CPUuser","CPUsys","intr/s","ctxt/s");
	printf "\n";
	printf "********THE BELOW OUTPUT IS FROM 'cpustats.txt'********\nObtained by using the command 'statcpu -iter <iterations> -d <duration>'\n\n";
	printf "**Here CPUutil is (100-idle)**\n\n";
	printf "The Output is formatted as follows:\n";
	for ($i=0; $i<=$#cpuStats; $i++) {
		printf "${cpuStats[$i]}-<node_no>-<cpu_no>,<value1_iter1>,<value2_iter2>,<value3_iter3>,...,<value(n)_iter(n)>,\n";
	}
	printf "\n";
	printf "The Totals are in the following format:\n";
	for ($i=0; $i<$#cpuSums; $i++) {
		printf "${cpuSums[$i]}-<node_no>,<total_value1_iter1>,<total_value2_iter2>,...,<total_value(n)_iter(n)>\n";
	} 
	printf "\n";
	printf "*********************************************************\n";
	printf "\n";
	for ($i=0; $i<=$#cpuStats; $i++) {
	    printf "$date[0],";
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		printf "%s,",$tod[$s];
	    }
	    printf "\n";
	    foreach $cpu (sort keys %cpus) {
		printf "${cpuStats[$i]}-$cpu,";
		for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		    $val=0;
		    if ((defined $cpus{$cpu}[$i][$s]) && ($cpus{$cpu}[$i] > 0)) { $val=$cpus{$cpu}[$i][$s]; }
		    printf "%d,",$val;
		}
		printf "\n";
	    }
	    print "\n\n";
	}
    }
    if (($cpcnt > 0) && ($summ == 1)) {
	$nodecnt=0; foreach $i (@nodes_flag) { if ($i == 1) {$nodecnt++;} }
	printf "CPU %dn: user  sys  intr/s ctxt/s\n",$nodecnt;
	printf "CPU %dn:  %.1f  %.1f  %d   %d\n",$nodecnt,$user_sum/$cpcnt,$sys_sum/$cpcnt,$intrs_sum/$cpcnt,$ctxts_sum/$cpcnt; 
	printf "\n";
    }
    if (($cpcnt > 0) && ($csv == 1)) {
	#$nodecnt=0; foreach $i (@nodes_flag) { if ($i == 1) {$nodecnt++;} }
	# process CPU stats per node
	printf "*******TOTALS********\n\n\n";
	@cpuSums=("CPUutil","CPUuser","CPUsys","intr/s","ctxt/s");
	for ($i=0; $i<=$#cpuSums; $i++) {
	    printf "$date[0],";
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		printf "%s,",$tod[$s];
	    }
	    printf "\n";
	    foreach $total (sort keys %cputotals) {
		printf "${cpuSums[$i]}-$total,";
		for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		    $val=0;
		    if ((defined $cputotals{$total}[$i][$s]) && ($cputotals{$total}[$i] > 0)) { $val=$cputotals{$total}[$i][$s]; }
		    printf "%d,",$val;
		}
		printf "\n";
	    }
	    print "\n\n";
	}
    }
}

sub hpstats_init {
    #rios = read io/s, rkbs = read kb/s
    #rmulrt = multiply read response time by read io/s, rmulxs = multiply read xfer size (IOSz) by read io/s
    #wios = write io/s, wkbs = write kb/s
    #wmulrt = multiply write response time by write io/s, wmulxs = multiply write write xfer size (IOSz) write io/s
    $flag=$hcnt=$hpql_sum=0;
    $rios_sum=$rkbs_sum=$rmulrt_sum=$rmulxs_sum=0; 
    $wios_sum=$wkbs_sum=$wmulrt_sum=$wmulxs_sum=0; 
    $num_samples=0;$s=-1;
    for $i ($min_node..$max_node) { $nodes_flag[$i]=0; }
    %hps=(); # initialize empty hash to be populated with host port stats later, hash of array of arrays
}

sub hpstats_gather {
    chomp;
    if (index($_,"KBytes") >= 0) { 
	$flag=0;
	$num_samples+=1;
	($thetod,$thedate) = split; 
	if ($dates_used == 1) { if ( ($thetod gt $tstart) && ($thetod lt $tstop) ) { $flag=1; } }
	if ($skip_used == 1) { if (($num_samples > $num_to_skip) && ($num_samples <= ($num_to_skip+$num_to_process))) {$flag=1;} }
	if ($flag == 1) { $hcnt++; $s++; $date[$s]=$thedate; $tod[$s]=$thetod; }
    }
    if (index($_,"----------") >= 0) { $flag=0; }
    if ( ($flag == 1) && (index($_,"Data") > 0) )  {
	@vals=split;
	$n=substr($vals[0],0,1);
	if ( ( $n >= $min_node) && ($n <= $max_node) )  {
	    $nodes_flag[$n]=1;
	    # Check if the name of the host port is already in the hash, if not create an entry for it
	    if ( ! exists $hps{"$vals[0]"}) {
		# %hps{port}=(HP-Rio/s HP-Rkb/s HP-Rrt HP-Rxs HP-Wio/s HP-Wkb/s HP-Wrt HP-Wxs HP-IO/s HP-KB/s HP-rt HP-Qlen)
		$hps{$vals[0]}=[[],[],[],[],[],[],[],[],[],[],[],[]];
	    }
	    if ($vals[2] eq "r") {  
		$rios_sum+=$vals[3];
		$rkbs_sum+=$vals[6];
		$rmulrt_sum+=$vals[9]*$vals[3];
		$rmulxs_sum+=$vals[11]*$vals[3];

		$hps{$vals[0]}[0][$s]=$vals[3];
		$hps{$vals[0]}[1][$s]=$vals[6];
		$hps{$vals[0]}[2][$s]=$vals[9];
		$hps{$vals[0]}[3][$s]=$vals[11];

	    } 
	    if ($vals[2] eq "w") {  
		$wios_sum+=$vals[3];
		$wkbs_sum+=$vals[6];
		$wmulrt_sum+=$vals[9]*$vals[3];
		$wmulxs_sum+=$vals[11]*$vals[3];

		$hps{$vals[0]}[4][$s]=$vals[3];
		$hps{$vals[0]}[5][$s]=$vals[6];
		$hps{$vals[0]}[6][$s]=$vals[9];
		$hps{$vals[0]}[7][$s]=$vals[11];

	    } 
	    if ($vals[2] eq "t") {
		$hpql_sum+=$vals[13];
		$hps{$vals[0]}[8][$s]=$vals[3];   # HP-IO/s
		$hps{$vals[0]}[9][$s]=$vals[6];   # HP-KB/s
		$hps{$vals[0]}[10][$s]=$vals[9];  # HP-rt
		$hps{$vals[0]}[11][$s]=$vals[13]; # HP-Qlen
	    }
	} 
    }
}

sub hpstats_process {
    #rrt = average read response time in ms, rxs = average read xfer size (IOSz)
    #wrt = average write response time in ms, wxs = average write xfer size (IOSz)
    $nodecnt=0; foreach $i (@nodes_flag) { if ($i == 1) {$nodecnt++;} }
    if (($hcnt > 0) && ($csv == 0)) {
	printf "HP %dn: HRio/s HRkb/s HRrt HRxs HWio/s HWkb/s HWrt HWxs HQlen\n",$nodecnt; #'H'Host,'R' Reads,'W' Writes
	$rrt=$rxs=$wrt=$wxs=0;
	if ($rios_sum > 0) { $rrt=$rmulrt_sum/$rios_sum; $rxs=$rmulxs_sum/$rios_sum };
	if ($wios_sum > 0) { $wrt=$wmulrt_sum/$wios_sum; $wxs=$wmulxs_sum/$wios_sum };
	printf "HP %dn: %d  %d %.1f  %.1f  %d  %d  %.1f  %.1f  %d\n",
	$nodecnt,$rios_sum/$hcnt,$rkbs_sum/$hcnt,$rrt,$rxs,$wios_sum/$hcnt,$wkbs_sum/$hcnt,$wrt,$wxs,$hpql_sum/$hcnt; 
	printf "\n";
    }
    if (($hcnt > 0) && ($csv == 1)) {

	# Print all host port stats
	@hpStats=("HP-Rio/s","HP-Rkb/s","HP-Rrt","HP-Rxs","HP-Wio/s","HP-Wkb/s","HP-Wrt","HP-Wxs","HP-IO/s","HP-KB/s","HP-rt","HP-Qlen");
	printf "\n";
    printf "********THE BELOW OUTPUT IS FROM 'porthoststat.txt'********\nObtained by using the command 'statport -host -iter <iterations> -d <duration> -rw'\n\n";
	printf "The following keywords are used in the output:\n
		HP-Rio/s: HostPort-Read I/O per second
		HP-Rio/s-sum: HostPort-Read I/O per second - sum of all node's port's Read I/Os
		HP-Rkb/s: HostPort-Read KB per second
		HP-Rkb/s-sum: HostPort-Read KB per second - sum of all node's port's Read KBs
		HP-Rrt: HostPort-Read Svt (ms)
		HP-Rrt-avg: HostPort-Read Svt (ms) - average of all node's port's Read Svt
		HP-Rxs: HostPort-Read IOSz (KB)
		HP-Rxs-avg: HostPort-Read IOSz (KB) - average of all node's port's Read IOSz
		HP-Wio/s: HostPort-Write I/O per second
		HP-Wio/s-sum: HostPort-Write I/O per second - sum of all node's port's Write I/Os
		HP-Wkb/s: HostPort-Write KB per second
		HP-Wkb/s-sum: HostPort-Write KB per second - sum of all node's port's Write KBs
		HP-Wrt: HostPort-Write Svt (ms)
		HP-Wrt-avg: HostPort-Write Svt (ms) - average of all node's port's Write Svt
		HP-Wxs: HostPort-Write IOSz (KB)
		HP-Wxs-avg: HostPort-Write IOSz (KB) - average of all node's port's Write IOSz\n
		*****TOTALS*****\n
		HP-IO/s: HostPort-Total(t) I/O per second
		HP-IO/s-sum: HostPort-Total(t) I/O per second - sum of all totals of R/W I/Os
		HP-KB/s: HostPort-Total(t) KB per second
		HP-KB/s-sum: HostPort-Total(t) KB per second - sum of all totals of R/W KBs
		HP-rt: HostPort-Total(t) Svt (ms)
		HP-rt-avg: HostPort-Total(t) Svt (ms) - average of all totals of R/W Svts
		HP-Qlen: HostPort-Total(t) queue length
		HP-Qlen-sum: HostPort-Total(t) queue length - sum of all the totals of Queue length\n\n";
        printf "The Output is formatted as follows:\n";
        for ($i=0; $i<=$#hpStats; $i++) {
                printf "${hpStats[$i]}-<node>:<slot>:<port>,<value1_iter1>,<value2_iter2>,<value3_iter3>,...,<value(n)_iter(n)>,\n";
        }
        printf "\n";
        printf "*********************************************************\n";
        printf "\n";
	for ($i=0; $i<=$#hpStats; $i++) {
	    printf "$date[0],";
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		printf "%s,",$tod[$s];
	    }
	    printf "\n";
	    foreach $hp (sort keys %hps) {
		printf "${hpStats[$i]}-$hp,";
		for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		    $val=0;
		    if ((defined $hps{$hp}[$i][$s]) && ($hps{$hp}[$i] > 0)) { $val=$hps{$hp}[$i][$s] }
		    printf "%.1f,",$val;
		}
		printf "\n";	
	    }
	    # Print total at the end
	    if ( ( ${hpStats[$i]} =~ "rt") ||
		 ( ${hpStats[$i]} =~ "xs") ) {
		printf "${hpStats[$i]}-avg,";
	    }
	    else {
		printf "${hpStats[$i]}-sum,";
	    }
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		$sum=0;
		$nonZero=0;
		foreach $hp (sort keys %hps) {
		    if ((defined $hps{$hp}[$i][$s]) && ($hps{$hp}[$i][$s] != 0) ) { ++$nonZero; }
		    else { $hps{$hp}[$i][$s] = 0 }
		    $sum+=$hps{$hp}[$i][$s];
		}
		if ( ( ${hpStats[$i]} =~ "rt") ||
		     ( ${hpStats[$i]} =~ "xs") ) {
		    if ( $nonZero > 0 ) { $sum=$sum/$nonZero; }
		}
		printf "%.1f,",$sum;
	    }
	    printf "\n";

	    printf "\n\n";
	}
    }		
}

sub cmpstats_init {
    #Get CMP stats
    #rcmacc = cm read access, rcmhit =cm read hits, wcmacc = cm write access, wcmhit = cm write hits
    #tcmcred = temporary and page credits
    #pcmfree = free pages, pcmclean = clean pages
    #pcmwrit1 = Write1 pages, pcmwritn = WriteN pages, pcmsched = WrtSched pages, pcmwrtng = Writing pages
    #delack_headerN = used to accomadate change in header titles between 313 and 321 releases
    for ($i=$min_node; $i<=$max_node; $i++) { $nodes_flag[$i]=0; }
    $flag=$cmcnt=$state=0; 
    $rcmacc_sum=$rcmhit_sum=$rcmcnt_sum=0;
    $wcmacc_sum=$wcmhit_sum=$wcmcnt_sum=0; 
    $tcmcred_sum=$tcmcnt_sum=0; 
    $pcmfree_sum=$pcmclean_sum=$pcmwrit1_sum=$pcmwritn_sum=$pcmsched_sum=$pcmwrtng_sum=$pcmcnt_sum=0; 
    $delack_header0=$delack_header1=$delack_header2=$delack_header3=$header_recorded=0;
    $num_samples=0;$s=-1;
    for $i ($min_node..$max_node) { $nodes_flag[$i]=0; }
    %cmps=(); # initialize empty hash to be populated with cache stats later, hash of array of arrays
}

sub cmpstats_gather {
    chomp;
    if (index($_,"Current") > 0) { 
	$flag=0;
    $state=0;
	$num_samples+=1;
	($thetod,$thedate) = split; 
	if ($dates_used == 1) { if ( ($thetod gt $tstart) && ($thetod lt $tstop) ) { $flag=1; } }
	if ($skip_used == 1) { if (($num_samples > $num_to_skip) && ($num_samples <= ($num_to_skip+$num_to_process))) {$flag=1;} }
	if ($flag == 1) { $cmcnt++; $s++; $date[$s]=$thedate; $tod[$s]=$thetod; }
    }
    @vals=split;
    if ( ($_ ne "") && ($flag == 1) && ($vals[1] eq "Read" || $vals[1] eq "Write") ) {
	$n=$vals[0];
	if ( ( $n >= $min_node) && ($n <= $max_node) )  {
	    $nodes_flag[$n]=1;
	    # Check node ID is already in the hash. If not create an entry for it
	    if ( ! exists $cmps{"$vals[0]"}) {
		# %cmps{node}=(rCMAcc rCMHit rHitPer rLockBlk wCMAcc wCMHit wHitPer wLockBlk pFree pClean pWrite1 pWriteN pWrtSched pWriting pDcowPend pDcowProc)
		$cmps{$vals[0]}=[[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]];
	    }
	    if ($vals[1] eq "Read") { 
		$rcmacc_sum+=$vals[2]; 
		$rcmhit_sum+=$vals[3]; 
		$rcmcnt_sum+=1; 

		$cmps{$vals[0]}[0][$s]=$vals[2];
		$cmps{$vals[0]}[1][$s]=$vals[3];
		$cmps{$vals[0]}[2][$s]=$vals[4];
		$cmps{$vals[0]}[3][$s]=$vals[8];		
	    } 
	    if ($vals[1] eq "Write") { 
		$wcmacc_sum+=$vals[2]; 
		$wcmhit_sum+=$vals[3]; 
		$wcmcnt_sum+=1; 

		$cmps{$vals[0]}[4][$s]=$vals[2];
		$cmps{$vals[0]}[5][$s]=$vals[3];
		$cmps{$vals[0]}[6][$s]=$vals[4];
		$cmps{$vals[0]}[7][$s]=$vals[8];
	    }
	} 
    }
    if ( ($_ ne "") && ($flag == 1) && ($vals[0] eq "Node") && ($vals[1] eq "Free") ) { $state=1 };
    if ( ($_ ne "") && ($flag == 1) && ($vals[0] eq "Temporary") && ($vals[2] eq "Page") ) { $state=2 };
    if ( ($_ ne "") && ($flag == 1) && (index($_,"CfcDirty") > 0)) { $state=3 };
    if ( ($_ ne "") && ($flag == 1) && ($state == 1) ) {
	$n=$vals[0];
	if ( ($n ne "Node") && ($n >= $min_node) && ($n <= $max_node) ) {
	    $pcmfree_sum+=$vals[1];
	    $pcmclean_sum+=$vals[2];
	    $pcmwrit1_sum+=$vals[3];
	    $pcmwritn_sum+=$vals[4];
	    $pcmsched_sum+=$vals[5];
	    $pcmwrtng_sum+=$vals[6];
	    $pcmcnt_sum+=1;

	    $cmps{$vals[0]}[8][$s]=$vals[1];		
	    $cmps{$vals[0]}[9][$s]=$vals[2];		
	    $cmps{$vals[0]}[10][$s]=$vals[3];		
	    $cmps{$vals[0]}[11][$s]=$vals[4];		
	    $cmps{$vals[0]}[12][$s]=$vals[5];		
	    $cmps{$vals[0]}[13][$s]=$vals[6];		
	    $cmps{$vals[0]}[14][$s]=$vals[7];		
	    $cmps{$vals[0]}[15][$s]=$vals[8];		
	} 
    }
#    if ( ($_ ne "") && ($flag == 1) && ($state==2) ) {
#	$n=$vals[0];
#	if ( ($n ne "Node") && ($n ne "Temporary") && ($n >= $min_node) && ($n <= $max_node) ) {
#	    foreach $i (@nodes_flag) { if ($i == 1) { $tcmcred_sum+=$vals[$i+1]; $tcmcred[$s]+=$vals[$i+1]; } }
#	    $tcmcnt_sum+=1; $tcmcnt[$s]+=1;
#	}
#    }
    if ( ($_ ne "") && ($flag == 1) && ($state == 3) && (index($_,"CfcDirty") < 0)) {
	$n=$vals[0];
    if ( ($n eq "Node") && ($header_recorded == 0) ) {
        $delack_header0=$vals[9];
        $delack_header1=$vals[10];
        $delack_header2=$vals[11];
        $delack_header3=$vals[12];
        $header_recorded=1;
    }
	if ( ($n ne "Node") && ($n >= $min_node) && ($n <= $max_node) ) {
        # No sums are taken for delayed ack stats because they are reported 
        # based on the cumulative number that have occured and not an instaneous value
        # like many of the other stats.
        $cmps{$vals[0]}[16][$s]=$vals[9];		
        $cmps{$vals[0]}[17][$s]=$vals[10];		
        $cmps{$vals[0]}[18][$s]=$vals[11];		
        $cmps{$vals[0]}[19][$s]=$vals[12];		
    }
    }
}

sub cmpstats_process {
    
    $nodecnt=0; foreach $i (@nodes_flag) { if ($i == 1) {$nodecnt++;} }
    if (($cmcnt > 0) && ($csv == 0) ) {  
	#raccavg = read cm access average, rhitavg = read hit average, rhitperc = read hit percentage
	$raccavg=$rhitavg=$rhitperc=0;
	if ($rcmcnt_sum > 0) { $raccavg=$rcmacc_sum/$rcmcnt_sum; $rhitavg=$rcmhit_sum/$rcmcnt_sum };
	if ($rcmacc_sum > 0) { $rhitperc=100*$rcmhit_sum/$rcmacc_sum };
	
	#waccavg = write cm access average, whitavg = write hit average, whitperc = write hit percentage
	$waccavg=$whitavg=$whitperc=0;
	if ($wcmcnt_sum > 0) { $waccavg=$wcmacc_sum/$wcmcnt_sum; $whitavg=$wcmhit_sum/$wcmcnt_sum };
	if ($wcmacc_sum > 0) { $whitperc=100*$wcmhit_sum/$wcmacc_sum };
	
	#pfreeavg = free pages average, pcleanavg = clean pages average, pwrit1avg = write1 pages average
	#pwritnavg = writeN pages average, pschedavg = sched pags average, pwrtngavg = writing pages average
	$pfreeavg=$pcleanavg=$pwrit1avg=$pwritnavg=$pschedavg=0;$pwrtngavg=0; 
	if ($pcmcnt_sum > 0) { 
	    $pfreeavg=$pcmfree_sum/$pcmcnt_sum; 
	    $pcleanavg=$pcmclean_sum/$pcmcnt_sum; 
	    $pwrit1avg=$pcmwrit1_sum/$pcmcnt_sum; 
	    $pwritnavg=$pcmwritn_sum/$pcmcnt_sum;
	    $pschedavg=$pcmsched_sum/$pcmcnt_sum; 
	    $pwrtngavg=$pcmwrtng_sum/$pcmcnt_sum;
	};
	
	#tcredavg = temporary and page credits average
	$tcmcredavg=0;
	if ($tcmcnt_sum > 0) { $tcmcredavg=$tcmcred_sum/$tcmcnt_sum };
	
	printf "CMP %dn: rCMAcc rCMHit rHitPer rCMcnt wCMAcc wCMHit wHitPer wCMcnt ",$nodecnt;
	printf "pFree pClean pWrit1 pWritN tCred tCMcnt\n";
	printf "CMP %dn: %d  %d %d  %d  %d %d %d %d ",$nodecnt,$raccavg,$rhitavg,$rhitperc,$rcmcnt_sum,$waccavg,$whitavg,$whitperc,$wcmcnt_sum;
	printf "%d  %d  %d %d %d  %d\n",$pfreeavg,$pcleanavg,$pwrit1avg,$pwritnavg,$tcmcredavg,$tcmcnt_sum;
	printf "\n";
    }
    if (($cmcnt > 0) && ($csv == 1) ) {  
    @cmpStats=("rCMAcc","rCMHit","rHitPer","rLockBlk","wCMAcc","wCMHit","wHitPer","wLockBlk","pFree","pClean","pWrite1","pWriteN","pWrtSched","pWriting","pDcowPend","pDcowProc","delAck$delack_header0","delAck$delack_header1","delAck$delack_header2","delAck$delack_header3");
    printf "\n";
	printf "********THE BELOW OUTPUT IS FROM 'cmpstat.txt'********\nObtained by using the command 'statcmp -iter <iterations> -d <duration>'\n\n";
	printf "CMP means Cache Memory Page\n\n"
	printf "The following keywords are used in the output:\n
			CMP-rCMAcc: CMP-Read-Current Memory Accesses
			CMP-rCMHit: CMP-Read-Current Memory Hits
			CMP-rHitPer: CMP-Read-Current Memory Hit Percentage
			CMP-rLockBlk: CMP-Read-LockBlk
			CMP-wCMAcc: CMP-Write-Current Memory Accesses
			CMP-wCMHit: CMP-Write-Current Memory Hits
			CMP-wHitPer: CMP-Write-Current Memory Hit Percentage
			CMP-wLockBlk: CMP-Write-LockBlk\n
			**Queue Statitics**
			CMP-pFree: CMP Number of cache pages without valid data on them
			CMP-pClean: CMP Number of clean cache pages (valid data on page)
			CMP-pWrite1: CMP Number of dirty pages that have been modified exactly 1 time
			CMP-pWriteN: CMP Number of dirty pages that have been modified more than 1 time
			CMP-pWrtSched: CMP Number of pages scheduled to be written to disk
			CMP-pWriting: CMP Number of pages being currently written by the flusher to disk
			CMP-pDcowPend: CMP Number of pages waiting for delayed copy on write resolution
			CMP-pDcowProc: CMP Number of pages currently being processed for delayed copy\n
			**Page Statitics**
			CMP-delAck<delAck_header>: Here delAck_header=SSD|FC|NL, it takes the 1st value as it is but the 2nd value is actually (2nd_value - 1st_value), similarly the nth value is (nth_value - (n-1)th_value)\n\n";
	printf "The Output is formatted as follows:\n";
	for ($i=0; $i<=$#cmpStats; $i++) {
		printf "CMP-${cmpStats[$i]}-<node_no>,<value1_iter1>,<value2_iter2>,<value3_iter3>,...,<value(n)_iter(n)>,\n";
	}
	printf "\n";
	printf "*********************************************************\n";
	printf "\n";
	# print all cmp stats
	#@cmpStats=("rCMAcc","rCMHit","rHitPer","rLockBlk","wCMAcc","wCMHit","wHitPer","wLockBlk","pFree","pClean","pWrite1","pWriteN","pWrtSched","pWriting","pDcowPend","pDcowProc","delAckFC","delAckNL","delAckSSD150","delAckSSD100");
	for ($i=0; $i<=$#cmpStats; $i++) {
	    # Print read access first
	    printf "$date[0],";
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		printf "%s,",$tod[$s];
	    }
	    printf "\n";
	    foreach $node (sort keys %cmps) {
		printf "CMP-$cmpStats[$i]-n$node,";
                # If we look at delAck then the difference to the previous sample (basically a rate of "delAck per sample")
                if ( $cmpStats[$i] =~ /delAck/ ) {
		    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
                        $val=0;
                        # First sample is 0, nothing previous to compare it to
                        if ((defined $cmps{$node}[$i][$s]) && ($cmps{$node}[$i][$s] > 0) && ($s == 0)) { $val=0 }
                        # Show the diff to the previous samples for all other
                        if ((defined $cmps{$node}[$i][$s]) && ($cmps{$node}[$i][$s] > 0) && ($s > 0)) { $val=$cmps{$node}[$i][$s]-$cmps{$node}[$i][$s-1] }
                        printf "%d,",$val;
		    }
                }
                # If not a delAck entry simply print the absolute value
                else {
                    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		        $val=0;
		        if ((defined $cmps{$node}[$i][$s]) && ($cmps{$node}[$i][$s] > 0)) { $val=$cmps{$node}[$i][$s] }
		        printf "%d,",$val;
		    }
                }
		printf "\n";
	    }
	    printf "\n\n";
	}
    }
}

sub cachestats_init {
    #Get flash cache stats
    #rcmacc = cm read access, rcmhit =cm read hit percent, rfchit =flash cache read hit percent
    #wcmacc = cm write access, wcmhit = cm write hit percent, wfchit =flash cache write hit percent
    #rbacc = read back accesses, rbios = read back IO/s, rbmbs = read back MB/s, rbclean = read back clean, rbdirty = read back dirty
    #dwacc = destage write accesses, dwios = destage write IO/s, dwmbs = destage write MB/s, dwclean = destage write clean, dwdirty = destage write dirty
    #pfcdorm = pages dormant, pfccold = pages cold, pfcwarm = pages warm, pfchot = pages hot
    #pfcdest = pages destage, pfcread = pages read, pfcwrite = pages write, pfcflush = pages flush, pfcwrtback = pages write back
    for ($i=$min_node; $i<=$max_node; $i++) { $nodes_flag[$i]=0; }
    $flag=$cmcnt=$state=0; 
    $rcmacc_sum=$rcmhit_sum=$rfchit_sum=0;
    $wcmacc_sum=$wcmhit_sum=$wfchit_sum=0; 
    $rbacc_sum=$rbios_sum=$rbmbs_sum=$rbclean_sum=$rbdirty_sum=0;
    $dwacc_sum=$dwios_sum=$dwmbs_sum=$dwclean_sum=$dwdirty_sum=0;
    $pfcdorm_sum=$pfccold_sum=$pfcnorm_sum=$pfcwarm_sum=$pfchot_sum=0;
    $pfcdest_sum=$pfcread_sum=$pfcflush_sum=$pfcwrtback_sum=0;
    $num_samples=0;$s=-1;
    for $i ($min_node..$max_node) { $nodes_flag[$i]=0; }
    %caches=(); # initialize empty hash to be populated with flash cache stats later, hash of array of arrays
}

sub cachestats_gather {
    chomp;
    if ( ( index($_,"Current") > 0 ) && ( (index($_,"/") > 0 ) ) ) { 
	$flag=0;
	$num_samples+=1;
	($thetod,$thedate) = split; 
	if ($dates_used == 1) { if ( ($thetod gt $tstart) && ($thetod lt $tstop) ) { $flag=1; } }
	if ($skip_used == 1) { if (($num_samples > $num_to_skip) && ($num_samples <= ($num_to_skip+$num_to_process))) {$flag=1;} }
	if ($flag == 1) { $cmcnt++; $s++; $date[$s]=$thedate; $tod[$s]=$thetod; }
    }
    @vals=split;
    # Determine in which of the four "blocks" we are in
    if ( ($_ ne "") && ($flag == 1) && ( index($_,"Current") > 0 ) && ( index($_,"/") > 0 ) ) { $state=1 };
    if ( ($_ ne "") && ($flag == 1) && ($vals[0] eq "Internal") && ($vals[1] eq "Flashcache") ) { $state=2 };
    if ( ($_ ne "") && ($flag == 1) && ( index($_,"FMP") > 0 ) && ( index($_,"Queue") > 0 ) ) { $state=3 };
    if ( ($_ ne "") && ($flag == 1) && ($vals[0] =~ "-------") && ($vals[1] eq "CMP") ) { $state=4 };

    # Now work through the different cases for each "state"
    if ( ($_ ne "") && ($flag == 1) && ($state == 1) && ($vals[1] eq "Read" || $vals[1] eq "Write") ) {
	$n=$vals[0];
	if ( ( $n >= $min_node) && ($n <= $max_node) )  {
	    $nodes_flag[$n]=1;
	    # Check node ID is already in the hash. If not create an entry for it
	    if ( ! exists $caches{"$vals[0]"}) {
		# %caches{node}=("rAcc","rCMPHitPer","rFCHitPer","wAcc","wCMPHitPer","wFCHitPer","rbAcc","rbIos","rbMbs","rbClean","rbDirty","dwAcc","dwIos","dwMbs","dwClean","dwDirty","pDorm","pCold","pNorm","pWarm","pHot","pDestage","pRead","pFlush","pWrtBack")
		# Note: Puprosely left out some of the "regular" cache stats since they are covered in cmpstats
		$caches{$vals[0]}=[[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]];
	    }
	    if ($vals[1] eq "Read") { 
		$rcmacc_sum+=$vals[2]; 
		$rcmhit_sum+=$vals[3]; 
		$rfchit_sum+=$vals[4];
		#$rcmcnt_sum+=1; 

		$caches{$vals[0]}[0][$s]=$vals[2]; # rACC
		$caches{$vals[0]}[1][$s]=$vals[3]; # rCMPHitPer
		$caches{$vals[0]}[2][$s]=$vals[4]; # rFCHitPer
	    } 
	    if ($vals[1] eq "Write") { 
		$wcmacc_sum+=$vals[2]; 
		$wcmhit_sum+=$vals[3]; 
		$wfchit_sum+=$vals[4];
		#$wcmcnt_sum+=1; 

		$caches{$vals[0]}[3][$s]=$vals[2]; # wAcc
		$caches{$vals[0]}[4][$s]=$vals[3]; # wCMPHitPer
		$caches{$vals[0]}[5][$s]=$vals[4]; # wFCHitPer
	    } 
	} 
    }
    if ( ($_ ne "") && ($flag == 1) && ($state == 2) && ($vals[1] eq "Read" || $vals[1] eq "Destaged") ) {
	$n=$vals[0];
	if ( ($n ne "Node") && ($n >= $min_node) && ($n <= $max_node) ) {
	    if ( $vals[1] eq "Read" ) {
		$caches{$vals[0]}[6][$s]=$vals[3]; # rbAcc
		$caches{$vals[0]}[7][$s]=$vals[4]; # rbIos
		$caches{$vals[0]}[8][$s]=$vals[5]; # rbMbs
		$caches{$vals[0]}[9][$s]=$vals[6]; # rbClean
		$caches{$vals[0]}[10][$s]=$vals[7]; # rbDirty

		$rbacc_sum+=$vals[3];
		$rbios_sum+=$vals[4];
		$rbmbs_sum+=$vals[5];
		$rbclean_sum+=$vals[6];
		$rbdirty_sum+=$vals[7];
	    }
	    if ( $vals[1] eq "Destaged" ) {
		$caches{$vals[0]}[11][$s]=$vals[3]; # dwAcc
		$caches{$vals[0]}[12][$s]=$vals[4]; # dwIos
		$caches{$vals[0]}[13][$s]=$vals[5]; # dwMbs
		$caches{$vals[0]}[14][$s]=$vals[6]; # dwClean
		$caches{$vals[0]}[15][$s]=$vals[7]; # dwDirty

		$dwacc_sum+=$vals[3];
		$dwios_sum+=$vals[4];
		$dwmbs_sum+=$vals[5];
		$dwclean_sum+=$vals[6];
		$dwdirty_sum+=$vals[7];
	    }
	} 
    }
    if ( ($_ ne "") && ($flag == 1) && ($state == 3) && ($vals[1] ne "FMP") && ($vals[0] !~ "----") ) {
	$n=$vals[0];
	if ( ($n ne "Node") && ($n >= $min_node) && ($n <= $max_node) ) {
	    $caches{$vals[0]}[16][$s]=$vals[1]; # pDorm
	    $caches{$vals[0]}[17][$s]=$vals[2]; # pCold
	    $caches{$vals[0]}[18][$s]=$vals[3]; # pNorm
	    $caches{$vals[0]}[19][$s]=$vals[4]; # pWarm
	    $caches{$vals[0]}[20][$s]=$vals[5]; # pHot
	    $caches{$vals[0]}[21][$s]=$vals[6]; # pDest
	    $caches{$vals[0]}[22][$s]=$vals[7]; # pRead
	    $caches{$vals[0]}[23][$s]=$vals[8]; # pFlush
	    $caches{$vals[0]}[24][$s]=$vals[9]; # pWrtBack

	    $pfcdorm_sum+=$vals[1];
	    $pfccold_sum+=$vals[2];
	    $pfcnorm_sum+=$vals[3];
	    $pfcwarm_sum+=$vals[4];
	    $pfchot_sum+=$vals[5];
	    $pfcdest_sum+=$vals[6];
	    $pfcread_sum+=$vals[7];
	    $pfcflush_sum+=$vals[8];
	    $pfcwrtback_sum+=$vals[9];
	}
    }
}

sub cachestats_process {
	@cacheStats=("rAcc","rCMPHitPer","rFCHitPer","wAcc","wCMPHitPer","wFCHitPer","rbAcc","rbIos","rbMbs","rbClean","rbDirty","dwAcc","dwIos","dwMbs","dwClean","dwDirty","pDorm","pCold","pNorm","pWarm","pHot","pDestage","pRead","pFlush","pWrtBack");
	printf "\n";
	printf "********THE BELOW OUTPUT IS FROM 'cachestat.txt'********\nObtained by using the command 'statcache -iter <iterations> -d <duration>'\n\n";
	printf "The following keywords are used in the output:\n
			FC-rAcc: FlashCache-Read-Accesses:  Number of CMPs and FMPs accessed by Write I/Os
			FC-rCMPHitPer: FlashCache-Read-CMP-Hit Percentage: (DRAM data memory) hits divided by accesses displayed in percentage
			FC-rFCHitPer: FlashCache-Read-FMP-Hit Percentage: Flash cache hits divided accesses displayed in percentage
			FC-wAcc: FlashCache-Write-Accesses: Number of CMPs and FMPs accessed by Write I/Os
			FC-wCMPHitPer: FlashCache-Write-CMP-Hit Percentage: (DRAM data memory) hits divided by accesses displayed in percentage
			FC-wFCHitPer: FlashCache-Write-FMP-Hit Percentage: Flash cache hits divided accesses displayed in percentage\n
			**Internal Flashcache Activity**
			FC-rbAcc: FlashCache-ReadBack-Accesses: On flash cache hits data is read from flash cache back into DRAM
			FC-rbIos: FlashCache-ReadBack-I/Os
			FC-rbMbs: FlashCache-ReadBack-MB-per second
			FC-rbClean: FlashCache-ReadBack-Total-Accesses: Cumulative Accesses since statcache command was invoked
			FC-rbDirty: FlashCache-ReadBack-Total-I/Os: Cumulative result since statcache command was invoked
			FC-dwAcc: FlashCache-Destaged Write-Accesses: Writes from DRAM to flash cache, done to free up space in DRAM and populate flash cache
			FC-dwIos: FlashCache-Destaged Write-I/Os
			FC-dwMbs: FlashCache-Destaged Write-MB-per second
			FC-dwClean: FlashCache-Destaged Write-Total-Accesses: Cumulative Accesses since statcache command was invoked
			FC-dwDirty: FlashCache-Destaged Write-Total-I/Os: Cumulative result since statcache command was invoked\n
			**FMP Queue Statistics**
			FC-pDorm: FlashCache-Dormant: Upon destaging from DRAM, FMPs are allocated from this LRU
			FC-pCold: FlashCache-Cold: Number of clean cache pages (valid data on page)
			FC-pNorm: FlashCache-Norm: FMPs are initially put on this LRU after being destaged from DRAM
			FC-pWarm: FlashCache-Warm: FMPs from Norm are promoted to Warm when they get hit once
			FC-pHot: FlashCache-Hot: FMPs from Warm are promoted to Hot when they get hit again and stay here on subsequent hits
			FC-pDestage: FlashCache-Destage: Number of FMPs currently being destaged from DRAM to flash cache
			FC-pRead: FlashCache-Read: Number of FMPs currently being read from flash cache into DRAM
			FC-pFlush: FlashCache-Flush: Number of FMPs with dirty write data that are being flushed from DRAM to flash cache
			FC-pWrtBack: FlashCache-WriteBack: Number of FMPs with dirty data being written from flash cache to backend disks\n\n";
	printf "The Output is formatted as follows:\n";
	for ($i=0; $i<=$#cacheStats; $i++) {
		printf "FC-${cacheStats[$i]}-<node_no>,<value1_iter1>,<value2_iter2>,<value3_iter3>,...,<value(n)_iter(n)>,\n";
	}
	printf "\n";
	printf "*********************************************************\n";
	printf "\n";
    $nodecnt=0; foreach $i (@nodes_flag) { if ($i == 1) {$nodecnt++;} }
    if (($cmcnt > 0) && ($csv == 1) ) {  

	# print all cmp stats
	for ($i=0; $i<=$#cacheStats; $i++) {
	    printf "$date[0],";
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		printf "%s,",$tod[$s];
	    }
	    printf "\n";
	    foreach $node (sort keys %caches) {
		printf "FC-$cacheStats[$i]-n$node,";
		for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		    $val=0;
		    if ((defined $caches{$node}[$i][$s]) && ($caches{$node}[$i][$s] > 0)) { $val=$caches{$node}[$i][$s] }
		    printf "%d,",$val;
		}
		printf "\n";	
	    }
	    printf "\n\n";
	}
    }
}

sub cachevstats_init {
    #Get flash cache stats per virtual volume
    #rcmacc = cm read access, rcmhit =cm read hit percent, rfchit =flash cache read hit percent, rtotalhit_sum =cm and flash cache read hit percent
    #wcmacc = cm write access, wcmhit = cm write hit percent, wfchit =flash cache write hit percent, wtotalhit_sum =cm and flash cache write hit percent
    #rbacc = read back accesses
    #dwacc = destage write accesses
    $flag=$cmcnt=$state=0; 
    $rcmacc_sum=$rcmhit_sum=$rfchit_sum=$rtotalhit_sum=0;
    $wcmacc_sum=$wcmhit_sum=$wfchit_sum=$wtotalhit_sum=0; 
    $rbacc_sum=0;
    $dwacc_sum=0;
    $num_samples=0;$s=-1;
    %vvcaches=(); # initialize empty hash to be populated with flash vv cache stats later, hash of array of arrays
}

sub cachevstats_gather {
    chomp;
    if ( ( index($_,"Current") > 0 ) && ( (index($_,"/") > 0 ) ) ) { 
	$flag=0;
	$num_samples+=1;
	($thetod,$thedate) = split; 
	if ($dates_used == 1) { if ( ($thetod gt $tstart) && ($thetod lt $tstop) ) { $flag=1; } }
	if ($skip_used == 1) { if (($num_samples > $num_to_skip) && ($num_samples <= ($num_to_skip+$num_to_process))) {$flag=1;} }
	if ($flag == 1) { $cmcnt++; $s++; $date[$s]=$thedate; $tod[$s]=$thetod; }
    }
    @vals=split;
    # Determine in which of the four "blocks" we are in
    if ( ($_ ne "") && ($flag == 1) && ( index($_,"Current") > 0 ) && ( index($_,"/") > 0 ) ) { $state=1 };
    if ( ($_ ne "") && ($flag == 1) && ($vals[1] eq "Internal") && ($vals[2] eq "Flashcache") ) { $state=2 };

    # Now work through the different cases for each "state"
    if ( ($_ ne "") && ($flag == 1) && ($state == 1) && ($vals[2] eq "Read" || $vals[2] eq "Write") ) {
	    # Check node ID is already in the hash. If not create an entry for it
	    if ( ! exists $vvcaches{"$vals[1]"}) {
		# %caches{node}=("rAcc","rCMPHitPer","rFCHitPer","rtotalHitPer","wAcc","wCMPHitPer","wFCHitPer","wtotalHitPer","rbAcc","dwAcc")
		$vvcaches{$vals[1]}=[[],[],[],[],[],[],[],[],[],[]];
	    }
	    if ($vals[2] eq "Read") { 
		$rcmacc_sum+=$vals[3]; 
		$rcmhit_sum+=$vals[4]; 
		$rfchit_sum+=$vals[5];
        $rtotalhit_sum+=$vals[6];
		#$rcmcnt_sum+=1; 

		$vvcaches{$vals[1]}[0][$s]=$vals[3]; # rACC
		$vvcaches{$vals[1]}[1][$s]=$vals[4]; # rCMPHitPer
		$vvcaches{$vals[1]}[2][$s]=$vals[5]; # rFCHitPer
		$vvcaches{$vals[1]}[3][$s]=$vals[6]; # rtotalHitPer
	    } 
	    if ($vals[2] eq "Write") { 
		$wcmacc_sum+=$vals[3]; 
		$wcmhit_sum+=$vals[4]; 
		$wfchit_sum+=$vals[5];
		$wtotalhit_sum+=$vals[6];
		#$wcmcnt_sum+=1; 

		$vvcaches{$vals[1]}[4][$s]=$vals[3]; # wAcc
		$vvcaches{$vals[1]}[5][$s]=$vals[4]; # wCMPHitPer
		$vvcaches{$vals[1]}[6][$s]=$vals[5]; # wFCHitPer
		$vvcaches{$vals[1]}[7][$s]=$vals[6]; # wtotalHitPer
	    } 
    }
    if ( ($_ ne "") && ($flag == 1) && ($state == 2) && ($vals[2] eq "Read" || $vals[2] eq "Destaged") ) {
	    if ( $vals[2] eq "Read" ) {
		$vvcaches{$vals[1]}[8][$s]=$vals[4]; # rbAcc

		$rbacc_sum+=$vals[4];
	    }
	    if ( $vals[2] eq "Destaged" ) {
		$vvcaches{$vals[1]}[9][$s]=$vals[4]; # dwAcc

		$dwacc_sum+=$vals[4];
	    }
    }
}

sub cachevstats_process {
    if (($cmcnt > 0) && ($csv == 1) ) {  

	# print all cmp stats
	@cacheStats=("rAcc","rCMPHitPer","rFCHitPer","rtotalHitPer","wAcc","wCMPHitPer","wFCHitPer","wtotalHitPer","rbAcc","dwAcc");
	printf "\n";
	printf "********THE BELOW OUTPUT IS FROM 'cachevstat.txt'********\nObtained by using the command 'statcache -v -iter <iterations> -d <duration>'\n\n";
	printf "The following keywords are used in the output:\n
			FC-rAcc: FlashCache-Read-Accesses:  Number of CMPs and FMPs accessed by Write I/Os
			FC-rCMPHitPer: FlashCache-Read-CMP-Hit Percentage: (DRAM data memory) hits divided by accesses displayed in percentage
			FC-rFCHitPer: FlashCache-Read-FMP-Hit Percentage: Flash cache hits divided accesses displayed in percentage
			FC-rtotalHitPer: FlashCache-Read-Total Hit Percentage
			FC-wAcc: FlashCache-Write-Accesses: Number of CMPs and FMPs accessed by Write I/Os
			FC-wCMPHitPer: FlashCache-Write-CMP-Hit Percentage: (DRAM data memory) hits divided by accesses displayed in percentage
			FC-wFCHitPer: FlashCache-Write-FMP-Hit Percentage: Flash cache hits divided accesses displayed in percentage		
			FC-wtotalHitPer: FlashCache-Write-Total Hit Percentage\n
			**Internal Flashcache Activity**
			FC-rbAcc: FlashCache-ReadBack-Accesses: On flash cache hits data is read from flash cache back into DRAM
			FC-dwAcc: FlashCache-Destaged Write-Accesses: Writes from DRAM to flash cache, done to free up space in DRAM and populate flash cache\n\n";
	printf "The Output is formatted as follows:\n";
	for ($i=0; $i<=$#cacheStats; $i++) {
		printf "FC-${cacheStats[$i]}-<node_no>-<VV_name>,<value1_iter1>,<value2_iter2>,<value3_iter3>,...,<value(n)_iter(n)>,\n";
	}
	printf "\n";
	printf "*********************************************************\n";
	printf "\n";
	for ($i=0; $i<=$#cacheStats; $i++) {
	    printf "$date[0],";
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		printf "%s,",$tod[$s];
	    }
	    printf "\n";
	    foreach $vv (sort keys %vvcaches) {
		printf "FC-$cacheStats[$i]-$vv,";
		for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		    $val=0;
		    if ((defined $vvcaches{$vv}[$i][$s]) && ($vvcaches{$vv}[$i][$s] > 0)) { $val=$vvcaches{$vv}[$i][$s] }
		    printf "%d,",$val;
		}
		printf "\n";	
	    }
	    printf "\n\n";
	}
    }
}

sub dpstats_init {
    #Get Disk Port stats
    #rios = read io/s, rkbs = read kb/s
    #rmulrt = multiply read response time by read io/s, rmulxs = multiply read xfer size (IOSz) by read io/s
    #wios = write io/s, wkbs = write kb/s
    #wmulrt = multiply write response time by write io/s, wmulxs = multiply write write xfer size (IOSz) write io/s
    $flag=$dcnt=0;
    $rios_sum=$rkbs_sum=$rmulrt_sum=$rmulxs_sum=0; 
    $wios_sum=$wkbs_sum=$wmulrt_sum=$wmulxs_sum=0;
    $num_samples=0;$s=-1;
    for $i ($min_node..$max_node) { $nodes_flag[$i]=0; } 
    %dps=(); # initialize empty hash to be populated with disk port stats later, hash of array of arrays
}

sub dpstats_gather {
    chomp;
    if (index($_,"KBytes") >= 0) { 
	$flag=0;
	$num_samples+=1;
	($thetod,$thedate) = split; 
	if ($dates_used == 1) { if ( ($thetod gt $tstart) && ($thetod lt $tstop) ) { $flag=1; } }
	if ($skip_used == 1) { if (($num_samples > $num_to_skip) && ($num_samples <= ($num_to_skip+$num_to_process))) {$flag=1;} }
	if ($flag == 1) { $dcnt++; $s++; $date[$s]=$thedate; $tod[$s]=$thetod; }
    }
    if  ( index($_,"----------") >= 0)   { $flag=0; }
    if ( ($flag == 1) && (index($_,"Data") > 0) )  {
	@vals=split;
	$n=substr($vals[0],0,1);
	if ( ( $n >= $min_node) && ($n <= $max_node) )  {
	    $nodes_flag[$n]=1;
	    # Check if the name of the disk port is already in the hash, if not create an entry for it
	    if ( ! exists $dps{"$vals[0]"}) {
		# %dps{port}=(DRio/s DRkb/s DRrt DRxs DWio/s DWkb/s DWrt DWxs DQlen)
		$hps{$vals[0]}=[[],[],[],[],[],[],[],[],[]];
	    }
	    if ($vals[2] eq "r") {  
		$rios_sum+=$vals[3];
		$rkbs_sum+=$vals[6];
		$rmulrt_sum+=$vals[9]*$vals[3];
		$rmulxs_sum+=$vals[11]*$vals[3];

		$dps{$vals[0]}[0][$s]=$vals[3];
		$dps{$vals[0]}[1][$s]=$vals[6];
		$dps{$vals[0]}[2][$s]=$vals[9];
		$dps{$vals[0]}[3][$s]=$vals[11];
	    } 
	    if ($vals[2] eq "w") {  
		$wios_sum+=$vals[3];
		$wkbs_sum+=$vals[6];
		$wmulrt_sum+=$vals[9]*$vals[3];
		$wmulxs_sum+=$vals[11]*$vals[3];

		$dps{$vals[0]}[4][$s]=$vals[3];
		$dps{$vals[0]}[5][$s]=$vals[6];
		$dps{$vals[0]}[6][$s]=$vals[9];
		$dps{$vals[0]}[7][$s]=$vals[11];
	    } 
	    if ($vals[2] eq "t") {
		$dps{$vals[0]}[8][$s]=$vals[13];
	    }
	} 
    }
}

sub dpstats_process {
    #rrt = average read response time in ms, rxs = average read xfer size (IOSz)
    #wrt = average write response time in ms, wxs = average write xfer size (IOSz)
    @dpStats=("DP-Rio/s","DP-Rkb/s","DP-Rrt","DP-Rxs","DP-Wio/s","DP-Wkb/s","DP-Wrt","DP-Wxs","DP-Qlen");
    $nodecnt=0; foreach $i (@nodes_flag) { if ($i == 1) {$nodecnt++;} }
    if (($dcnt > 0) && ($summ == 1)) {
	printf "DP %dn: DRio/s DRkb/s DRrt DRxs DWio/s DWkb/s DWrt DWxs\n",$nodecnt; #'D' Disk,'R' Reads,'W' Writes
	$rrt=$rxs=$wrt=$wxs=0;
	if ($rios_sum > 0) { $rrt=$rmulrt_sum/$rios_sum; $rxs=$rmulxs_sum/$rios_sum };
	if ($wios_sum > 0) { $wrt=$wmulrt_sum/$wios_sum; $wxs=$wmulxs_sum/$wios_sum };
	printf "DP %dn: %d %d %.1f  %.1f  %d  %d  %.1f  %.1f\n",
	$nodecnt,$rios_sum/$dcnt,$rkbs_sum/$dcnt,$rrt,$rxs,$wios_sum/$dcnt,$wkbs_sum/$dcnt,$wrt,$wxs; 
	printf "\n";
    }
    if (($dcnt > 0) && ($csv == 1)) {
    printf "\n";
	printf "********THE BELOW OUTPUT IS FROM 'pdstat.txt'********\nObtained by using the command 'statpd -iter <iterations> -d <duration> -ni -rw'\n\n";
	printf "The following keywords are used in the output:\n
			DP-Rio/s: Physical-Disks-Read I/Os per second
			DP-Rio/s-sum: Sum of Physical-Disks-Read I/Os per second
			DP-Rkb/s: Physical-Disks-Read KB per second
			DP-Rkb/s-sum: Sum of Physical-Disks-Read KB per second
			DP-Rrt: Physical-Disks-Read-Svt (ms): Service Time + Waiting Time in ms
			DP-Rrt-avg: Average of Physical-Disks-Read-Svt (ms): Service Time + Waiting Time in ms
			DP-Rxs: Physical-Disks-Read-IOSz (KB): The current I/O size in KB
			DP-Rxs-avg: Average of Physical-Disks-Read-IOSz (KB): The current I/O size in KB
			DP-Wio/s: Physical-Disks-Write I/Os per second
			DP-Wio/s-sum: Sum of Physical-Disks-Write I/Os per second
			DP-Wkb/s: Physical-Disks-Write KB per second
			DP-Wkb/s-sum: Sum of Physical-Disks-Write KB per second
			DP-Wrt: Physical-Disks-Write-Svt (ms): Service Time + Waiting Time in ms
			DP-Wrt-avg: Average of Physical-Disks-Write-Svt (ms): Service Time + Waiting Time in ms
			DP-Wxs: Physical-Disks-Write-IOSz (KB): The current I/O size in KB
			DP-Wxs-avg: Average of Physical-Disks-Write-IOSz (KB): The current I/O size in KB
			DP-Qlen: Physical-Disks-Write-Queue length
			DP-Qlen-sum: Sum of Physical-Disks-Write-Queue length\n\n";
	printf "The Output is formatted as follows:\n";
	for ($i=0; $i<=$#dpStats; $i++) {
		printf "${dpStats[$i]}-<node>:<slot>:<port>,<value1_iter1>,<value2_iter2>,<value3_iter3>,...,<value(n)_iter(n)>,\n";
	}
	printf "\n";
	printf "*********************************************************\n";
	printf "\n";
	# Print all host port stats
	for ($i=0; $i<=$#dpStats; $i++) {
	    printf "$date[0],";
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		printf "%s,",$tod[$s];
	    }
	    printf "\n";
	    foreach $dp (sort keys %dps) {
		printf "${dpStats[$i]}-$dp,";
		for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		    $val=0;
		    if ((defined $dps{$dp}[$i][$s]) && ($dps{$dp}[$i] > 0)) { $val=$dps{$dp}[$i][$s] }
		    printf "%.1f,",$val;
		}
		printf "\n";	
	    }
	    # Print total at the end
	    if ( ( ${dpStats[$i]} =~ "rt") ||
		 ( ${dpStats[$i]} =~ "xs") ) {
		printf "${dpStats[$i]}-avg,";
	    }
	    else {
		printf "${dpStats[$i]}-sum,";
	    }
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		$sum=0;
		$nonZero=0;
		foreach $dp (sort keys %dps) {
		    if ((defined $dps{$dp}[$i][$s]) && ($dps{$dp}[$i][$s] != 0) ) { ++$nonZero; }
		    else { $dps{$dp}[$i][$s] = 0 }
		    $sum+=$dps{$dp}[$i][$s];
		}
		if ( ( ${dpStats[$i]} =~ "rt") ||
		     ( ${dpStats[$i]} =~ "xs") ) {
		    if ( $nonZero > 0 ) { $sum=$sum/$nonZero; }
		}
		printf "%.1f,",$sum;
	    }
	    printf "\n";

	    printf "\n\n";
	}
    }
}

sub vlstats_init {
    #Get Vlun stats
    #rios = read io/s, rkbs = read kb/s
    #rmulrt = multiply read response time by read io/s, rmulxs = multiply read xfer size (IOSz) by read io/s
    #wios = write io/s, wkbs = write kb/s
    #wmulrt = multiply write response time by write io/s, wmulxs = multiply write write xfer size (IOSz) write io/s
    $flag=$vlcnt=$qlen_sum=0;
    $rios_sum=$rkbs_sum=$rmulrt_sum=$rmulxs_sum=0; 
    $wios_sum=$wkbs_sum=$wmulrt_sum=$wmulxs_sum=0; 
    $num_samples=0;$s=-1;
    for $i ($min_node..$max_node) { $nodes_flag[$i]=0; }
    %vls=(); # initialize empty hash to be populated with VLUN stats, hash of array of arrays
}

sub vlstats_gather {
    chomp;
    if (index($_,"KBytes") >= 0) { 
	$flag=0;
	$num_samples+=1;
	($thetod,$thedate) = split; 
	if ($dates_used == 1) { if ( ($thetod gt $tstart) && ($thetod lt $tstop) ) { $flag=1; } }
	if ($skip_used == 1) { if (($num_samples > $num_to_skip) && ($num_samples <= ($num_to_skip+$num_to_process))) {$flag=1;} }
	if ($flag == 1) { $vlcnt++; $s++; $date[$s]=$thedate; $tod[$s]=$thetod; }
    }
    if  ( index($_,"----------") >= 0) { $flag=0; }
    @vals=split;
    if ( ($flag == 1) && ($vals[4] eq "r" || $vals[4] eq "w" || $vals[4] eq "t") )  {
	$n=substr($vals[3],0,1);
	if ( ( $n >= $min_node) && ($n <= $max_node) )  {
	    $nodes_flag[$n]=1;
	    # Check if the name of the VLUN is already in the hash, if not create an entry for it
	    if ( ! exists $vls{"$vals[0]"}) {
		# %vls{vlname}=(VRio/s VRkb/s VRrt VRxs VWio/s VWkb/s VWrt VWxs VQlen)
		$vls{$vals[0]}=[[],[],[],[],[],[],[],[],[]];
	    }
	    if ($vals[4] eq "r") {  
		$rios_sum+=$vals[5];
		$rkbs_sum+=$vals[8];
		$rmulrt_sum+=$vals[11]*$vals[5];
		$rmulxs_sum+=$vals[13]*$vals[5];

		$vls{$vals[0]}[0][$s]=$vals[5];
		$vls{$vals[0]}[1][$s]=$vals[8];
		$vls{$vals[0]}[2][$s]=$vals[11];
		$vls{$vals[0]}[3][$s]=$vals[13];
	    } 
	    if ($vals[4] eq "w") {  
		$wios_sum+=$vals[5];
		$wkbs_sum+=$vals[8];
		$wmulrt_sum+=$vals[11]*$vals[5];
		$wmulxs_sum+=$vals[13]*$vals[5];

		$vls{$vals[0]}[4][$s]=$vals[5];
		$vls{$vals[0]}[5][$s]=$vals[8];
		$vls{$vals[0]}[6][$s]=$vals[11];
		$vls{$vals[0]}[7][$s]=$vals[13];
	    } 
	    if ($vals[4] eq "t") {  
		$qlen_sum+=$vals[15];
		$vls{$vals[0]}[8][$s]=$vals[15];
	    }
	} 
    }
}

sub vlstats_process {
    #rrt = average read response time in ms, rxs = average read xfer size (IOSz)
    #wrt = average write response time in ms, wxs = average write xfer size (IOSz)
    $nodecnt=0; foreach $i (@nodes_flag) { if ($i == 1) {$nodecnt++;} }
    if (($vlcnt > 0) && ($csv == 0)) {
	printf "VL %dn:  VRio/s VRkb/s VRrt VRxs VWio/s VWkb/s VWrt VWxs VQlen\n",$nodecnt; #'V' Vluns, 'R' Reads, 'W' Writes
	$rrt=$rxs=$wrt=$wxs=0;
	if ($rios_sum > 0) { $rrt=$rmulrt_sum/$rios_sum; $rxs=$rmulxs_sum/$rios_sum };
	if ($wios_sum > 0) { $wrt=$wmulrt_sum/$wios_sum; $wxs=$wmulxs_sum/$wios_sum };
	printf "VL %dn: %d %d %.1f  %.1f  %d  %d  %.1f  %.1f  %.1f\n",
	$nodecnt,$rios_sum/$vlcnt,$rkbs_sum/$vlcnt,$rrt,$rxs,$wios_sum/$vlcnt,$wkbs_sum/$vlcnt,$wrt,$wxs,$qlen_sum/$vlcnt; 
	printf "\n";
    }
    if (($vlcnt > 0) && ($csv == 1)) {
	# Print VLUN stats
	@vlStats=("VL-Rio/s","VL-Rkb/s","VL-Rrt","VL-Rxs","VL-Wio/s","VL-Wkb/s","VL-Wrt","VL-Wxs","VL-Qlen");
	printf "\n";
	printf "********THE BELOW OUTPUT IS FROM 'vlunstat.txt'********\nObtained by using the command 'statvlun -iter <iterations> -d <duration> -ni -rw'\n\n";
	printf "The following keywords are used in the output:\n
			VL-Rio/s: VLUN-Read-I/Os per second
			VL-Rio/s-sum: Sum of VLUN-Read-I/Os per second
			VL-Rkb/s: VLUN-Read-KBs per second 
			VL-Rkb/s-sum: Sum of VLUN-Read-KBs per second 
			VL-Rrt: VLUN-Read-Svt (ms): Service Time (milliseconds)
			VL-Rrt-avg: Average of VLUN-Read-Svt (ms): Service Time (milliseconds)
			VL-Rxs: VLUN-Read-IOSz (KB): I/O size in KB
			VL-Rxs-avg: Average of VLUN-Read-IOSz (KB): I/O size in KB
			VL-Wio/s: VLUN-Read-I/Os per second
			VL-Wio/s-sum: Sum of VLUN-Read-I/Os per second
			VL-Wkb/s: VLUN-Read-KBs per second
			VL-Wkb/s-sum: Sum of VLUN-Read-KBs per second
			VL-Wrt: VLUN-Read-Svt (ms): Service Time (milliseconds)
			VL-Wrt-avg: Average of VLUN-Read-Svt (ms): Service Time (milliseconds)
			VL-Wxs: VLUN-Read-IOSz (KB): I/O size in KB
			VL-Wxs-avg: Average of VLUN-Read-IOSz (KB): I/O size in KB
			VL-Qlen: VLUN-Write-Queue Length
			VL-Qlen-sum: Sum of VLUN-Write-Queue Length\n\n";
	printf "The Output is formatted as follows:\n";
	for ($i=0; $i<=$#vlStats; $i++) {
		printf "${vlStats[$i]}-<LUN_ID>,<value1_iter1>,<value2_iter2>,<value3_iter3>,...,<value(n)_iter(n)>,\n";
	}
	printf "\n";
	printf "*********************************************************\n";
	printf "\n";
	for ($i=0; $i<=$#vlStats; $i++) {
	    printf "$date[0],";
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		printf "%s,",$tod[$s];
	    }
	    printf "\n";
	    foreach $vl (sort keys %vls) {
		printf "${vlStats[$i]}-$vl,";
		for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		    $val=0;
		    if ((defined $vls{$vl}[$i][$s]) && ($vls{$vl}[$i] > 0)) { $val=$vls{$vl}[$i][$s] }
		    printf "%.1f,",$val;
		}
		printf "\n";	
	    }
	    # Print total at the end
	    if ( ( ${vlStats[$i]} =~ "rt") ||
		 ( ${vlStats[$i]} =~ "xs") ) {
		printf "${vlStats[$i]}-avg,";
	    }
	    else {
		printf "${vlStats[$i]}-sum,";
	    }
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		$sum=0;
		$nonZero=0;
		foreach $vl (sort keys %vls) {
		    if ((defined $vls{$vl}[$i][$s]) && ($vls{$vl}[$i][$s] != 0) ) { ++$nonZero; }
		    else { $vls{$vl}[$i][$s] = 0 }
		    $sum+=$vls{$vl}[$i][$s];
		}
		if ( ( ${vlStats[$i]} =~ "rt") ||
		     ( ${vlStats[$i]} =~ "xs") ) {
		    if ( $nonZero > 0 ) { $sum=$sum/$nonZero; }
		}
		printf "%.1f,",$sum;
	    }
	    printf "\n";

	    printf "\n\n";
	}
    }
}

sub vvstats_init {
    #Get VV stats
    #rios = read io/s, rkbs = read kb/s
    #rmulrt = multiply read response time by read io/s, rmulxs = multiply read xfer size (IOSz) by read io/s
    #wios = write io/s, wkbs = write kb/s
    #wmulrt = multiply write response time by write io/s, wmulxs = multiply write write xfer size (IOSz) write io/s
    $flag=$vvcnt=$qlen_sum=0;
    $rios_sum=$rkbs_sum=$rmulrt_sum=$rmulxs_sum=0; 
    $wios_sum=$wkbs_sum=$wmulrt_sum=$wmulxs_sum=0; 
    $num_samples=0;$s=-1;
    for $i ($min_node..$max_node) { $nodes_flag[$i]=0; }
    %vvs=(); # initialize empty hash to be populated with VV stats, hash of arrays of arrays
}

sub vvstats_gather {
    chomp;
    if (index($_,"KBytes") >= 0) { 
	$flag=0;
	$num_samples+=1;
	($thetod,$thedate) = split; 
	if ($dates_used == 1) { if ( ($thetod gt $tstart) && ($thetod lt $tstop) ) { $flag=1; } }
	if ($skip_used == 1) { if (($num_samples > $num_to_skip) && ($num_samples <= ($num_to_skip+$num_to_process))) {$flag=1;} }
	if ($flag == 1) { $vvcnt++; $s++; $date[$s]=$thedate; $tod[$s]=$thetod; }
    }

    if  ( index($_,"----------") >= 0) { $flag=0; }
    @vals=split(' ', $_);
    if ( ($flag == 1) && ($vals[1] eq "r" || $vals[1] eq "w" || $vals[1] eq "t") )  {
	# Check if the name of the VV is already in the hash, if not create an entry for it
	if ( ! exists $vvs{"$vals[0]"}) {
	    # %vvs{vvname}=(VRio/s VRkb/s VRrt VRxs VWio/s VWkb/s VWrt VWxs VQlen)
	    $vvs{$vals[0]}=[[],[],[],[],[],[],[],[],[]];
	}
	if ($vals[1] eq "r") {
	    $rios_sum+=$vals[2];
	    $rkbs_sum+=$vals[5];
	    $rmulrt_sum+=$vals[8]*$vals[2];
	    $rmulxs_sum+=$vals[10]*$vals[2];

	    $vvs{$vals[0]}[0][$s]=$vals[2];
	    $vvs{$vals[0]}[1][$s]=$vals[5];
	    $vvs{$vals[0]}[2][$s]=$vals[8];
	    $vvs{$vals[0]}[3][$s]=$vals[10];
	} 
	if ($vals[1] eq "w") {  
	    $wios_sum+=$vals[2];
	    $wkbs_sum+=$vals[5];
	    $wmulrt_sum+=$vals[8]*$vals[2];
	    $wmulxs_sum+=$vals[10]*$vals[2];

	    $vvs{$vals[0]}[4][$s]=$vals[2];
	    $vvs{$vals[0]}[5][$s]=$vals[5];
	    $vvs{$vals[0]}[6][$s]=$vals[8];
	    $vvs{$vals[0]}[7][$s]=$vals[10];

	} 
	if ($vals[1] eq "t") {  
	    $qlen_sum+=$vals[12];
	    $vvs{$vals[0]}[8][$s]=$vals[12];
	}
    }
}

sub vvstats_process {
    #rrt = average read response time in ms, rxs = average read xfer size (IOSz)
    #wrt = average write response time in ms, wxs = average write xfer size (IOSz)
    #$nodecnt=0; foreach $i (@nodes_flag) { if ($i == 1) {$nodecnt++;} }
    $nodecnt=2; #hardcoded for now. Memo did it on March 13, 2013
    if (($vvcnt > 0) && ($summ == 1)) {
	printf "VV %dn:  VRio/s VRkb/s VRrt VRxs VWio/s VWkb/s VWrt VWxs VQlen\n",$nodecnt; #'V' VVs, 'R' Reads, 'W' Writes
	$rrt=$rxs=$wrt=$wxs=0;
	if ($rios_sum > 0) { $rrt=$rmulrt_sum/$rios_sum; $rxs=$rmulxs_sum/$rios_sum };
	if ($wios_sum > 0) { $wrt=$wmulrt_sum/$wios_sum; $wxs=$wmulxs_sum/$wios_sum };
	printf "VV %dn: %d %d %.1f  %.1f  %d  %d  %.1f  %.1f  %.1f\n",
	$nodecnt,$rios_sum/$vvcnt,$rkbs_sum/$vvcnt,$rrt,$rxs,$wios_sum/$vvcnt,$wkbs_sum/$vvcnt,$wrt,$wxs,$qlen_sum/$vvcnt; 
	printf "\n";
    }
    if (($vvcnt > 0) && ($csv == 1)) {
	# Print VV stats
	@vvStats=("VV-Rio/s","VV-Rkb/s","VV-Rrt","VV-Rxs","VV-Wio/s","VV-Wkb/s","VV-Wrt","VV-Wxs","VV-Qlen");
	printf "\n";
	printf "********THE BELOW OUTPUT IS FROM 'vlunstat.txt'********\nObtained by using the command 'statvlun -iter <iterations> -d <duration> -ni -rw'\n\n";
	printf "The following keywords are used in the output:\n
			VV-Rio/s: VirtualVolume-Read-I/Os per second
			VV-Rio/s-sum: Sum of VirtualVolume-Read-I/Os per second
			VV-Rkb/s: VirtualVolume-Read-KBs per second
			VV-Rkb/s-sum: Sum of VirtualVolume-Read-KBs per second
			VV-Rrt: VirtualVolume-Read-Svt (ms): Service Time in ms
			VV-Rrt-avg: Average of VirtualVolume-Read-Svt (ms): Service Time in ms
			VV-Rxs: VirtualVolume-Read-IOSz (KB): Size of I/Os done in KB
			VV-Rxs-avg: Average of VirtualVolume-Read-IOSz (KB): Size of I/Os done in KB
			VV-Wio/s: VirtullVolume-Write-I/Os per second
			VV-Wio/s-sum: Sum of VirtullVolume-Write-I/Os per second
			VV-Wkb/s: VirtualVolume-Write-KBs per second
			VV-Wkb/s-sum: Sum of VirtualVolume-Write-KBs per second
			VV-Wrt: VirtualVolume-Write-Svt (ms): Service Time in ms
			VV-Wrt-avg: Average of VirtualVolume-Write-Svt (ms): Service Time in ms
			VV-Wxs: VirtualVolume-Write-IOSz (KB): Size of I/Os done in KB
			VV-Wxs-avg: Average of VirtualVolume-Write-IOSz (KB): Size of I/Os done in KB
			VV-Qlen-sum: Sum of VirtualVolume-Queue Length\n\n";
	printf "The Output is formatted as follows:\n";
	for ($i=0; $i<=$#vvStats; $i++) {
		printf "${vvStats[$i]}-<VV_name>,<value1_iter1>,<value2_iter2>,<value3_iter3>,...,<value(n)_iter(n)>,\n";
	}
	printf "\n";
	printf "*********************************************************\n";
	printf "\n";
	for ($i=0; $i<=$#vvStats; $i++) {
	    printf "$date[0],";
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		printf "%s,",$tod[$s];
	    }
	    printf "\n";
	    foreach $vv (sort keys %vvs) {
		printf "${vvStats[$i]}-$vv,";
		for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		    $val=0;
		    if ((defined $vvs{$vv}[$i][$s]) && ($vvs{$vv}[$i] > 0)) { $val=$vvs{$vv}[$i][$s] }
		    printf "%.1f,",$val;
		}
		printf "\n";	
	    }
	    # Print total at the end
	    if ( ( ${vvStats[$i]} =~ "rt") ||
		 ( ${vvStats[$i]} =~ "xs") ) {
		printf "${vvStats[$i]}-avg,";
	    }
	    else {
		printf "${vvStats[$i]}-sum,";
	    }
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		$sum=0;
		$nonZero=0;
		foreach $vv (sort keys %vvs) {
		    if ((defined $vvs{$vv}[$i][$s]) && ($vvs{$vv}[$i][$s] != 0) ) { ++$nonZero; }
		    else { $vvs{$vv}[$i][$s] = 0 }
		    $sum+=$vvs{$vv}[$i][$s];
		}
		if ( ( ${vvStats[$i]} =~ "rt") ||
		     ( ${vvStats[$i]} =~ "xs") ) {
		    if ( $nonZero > 0 ) { $sum=$sum/$nonZero; }
		}
		printf "%.1f,",$sum;
	    }
	    printf "\n";

	    printf "\n\n";
	}
    }
}

sub pdstats_init {
    #Get PD stats
    #rios = read io/s, rkbs = read kb/s
    #rmulrt = multiply read response time by read io/s, rmulxs = multiply read xfer size (IOSz) by read io/s
    #wios = write io/s, wkbs = write kb/s
    #wmulrt = multiply write response time by write io/s, wmulxs = multiply write write xfer size (IOSz) write io/s
    $pdcnt=$num_pds_sum=$qlen_sum=$idle_sum=0;
    $rios_sum=$rkbs_sum=$rmulrt_sum=$rmulxs_sum=0; 
    $wios_sum=$wkbs_sum=$wmulrt_sum=$wmulxs_sum=0; 
    $flag=$num_samples=0;$s=-1;
    for $i ($min_node..$max_node) { $nodes_flag[$i]=0; }
    %pds=(); # initialize empty hash to be populated with PD stats, hash of arrays of arrays
}

sub pdstats_gather {
    chomp;
    if (index($_,"KBytes") >= 0) { 
	$flag=0;
	$num_samples+=1;
	($thetod,$thedate) = split; 
	if ($dates_used == 1) { if ( ($thetod gt $tstart) && ($thetod lt $tstop) ) { $flag=1; } }
	if ($skip_used == 1) { if (($num_samples > $num_to_skip) && ($num_samples <= ($num_to_skip+$num_to_process))) {$flag=1;} }
	if ($flag == 1) { $pdcnt++; $s++; $date[$s]=$thedate; $tod[$s]=$thetod; }
    }
    if  ( index($_,"----------") >= 0)   { $flag=0; }
    @vals=split;
    if ( ($flag == 1) && ($vals[2] eq "r" || $vals[2] eq "w" || $vals[2] eq "t") )  {
	$n=substr($vals[1],0,1);
	if ( ( $n >= $min_node) && ($n <= $max_node) )  {
	    $nodes_flag[$n]=1;
	    # Check if the ID of the PD is already in the hash, if not create an entry for it
	    if ( ! exists $pds{"$vals[0]"}) {
		# %pds{pdId}=(PDRio/s PDRkb/s PDRrt PDRxs PDWio/s PDWkb/s PDWrt PDWxs PDQlen PDidle)
		$pds{$vals[0]}=[[],[],[],[],[],[],[],[],[],[]];
	    }
	    if ($vals[2] eq "r") {  
		$rios_sum+=$vals[3];
		$rkbs_sum+=$vals[6];
		$rmulrt_sum+=$vals[9]*$vals[3];
		$rmulxs_sum+=$vals[11]*$vals[3];

		$pds{$vals[0]}[0][$s]=$vals[3];
		$pds{$vals[0]}[1][$s]=$vals[6];
		$pds{$vals[0]}[2][$s]=$vals[9];
		$pds{$vals[0]}[3][$s]=$vals[11];
	    } 
	    if ($vals[2] eq "w") {  
		$wios_sum+=$vals[3];
		$wkbs_sum+=$vals[6];
		$wmulrt_sum+=$vals[9]*$vals[3];
		$wmulxs_sum+=$vals[11]*$vals[3];

		$pds{$vals[0]}[4][$s]=$vals[3];
		$pds{$vals[0]}[5][$s]=$vals[6];
		$pds{$vals[0]}[6][$s]=$vals[9];
		$pds{$vals[0]}[7][$s]=$vals[11];
	    } 
	    if ($vals[2] eq "t") {  
		$qlen_sum+=$vals[13];
		$idle_sum+=$vals[14];
		$num_pds_sum+=1;

		$pds{$vals[0]}[8][$s]=$vals[13];
		$pds{$vals[0]}[9][$s]=$vals[14];
	    }
	} 
    }
}

sub pdstats_process {
    #rrt = average read response time in ms, rxs = average read xfer size (IOSz)
    #wrt = average write response time in ms, wxs = average write xfer size (IOSz)
    $nodecnt=0; foreach $i (@nodes_flag) { if ($i == 1) {$nodecnt++;} }
    if (($pdcnt > 0) && ($csv == 0)) {
	printf "PD %dn: DRio/s DRkb/s DRrt DRxs DWio/s DWkb/s DWrt DWxs DQlen DIdle DNumPDs\n",$nodecnt; #'D' PDs,'R' Reads,'W' Writes
	$rrt=$rxs=$wrt=$wxs=$qlen_sum=$idle_sum=0;
	if ($rios_sum > 0) { $rrt=$rmulrt_sum/$rios_sum; $rxs=$rmulxs_sum/$rios_sum };
	if ($wios_sum > 0) { $wrt=$wmulrt_sum/$wios_sum; $wxs=$wmulxs_sum/$wios_sum };
	if ($num_pds_sum > 0) { $qlen_sum/=$num_pds_sum; $idle_sum/=$num_pds_sum; };
	printf "PD %dn: %d %d %.1f  %.1f  %d  %d  %.1f  %.1f  %d  %d  %d\n",
	$nodecnt,$rios_sum/$pdcnt,$rkbs_sum/$pdcnt,$rrt,$rxs,$wios_sum/$pdcnt,$wkbs_sum/$pdcnt,$wrt,$wxs,
	$qlen_sum,$idle_sum,$num_pds_sum/$pdcnt; 
	printf "\n";
    }
    if (($pdcnt > 0) && ($csv == 1)) {
    @pdStats=("PD-Rio/s","PD-Rkb/s","PD-Rrt","PD-Rxs","PD-Wio/s","PD-Wkb/s","PD-Wrt","PD-Wxs","PD-Qlen","PD-idle");
    printf "\n";
	printf "********THE BELOW OUTPUT IS FROM 'pdstat.txt'********\nObtained by using the command 'statpd -iter <iterations> -d <duration> -ni -rw'\n\n";
	printf "The following keywords are used in the output:\n
			PD-Rio/s: PhysicalDisk-Read I/Os per secondPD-Rio/s: PhysicalDisk-Read I/Os per second
			PD-Rio/s-sum: Sum of PhysicalDisk-Read I/Os per second
			PD-Rkb/s: PhysicalDisk-Read KBs per second
			PD-Rkb/s-sum: Sum of PhysicalDisk-Read KBs per second
			PD-Rrt: PhysicalDisk-Read Svt ms: Service Time in ms
			PD-Rrt-avg: Average of PhysicalDisk-Read Svt ms: Service Time in ms
			PD-Rxs: PhysicalDisk-Read IOSz KB: I/O size in KB
			PD-Rxs-avg: Average of PhysicalDisk-Read IOSz KB: I/O size in KB
			PD-Wio/s: PhysicalDisk-Write I/Os per second
			PD-Wio/s-sum: Sum of PhysicalDisk-Write I/Os per second
			PD-Wkb/s: PhysicalDisk-Write KBs per second
			PD-Wkb/s-sum: Sum of PhysicalDisk-Write KBs per second
			PD-Wrt: PhysicalDisk-Write Svt ms: Service Time in ms
			PD-Wrt-avg: Average of PhysicalDisk-Write Svt ms: Service Time in ms
			PD-Wxs: PhysicalDisk-Write IOSz KB: I/O size in KB
			PD-Wxs-avg: Average of PhysicalDisk-Write IOSz KB: I/O size in KB
			PD-Qlen: PhysicalDisk-Queue Length
			PD-Qlen-Sum: Sum of PhysicalDisk-Queue Length
			PD-idle: PhysicalDisk-idle
			PD-idle-avg: Average of PhysicalDisk-idle";
	printf "The Output is formatted as follows:\n";
	for ($i=0; $i<=$#pdStats; $i++) {
		printf "${pdStats[$i]}-<ID>,<value1_iter1>,<value2_iter2>,<value3_iter3>,...,<value(n)_iter(n)>,\n";
	}
	printf "\n";
	printf "*********************************************************\n";
	printf "\n";
	# Print PD stats
	for ($i=0; $i<=$#pdStats; $i++) {
	    printf "$date[0],";
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		printf "%s,",$tod[$s];
	    }
	    printf "\n";
	    foreach $pd (sort keys %pds) {
		printf "${pdStats[$i]}-$pd,";
		for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		    $val=0;
		    if ((defined $pds{$pd}[$i][$s]) && ($pds{$pd}[$i] > 0)) { $val=$pds{$pd}[$i][$s] }
		    elsif ((! defined $pds{$pd}[$i][$s]) && ( $i == 9 )) { $val=100 }
		    else { $val = 0 }
		    printf "%.1f,",$val;
		}
		printf "\n";	
	    }
	    # Print total at the end
	    if ( ( ${pdStats[$i]} =~ "rt") ||
		 ( ${pdStats[$i]} =~ "xs") ||
		 ( ${pdStats[$i]} =~ "idle") ) {
		printf "${pdStats[$i]}-avg,";
	    }
	    else {
		printf "${pdStats[$i]}-sum,";
	    }
	    for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
		$sum=0;
		$nonZero=0;
		foreach $pd (sort keys %pds) {
		    if ( $i == 9 ) {
			if ( ! defined $pds{$pd}[$i][$s]) { $pds{$pd}[$i][$s]=100 }
		    }
		    else {
			if ((defined $pds{$pd}[$i][$s]) && ($pds{$pd}[$i][$s] != 0)) { ++$nonZero }
			else { $pds{$pd}[$i][$s] = 0 }
		    }
		$sum+=$pds{$pd}[$i][$s];
		}
		if ( ( ${pdStats[$i]} =~ "rt") ||
		     ( ${pdStats[$i]} =~ "xs") ) {
		    if ( $nonZero > 0 ) { $sum=$sum/$nonZero; }
		}
		elsif ( ${pdStats[$i]} =~ "idle" ) { $sum=$sum/(scalar keys %pds); }
		printf "%.1f,",$sum;
	    }
	    printf "\n";

	    printf "\n\n";
	}
    }
}


sub memstats_init {
    #Get free memory stats using free -mt
    $memcnt=$used_mem_sum=$free_mem_sum=$total_mem=$buffers_mem_sum=$cached_mem_sum=$shared_mem_sum=0;
    $flag=$num_samples=0;$s=-1;
}

sub memstats_gather {
    chomp;
    if ($_  =~ m/(\d+):(\d+):(\d+)/) {
	$flag=0;
	$num_samples+=1;
	($thetod,$thedate) = split; 
	if ($dates_used == 1) { if ( ($thetod gt $tstart) && ($thetod lt $tstop) ) { $flag=1; } }
	if ($skip_used == 1) { if (($num_samples > $num_to_skip) && ($num_samples <= ($num_to_skip+$num_to_process))) {$flag=1;} }
	if ($flag == 1) { $memcnt++; $s++; $date[$s]=$thedate; $tod[$s]=$thetod; }
    }
    if (index($_,"Total:") >= 0) { $flag=0; }
    if ( ($flag == 1) && (index($_,"Mem:") >= 0) )  {
	@vals=split;
	$total_mem=($vals[1]/1024); #get it every time even though it doesnt' change
	$shared_mem[$s]=($vals[4]/1024);
	$buffers_mem[$s]=($vals[5]/1024);
	$cached_mem[$s]=($vals[6]/1024);
	$shared_mem_sum+=($vals[4]/1024);
	$buffers_mem_sum+=($vals[5]/1024);
	$cached_mem_sum+=($vals[6]/1024);
    }
    if ( ($flag == 1) && ($_ =~ /\-\/\+/) )  {
	@vals=split;
	$used_mem[$s]=($vals[2]/1024);
	$free_mem[$s]=($vals[3]/1024);
	$used_mem_sum+=($vals[2]/1024);
	$free_mem_sum+=($vals[3]/1024);
    }
}

sub memstats_process {
    if (($memcnt > 0) && ($summ == 1)) {
	printf "Inform Mem:  UsedGB   FreeGB  PercUsed  SharedGB  BuffersGB  CachedGB\n"; 
	$used_mem_avg=$free_mem_avg=$perc_used_mem=$shared_mem_avg=$buffer_mem_avg=$cached_mem_avg=0;
	if ($used_mem_sum > 0) { $used_mem_avg=$used_mem_sum/$memcnt; };
	if ($free_mem_sum > 0) { $free_mem_avg=$free_mem_sum/$memcnt; };
	if ($total_mem > 0) { $perc_used_mem=100*($used_mem_avg/$total_mem); }
	if ($shared_mem_sum > 0) { $shared_mem_avg=$shared_mem_sum/$memcnt; };
	if ($buffers_mem_sum > 0) { $buffers_mem_avg=$buffers_mem_sum/$memcnt; };
	if ($cached_mem_sum > 0) { $cached_mem_avg=$cached_mem_sum/$memcnt; };
	printf "         %.2f     %.2f      %.2f      %.2f      %.2f      %.2f\n",
	$used_mem_avg,$free_mem_avg,$perc_used_mem,$shared_mem_avg,$buffer_mem_avg,$cached_mem_avg; 
	printf "\n";
    }
    if (($memcnt > 0) && ($csv == 1)) { 
	printf "Inform Mem,stats,UsedGB,FreeGB,PercUsed,SharedGB,BuffersGB,CachedGB\n";
	for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
	    $perc_used_mem=0;
	    if ((defined $used_mem[$s]) && ($total_mem > 0)) { $perc_used_mem=100*($used_mem[$s]/$total_mem); };
	    if ( (defined $used_mem[$s]) && (defined $free_mem[$s]) && (defined $shared_mem[$s]) 
		 &&(defined $buffers_mem[$s]) && (defined $cached_mem[$s]) ) {
		printf "%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n",
		$date[$s],$tod[$s],$used_mem[$s],$free_mem[$s],$perc_used_mem,$shared_mem[$s],$buffers_mem[$s],$cached_mem[$s]; 
	    } 
	}
	printf "\n\n";
    }
}

sub kvmmstats_process {
    if (($memcnt > 0) && ($summ == 1)) {
	printf "KVM Mem:  UsedGB   FreeGB  PercUsed  SharedGB  BuffersGB  CachedGB\n"; 
	$used_mem_avg=$free_mem_avg=$perc_used_mem=$shared_mem_avg=$buffer_mem_avg=$cached_mem_avg=0;
	if ($used_mem_sum > 0) { $used_mem_avg=$used_mem_sum/$memcnt; };
	if ($free_mem_sum > 0) { $free_mem_avg=$free_mem_sum/$memcnt; };
	if ($total_mem > 0) { $perc_used_mem=100*($used_mem_avg/$total_mem); }
	if ($shared_mem_sum > 0) { $shared_mem_avg=$shared_mem_sum/$memcnt; };
	if ($buffers_mem_sum > 0) { $buffers_mem_avg=$buffers_mem_sum/$memcnt; };
	if ($cached_mem_sum > 0) { $cached_mem_avg=$cached_mem_sum/$memcnt; };
	printf "           %.2f     %.2f      %.2f      %.2f      %.2f      %.2f\n",
	$used_mem_avg,$free_mem_avg,$perc_used_mem,$shared_mem_avg,$buffer_mem_avg,$cached_mem_avg; 
	printf "\n";
    }
    if (($memcnt > 0) && ($csv == 1)) { 
	printf "KVM Mem,stats,UsedGB,FreeGB,PercUsed,SharedGB,BuffersGB,CachedGB\n";
	for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
	    $perc_used_mem=0;
	    if ((defined $used_mem[$s]) && ($total_mem > 0)) { $perc_used_mem=100*($used_mem[$s]/$total_mem); };
	    if ( (defined $used_mem[$s]) && (defined $free_mem[$s]) && (defined $shared_mem[$s]) 
		 &&(defined $buffers_mem[$s]) && (defined $cached_mem[$s]) ) {
		printf "%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n",
		$date[$s],$tod[$s],$used_mem[$s],$free_mem[$s],$perc_used_mem,$shared_mem[$s],$buffers_mem[$s],$cached_mem[$s]; 
	    } 
	}
	printf "\n\n";
    }
}

sub rcipstats_init {
    #Get rcip network activity in MB/s
    $rcipcnt=$rcip_rkbs_sum=$rcip_wkbs_sum=$rcip_tkbs_sum=0;
    $flag=$num_samples=0;$s=-1;
}

sub rcipstats_gather {
    chomp;
    if ($_  =~ /(\d+)\/(\d+)\/(\d+)/) {
	$flag=0;
	$num_samples+=1;
	($thetod,$thedate) = split; 
	if ($dates_used == 1) { if ( ($thetod gt $tstart) && ($thetod lt $tstop) ) { $flag=1; } }
	if ($skip_used == 1) { if (($num_samples > $num_to_skip) && ($num_samples <= ($num_to_skip+$num_to_process))) {$flag=1;} }
	if ($flag == 1) { $rcipcnt++; $s++; $date[$s]=$thedate; $tod[$s]=$thetod; }
    }

    if ( ($flag == 1) && ($_ =~ /total/) )  {
	@vals=split;
	if ($vals[1] eq "r") {  
	    $rcip_rkbs_sum+=$vals[4];
	    $rcip_rkbs[$s]=$vals[4];
	} 
	if ($vals[1] eq "w") {  
	    $rcip_wkbs_sum+=$vals[4];
	    $rcip_wkbs[$s]=$vals[4];
	} 
	if ($vals[1] eq "t") {  
	    $rcip_tkbs_sum+=$vals[4];
	    $rcip_tkbs[$s]=$vals[4];
	    $flag=0;
	}
    }
}

sub rcipstats_process {
    if (($rcipcnt > 0) && ($summ == 1)) {
	printf "RCIP:  ReadMB   WriteMB  TotalMB\n"; 
	$rcip_rmbs_avg=$rcip_wmbs_avg=$rcip_tmbs_avg=0;
	if ($rcip_rkbs_sum > 0) { $rcip_rmbs_avg=($rcip_rkbs_sum/$rcipcnt)/1000; };
	if ($rcip_wkbs_sum > 0) { $rcip_wmbs_avg=($rcip_wkbs_sum/$rcipcnt)/1000; };
	if ($rcip_tkbs_sum > 0) { $rcip_tmbs_avg=($rcip_tkbs_sum/$rcipcnt)/1000; }
	printf "       %.2f    %.2f    %.2f\n",$rcip_rmbs_avg,$rcip_wmbs_avg,$rcip_tmbs_avg;
	printf "\n";
    }
    if (($rcipcnt > 0) && ($csv == 1)) {
	printf "RCIP,stats,ReadMB,WriteMB,TotalMB\n"; 
	for ($stats_samples=$s,$s=0; $s<$stats_samples; $s++) {
	    if ((defined $rcip_rkbs[$s]) && (defined $rcip_wkbs[$s]) && (defined $rcip_wkbs[$s])) {
		printf "%s,%s,%.2f,%.2f,%.1f\n",$date[$s],$tod[$s],$rcip_rkbs[$s]/1000,$rcip_wkbs[$s]/1000,$rcip_tkbs[$s]/1000; 
	    } 
	}
	printf "\n\n";
    }
}

####End of Subroutine section###########################################################


##### Start of Main flow for multiple files (one file per stat: cpu,hp,dp,vl,pd,cmp) ##############
if ($multiple_files == 1) {
    if ((defined $cpustats_file) && (-e $cpustats_file)) {
	#Get CPU stats
	cpustats_init;
	open(INF,$cpustats_file);
	while (<INF>) {
	    cpustats_gather($_);
	}
	close(INF);
	cpustats_process;
    }

    if ((defined $porthoststats_file) && (-e $porthoststats_file)) {
	#Get Host Port stats
	hpstats_init;
	open(INF,$porthoststats_file);
	while (<INF>) {
	    hpstats_gather($_);
	}
	close(INF);
	hpstats_process;
    }

    if ((defined $cmpstats_file) && (-e $cmpstats_file)) {
	cmpstats_init;
	open(INF,$cmpstats_file); 
	while (<INF>) {
	    cmpstats_gather($_);
	}
	close(INF);
	cmpstats_process;
    }

    if ((defined $cachestats_file) && (-e $cachestats_file)) {
	cachestats_init;
	open(INF,$cachestats_file); 
	while (<INF>) {
	    cachestats_gather($_);
	}
	close(INF);
	cachestats_process;
    }
    
    if ((defined $cachevstats_file) && (-e $cachevstats_file)) {
	cachevstats_init;
	open(INF,$cachevstats_file); 
	while (<INF>) {
	    cachevstats_gather($_);
	}
	close(INF);
	cachevstats_process;
    }

    if ((defined $portdiskstats_file) && (-e $portdiskstats_file)) {
	dpstats_init;
	open(INF,$portdiskstats_file);
	while (<INF>) {
	    dpstats_gather($_);
	}
	close(INF);
	dpstats_process;
    }

    if ((defined $vlunstats_file) && (-e $vlunstats_file)) {
	vlstats_init;
	open(INF,$vlunstats_file);
	while (<INF>) {
	    vlstats_gather($_);
	}
	close(INF);
	vlstats_process;
    }

    if ((defined $vvstats_file) && (-e $vvstats_file)) {
	vvstats_init;
	open(INF,$vvstats_file);
	while (<INF>) {
	    vvstats_gather($_);
	}
	close(INF);
	vvstats_process;
    }
    
    if ((defined $pdstats_file) && (-e $pdstats_file)) {
	pdstats_init;
	open(INF,$pdstats_file);
	while (<INF>) {
	    pdstats_gather($_);
	}
	close(INF);
	pdstats_process;
    } 

    if ((defined $memstats_file) && (-e $memstats_file)) {
	memstats_init;
	open(INF,$memstats_file); 
	while (<INF>) {
	    memstats_gather($_);
	}
	close(INF);
	memstats_process;
    }

    if ((defined $portrcipstats_file) && (-e $portrcipstats_file)) {
	rcipstats_init;
	open(INF,$portrcipstats_file); 
	while (<INF>) {
	    rcipstats_gather($_);
	}
	close(INF);
	rcipstats_process;
    }

    if ((defined $kvmmstats_file) && (-e $kvmmstats_file)) {
	memstats_init;
	open(INF,$kvmmstats_file); 
	while (<INF>) {
	    memstats_gather($_);
	}
	close(INF);
	kvmmstats_process;
    }
}
##### End of Main flow for multiple files (one file per stat: cpu,hp,dp,vl,pd,cmp) ##############

##### Start of Main flow for one single file with the stats: cpu,hp,dp,vl,pd,cmp ##############
if ($single_file == 1) {
    $current_stat=$previous_stat=0; # 0:no stat,1:cpu,2:hp,3:dp,4:vl,5:pd,6:cmp,7:rcip,8:informmemory,9:vv,10:kvmmemory
    $change_in_stats=0;
    open(INF,$stats_file);
    while (<INF>) {
	if (($_ =~ /cpustat/) || ($_ =~ /CPUSTAT/)) { $change_in_stats=1; $previous_stat=$current_stat; $current_stat=1; }
	if (($_ =~ /porthoststat/) || ($_ =~ /PORTHOSTSTAT/)) { $change_in_stats=1; $previous_stat=$current_stat; $current_stat=2; }
	if (($_ =~ /portdiskstat/) || ($_ =~ /PORTDISKSTAT/)) { $change_in_stats=1; $previous_stat=$current_stat; $current_stat=3; }
	if (($_ =~ /vlunstat/) || ($_ =~ /VLUNSTAT/)) { $change_in_stats=1; $previous_stat=$current_stat; $current_stat=4; }
	if (($_ =~ /pdstat/) || ($_ =~ /PDSTAT/)) { $change_in_stats=1; $previous_stat=$current_stat; $current_stat=5; }
	if (($_ =~ /cmpstat/) || ($_ =~ /CMPSTAT/)) { $change_in_stats=1; $previous_stat=$current_stat; $current_stat=6; }
	if (($_ =~ /portrcipstat/) || ($_ =~ /PORTRCIPSTAT/)) { $change_in_stats=1; $previous_stat=$current_stat; $current_stat=7; }
	if (($_ =~ /informmemory/) || ($_ =~ /INFORMMEMORY/)) { $change_in_stats=1; $previous_stat=$current_stat; $current_stat=8; }
	if (($_ =~ /vvstat/) || ($_ =~ /VVSTAT/)) { $change_in_stats=1; $previous_stat=$current_stat; $current_stat=9; }
	if (($_ =~ /kvmmemory/) || ($_ =~ /KVMMEMORY/)) { $change_in_stats=1; $previous_stat=$current_stat; $current_stat=10; }
	if (($_ =~ /cachestat/) || ($_ =~ /CACHESTAT/)) { $change_in_stats=1; $previous_stat=$current_stat; $current_stat=11; }
	if (($_ =~ /cachevstat/) || ($_ =~ /CACHEVSTAT/)) { $change_in_stats=1; $previous_stat=$current_stat; $current_stat=12; }

	if ($change_in_stats == 1) { 
	    #A change in the stats gathered occurred
	    if ($previous_stat == 1) { cpustats_process; }
	    if ($previous_stat == 2) { hpstats_process; }
	    if ($previous_stat == 3) { dpstats_process; }
	    if ($previous_stat == 4) { vlstats_process; }
	    if ($previous_stat == 5) { pdstats_process; }
	    if ($previous_stat == 6) { cmpstats_process; }
	    if ($previous_stat == 7) { rcipstats_process; }
	    if ($previous_stat == 8) { memstats_process; }
	    if ($previous_stat == 9) { vvstats_process; }
	    if ($previous_stat == 10) { kvmmstats_process; }
	    if ($previous_stat == 11) {cachestats_process; }
	    if ($previous_stat == 12) {cachevstats_process; }
	    if ($current_stat == 1) { cpustats_init; }
	    if ($current_stat == 2) { hpstats_init; }
	    if ($current_stat == 3) { dpstats_init; }
	    if ($current_stat == 4) { vlstats_init; }
	    if ($current_stat == 5) { pdstats_init; }
	    if ($current_stat == 6) { cmpstats_init; }
	    if ($current_stat == 7) { rcipstats_init; }
	    if ($current_stat == 8) { memstats_init; }
	    if ($current_stat == 9) { vvstats_init; }
	    if ($current_stat == 10) { memstats_init; }
	    if ($current_stat == 11) {cachestats_init; }
	    if ($current_stat == 12) {cachevstats_init; }
	    $change_in_stats=0;
	}
	else {
	    if ($current_stat == 1) { cpustats_gather($_); }
	    if ($current_stat == 2) { hpstats_gather($_); }
	    if ($current_stat == 3) { dpstats_gather($_); }
	    if ($current_stat == 4) { vlstats_gather($_); }
	    if ($current_stat == 5) { pdstats_gather($_); }
	    if ($current_stat == 6) { cmpstats_gather($_); }
	    if ($current_stat == 7) { rcipstats_gather($_); }
	    if ($current_stat == 8) { memstats_gather($_); }
	    if ($current_stat == 9) { vvstats_gather($_); }
	    if ($current_stat == 10) { memstats_gather($_); }
	    if ($current_stat == 11) { cachestats_gather($_); }
	    if ($current_stat == 12) { cachevstats_gather($_); }
	}
    }
    close(INF);
    if ($current_stat == 1) { cpustats_process; }
    if ($current_stat == 2) { hpstats_process; }
    if ($current_stat == 3) { dpstats_process; }
    if ($current_stat == 4) { vlstats_process; }
    if ($current_stat == 5) { pdstats_process; }
    if ($current_stat == 6) { cmpstats_process; }
    if ($current_stat == 7) { rcipstats_process; }
    if ($current_stat == 8) { memstats_process; }
    if ($current_stat == 9) { vvstats_process; }
    if ($current_stat == 10) { kvmmstats_process; }
    if ($current_stat == 11) { cachestats_process; }
    if ($current_stat == 12) { cachevstats_process; }
}
##### End of Main flow for one single file with the six stats: cpu,hp,dp,vl,pd,cmp ##############

print "\n"; # Just to separat the output from the prompt or the next output if redirected to a file
