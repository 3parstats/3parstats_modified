{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1033{\fonttbl{\f0\fnil\fcharset0 Calibri;}}
{\*\generator Riched20 10.0.14393}\viewkind4\uc1 
\pard\sa200\sl276\slmult1\f0\fs22\lang9 #!/bin/bash\par
u1="`basename $0` -i count_of_iterations -d duration_of_iteration\\n"\par
u2="Example: `basename $0` -i 60 -d 5\\n"\par
USAGE=$u1$u2\par
\par
#Parse command line options.\par
while getopts i:d: OPT; do\par
    case "$OPT" in\par
        i)\par
            count=$OPTARG\par
            ;;\par
        d)\par
            duration=$OPTARG\par
            ;;\par
        \\?)\par
            # getopts issues an error message\par
            echo -e $USAGE >&2\par
            exit 1\par
            ;;\par
    esac\par
done\par
\par
if [ $# -lt 4 ] ; then\par
\tab echo -e $USAGE\par
\tab exit 1\par
fi\par
\par
while [ $count -gt 0 ]\par
do\par
\tab date +"%T %D"\par
\tab free -tm\par
\tab echo ""\par
\tab count=$(($count - 1))\par
\tab sleep $duration\par
done\par
}
 