#!/bin/bash
#########################################################################
adduser2.sh:
#!/bin/bash
! id user1 &> /dev/null && useradd user1 && echo "user1" | passwd --stdin user1 &> /dev/null || echo "user1 exists."
! id user2 &> /dev/null	&& useradd user2 && echo "user2" | passwd --stdin user2	&> /dev/null ||	echo "user2 exists."
! id user3 &> /dev/null	&& useradd user3 && echo "user3" | passwd --stdin user3	&> /dev/null ||	echo "user3 exists."

USERS=`wc -l /etc/passwd | cut -d: -f1`
echo "$USERS users."

#########################################################################
adduser.sh:
#!/bin/bash
#
DEBUG=0

case $1 in
-v|--verbose)
  DEBUG=1
  ;;
esac

useradd tom &> /dev/null
[ $DEBUG -eq 1 ] && echo "Add user tom finished."

#########################################################################
addusers.sh:
#!/bin/bash
useradd user1
echo "user1" | passwd --stdin user1 &> /dev/null
echo "Add user1 finished."

#########################################################################
adminusers2.sh:
#!/bin/bash
#

if [ $1 == '--add' ]; then
  for I in `echo $2 | sed 's/,/ /g'`; do
    if id $I &> /dev/null; then
      echo "$I exists."
    else
      useradd $I
      echo $I | passwd --stdin $I &> /dev/null
      echo "add $I finished."
    fi
  done
elif [ $1 == '--del' ];then
  for I in `echo $2 | sed 's/,/ /g'`; do
    if id $I &> /dev/null; then
      userdel -r $I
      echo "Delete $I finished."
    else
      echo "$I NOT exist."
    fi
  done
elif [ $1 == '--help' ]; then
  echo "Usage: adminuser2.sh --add USER1,USER2,... | --del USER1,USER2,...| --help"
else
  echo "Unknown options."
fi


#########################################################################
adminusers3.sh:
#!/bin/bash
#
DEBUG=0
ADD=0
DEL=0

for I in `seq 0 $#`; do
if [ $# -gt 0 ]; then
case $1 in
-v|--verbose)
  DEBUG=1
  shift ;;
-h|--help)
  echo "Usage: `basename $0` --add USER_LIST --del USER_LIST -v|--verbose -h|--help"
  exit 0
  ;;
--add)
  ADD=1
  ADDUSERS=$2
  shift 2
  ;;
--del)
  DEL=1
  DELUSERS=$2
  shift 2
  ;;
*)
  echo "Usage: `basename $0` --add USER_LIST --del USER_LIST -v|--verbose -h|--help"
  exit 7
  ;;
esac
fi
done

if [ $ADD -eq 1 ]; then
  for USER in `echo $ADDUSERS | sed 's@,@ @g'`; do
    if id $USER &> /dev/null; then
      [ $DEBUG -eq 1 ] && echo "$USER exists."
    else
      useradd $USER
      [ $DEBUG -eq 1 ] && echo "Add user $USER finished."
    fi
  done
fi

if [ $DEL -eq 1 ]; then
  for USER in `echo $DELUSERS | sed 's@,@ @g'`; do
    if id $USER &> /dev/null; then
      userdel -r $USER
      [ $DEBUG -eq 1 ] && echo "Delete $USER finished."
    else
      [ $DEBUG -eq 1 ] && echo "$USER not exist."
    fi
  done
fi

#########################################################################
adminusers.sh:
#!/bin/bash
#

