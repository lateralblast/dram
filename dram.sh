#!/bin/sh

# Name:         dram (Disk RAID Automated/Alert Monitoring)
# Version:      0.1.3
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
#               Written in bash so it can be run on different releases

# Set some defaults

host_name=$(hostname)
do_slack="no"
do_list="no"
do_email="no"
do_false="no"
megacli="/opt/MegaRAID/MegaCli/MegaCli64"
auto_update="yes"

# Get the path the script starts from

app_file="$0"
app_path=$(dirname "$app_file")
app_base=$(basename "$app_file")

# Get the script info from the script itself

app_vers=$(cd "$app_path" || exit ; grep "^# Version" "$0" |awk '{print $3}')
app_name=$(cd "$app_path" || exit ; grep "^# Name" "$0" |awk '{for (i=3;i<=NF;++i) printf $i" "}' |sed 's/ $//g')
app_same=$(cd "$app_path" || exit ; grep "^# Name" "$0" |awk '{print $3}')
app_pkgr=$(cd "$app_path" || exit ; grep "^# Packager" "$0" |awk '{for (i=3;i<=NF;++i) printf $i" "}')
app_help=$(cd "$app_path" || exit ; grep -A1 " [A-Z,a-z])$" "$0" |sed "s/[#,\-\-]//g" |sed '/^\s*$/d')

# Remote version file

rem_vers_url="https://raw.githubusercontent.com/lateralblast/$app_same/master/version"
rem_app_url="https://raw.githubusercontent.com/lateralblast/$app_same/master/$app_base"
echo "$rem_app_url"
exit
rem_vers_dir="/tmp/$app_same"
if [ ! -d "$rem_vers_dir" ] ; then
  mkdir "$rem_vers_dir"
fi
rem_vers_file="$rem_vers_dir/version"

handle_vers() {
  echo "$@" |awk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }';
}

self_update() {
  printf "Checking $app_same is up to date... "
  if [ -f "$rem_vers_file" ] ; then
    rm "$rem_vers_file"
  fi
  curl -s -o "$rem_vers_file" "$rem_vers_url"
  if [ -f "$rem_vers_file" ] ; then
    rem_vers=$(cat "$rem_vers_file")
    if [ "$(handle_vers "$rem_vers")" -gt "$(handle_vers "$app_vers")" ]; then
      printf "Newer version of $app_same exists\n"
      if [ "$auto_update" = "yes" ] ; then
        echo "Updating $app_same"
        curl -s -o "$app_file" "$rem_app_url"
        exec "$app_file" "$@"
        exit 1
      fi
    else
      printf "$app_same is up to date\n"
    fi
  fi
}

self_update

# Set up directory for storing Slack hook etc

home_dir=$HOME
dram_dir="$home_dir/.dram"
slack_file="$dram_dir/slack_hook_file"
email_file="$dram_dir/email_list_file"
os_name=$(uname)

# Create config directory if not present

if [ ! -d "$dram_dir" ]; then
  mkdir -p "$dram_dir"
fi

# Work out which package manager to use

if [ -f "/etc/redhat-release" ]; then
  pkg_bin="yum"
else
  pkg_bin="apt-get"
fi

# Check we are running on a supported OS

os_check() {
  if [ ! "$os_name" = "Linux" ] ; then
    echo "Currently only Linux is supported"
    exit
  fi
  return
}

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

# LSI install check

lsi_install_check() {
  if [ ! -f "$megacli" ]; then
    cd /tmp || exit
    if [ ! -f "/tmp/8-07-14_MegaCLI.zip" ]; then
      wget https://docs.broadcom.com/docs-and-downloads/raid-controllers/raid-controllers-common-files/8-07-14_MegaCLI.zip
    fi
    unzip 8-07-14_MegaCLI.zip
    cd Linux || exit
    if [ "$pkg_bin" = "yum" ] ; then
      sudo $pkg_bin -i MegaCli-8.07.14-1.noarch.rpm
    else
      alien MegaCli-8.07.14-1.noarch.rpm
      sudo $pkg_bin -i megacli_8.07.14-2_all.deb
    fi
  fi
  if [ ! -e "/usr/bin/megacli" ];  then
    sudo sh -c "ln -s $megacli /usr/bin/megacli"
  fi
  return
}

