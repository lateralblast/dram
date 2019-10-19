![alt tag](https://raw.githubusercontent.com/lateralblast/dram/master/dram.jpg)

DRAM
====

Disk/Drive RAID Alert/Automated Monitoring

Introduction
------------

A simple shell script for monitoring RAID devices.

Why a shell script? To minimise the number of additional packages needed.

Features
--------

Current Supported RAID controllers:

- PERC H700

This is the begining of updating/rewriting some old scripts to utilise updated tools such as lshw.

The slack hook and email address information are read from files so that the information does not appear in the script.

Supported Operating Systems
---------------------------

The following Operating Systems are currently supported:

- Linux
  - Ubuntu

Supported Services
------------------

The following alerting services are supported:

- Slack
- Email

Requirements
------------

The script will attempt to install required supported packages if they are not available and are required.

- Ubuntu / Debian
  - mailutils (to send email alerts)
  - LSI MegaCLI
  - alien (to convert LSI MegaCLI RPM)
  - unzip

License
-------

This software is licensed as CC-BA (Creative Commons By Attrbution)

http://creativecommons.org/licenses/by/4.0/legalcode

Usage
-----

Get usage information:

```
./dram.sh -h
dram (Disk Raid Automated/Alert Monitoring)  0.0.4
Richard Spindler <richard@lateralblast.com.au>

Usage Information:

    V)
       Display Version
    f)
       Create false alerts
    h)
       Display Usage Information
    s)
       Use Slack to post alerts
    m)
       Email alerts
    l)
       List devices
```


Examples
--------

List devices and send alerts to Slack:

```
./dram.sh -l -s
```

The following example is useful for testing purposes.

List devices and send false alerts to Slack:

```
./dram.sh -l -f -s
```