if [ $# -lt 1 ]; then
  echo "Usage: adminusers ARG"
  exit 7
fi

if [ $1 == '--add' ]; then
  for I in {1..10}; do
    if id user$I &> /dev/null; then
      echo "user$I exists."
    else
      useradd user$I
      echo user$I | passwd --stdin user$I &> /dev/null
      echo "Add user$I finished."
    fi
  done
elif [ $1 == '--del' ]; then
  for I in {1..10}; do
    if id user$I &> /dev/null; then
      userdel -r user$I
      echo "Delete user$I finished."
    else
      echo "No user$I."
    fi
  done
else
  echo "Unknown ARG"
  exit 8
fi
  


#########################################################################
bash2.sh:
#!/bin/bash
#
grep "\<bash$" /etc/passwd &> /dev/null
RETVAL=$?

if [ $RETVAL -eq 0 ]; then
  AUSER=`grep "\<bash$" /etc/passwd | head -1 | cut -d: -f1`
  echo "$AUSER is one of such users."
else
  echo "No such user."
fi 

#########################################################################
bash.sh:
#!/bin/bash
#
grep "\<bash$" /etc/passwd &> /dev/null
RETVAL=$?

if [ $RETVAL -eq 0 ]; then
  USERS=`grep "\<bash$" /etc/passwd | wc -l`
  echo "The shells of $USERS users is bash." 
else
  echo "No such user."
fi 

#########################################################################
bincp.sh:
#!/bin/bash
#
DEST=/mnt/sysroot
libcp() {
  LIBPATH=${1%/*}
  [ ! -d $DEST$LIBPATH ] && mkdir -p $DEST$LIBPATH
  [ ! -e $DEST${1} ] && cp $1 $DEST$LIBPATH && echo "copy lib $1 finished."
}

bincp() {
  CMDPATH=${1%/*}
  [ ! -d $DEST$CMDPATH ] && mkdir -p $DEST$CMDPATH
  [ ! -e $DEST${1} ] && cp $1 $DEST$CMDPATH

  for LIB in  `ldd $1 | grep -o "/.*lib\(64\)\{0,1\}/[^[:space:]]\{1,\}"`; do
    libcp $LIB
  done
}

read -p "Your command: " CMD
until [ $CMD == 'q' ]; do
   ! which $CMD && echo "Wrong command" && read -p "Input again:" CMD && continue
  COMMAND=` which $CMD | grep -v "^alias" | grep -o "[^[:space:]]\{1,\}"`
  bincp $COMMAND
  echo "copy $COMMAND finished."
  read -p "Continue: " CMD
done

#########################################################################
calc.sh:
#!/bin/bash
#
if [ $# -lt 2 ]; then
  echo "Usage: cacl.sh ARG1 ARG2"
  exit 8
fi

echo "The sum is: $[$1+$2]."
echo "The prod is: $[$1*$2]."

#########################################################################
case.sh:
#!/bin/bash
#
case $1 in
[0-9])
  echo "A digit." ;;
[a-z])
  echo "Lower" ;;
[A-Z])
  echo "Upper" ;;
*)
  echo "Special character." ;;
esac

#########################################################################
check_cpu.sh:
#!/bin/bash

# Check CPU Usage via /proc/stats

########################
# DECLARATIONS
########################

PROGNAME=`basename $0`
REVISION=`echo '$Revision: 1.0 $' | sed -e 's/[^0-9.]//g'`

DEBUG=0

exitstatus=0
result=""
perfdata=""
scale=2
show_all=0
warning=999
critical=999

TMPFILE="/tmp/check_cpu.tmp"

status[0]="OK: "
status[1]="WARNING: "
status[2]="CRITICAL: "
status[3]="UNKNOWN: "

########################
# FUNCTIONS
########################

print_usage() {
  echo "Usage: $PROGNAME [options]"
  echo "  e.g. $PROGNAME -w 75 -c 90 -s 2 --all"
  echo
  echo "Options:"
  echo -e "\t --help    | -h       print help"
  echo -e "\t --version | -V       print version"
  echo -e "\t --verbose | -v       be verbose (debug mode)"
  echo -e "\t --scale   | -s [int] decimal precision of results"
  echo -e "\t                        default=2"
  echo -e "\t --all     | -a       return values for all cpus individually"
  echo -e "\t                        default= summary data only"
  echo -e "\t -w [int]             set warning value"
  echo -e "\t -c [int]             set critical value"
  echo
  echo
}

print_help() {
#  print_revision $PROGNAME $REVISION
  echo "${PROGNAME} Revision: ${REVISION}"
  echo
  echo "This plugin checks local cpu usage using /proc/stat"
  echo
  print_usage
  echo
# support
  exit 3
}

parse_options() {
# parse cmdline arguments
  (( DEBUG )) && echo "Parsing options $1 $2 $3 $4 $5 $6 $7 $8"
  if [ "$#" -gt 0 ]; then
    while [ "$#" -gt 0 ]; do
      case "$1" in
        '--help'|'-h')
          print_help
          exit 3
          ;;
        '--version'|'-V')
          #print_revision $PROGNAME $REVISION
          echo "${PROGNAME} Revision: ${REVISION}"
          exit 3
          ;;
        '--verbose'|'-v')
          DEBUG=1
          shift 1
          ;;
        '--scale'|'-s')
          scale="$2"
          shift 2
          ;;
        '--all'|'-a')
          show_all=1
          shift 1
          ;;
        '-c')
          critical="$2"
          shift 2
          ;;
        '-w')
          warning="$2"
          shift 2
          ;;
        *)
          echo "Unknown option!"
          print_usage
          exit 3
          ;;
      esac
    done
  fi
}

write_tmpfile() {
  echo "old_date=$(date +%s)" > ${TMPFILE}
  for a in $(seq 0 1 ${cpucount} ); do
    echo "old_system[${a}]=${system[${a}]}" >> ${TMPFILE}
    echo "old_user[${a}]=${user[${a}]}" >> ${TMPFILE}
    echo "old_nice[${a}]=${nice[${a}]}" >> ${TMPFILE}
    echo "old_iowait[${a}]=${iowait[${a}]}" >> ${TMPFILE}
    echo "old_irq[${a}]=${irq[${a}]}" >> ${TMPFILE}
    echo "old_softirq[${a}]=${softirq[${a}]}" >> ${TMPFILE}
    echo "old_idle[${a}]=${idle[${a}]}" >> ${TMPFILE}
    echo "old_used[${a}]=${used[${a}]}" >> ${TMPFILE}
    echo "old_total[${a}]=${total[${a}]}" >> ${TMPFILE}
  done
}

read_tmpfile() {
  if [ -e ${TMPFILE} ]; then
    source ${TMPFILE}			# include the vars from the tmp file
  fi
  (( DEBUG )) && cat ${TMPFILE}
}

########################
# MAIN
########################

parse_options $@

read_tmpfile

procstat=$(cat /proc/stat 2>&1)
 (( DEBUG )) && echo "$procstat"
cpucount=$(( $(grep -i cpu <<< "${procstat}" | tail -n 1 | cut -d' ' -f 1 | grep -Eo [0-9]+) + 1 ))
  (( DEBUG )) && echo "cpucount=${cpucount}"

for a in $(seq 0 1 ${cpucount} ); do
  if [ $a -eq ${cpucount} ]; then
    cpu[$a]=$(head -n 1 <<< "${procstat}" | sed 's/  / /g')
  else
    cpu[$a]=$(grep cpu${a} <<< "${procstat}")
  fi
  user[$a]=$(cut -d' ' -f 2 <<< ${cpu[$a]})
  nice[$a]=$(cut -d' ' -f 3 <<< ${cpu[$a]})
  system[$a]=$(cut -d' ' -f 4 <<< ${cpu[$a]})
  idle[$a]=$(cut -d' ' -f 5 <<< ${cpu[$a]})
  iowait[$a]=$(cut -d' ' -f 6 <<< ${cpu[$a]})
  irq[$a]=$(cut -d' ' -f 7 <<< ${cpu[$a]})
  softirq[$a]=$(cut -d' ' -f 8 <<< ${cpu[$a]})
  used[$a]=$((( ${user[$a]} + ${nice[$a]} + ${system[$a]} + ${iowait[$a]} + ${irq[$a]} + ${softirq[$a]} )))
  total[$a]=$((( ${user[$a]} + ${nice[$a]} + ${system[$a]} + ${idle[$a]} + ${iowait[$a]} + ${irq[$a]} + ${softirq[$a]} )))

  [ -z ${old_user[${a}]} ] && old_user[${a}]=0
  [ -z ${old_nice[${a}]} ] && old_nice[${a}]=0
  [ -z ${old_system[${a}]} ] && old_system[${a}]=0
  [ -z ${old_idle[${a}]} ] && old_idle[${a}]=0
  [ -z ${old_iowait[${a}]} ] && old_iowait[${a}]=0
  [ -z ${old_irq[${a}]} ] && old_irq[${a}]=0
  [ -z ${old_softirq[${a}]} ] && old_softirq[${a}]=0
  [ -z ${old_used[${a}]} ] && old_used[${a}]=0
  [ -z ${old_total[${a}]} ] && old_total[${a}]=0

  diff_user[$a]=$(((${user[$a]}-${old_user[${a}]})))
  diff_nice[$a]=$(((${nice[$a]}-${old_nice[${a}]})))
  diff_system[$a]=$(((${system[$a]}-${old_system[${a}]})))
  diff_idle[$a]=$(((${idle[$a]}-${old_idle[${a}]})))
  diff_iowait[$a]=$(((${iowait[$a]}-${old_iowait[${a}]})))
  diff_irq[$a]=$(((${irq[$a]}-${old_irq[${a}]})))
  diff_softirq[$a]=$(((${softirq[$a]}-${old_softirq[${a}]})))
  diff_used[$a]=$(((${used[$a]}-${old_used[${a}]})))
  diff_total[$a]=$(((${total[$a]}-${old_total[${a}]})))
 
  pct_user[$a]=$(bc <<< "scale=${scale};${diff_user[$a]}*100/${diff_total[$a]}")
  pct_nice[$a]=$(bc <<< "scale=${scale};${diff_nice[$a]}*100/${diff_total[$a]}")
  pct_system[$a]=$(bc <<< "scale=${scale};${diff_system[$a]}*100/${diff_total[$a]}")
  pct_idle[$a]=$(bc <<< "scale=${scale};${diff_idle[$a]}*100/${diff_total[$a]}")
  pct_iowait[$a]=$(bc <<< "scale=${scale};${diff_iowait[$a]}*100/${diff_total[$a]}")
  pct_irq[$a]=$(bc <<< "scale=${scale};${diff_irq[$a]}*100/${diff_total[$a]}")
  pct_softirq[$a]=$(bc <<< "scale=${scale};${diff_softirq[$a]}*100/${diff_total[$a]}")
  pct_used[$a]=$(bc <<< "scale=${scale};${diff_used[$a]}*100/${diff_total[$a]}")
done

write_tmpfile

[ $(cut -d'.' -f 1 <<< ${pct_used[${cpucount}]}) -ge ${warning} ] && exitstatus=1
[ $(cut -d'.' -f 1 <<< ${pct_used[${cpucount}]}) -ge ${critical} ] && exitstatus=2

result="CPU=${pct_used[${cpucount}]}"
if [ $show_all -gt 0 ]; then
  for a in $(seq 0 1 $(((${cpucount} - 1)))); do
    result="${result}, CPU${a}=${pct_used[${a}]}"
  done
fi

if [ "${warning}" = "999" ]; then
  warning=""
fi
if [ "${critical}" = "999" ]; then
  critical=""
fi

perfdata="used=${pct_used[${cpucount}]};${warning};${critical};; system=${pct_system[${cpucount}]};;;; user=${pct_user[${cpucount}]};;;; nice=${pct_nice[${cpucount}]};;;; iowait=${pct_iowait[${cpucount}]};;;; irq=${pct_irq[${cpucount}]};;;; softirq=${pct_softirq[${cpucount}]};;;;"
if [ $show_all -gt 0 ]; then
  for a in $(seq 0 1 $(((${cpucount} - 1)))); do
    perfdata="${perfdata} used${a}=${pct_used[${a}]};;;; system${a}=${pct_system[${a}]};;;; user${a}=${pct_user[${a}]};;;; nice${a}=${pct_nice[${a}]};;;; iowait${a}=${pct_iowait[${a}]};;;; irq${a}=${pct_irq[${a}]};;;; softirq${a}=${pct_softirq[${a}]};;;;"
  done
fi

echo "${status[$exitstatus]}${result} | ${perfdata}"
exit $exitstatus


#########################################################################
check_cpu.sh.bak:
#!/bin/bash

# Check CPU Usage via /proc/stats

########################
# DECLARATIONS
########################

PROGNAME=`basename $0`
REVISION=`echo '$Revision: 1.0 $' | sed -e 's/[^0-9.]//g'`

DEBUG=0

exitstatus=0
result=""
perfdata=""
scale=2
show_all=0
warning=999
critical=999

TMPFILE="/tmp/check_cpu.tmp"

status[0]="OK: "
status[1]="WARNING: "
status[2]="CRITICAL: "
status[3]="UNKNOWN: "

########################
# FUNCTIONS
########################

print_usage() {
  echo "Usage: $PROGNAME [options]"
  echo "  e.g. $PROGNAME -w 75 -c 90 -s 2 --all"
  echo
  echo "Options:"
  echo -e "\t --help    | -h       print help"
  echo -e "\t --version | -V       print version"
  echo -e "\t --verbose | -v       be verbose (debug mode)"
  echo -e "\t --scale   | -s [int] decimal precision of results"
  echo -e "\t                        default=2"
  echo -e "\t --all     | -a       return values for all cpus individually"
  echo -e "\t                        default= summary data only"
  echo -e "\t -w [int]             set warning value"
  echo -e "\t -c [int]             set critical value"
  echo
  echo
}

print_help() {
#  print_revision $PROGNAME $REVISION
  echo "${PROGNAME} Revision: ${REVISION}"
  echo
  echo "This plugin checks local cpu usage using /proc/stat"
  echo
  print_usage
  echo
# support
  exit 3
}

parse_options() {
# parse cmdline arguments
  (( DEBUG )) && echo "Parsing options $1 $2 $3 $4 $5 $6 $7 $8"
  if [ "$#" -gt 0 ]; then
    while [ "$#" -gt 0 ]; do
      case "$1" in
        '--help'|'-h')
          print_help
          exit 3
          ;;
        '--version'|'-V')
          #print_revision $PROGNAME $REVISION
          echo "${PROGNAME} Revision: ${REVISION}"
          exit 3
          ;;
        '--verbose'|'-v')
          DEBUG=1
          shift 1
          ;;
        '--scale'|'-s')
          scale="$2"
          shift 2
          ;;
        '--all'|'-a')
          show_all=1
          shift 1
          ;;
        '-c')
          critical="$2"
          shift 2
          ;;
        '-w')
          warning="$2"
          shift 2
          ;;
        *)
          echo "Unknown option!"
          print_usage
          exit 3
          ;;
      esac
    done
  fi
}

write_tmpfile() {
  echo "old_date=$(date +%s)" > ${TMPFILE}
  for a in $(seq 0 1 ${cpucount} ); do
    echo "old_system[${a}]=${system[${a}]}" >> ${TMPFILE}
    echo "old_user[${a}]=${user[${a}]}" >> ${TMPFILE}
    echo "old_nice[${a}]=${nice[${a}]}" >> ${TMPFILE}
    echo "old_iowait[${a}]=${iowait[${a}]}" >> ${TMPFILE}
    echo "old_irq[${a}]=${irq[${a}]}" >> ${TMPFILE}
    echo "old_softirq[${a}]=${softirq[${a}]}" >> ${TMPFILE}
    echo "old_idle[${a}]=${idle[${a}]}" >> ${TMPFILE}
    echo "old_used[${a}]=${used[${a}]}" >> ${TMPFILE}
    echo "old_total[${a}]=${total[${a}]}" >> ${TMPFILE}
  done
}

read_tmpfile() {
  if [ -e ${TMPFILE} ]; then
    source ${TMPFILE}			# include the vars from the tmp file
  fi
  (( DEBUG )) && cat ${TMPFILE}
}

########################
# MAIN
########################

parse_options $@

read_tmpfile

procstat=$(cat /proc/stat 2>&1)
 (( DEBUG )) && echo "$procstat"
cpucount=$(( $(grep -i cpu <<< "${procstat}" | tail -n 1 | cut -d' ' -f 1 | grep -Eo [0-9]+) + 1 ))
  (( DEBUG )) && echo "cpucount=${cpucount}"

for a in $(seq 0 1 ${cpucount} ); do
  if [ $a -eq ${cpucount} ]; then
    cpu[$a]=$(head -n 1 <<< "${procstat}" | sed 's/  / /g')
  else
    cpu[$a]=$(grep cpu${a} <<< "${procstat}")
  fi
  user[$a]=$(cut -d' ' -f 2 <<< ${cpu[$a]})
  nice[$a]=$(cut -d' ' -f 3 <<< ${cpu[$a]})
  system[$a]=$(cut -d' ' -f 4 <<< ${cpu[$a]})
  idle[$a]=$(cut -d' ' -f 5 <<< ${cpu[$a]})
  iowait[$a]=$(cut -d' ' -f 6 <<< ${cpu[$a]})
  irq[$a]=$(cut -d' ' -f 7 <<< ${cpu[$a]})
  softirq[$a]=$(cut -d' ' -f 8 <<< ${cpu[$a]})
  used[$a]=$((( ${user[$a]} + ${nice[$a]} + ${system[$a]} + ${iowait[$a]} + ${irq[$a]} + ${softirq[$a]} )))
  total[$a]=$((( ${user[$a]} + ${nice[$a]} + ${system[$a]} + ${idle[$a]} + ${iowait[$a]} + ${irq[$a]} + ${softirq[$a]} )))

  [ -z ${old_user[${a}]} ] && old_user[${a}]=0
  [ -z ${old_nice[${a}]} ] && old_nice[${a}]=0
  [ -z ${old_system[${a}]} ] && old_system[${a}]=0
  [ -z ${old_idle[${a}]} ] && old_idle[${a}]=0
  [ -z ${old_iowait[${a}]} ] && old_iowait[${a}]=0
  [ -z ${old_irq[${a}]} ] && old_irq[${a}]=0
  [ -z ${old_softirq[${a}]} ] && old_softirq[${a}]=0
  [ -z ${old_used[${a}]} ] && old_used[${a}]=0
  [ -z ${old_total[${a}]} ] && old_total[${a}]=0

  diff_user[$a]=$(((${user[$a]}-${old_user[${a}]})))
  diff_nice[$a]=$(((${nice[$a]}-${old_nice[${a}]})))
  diff_system[$a]=$(((${system[$a]}-${old_system[${a}]})))
  diff_idle[$a]=$(((${idle[$a]}-${old_idle[${a}]})))
  diff_iowait[$a]=$(((${iowait[$a]}-${old_iowait[${a}]})))
  diff_irq[$a]=$(((${irq[$a]}-${old_irq[${a}]})))
  diff_softirq[$a]=$(((${softirq[$a]}-${old_softirq[${a}]})))
  diff_used[$a]=$(((${used[$a]}-${old_used[${a}]})))
  diff_total[$a]=$(((${total[$a]}-${old_total[${a}]})))
 
  pct_user[$a]=$(bc <<< "scale=${scale};${diff_user[$a]}*100/${diff_total[$a]}")
  pct_nice[$a]=$(bc <<< "scale=${scale};${diff_nice[$a]}*100/${diff_total[$a]}")
  pct_system[$a]=$(bc <<< "scale=${scale};${diff_system[$a]}*100/${diff_total[$a]}")
  pct_idle[$a]=$(bc <<< "scale=${scale};${diff_idle[$a]}*100/${diff_total[$a]}")
  pct_iowait[$a]=$(bc <<< "scale=${scale};${diff_iowait[$a]}*100/${diff_total[$a]}")
  pct_irq[$a]=$(bc <<< "scale=${scale};${diff_irq[$a]}*100/${diff_total[$a]}")
  pct_softirq[$a]=$(bc <<< "scale=${scale};${diff_softirq[$a]}*100/${diff_total[$a]}")
  pct_used[$a]=$(bc <<< "scale=${scale};${diff_used[$a]}*100/${diff_total[$a]}")
done

write_tmpfile

[ $(cut -d'.' -f 1 <<< ${pct_used[${cpucount}]}) -ge ${warning} ] && exitstatus=1
[ $(cut -d'.' -f 1 <<< ${pct_used[${cpucount}]}) -ge ${critical} ] && exitstatus=2

result="CPU=${pct_used[${cpucount}]}"
if [ $show_all -gt 0 ]; then
  for a in $(seq 0 1 $(((${cpucount} - 1)))); do
    result="${result}, CPU${a}=${pct_used[${a}]}"
  done
fi

if [ "${warning}" = "999" ]; then
  warning=""
fi
if [ "${critical}" = "999" ]; then
  critical=""
fi

perfdata="used=${pct_used[${cpucount}]};${warning};${critical};; system=${pct_system[${cpucount}]};;;; user=${pct_user[${cpucount}]};;;; nice=${pct_nice[${cpucount}]};;;; iowait=${pct_iowait[${cpucount}]};;;; irq=${pct_irq[${cpucount}]};;;; softirq=${pct_softirq[${cpucount}]};;;;"
if [ $show_all -gt 0 ]; then
  for a in $(seq 0 1 $(((${cpucount} - 1)))); do
    perfdata="${perfdata} used${a}=${pct_used[${a}]};;;; system${a}=${pct_system[${a}]};;;; user${a}=${pct_user[${a}]};;;; nice${a}=${pct_nice[${a}]};;;; iowait${a}=${pct_iowait[${a}]};;;; irq${a}=${pct_irq[${a}]};;;; softirq${a}=${pct_softirq[${a}]};;;;"
  done
fi

echo "${status[$exitstatus]}${result} | ${perfdata}"
exit $exitstatus


#########################################################################
check_mem.pl:
#! /usr/bin/perl -w
#
# $Id: check_mem.pl 8 2008-08-23 08:59:52Z rhomann $
#
# check_mem v1.7 plugin for nagios
#
# uses the output of `free` to find the percentage of memory used
#
# Copyright Notice: GPL
#
# History:
# v1.8 Rouven Homann - rouven.homann@cimt.de
# + added findbin patch from Duane Toler
# + added backward compatibility patch from Timour Ezeev
#
# v1.7 Ingo Lantschner - ingo AT boxbe DOT com
# + adapted for systems with no swap (avoiding divison through 0)
#
# v1.6 Cedric Temple - cedric DOT temple AT cedrictemple DOT info
# + add swap monitoring
#       + if warning and critical threshold are 0, exit with OK
#       + add a directive to exclude/include buffers
#
# v1.5 Rouven Homann - rouven.homann@cimt.de
# + perfomance tweak with free -mt (just one sub process started instead of 7)
# + more code cleanup
#
# v1.4 Garrett Honeycutt - gh@3gupload.com
# + Fixed PerfData output to adhere to standards and show crit/warn values
#
# v1.3 Rouven Homann - rouven.homann@cimt.de
#   + Memory installed, used and free displayed in verbose mode
# + Bit Code Cleanup
#
# v1.2 Rouven Homann - rouven.homann@cimt.de
# + Bug fixed where verbose output was required (nrpe2)
#       + Bug fixed where perfomance data was not displayed at verbose output
# + FindBin Module used for the nagios plugin path of the utils.pm
#
# v1.1 Rouven Homann - rouven.homann@cimt.de
#     + Status Support (-c, -w)
# + Syntax Help Informations (-h)
#       + Version Informations Output (-V)
# + Verbose Output (-v)
#       + Better Error Code Output (as described in plugin guideline)
#
# v1.0 Garrett Honeycutt - gh@3gupload.com
#   + Initial Release
#
use strict;
use FindBin;
FindBin::again();
use lib $FindBin::Bin;
use utils qw($TIMEOUT %ERRORS &print_revision &support);
use vars qw($PROGNAME $PROGVER);
use Getopt::Long;
use vars qw($opt_V $opt_h $verbose $opt_w $opt_c);

$PROGNAME = "check_mem";
$PROGVER = "1.8";

# add a directive to exclude buffers:
my $DONT_INCLUDE_BUFFERS = 0;

sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');
GetOptions ("V"   => \$opt_V, "version"    => \$opt_V,
  "h"   => \$opt_h, "help"       => \$opt_h,
        "v" => \$verbose, "verbose"  => \$verbose,
  "w=s" => \$opt_w, "warning=s"  => \$opt_w,
  "c=s" => \$opt_c, "critical=s" => \$opt_c);

if ($opt_V) {
  print_revision($PROGNAME,'$Revision: '.$PROGVER.' $');
  exit $ERRORS{'UNKNOWN'};
}

if ($opt_h) {
  print_help();
  exit $ERRORS{'UNKNOWN'};
}

print_usage() unless (($opt_c) && ($opt_w));

my ($mem_critical, $swap_critical);
my ($mem_warning, $swap_warning);
($mem_critical, $swap_critical) = ($1,$2) if ($opt_c =~ /([0-9]+)[%]?(?:,([0-9]+)[%]?)?/);
($mem_warning, $swap_warning)   = ($1,$2) if ($opt_w =~ /([0-9]+)[%]?(?:,([0-9]+)[%]?)?/);

# Check if swap params were supplied
$swap_critical ||= 100;
$swap_warning  ||= 100;

# print threshold in output message
my $mem_threshold_output = " (";
my $swap_threshold_output = " (";

if ( $mem_warning > 0 && $mem_critical > 0) {
  $mem_threshold_output .= "W> $mem_warning, C> $mem_critical";
}
elsif ( $mem_warning > 0 ) {
  $mem_threshold_output .= "W> $mem_warning";
}
elsif ( $mem_critical > 0 ) {
  $mem_threshold_output .= "C> $mem_critical";
}

if ( $swap_warning > 0 && $swap_critical > 0) {
  $swap_threshold_output .= "W> $swap_warning, C> $swap_critical";
}
elsif ( $swap_warning > 0 ) {
  $swap_threshold_output .= "W> $swap_warning";
}
elsif ( $swap_critical > 0 )  {
  $swap_threshold_output .= "C> $swap_critical";
}

$mem_threshold_output .= ")";
$swap_threshold_output .= ")";

my $verbose = $verbose;

my ($mem_percent, $mem_total, $mem_used, $swap_percent, $swap_total, $swap_used) = &sys_stats();
my $free_mem = $mem_total - $mem_used;
my $free_swap = $swap_total - $swap_used;

# set output message
my $output = "Memory Usage".$mem_threshold_output.": ". $mem_percent.'% <br>';
$output .= "Swap Usage".$swap_threshold_output.": ". $swap_percent.'%';

# set verbose output message
my $verbose_output = "Memory Usage:".$mem_threshold_output.": ". $mem_percent.'% '."- Total: $mem_total MB, used: $mem_used MB, free: $free_mem MB<br>";
$verbose_output .= "Swap Usage:".$swap_threshold_output.": ". $swap_percent.'% '."- Total: $swap_total MB, used: $swap_used MB, free: $free_swap MB<br>";

# set perfdata message
my $perfdata_output = "MemUsed=$mem_percent\%;$mem_warning;$mem_critical";
$perfdata_output .= " SwapUsed=$swap_percent\%;$swap_warning;$swap_critical";


# if threshold are 0, exit with OK
if ( $mem_warning == 0 ) { $mem_warning = 101 };
if ( $swap_warning == 0 ) { $swap_warning = 101 };
if ( $mem_critical == 0 ) { $mem_critical = 101 };
if ( $swap_critical == 0 ) { $swap_critical = 101 };


if ($mem_percent>$mem_critical || $swap_percent>$swap_critical) {
    if ($verbose) { print "<b>CRITICAL: ".$verbose_output."</b>|".$perfdata_output."\n";}
    else { print "<b>CRITICAL: ".$output."</b>|".$perfdata_output."\n";}
    exit $ERRORS{'CRITICAL'};
} elsif ($mem_percent>$mem_warning || $swap_percent>$swap_warning) {
    if ($verbose) { print "<b>WARNING: ".$verbose_output."</b>|".$perfdata_output."\n";}
    else { print "<b>WARNING: ".$output."</b>|".$perfdata_output."\n";}
    exit $ERRORS{'WARNING'};
} else {
    if ($verbose) { print "OK: ".$verbose_output."|".$perfdata_output."\n";}
    else { print "OK: ".$output."|".$perfdata_output."\n";}
    exit $ERRORS{'OK'};
}

sub sys_stats {
    my @memory = split(" ", `free -mt`);
    my $mem_total = $memory[7];
    my $mem_used;
    if ( $DONT_INCLUDE_BUFFERS) { $mem_used = $memory[15]; }
    else { $mem_used = $memory[8];}
    my $swap_total = $memory[18];
    my $swap_used = $memory[19];
    my $mem_percent = ($mem_used / $mem_total) * 100;
    my $swap_percent;
    if ($swap_total == 0) {
  $swap_percent = 0;
    } else {
  $swap_percent = ($swap_used / $swap_total) * 100;
    }
    return (sprintf("%.0f",$mem_percent),$mem_total,$mem_used, sprintf("%.0f",$swap_percent),$swap_total,$swap_used);
}

sub print_usage () {
    print "Usage: $PROGNAME -w <warn> -c <crit> [-v] [-h]\n";
    exit $ERRORS{'UNKNOWN'} unless ($opt_h);
}

sub print_help () {
    print_revision($PROGNAME,'$Revision: '.$PROGVER.' $');
    print "Copyright (c) 2005 Garrett Honeycutt/Rouven Homann/Cedric Temple\n";
    print "\n";
    print_usage();
    print "\n";
    print "-w <MemoryWarn>,<SwapWarn> = Memory and Swap usage to activate a warning message (eg: -w 90,25 ) .\n";
    print "-c <MemoryCrit>,<SwapCrit> = Memory and Swap usage to activate a critical message (eg: -c 95,50 ).\n";
    print "-v = Verbose Output.\n";
    print "-h = This screen.\n\n";
    support();
}

#########################################################################
check_mem.sh:
#!/bin/bash

# Check Memory Usage via `free -mt`

########################
# DECLARATIONS
########################

PROGNAME=`basename $0`
REVISION=`echo '$Revision: 1.0 $' | sed -e 's/[^0-9.]//g'`

DEBUG=0

exitstatus=0
result=""
perfdata=""
pctWarning=""
pctCritical=""
pctSwpWarning=""
pctSwpCritical=""
rawOutput=0

status[0]="OK: "
status[1]="WARNING: "
status[2]="CRITICAL: "
status[3]="UNKNOWN: "

########################
# FUNCTIONS
########################

print_usage() {
  echo "Usage: $PROGNAME [options]"
  echo "  e.g. $PROGNAME -w 75 -c 95"
  echo
  echo "Options:"
  echo -e "\t --help    | -h       print help"
  echo -e "\t --version | -V       print version"
  echo -e "\t --verbose | -v       be verbose (debug mode)"
  echo -e "\t --raw     | -r       Use MB instead of % for output data"
  echo -e "\t -w [int]             set warning value for physical RAM used %"
  echo -e "\t -c [int]             set critical value for physical RAM used %"
  echo
  echo
}

print_help() {
#  print_revision $PROGNAME $REVISION
  echo "${PROGNAME} Revision: ${REVISION}"
  echo
  echo "This plugin checks local memory usage using 'free -mt' and 'ps axo comm,rss"
  echo
  print_usage
  echo
# support
  exit 3
}

parse_options() {
# parse cmdline arguments
  (( DEBUG )) && echo "Parsing options $1 $2 $3 $4 $5 $6 $7 $8"
  if [ "$#" -gt 0 ]; then
    while [ "$#" -gt 0 ]; do
      case "$1" in
        '--help'|'-h')
          print_help
          exit 3
          ;;
        '--version'|'-V')
          #print_revision $PROGNAME $REVISION
          echo "${PROGNAME} Revision: ${REVISION}"
          exit 3
          ;;
        '--verbose'|'-v')
          DEBUG=1
          shift 1
          ;;
        '--raw'|'-r')
          rawOutput=1
          shift 1
          ;;
        '-c')
          pctCritical="$2"
          shift 2
          ;;
        '-w')
          pctWarning="$2"
          shift 2
          ;;
        *)
          echo "Unknown option!"
          print_usage
          exit 3
          ;;
      esac
    done
  fi
}

########################
# MAIN
########################
if ps axo comm,rss | grep java &> /dev/null; then
  MemUsedList=$(ps axo comm,rss | grep java | awk '{print $2}')
  for I in $MemUsedList; do
    javaUsed+=$I
    (( DEBUG )) && echo "javaUsed=$javaUsed"
  done
else
  echo "Java was not started yet."
  exit 3
fi

parse_options $@

memory=$(free -mt)
 (( DEBUG )) && echo "memory=$memory"

phyTotal=$(cut -d' ' -f  8 <<< $memory)
 (( DEBUG )) && echo "phyTotal=$phyTotal"
phyShared=$(cut -d' ' -f 11 <<< $memory)
 (( DEBUG )) && echo "phyShared=$phyShared"
phyBuffers=$(cut -d' ' -f 12 <<< $memory)
 (( DEBUG )) && echo "phyBuffers=$phyBuffers"
phyCached=$(cut -d' ' -f 13 <<< $memory)
 (( DEBUG )) && echo "phyCached=$phyCached"
phyUsed=$(cut -d' ' -f 16 <<< $memory)
 (( DEBUG )) && echo "phyUsed=$phyUsed"
phyAllUsed=$(cut -d' ' -f 9 <<< $memory)
 (( DEBUG )) && echo "phyAllUsed=$phyAllUsed"

pctPhyShared=$(bc <<< "scale=2;$phyShared*100/$phyTotal")
 (( DEBUG )) && echo "pctPhyShared=$pctPhyShared"
pctPhyBuffers=$(bc <<< "scale=2;$phyBuffers*100/$phyTotal")
 (( DEBUG )) && echo "pctPhyBuffers=$pctPhyBuffers"
pctPhyCached=$(bc <<< "scale=2;$phyCached*100/$phyTotal")
 (( DEBUG )) && echo "pctPhyCached=$pctPhyCached"
pctPhyUsed=$(bc <<< "scale=2;$phyUsed*100/$phyTotal")
 (( DEBUG )) && echo "pctPhyUsed=$pctPhyUsed"
pctPhyAllUsed=$(bc <<< "scale=2;$phyAllUsed*100/$phyTotal")
 (( DEBUG )) && echo "pctPhyAllUsed=$pctPhyAllUsed"

 (( DEBUG )) && echo "rawOutput=$rawOutput"
 (( DEBUG )) && echo "pctWarning=$pctWarning"
 (( DEBUG )) && echo "pctCritical=$pctCritical"

if [ -n "$pctWarning" ]; then
  warning=$(bc <<< "scale=0;$pctWarning * $phyTotal / 100")
  (( DEBUG )) && echo "warning=$warning"
  if [ $(bc <<< "$javaUsed >= $pctWarning") -ne 0 ]; then
    exitstatus=1
  fi
fi

if [ -n "$pctCritical" ]; then
  critical=$(bc <<< "scale=0;$pctCritical * $phyTotal / 100")
  (( DEBUG )) && echo "critical=$critical"
  if [ $(bc <<< "$javaUsed >= $pctCritical") -ne 0 ]; then
    exitstatus=2
  fi
fi

  result="Memory Usage - ${phyUsed}MB of ${phyTotal}MB RAM used"
  perfdata="phyUsed=${phyUsed};${warning};${critical};0;${phyTotal} phyShared=${phyShared};;;0;${phyTotal} phyBuffers=${phyBuffers};;;0;${phyTotal} phyCached=${phyCached};;;0;${phyTotal} phyAllUsed=${phyAllUsed};;;0;${phyTotal}"

echo "${status[$exitstatus]}${result} | ${perfdata}"
exit $exitstatus

#########################################################################
check_mem.sh.bak:
#!/bin/bash

# Check Memory Usage via `free -mt`

########################
# DECLARATIONS
########################

PROGNAME=`basename $0`
REVISION=`echo '$Revision: 1.0 $' | sed -e 's/[^0-9.]//g'`

DEBUG=0

exitstatus=0
result=""
perfdata=""
pctWarning=""
pctCritical=""
pctSwpWarning=""
pctSwpCritical=""
rawOutput=0

status[0]="OK: "
status[1]="WARNING: "
status[2]="CRITICAL: "
status[3]="UNKNOWN: "

########################
# FUNCTIONS
########################

print_usage() {
  echo "Usage: $PROGNAME [options]"
  echo "  e.g. $PROGNAME -w 75 -W 25 -c 95 -C 75"
  echo
  echo "Options:"
  echo -e "\t --help    | -h       print help"
  echo -e "\t --version | -V       print version"
  echo -e "\t --verbose | -v       be verbose (debug mode)"
  echo -e "\t --raw     | -r       Use MB instead of % for output data"
  echo -e "\t -w [int]             set warning value for physical RAM used %"
  echo -e "\t -c [int]             set critical value for physical RAM used %"
  echo -e "\t -W [int]             set warning value for swap used %"
  echo -e "\t -C [int]             set critical value for swap used %"
  echo
  echo
}

print_help() {
#  print_revision $PROGNAME $REVISION
  echo "${PROGNAME} Revision: ${REVISION}"
  echo
  echo "This plugin checks local memory usage using 'free -mt'"
  echo
  print_usage
  echo
# support
  exit 3
}

parse_options() {
# parse cmdline arguments
  (( DEBUG )) && echo "Parsing options $1 $2 $3 $4 $5 $6 $7 $8"
  if [ "$#" -gt 0 ]; then
    while [ "$#" -gt 0 ]; do
      case "$1" in
        '--help'|'-h')
          print_help
          exit 3
          ;;
        '--version'|'-V')
          #print_revision $PROGNAME $REVISION
          echo "${PROGNAME} Revision: ${REVISION}"
          exit 3
          ;;
        '--verbose'|'-v')
          DEBUG=1
          shift 1
          ;;
        '--raw'|'-r')
          rawOutput=1
          shift 1
          ;;
        '-c')
          pctCritical="$2"
          shift 2
          ;;
        '-w')
          pctWarning="$2"
          shift 2
          ;;
        '-C')
          pctSwpCritical="$2"
          shift 2
          ;;
        '-W')
          pctSwpWarning="$2"
          shift 2
          ;;
        *)
          echo "Unknown option!"
          print_usage
          exit 3
          ;;
      esac
    done
  fi
}

########################
# MAIN
########################

parse_options $@

memory=$(free -mt)
 (( DEBUG )) && echo "memory=$memory"

phyTotal=$(cut -d' ' -f  8 <<< $memory)
 (( DEBUG )) && echo "phyTotal=$phyTotal"
swpTotal=$(cut -d' ' -f 19 <<< $memory)
 (( DEBUG )) && echo "swpTotal=$swpTotal"
phyShared=$(cut -d' ' -f 11 <<< $memory)
 (( DEBUG )) && echo "phyShared=$phyShared"
phyBuffers=$(cut -d' ' -f 12 <<< $memory)
 (( DEBUG )) && echo "phyBuffers=$phyBuffers"
phyCached=$(cut -d' ' -f 13 <<< $memory)
 (( DEBUG )) && echo "phyCached=$phyCached"
phyUsed=$(cut -d' ' -f 16 <<< $memory)
 (( DEBUG )) && echo "phyUsed=$phyUsed"
phyAllUsed=$(cut -d' ' -f 9 <<< $memory)
 (( DEBUG )) && echo "phyAllUsed=$phyAllUsed"
swpUsed=$(cut -d' ' -f 20 <<< $memory)
 (( DEBUG )) && echo "swpUsed=$swpUsed"

pctPhyShared=$(bc <<< "scale=2;$phyShared*100/$phyTotal")
 (( DEBUG )) && echo "pctPhyShared=$pctPhyShared"
pctPhyBuffers=$(bc <<< "scale=2;$phyBuffers*100/$phyTotal")
 (( DEBUG )) && echo "pctPhyBuffers=$pctPhyBuffers"
pctPhyCached=$(bc <<< "scale=2;$phyCached*100/$phyTotal")
 (( DEBUG )) && echo "pctPhyCached=$pctPhyCached"
pctPhyUsed=$(bc <<< "scale=2;$phyUsed*100/$phyTotal")
 (( DEBUG )) && echo "pctPhyUsed=$pctPhyUsed"
pctPhyAllUsed=$(bc <<< "scale=2;$phyAllUsed*100/$phyTotal")
 (( DEBUG )) && echo "pctPhyAllUsed=$pctPhyAllUsed"
if [ $swpTotal -eq 0 ]; then
  pctSwpUsed=0
else
  pctSwpUsed=$(bc <<< "scale=2;$swpUsed*100/$swpTotal")
fi
 (( DEBUG )) && echo "pctSwpUsed=$pctSwpUsed"
 (( DEBUG )) && echo "rawOutput=$rawOutput"
 (( DEBUG )) && echo "pctWarning=$pctWarning"
 (( DEBUG )) && echo "pctCritical=$pctCritical"
 (( DEBUG )) && echo "pctSwpWarning=$pctSwpWarning"
 (( DEBUG )) && echo "pctSwpCritical=$pctSwpCritical"

if [ -n "$pctWarning" ]; then
  warning=$(bc <<< "scale=0;$pctWarning * $phyTotal / 100")
  (( DEBUG )) && echo "warning=$warning"
  if [ $(bc <<< "$pctPhyUsed >= $pctWarning") -ne 0 ]; then
    exitstatus=1
  fi
fi

if [ -n "$pctSwpWarning" ]; then
  swpWarning=$(bc <<< "scale=0;$pctSwpWarning * $swpTotal / 100")
  (( DEBUG )) && echo "swpWarning=$swpWarning"
  if [ $(bc <<< "$pctSwpUsed >= $pctSwpWarning") -ne 0 ]; then
    exitstatus=1
  fi
fi

if [ -n "$pctCritical" ]; then
  critical=$(bc <<< "scale=0;$pctCritical * $phyTotal / 100")
  (( DEBUG )) && echo "critical=$critical"
  if [ $(bc <<< "$pctPhyUsed >= $pctCritical") -ne 0 ]; then
    exitstatus=2
  fi
fi

if [ -n "$pctSwpCritical" ]; then
  swpCritical=$(bc <<< "scale=0;$pctSwpCritical * $swpTotal / 100")
  (( DEBUG )) && echo "swpCritical=$swpCritical"
  if [ $(bc <<< "$pctSwpUsed >= $pctSwpCritical") -ne 0 ]; then
    exitstatus=2
  fi
fi

if [ $rawOutput -eq 1 ]; then
  result="Memory Usage - ${phyUsed}MB of ${phyTotal}MB RAM used, ${swpUsed}MB of ${swpTotal}MB Swap used"
  perfdata="phyUsed=${phyUsed};${warning};${critical};0;${phyTotal} phyShared=${phyShared};;;0;${phyTotal} phyBuffers=${phyBuffers};;;0;${phyTotal} phyCached=${phyCached};;;0;${phyTotal} phyAllUsed=${phyAllUsed};;;0;${phyTotal} swpUsed=${swpUsed};${swpWarning};${swpCritical};0;${swpTotal}"
else
  result="Memory Usage - ${pctPhyUsed}% RAM, ${pctSwpUsed}% Swap"
  perfdata="phyUsed=${pctPhyUsed}%;${pctWarning};${pctCritical};0;100 phyShared=${pctPhyShared}%;;;0;100 phyBuffers=${pctPhyBuffers}%;;;0;100 phyCached=${pctPhyCached}%;;;0;100 phyAllUsed=${pctPhyAllUsed}%;;;0;100 swpUsed=${pctSwpUsed}%;${pctSwpWarning};${pctSwpCritical};0;100"
fi

echo "${status[$exitstatus]}${result} | ${perfdata}"
exit $exitstatus


#########################################################################
debug.sh:
#!/bin/bash
#
DEBUG=0

case $1 in
-v|--verbose)
  DEBUG=1 ;;
*) 
  echo "Unknown options"
  exit 7
  ;;
esac

[ $DEBUG -eq 1 ] && echo hello

#########################################################################
delusers.sh:
#!/bin/bash
#

for I in {1..10}; do
  if id user$I &> /dev/null; then
    userdel -r user$I
    echo "Delete user$I finished."
  else
    echo "user$I not exist."
  fi
done


#########################################################################
filetest2.sh:
#!/bin/bash
#
FILE=/etc/rc.dddd

if [ ! -e $FILE ]; then
  echo "No such file."
  exit
fi

if [ -f $FILE ]; then
  echo "Common file."
elif [ -d $FILE ]; then
  echo "Directory."
else
  echo "Unknown."
fi

#########################################################################
filetest3.sh:
#!/bin/bash
#
if [ $# -lt 1 ]; then
  echo "Usage: ./filetest3.sh ARG1 [ARG2 ...]"
  exit 7
fi

if [ -e $1 ]; then
  echo "OK."
else
  echo "No such file."
fi

#########################################################################
filetest.sh:
#!/bin/bash
#
FILE=/etc/inittabb

if [ -e $FILE ]; then
  echo "OK"
else
  echo "No such file."
fi

#########################################################################
first.sh:
#!/bin/bash
cat /etc/fstab
# ls /var

#########################################################################
hello.sh:
#!/bin/bash
#
if [ $# -gt 0 ]; then
  if [ $1 == '--add' ]; then
    OP='useradd'
    USERS=$2
    shift 2
  elif [ $1 == '--del' ]; then
    OP='userdel -r'
    USERS=$2
    shift 2
  else
    echo "Unknown Options."
    exit 3
  fi
fi

$OP $USERS

#########################################################################
quit.sh:
#!/bin/bash
#
if [ $1 == 'q' -o $1 == 'Q' -o $1 == 'Quit' -o $1 == 'quit' ]; then
  echo "Not Quiting..."
  exit 0
else
  echo "Unknown Argument."
  exit 1
fi

#########################################################################
random.sh:
#!/bin/bash
#
declare -i MAX=0
declare -i MIN=0

for I in {1..10}; do
  MYRAND=$RANDOM
  [ $I -eq 1 ] && MIN=$MYRAND
  if [ $I -le 9 ]; then
    echo -n "$MYRAND,"
  else
    echo "$MYRAND"
  fi
  [ $MYRAND -gt $MAX ] && MAX=$MYRAND
  [ $MYRAND -lt $MIN ] && MIN=$MYRAND
done

echo $MAX, $MIN

#########################################################################
rc.functions:
# /etc/rc.d/rc.functions
# (2009) Douglas Jerome <douglas@ttylinux.org>

export PATH=/sbin:/usr/sbin:/bin:/usr/bin
export LC_ALL=POSIX
umask 022

RC_SIZE=$(stty -F /dev/console size)
RC_COLUMNS=${RC_SIZE#* }
[[ "${RC_COLUMNS}" = "0" ]] && RC_COLUMNS=80
RC_STATUS_COLUMN=$((${RC_COLUMNS}-11))

MOVE_TO_STATCOL="\\033[${RC_STATUS_COLUMN}G"
T_RED="\\033[1;31m"    # bold+red
T_GREEN="\\033[1;32m"  # bold+green
T_YELLOW="\\033[1;33m" # bold+yellow
T_BLUE="\\033[1;34m"   # bold+blue
T_CYAN="\\033[1;36m"   # cyan
T_BOLD="\\033[1;37m"   # bold+white
T_NORM="\\033[0;39m"   # normal
T_PASS=${T_GREEN}
T_WARN=${T_YELLOW}
T_FAIL=${T_RED}

success() {
	local count=$((${RC_STATUS_COLUMN}-${#1}))
	echo -n "${1} "
	while [[ ${count} -gt 0 ]];do
		echo -en "${T_BLUE}.${T_NORM}"
		count=$((${count}-1))
	done
	echo -e $" [  ${T_PASS}OK${T_NORM}  ]"
}

attn() {
	local count=$((${RC_STATUS_COLUMN}-${#1}))
	echo -n "${1} "
	while [[ ${count} -gt 0 ]];do
		echo -en $"${T_BLUE}.${T_NORM}"
		count=$((${count}-1))
	done
	echo -e $" [ ${T_WARN}ATTN${T_NORM} ]"
}

failure() {
	local count=$((${RC_STATUS_COLUMN}-${#1}))
	echo -n "${1} "
	while [[ ${count} -gt 0 ]];do
		echo -en $"${T_BLUE}.${T_NORM}"
		count=$((${count}-1))
	done
	echo -e $" [${T_FAIL}FAILED${T_NORM}]"
}

waiting() {
	local count=$((${RC_STATUS_COLUMN}-${#1}))
	echo -n $"${1} "
	while [[ ${count} -gt 0 ]];do
		echo -en $"${T_BLUE}.${T_NORM}"
		count=$((${count}-1))
	done
	echo -en $" [${T_WARN}WATING${T_NORM}]"
	echo -en "${MOVE_TO_STATCOL}${T_BLUE}..${T_NORM}"
}

done_success() {
	echo -e $" [  ${T_PASS}OK${T_NORM}  ]"
}

done_failure() {
	echo -e $" [${T_FAIL}FAILED${T_NORM}]"
}

action() {
	local rc=
	local string=${1}
	shift
	$* && success "${string}" || failure "${string}"
	rc=$?
	return ${rc}
}

load_proc() {
	local name=""
	local nicelevel=""
	if [[ $# = 0 ]]; then
		echo "Usage: load_proc [ +/-nicelevel ] PROGRAM" 1>&2
		return 1
	fi
	name=${1##*/} # basename ${1}
	case ${1} in
		[-+][0-9]*)
			nicelevel="nice -n ${1}"
			shift
			;;
	esac
	ulimit -S -c 0
	${nicelevel} $@
	if [[ $? -eq 0 ]]; then
		success "startup ${name}"
	else
		failure "startup ${name}"
	fi
}

