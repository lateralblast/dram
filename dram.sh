#!/bin/sh

# Name:         dram (Disk Raid Automated/Alert Monitoring)
# Version:      0.0.4
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: Linux
# Vendor:       UNIX
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Shell script
#               Written in bourne shell so it can be run on different releases

# Set some defaults

host_name=`hostname`
do_slack="no"
do_list="no"
do_email="no"
do_false="no"
megacli="/opt/MegaRAID/MegaCli/MegaCli64"

# Get the path the script starts from

start_path=`pwd`

# Get the script info from the script itself

app_vers=`cd $start_path ; cat $0 | grep '^# Version' |awk '{print $3}'`
app_name=`cd $start_path ; cat $0 | grep '^# Name' |awk '{for (i=3;i<=NF;++i) printf $i" "}'`
app_pkgr=`cd $start_path ; cat $0 | grep '^# Packager' |awk '{for (i=3;i<=NF;++i) printf $i" "}'`
app_help=`cd $start_path ; cat $0 | grep -A1 " [A-Z,a-z])$" |sed 's/#//g'`

# Set up directory for storing Slack hook etc

home_dir=$HOME
dram_dir="$home_dir/.dram"
slack_file="$dram_dir/slack_hook_file"
email_file="$dram_dir/email_list_file"

if [ ! -d "$dram_dir" ]; then
  mkdir -p $dram_dir
fi

# Print some help

print_help() {
  echo "$app_name $app_vers"
  echo "$app_pkgr"
  echo ""
  echo "Usage Information:"
  echo ""
  echo "$app_help"
  echo ""
  return
}

# Install check

install_check() {
  if [ -z `which mail` ]; then
    sudo apt-get install -y mailutils
  fi
  if [ ! -f "$megacli" ]; then
    cd /tmp
    if [ ! -f "/tmp/8-07-14_MegaCLI.zip" ]; then
      wget wget https://docs.broadcom.com/docs-and-downloads/raid-controllers/raid-controllers-common-files/8-07-14_MegaCLI.zip
    fi
    if [ -z `which alien` ]; then
      sudo apt-get install -y alien
    fi
    if [ -z `which unzip` ]; then
      sudo apt-get install -y unzip
    fi
    unzip 8-07-14_MegaCLI.zip
    cd Linux
    alien MegaCli-8.07.14-1.noarch.rpm
    sudo dpkg -i megacli_8.07.14-2_all.deb
  fi
}

# Handle alert

handle_alert() {
  device=$1
  if [ "$do_slack" = "yes" ]; then
    curl -X POST -H 'Content-type: application/json' --data "{'text':'Warning $device on $host_name is not optimal'}" $slack_hook
  fi
  if [ "$do_email" = "yes" ]; then
    echo "Warning $device on $host_name is not Optimal" | mail -s "Warning $device on $host_name is not optimal" $alert_email
  fi
  return
}

# List devices

list_devices() {
  install_check
  sudo lshw -class disk -businfo |grep "PERC" | while read line ; do
    device=`echo "$line" |awk '{print $2}'`
    fstab=`cat /etc/fstab |grep "$device"`
    echo "Device: $device"
    if [ -z "$fstab" ]; then
      printf "Filesystem: "
      sudo pvscan |grep "$device" |awk '{print $4}' |while read volume; do
      	sudo lvscan |grep "$volume" |awk '{print $2}' |sed "s/'//g" |while read fstab; do
	  printf "$fstab "
        done
      done
      printf "\n"
    else
      echo "Filesystem: $fstab"
    fi
    vdisk=`sudo lshw -class disk -businfo |grep "PERC" |grep "$device" |awk '{print $1}' |cut -f2 -d: |cut -f2 -d.`
    sudo $megacli -LDInfo -L$vdisk -aAll |sed "s/: /:/g" |grep ":" |egrep -v "^Adapter|^Exit" |tr -s '[:blank:]' ' ' |sed "s/ :/:/g" |sed "s/:/: /g" |while read info; do
      if [ -z "`echo "$info" |grep "^State"`" ]; then
	echo "$info"
      else
        if [ -z "`echo "$info" |grep '^State' |grep Optimal`" ]; then
	  handle_alert $device
	else
	  if [ "$do_false" = "yes" ]; then
	    handle_alert $device
          fi
	fi
        echo "$info"
      fi
    done
  done
  return
}

# Handle command line arguments

while getopts "Vhsmlf" opt; do
  case $opt in
    V)
      # Display Version
      echo "$app_vers"
      exit
      ;;
    f)
      # Create false alerts
      do_false="yes"
      ;;
    h)
      # Display Usage Information
      print_help
      exit
      ;;
    s)
      # Use Slack to post alerts
      do_slack="yes"
      ;;
    m)
      # Email alerts
      do_email="yes"
      ;;
    l)
      # List devices
      do_list="yes"
      ;;
    *)
      print_help
      exit
      ;;
  esac
done

if [ "$do_slack" = "yes" ]; then
  if [ -f "$slack_file" ] ; then
    slack_hook=`cat $slack_file`
  else
    echo "Warning Slack hook file $slack_file does not exist"
    exit
  fi
fi

if [ "$do_email" = "yes" ]; then
  if [ -f "$email_file" ] ; then
    alert_email=`cat $email_file`
  else
    echo "Warning email alert list file $email_file does not exist"
    exit
  fi
fi

if [ "$do_list" = "yes" ]; then
  list_devices
  exit
fi

# If given no command line arguments print usage information

if [ `expr "$args" : "\-"` != 1 ]; then
  print_help
  exit
fi
