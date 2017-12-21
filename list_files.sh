#!/bin/bash

ANALYZE_PATH=$1
PID=$$
BASEDIR=`dirname $0`
BASENAME=`basename $0`
WORKDIR="/tmp/policy.${PID}"
POLICY_FILE="${WORKDIR}/policy.in"
LOGFILE="${WORKDIR}/policy.log"

if [ "x${ANALYZE_PATH}" == "x" ] ; then
   cat <<EOHELP

   Usage: ${BASENAME} <PATH TO ANALYZE>

   Example: list_files.sh /gpfs/largeblockFS/projects/TDataFus

EOHELP
   exit 1
fi

mkdir -p ${WORKDIR}

cat <<EOPOLICY >${POLICY_FILE}
RULE 'listall' list 'all-files'
   SHOW( varchar(kb_allocated) || ' ' ||
         varchar(file_size) || ' ' ||
         varchar( days(current_timestamp) - days(creation_time) ) || ' ' ||
         varchar( days(current_timestamp) - days(change_time) ) || ' ' ||
         varchar( days(current_timestamp) - days(modification_time) ) || ' ' ||
         varchar( days(current_timestamp) - days(access_time) ) || ' ' ||
         varchar(group_id) || ' ' ||
         varchar(user_id) )
   WHERE PATH_NAME like '${ANALYZE_PATH}/%'
EOPOLICY

/usr/lpp/mmfs/bin/mmapplypolicy ${ANALYZE_PATH} -f ${WORKDIR} -P ${POLICY_FILE} -I defer                                             

#
# Breakdown of the list.all-files fields.
#
# Field     Usage
# 1         Inode
# 2         Generation Number
# 3         Snapshot Id
# 4         KB Allocated
# 5         File Size
# 6         Creation Time in days from today
# 7         Change Time in days from today
# 8         Modification time in days from today
# 9         Acces time in days from today
# 10        GID
# 11        UID
# 12        Separator
# 13        Fully qualified File Name
#