kill_proc() {
	local killlevel=""
	local name=""
	local pidlist=""
	if [[ $# = 0 ]]; then
		echo "Usage: kill_proc PROGRAM [ signal ]" 1>&2
		return 1
	fi
	name=${1##*/} # basename ${1}
	pidlist=$(pidof -o $$ -o $PPID -o %PPID ${name})
	[[ "${2}" != "" ]] && killlevel="-${2}" || killlevel="-9"
	if [[ -n "${pidlist}" ]]; then
		kill ${killlevel} ${pidlist}
		if [[ $? -eq 0 ]]; then
			success "signal(kill) ${killlevel} ${name}"
			rm -f /var/run/${name}.pid
		else
			failure "signal(kill) ${killlevel} ${name}"
		fi
	else
		attn "signal(kill) ${killlevel} ${name} ** NO PID **"
	fi
}

status_proc() {
	local name=""
	local pid=""
	if [[ $# = 0 ]]; then
		echo "Usage: status_proc {program}"
		return 1
	fi
	name=${1##*/} # basename ${1}
	pid=$(pidof -o $$ -o $PPID -o %PPID ${name})
	if [[ -n "${pid}" ]]; then
		echo "${1} running with process id ${pid}."
		return 0
	fi
	if [[ -f /var/run/${name}.pid ]]; then
		read pid < /var/run/${name}.pid
		if [[ -n "${pid}" ]]; then
			echo "${1} not running but /var/run/${name}.pid exists."
			return 1
		fi
	fi
	if [[ -f /var/lock/subsys/${name} ]]; then
		echo $"${name} not running but /var/lock/subsys/${name} exists."
		return 2
	fi
	echo "${1} is not running."
	return 3
}

which_prog() {
	local prog=""
	for p in $(echo ${PATH} | tr ':' ' '); do
		[[ -x "${p}/${1}" ]] && prog="${p}/${1}"
	done
	echo ${prog}
}

#########################################################################
second.sh:
#!/bin/bash
LINES=`wc -l /etc/inittab`
#echo $LINES

FINLINES=`echo $LINES | cut -d' ' -f1`
#echo $FINLINES

[ $FINLINES -gt 100 ] && echo "/etc/inittab is a big file." || echo "/etc/inittab is a small file."

#########################################################################
service.sh:
#!/bin/bash
#
case $1 in
'start')
  echo "start server ..." ;;
'stop')
  echo "stop server ..." ;;
'restart')
  echo "Restarting server ..." ;;
'status')
  echo "Running..." ;;
*)
  echo "`basename $0` {start|stop|restart|status}" ;;
esac

#########################################################################
shift.sh:
#!/bin/bash
#
echo $1
shift 2
echo $1
shift 2
echo $1

#########################################################################
showlogged.sh:
#!/bin/bash
#
declare -i SHOWNUM=0
declare -i SHOWUSERS=0

for I in `seq 1 $#`; do
  if [ $# -gt 0 ]; then
    case $1 in
    -h|--help)
      echo "Usage: `basename $0` -h|--help -c|--count -v|--verbose"
      exit 0 ;;
    -v|--verbose)
      let SHOWUSERS=1 
      shift ;;
    -c|--count)
      let SHOWNUM=1 
      shift ;;
    *)
      echo "Usage: `basename $0` -h|--help -c|--count -v|--verbose"
      exit 8 ;;
    esac
  fi
