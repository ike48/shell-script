#!/bin/bash
#//////////////////////////////////////////////////////////////////////
#
# Script Name : template.sh
#
# Desctiption :
#     1. hoge
#     2. fuga
#     3. piyo
#
# Usage :
#     template.sh param1 param2 [param3]
#         param 1 - foo
#         param 2 - bar
#         param 3 - buz
#     e.g.) template.sh foo bar buz
#           template.sh for bar
#
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

if [ ${DEBUG} -eq 1 ];then
  set -x
fi

_Message -i "===== [${SCRIPT_NAME} ${SCRIPT_ARGS}] started. ====="

# ------------------------------------------
# Pre Process
# ------------------------------------------
_Message -i "----- Pre process started. -----"

#_CheckUser "root"


# ------------------------------------------
# Main Process
# ------------------------------------------
_Message -i "----- Main process started. -----"

env


# ------------------------------------------
# Post Process
# ------------------------------------------
_Success
