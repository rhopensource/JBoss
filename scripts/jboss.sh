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

usage() { 
  echo "Usage: $PROGNAME [-d|-i] [jon|eap] [-f server] [-t destination]"
}

error_exit() {
  TSTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  echo "$TSTAMP: ${PROGNAME}: ${1:-"Unknown Error"}" >&2
  usage
  exit 1
}

log() {
    TSTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$TSTAMP: $*"
}

export v_D=
export v_I=
export v_Action=
export v_From=
export v_To=
export v_SW=
export v_Error=
export v_Dir=

while [[ -n $1 ]]; do
  case $1 in
  -h) 
      if [ -r help_message.txt ]
      then
        less help_message.txt
        exit 0
      elif [ -x /usr/bin/wget ]
        then
        wget https://raw.githubusercontent.com/rhopensource/JBoss/master/scripts/help_message.txt
        less help_message.txt
        exit 0
      else
        error_exit "Missing help file"
      fi
      ;;
  -d) shift; v_D=D; v_SW=$1 ;;
  -i) shift; v_I=I; v_SW=$1 ;;
  -f) shift; v_From=$1 ;;
  -t) shift; v_To=$1 ;;
  -*|--*) error_exit "Invalid option" ;;
  *) error_exit "Invalid option" ;;
  esac
  shift
done

if [ "x$v_D"  = "xD" -a "x$v_I" = "x" ]
then
  v_Action=Download
elif [ "x$v_D"  = "x" -a "x$v_I" = "xI" ]
then
  v_Action=Install
else
  error_exit "Invalid option";
fi

case "$v_SW" in
  jon) v_Dir=JBOSS-ON ;;
  eap) v_Dir=EAP ;;
  *) error_exit "Invalid option" ;;
esac

if [ "x$v_Action" = "xDownload" -a "x$v_From" = "x" ]
then
  error_exit "Missing download server details"
fi

if [ "x$v_Action" = "xInstall" -a "x$v_To" = "x" ]
then
  error_exit "Missing install destination details"
fi

if [ "x$v_Action" = "xDownload" -a ! -r files.dat -a -x /usr/bin/wget ]
then
  wget https://raw.githubusercontent.com/rhopensource/JBoss/master/scripts/files.dat
  if [ ! -r files.dat ]
  then
    error_exit "Missing files.dat"
  fi
fi


if [ "x$v_Action" = "xDownload" ]
then

  if [ "x$v_To" = "x" ]
  then
    v_To="./JBoss-Downloads/$v_Dir"
  else
    v_To="$v_To/$v_Dir"
  fi

  if [ ! -d $v_To ]
  then
    mkdir -p $v_To
    chmod 755 $v_To
  fi

  grep "${v_SW}=" files.dat | sed -e "s!$v_SW=!!g" | while read urlpath
  do
    basefile=`/usr/bin/basename $urlpath`
    wget -O "$v_To/$basefile"  "http://$v_From$urlpath"
 
  done
fi

exit 0