done

if [ $SHOWNUM -eq 1 ]; then
  echo "Logged users: `who | wc -l`."
  if [ $SHOWUSERS -eq 1 ]; then
    echo "They are:"
    who
  fi      
fi


#########################################################################
showshells.sh:
#!/bin/bash
#
if [ $1 == '-s' ]; then
  ! grep "${2}$" /etc/shells &> /dev/null && echo "Invalid shell." && exit 7
elif [ $1 == '--help' ];then
  echo "Usage: `basename $0` -s SHELL | --help"
  exit 0
else
  echo "Unknown Options."
  exit 8
fi

NUMOFUSER=`grep "${2}$" /etc/passwd | wc -l` 
SHELLUSERS=`grep "${2}$" /etc/passwd | cut -d: -f1`
SHELLUSERS=`echo $SHELLUSERS | sed 's@[[:space:]]@,@g'`

echo -e "$2, $NUMOFUSER users, they are: \n$SHELLUSERS"

#########################################################################
showsum.sh:
#!/bin/bash
#
declare -i EVENSUM=0
declare -i ODDSUM=0

for I in {1..100}; do
  if [ $[$I%2] -eq 0 ]; then
    let EVENSUM+=$I
  else
    let ODDSUM+=$I
  fi
done

echo "Odd sum is: $ODDSUM."
echo "Even sum is: $EVENSUM."

