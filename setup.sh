#!/bin/bash
#//////////////////////////////////////////////////////////////////////
#/
#/ Script Name : setup.sh
#/ 
#/ Desctiption :
#/     1. Create required directories.
#/     2. Setting permissions.
#/     3. Setting owner and group.
#/ 
#/ Usage :
#/     setup.sh param1 [param2]
#/	param 1 - owner name for tools
#/	param 2 - group name for tools
#/     e.g.) setup.sh hoge
#/           setup.sh hoge fuga
#/
#//////////////////////////////////////////////////////////////////////
# ------------------------------------------
# Init Process
# ------------------------------------------
COMMON_ENV=$(dirname $0)/common.env
CUSTOM_ENV=$(dirname $0)/custom.env

if [ -r ${COMMON_ENV} ];then
    . ${COMMON_ENV}
else
    echo $(date +'%Y-%m-%d %H:%M:%S') $(hostname -s) $(basename $0)\($$\): "[ERROR]" "${COMMON_ENV} is not found."
    exit 255
fi

if [ -r ${CUSTOM_ENV} ];then
    . ${CUSTOM_ENV}
fi

_Message -i "===== [${SCRIPT_NAME} ${SCRIPT_ARGS}] started. ====="

# ------------------------------------------
# Pre Process
# ------------------------------------------
_Message -i "----- Pre process started. -----"

_CheckUser "root"

TOOL_OWNER=$1
TOOL_GROUP=$2

if [ -z "${TOOL_OWNER}" ] ;then
    _Usage
fi


getent passwd ${TOOL_OWNER} > /dev/null
if [ $? -ne 0 ];then
    _Message -e "User ${TOOL_OWNER} is not available."
    _Failure
fi

if [ -z "${TOOL_GROUP}" ];then
    TOOL_GROUP=$(id -gn ${TOOL_OWNER})
else
    getent group ${TOOL_GROUP} > /dev/null
    if [ $? -ne 0 ];then
        _Message -e "Group ${TOOL_GROUP} is not available."
        _Failure
    fi
fi

# ------------------------------------------
# Main Process
# ------------------------------------------
_Message -i "----- Main process started. -----"

LOG_DIR_ORG=/var/log/${SCRIPT_BASE_DIR##*/}

cd ${SCRIPT_BASE_DIR}
mkdir -p tmp dat ${LOG_DIR_ORG}

_Message -i "Link log to ${LOG_DIR_ORG}"
ln -nfs ${LOG_DIR_ORG} log

_Message -i "Change owner to ${TOOL_OWNER}"
_Message -i "Change group to ${TOOL_GROUP}"
chown ${TOOL_OWNER}:${TOOL_GROUP} ${SCRIPT_BASE_DIR}
chown ${TOOL_OWNER}:${TOOL_GROUP} ${SCRIPT_BASE_DIR}/*
chown ${TOOL_OWNER}:${TOOL_GROUP} ${SCRIPT_CONF_DIR}/*

_Message -i "Change permissions."
chmod 755 *
chmod 644 ${SCRIPT_CONF_DIR}/*
chmod 777 tmp dat log

_Message -l
ls -l ${SCRIPT_BASE_DIR}
_Message -l

# ------------------------------------------
# Post Process
# ------------------------------------------
_Success
