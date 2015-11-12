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

# Usage: jboss.sh [-h|--help] [-s server -d|-i] [jon|eap]

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
  echo -e "Usage: $PROGNAME [-h|--help] [-s server -d|-i] [jon|eap]"
}

help_message() {
  cat <<- _EOF_
  $PROGNAME ver. $VERSION
  JBoss Demo Environment Setup

  $(usage)

  Options:
  -h, --help help message
  -d  Download
  -i  Install
  -s  Server hostname to download from

_EOF_
  return
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
  if [ -d JBoss-ON ]
  then
    log_exit "JBoss-ON directory exists! Please rename it and then rerun this script"
  else
    mkdir JBoss-ON; chmod 755 JBoss-ON; cd JBoss-ON
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

  echo "================================================================================="
  ls -l | fgrep -v wget.log
  echo "================================================================================="
fi

# Exit
graceful_exit