#########################################################################
showusers2.sh:
#!/bin/bash
#
NUMBASH=`grep "bash$" /etc/passwd | wc -l`

BASHUSERS=`grep "bash$" /etc/passwd | cut -d: -f1`

BASHUSERS=`echo $BASHUSERS | sed 's@[[:space:]]@,@g'`

echo "BASH, $NUMBASH users, they are:"
echo "$BASHUSERS"


#########################################################################
showusers.sh:
#!/bin/bash
#
LINES=`wc -l /etc/passwd | cut -d' ' -f1`
declare -i NUMBASH=0

for I in `seq 1 $LINES`; do
  if [ `head -$I /etc/passwd | tail -1 | cut -d: -f7 | cut -d'/' -f3` == 'bash' ]; then
    NUMBASH=$[$NUMBASH+1]
    [ -z $BASHUSERS ] && BASHUSERS=`head -$I /etc/passwd | tail -1 | cut -d: -f1` || BASHUSERS="$BASHUSERS,`head -$I /etc/passwd | tail -1 | cut -d: -f1`"
  fi
done

echo "BASH, $NUMBASH users, they are:"
echo "$BASHUSERS"
    


#########################################################################
sum.sh:
#!/bin/bash
#
declare -i SUM=0

for I in {1..100}; do
  let SUM=$[$SUM+$I]
done

echo "The sum is: $SUM."

#########################################################################
testuser2.sh:
#!/bin/bash
#


#########################################################################
testuser.sh:
#!/bin/bash
#
if ! id $1 &>/dev/null; then
  echo "No such user."
  exit 10
fi

if [ $1 == `id -n -g $1` ]; then
  echo "Yiyang"
else
  echo "Bu Yiyang"
fi

#########################################################################
third.sh:
#!/bin/bash
#
NAME=root
USERID=`id -u $NAME`
[ $USERID -eq 0 ] && echo "Admin" || echo "Common user."

#########################################################################
usertest.sh:
#!/bin/bash
#
NAME=user17

if id $NAME &> /dev/null; then
  echo "$NAME exists."
else
  useradd $NAME
  echo $NAME | passwd --stdin $NAME &> /dev/null
  echo "Add $NAME finished."
fi
