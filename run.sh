#!/bin/bash
#//////////////////////////////////////////////////////////////////////
#/
#/ Script Name : run.sh
#/ 
#/ Desctiption :
#/     1. Execute the shell specified by the argument.
#/     2. Output shell's standard output and standard error output to the log.
#/ 
#/ Usage :
#/     run.sh shell [params]
#/     e.g.) run.sh foo.sh
#/           run.sh bar.sh buz
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

if [ $# -eq 0 ];then
    _Usage
fi

EXEC_SHELL_NAME=$1
EXEC_SHELL_WITH_ARGS=$*
LOG_NAME=${SCRIPT_LOG_DIR}/${EXEC_SHELL_NAME}.${LOG_TIME}.log   # LOG_TIME in custom.env

# ------------------------------------------
# Main Process
# ------------------------------------------
_Message -i "----- Main process started. -----"

_Message -l
_Message -i "SHELL : ${EXEC_SHELL_WITH_ARGS}"
_Message -i "LOG   : ${LOG_NAME}"
_Message -l

cd ${SCRIPT_BASE_DIR}
bash ${EXEC_SHELL_WITH_ARGS} >> ${LOG_NAME} 2>&1
RET=$?

if [ ${RET} -ne 0 ];then
    _Message -e "${EXEC_SHELL_WITH_ARGS} failed."
    _Failure ${RET}
fi

# ------------------------------------------
# Post Process
# ------------------------------------------
_Success
