#!/usr/bin/bash
# ---------------------------------------------------------------------------
# jboss.sh - JBoss Demo Environment Setup

# Copyright 2015, Red Hat Inc.
  
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.

# Revision history:
# 2015-11-12 Created 
# ---------------------------------------------------------------------------

PROGNAME=${0##*/}
VERSION="0.1"

clean_up() { 
  return
}

error_exit() {
  echo -e "${PROGNAME}: ${1:-"Unknown Error"}" >&2
  echo
  clean_up
  exit 1
}

graceful_exit() {
  clean_up
  exit
}

signal_exit() { 
  case $1 in
    INT)
      error_exit "Program interrupted by user" ;;
    TERM)
      echo -e "\n$PROGNAME: Program terminated" >&2
      graceful_exit ;;
    *)
      error_exit "$PROGNAME: Terminating on unknown signal" ;;
  esac
}

usage() {
  echo -e "Usage: $PROGNAME [-h|--help|--jon-help] [-s server -d|-i] [jon|eap]"
}

help_message() {
  cat <<- _EOF_
  $PROGNAME ver. $VERSION
  JBoss Demo Environment Setup

  $(usage)

  Options:
  -h, --help This help message
  --jon-help JBoss-ON database setup help
  -d  Download
  -i  Install
  -s  Server hostname to download from

_EOF_
  return
}

jon_help_message() {

  cat <<- _EOF_
$PROGNAME ver. $VERSION
JBoss Demo Environment Setup

Postgres database setup for JBoss Operations Network

Step 1: Setup sudo access by logging in as root and execute visudo command. Verify setup by executing "sudo id" and check if it ran as root.

Step 2: If Postgres database is not already installed, download and install it in your local RHEL environment using the following commands:

sudo yum install -y postgres\*
sudo service postgresql initdb
sudo service postgresql start
sudo service postgresql status
sudo service postgresql stop

Step 3: Search and uncomment and update each of the parameters in postgresql.conf file as shown below.

# Performance changes for JBoss ON
shared_buffers = 80MB    
work_mem = 2048MB       
checkpoint_segments = 10

sudo su - postgres -c "vi /var/lib/pgsql/data/postgresql.conf"

Step 4: Start Postgres database
sudo service postgresql start
sudo service postgresql status

Step 5: /tmp/jbosson.sql has been created with SQL commands to be run in Postgres. Execute it.

sudo su - postgres -c "psql -f /tmp/jbosson.sql"

Step 6: Modify the file pg_hba.conf and replace all authentication methods to md5 in the end of the file.
sudo su - postgres -c "vi /var/lib/pgsql/data/pg_hba.conf"

Step 7: Restart Postgres

sudo service postgresql stop
sudo service postgresql start
sudo service postgresql status
  
_EOF_
}

# Trap signals
trap "signal_exit TERM" TERM HUP
trap "signal_exit INT"  INT

action=
target=
server=

# Parse command-line
while [[ -n $1 ]]; do
  case $1 in
    -h | --help)
      help_message; graceful_exit ;;
    --jon-help)
      jon_help_message; graceful_exit ;;
    -d)
      if [ "x$target" != "x" ]
      then
        usage
        error_exit "Invalid option"
      else
        shift; target="$1" ; action=download 
      fi
      ;;
    -i)
      shift; target="$1" ; action=install ;;
    -s)
      shift; server="$1" ;;
    -* | --*)
      usage
      error_exit "Unknown option $1" ;;
    *)
      usage
      error_exit "Unknown option $1" ;;
  esac
  shift
done

error_flag=0
[ "x$target" = "x" -o "x$action" = "x" ] && error_flag=1
[ "x$action" = "xdownload" -a "x$server" = "x" ] && error_flag=1

if [ $error_flag -eq 1 ]
then
  usage
  error_exit "Provide relevant options to proceed";
fi

# Util Functions

log() {
    TSTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$TSTAMP: $*"
}

logc() {
    TSTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo -n "$TSTAMP: $1 ... "
}

loga() {
    echo "$*"
}

log_exit() {
    TSTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$TSTAMP: $*"
    echo
    exit 1
}

jget() {
  bname=$(basename $1)
  logc "Downloading $bname"
  wget --output-file=wget.log $1
  if [ $? -eq 0 ]
  then
    loga "... Success!"
  else
    loga "... Error! Check wget.log for details"
  fi
}

# JBoss Demo Environment Setup

if [ "x$action" = "xdownload" -a "x$target" = "xjon" ]
then
  log "JBoss Demo Environment Setup ver. $VERSION"
  log "Downloading JBoss Operations Network from $server"
  log "Checking for JBoss-ON directory at `/usr/bin/pwd`"
  if [ -d Downloads/JBoss-ON ]
  then
    log_exit "JBoss-ON directory exists! Please rename it and then rerun this script"
  else
    mkdir -p Downloads/JBoss-ON; chmod 755 Downloads/JBoss-ON; cd Downloads/JBoss-ON
    log "Created JBoss-ON directory"
  fi

  log "Downloading JBoss-ON Server"
  jget http://$server/released/JBossON/3.3.0/jon-server-3.3.0.GA.zip
  log "Downloading JBoss-ON Patches"
  jget http://$server/released/JBossON/3.3.4/jon-server-3.3-update-04.zip

  log "Download JBoss-ON Plugins"
  jget http://$server/released/JBossON/3.3.0/jon-plugin-pack-datavirtualization-3.3.0.GA.zip
  jget http://$server/released/JBossON/3.3.0/jon-plugin-pack-brms-bpms-3.3.0.GA.zip
  jget http://$server/released/JBossON/3.3.0/jon-plugin-pack-fuse-3.3.0.GA.zip
  jget http://$server/released/JBossON/3.3.0/jon-plugin-pack-jdg-3.3.0.GA.zip

  echo "ALTER USER postgres PASSWORD 'postgres';" > jbosson.sql
  echo "CREATE USER rhqadmin PASSWORD 'rhqadmin';" >> jbosson.sql
  echo "CREATE DATABASE rhq OWNER rhqadmin;" >> jbosson.sql
  echo "ALTER USER rhqadmin SET statement_timeout=0;" >> jbosson.sql
  cp jbosson.sql /tmp/jbosson.sql
  chmod 644 jbosson.sql /tmp/jbosson.sql

  echo "================================================================================="
  ls -l | fgrep -v wget.log
  echo "================================================================================="
  echo 
  echo "Run $PROGNAME --jon-help for details about Postgres database setup prior to installing JBoss Operations Network"
  echo
fi

# Exit
graceful_exit