# Install check

install_check() {
  os_check
  if [ ! "$pkg_bin" = "yum" ] ; then
    if [ -z "$(command -v alien)" ]; then
      sudo $pkg_bin install -y alien
    fi
  fi
  if [ -z "$(command -v unzip)" ]; then
    sudo $pkg_bin install -y unzip
  fi
  if [ -z "$(command -v mail)" ]; then
    sudo $pkg_bin install -y mailutils
  fi
  if [ -z "$(command -v lsscsi)" ]; then
    sudo $pkg_bin install -y lsscsi
  fi
  return
}

# Handle alert

handle_alert() {
  device=$1
  if [ "$do_slack" = "yes" ]; then
    curl -X POST -H 'Content-type: application/json' --data "{'text':'Warning $device on $host_name is not optimal'}" "$slack_hook"
  fi
  if [ "$do_email" = "yes" ]; then
    echo "Warning $device on $host_name is not Optimal" | mail -s "Warning $device on $host_name is not optimal" "$alert_email"
  fi
  return
}

# List devices

list_devices() {
  install_check
  sudo sh -c "lsscsi -d |grep -Ei \"PERC|RAID\" |awk '{print \$1\":\"\$7}' |sed 's/\[//g' |sed 's/\]//g'" | while read -r line ; do
    if echo "$line" |grep -Ei "PERC|MegaRAID|RD2|TD2|TS4"; then
      lsi_install_check
    else
      if echo "$line" |grep -Ei "ServeRAID"; then
        if echo "$line" |grep -Ei "M51|M50|M10|MR10"; then
          lsi_install_check
        fi
      fi
    fi
    devnum=$(echo "$line" |cut -f3 -d:)
    device=$(echo "$line" |cut -f5 -d:)
    fstab=$(grep "$device" /etc/fstab || exit)
    echo "Device: $device"
    if [ -z "$fstab" ]; then
      printf "Filesystem: "
      sudo sh -c "pvscan |grep \"$device\" |awk '{print \$4}'" |while read -r volume; do
        sudo sh -c "lvscan |grep \"$volume\" |awk '{print \$2}'" |sed "s/'//g" |while read -r entry; do
          printf "%s " "$entry"
        done
      done
      printf "\n"
    else
      echo "Filesystem: $fstab"
    fi
    sudo sh -c "$megacli -LDInfo -L\"$devnum\" -aAll |sed \"s/: /:/g\" |grep \":\" |grep -Ev \"^Adapter|^Exit\" |tr -s '[:blank:]' ' ' |sed \"s/ :/:/g\" |sed \"s/:/: /g\"" |while read -r info; do
      if echo "$info" |grep "^State" ; then
        if echo "$info" |grep "^State" |grep "Optimal"; then
          handle_alert "$device"
        else
          if [ "$do_false" = "yes" ]; then
            handle_alert "$device"
          fi
        fi
      fi
      echo "$info"
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

# Handle Slack hook

if [ "$do_slack" = "yes" ]; then
  if [ -f "$slack_file" ] ; then
    slack_hook=$(cat "$slack_file")
  else
    echo "Warning Slack hook file $slack_file does not exist"
    exit
  fi
fi

#Handle alert email address

if [ "$do_email" = "yes" ]; then
  if [ -f "$email_file" ] ; then
    alert_email=$(cat "$email_file")
  else
    echo "Warning email alert list file $email_file does not exist"
    exit
  fi
fi

# Handle list

if [ "$do_list" = "yes" ]; then
  list_devices
  exit
fi

# If given no command line arguments print usage information

if expr "$opt" : "\-" != 1; then
  print_help
  exit
fi
