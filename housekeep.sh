#!/bin/bash
#/////////////////////////////////////////////////////////////////////
#/
#/ Script Name : housekeep.sh
#/
#/ Desctiption :
#/     1.   create config for myself.
#/     2-1. check config setting (for each iterations).
#/     2-2. delete old files  (for each iterations).
#/
#/ Usage :
#/     housekeep.sh param1
#/         param 1 - list of housekeep target
#/     e.g.) housekeep.sh /path/to/dir/my_housekeep.list
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

if [ ${DEBUG} -eq 1 ];then
  set -x
fi

_Message -i "===== [${SCRIPT_NAME} ${SCRIPT_ARGS}] started. ====="

# ------------------------------------------
# Pre Process
# ------------------------------------------
_Message -i "----- Pre process started. -----"

_CheckUser "root"

if [ ! -r ${SCRIPT_CONF_FILE} ];then
    _Message -e "${SCRIPT_CONF_FILE} is not found."
    _Failure
else
    . ${SCRIPT_CONF_FILE}
fi

if [ $# -ne 1 ];then
    _Usage
else
    HOUSE_KEEP_LIST=$1
fi

if [ ! -r "${HOUSE_KEEP_LIST}" ];then
    if [ ! -r "${SCRIPT_CONF_DIR}/${HOUSE_KEEP_LIST}" ];then
        _Message -e "${HOUSE_KEEP_LIST} is not found."
        _Failure
    else
        HOUSE_KEEP_LIST=${SCRIPT_CONF_DIR}/${HOUSE_KEEP_LIST}
    fi
fi


# ------------------------------------------
# Main Process
# ------------------------------------------
_Message -i "----- Main process started. -----"

_Message -i "START:create config for myself."

EXEC_CONFIG=${SCRIPT_TMP_DIR}/housekeep_${MY_HOST}.${MY_PID}
cat /dev/null > ${EXEC_CONFIG}
if [ $? -ne 0 ];then
    _Message -e "Create ${EXEC_CONFIG} failed."
    _Failure
fi

cat ${HOUSE_KEEP_LIST} | tr -d '\r' | awk -v exec_host=all        '$1 == exec_host {print $0}'  > ${EXEC_CONFIG}
cat ${HOUSE_KEEP_LIST} | tr -d '\r' | awk -v exec_host=${MY_HOST} '$1 == exec_host {print $0}' >> ${EXEC_CONFIG}

_Message -i "END:create config for myself."

ERR_COUNT=0
ENTRY_NO=0

_Message -i "START:Housekeeping."
while read _HOST _TYPE _OWNER _TARGET_DIR _FILE_PATTN _RETNTION_DAYS _ACTION
do
    ENTRY_NO=$(( ENTRY_NO + 1 ))

    _Message -l
    _Message -i "***** Entry No.${ENTRY_NO} *****"
    _Message -i "TYPE          : ${_TYPE}"
    _Message -i "OWNER         : ${_OWNER}"
    _Message -i "TARGET_DIR    : ${_TARGET_DIR}"
    _Message -i "FILE_PATTN    : ${_FILE_PATTN}"
    _Message -i "RETENTION_DAYS: ${_RETNTION_DAYS}"
    _Message -i "ACTION        : ${_ACTION}"

    ### check _TYPE
    case "${_TYPE}" in
    "f" )
        REMOVE_OPT="-f"
        FIND_OPT="-maxdepth 1"
        ;;
    "fr" )
        ### recursive
        _TYPE=f
        REMOVE_OPT="-f"
        FIND_OPT=""
        ;;
    "d" )
        REMOVE_OPT="-rf"
        FIND_OPT="-mindepth 1 -maxdepth 1"
        ;;
    * )
        _Message -e "TYPE:${_TYPE} is invalid in the 2nd filed."
        _Message -w "Continue to the next entry."
        ERR_COUNT=$(( ERR_COUNT + 1 ))
        continue
        ;;
    esac

    ### check _OWNER
    sudo -u ${_OWNER} id > /dev/null
    if [ $? -ne 0 ];then
        _Message -e "OWNER:${_OWNER} is not available on this host."
        _Message -w "Continue to the next entry."
        ERR_COUNT=$(( ERR_COUNT + 1 ))
        continue
    fi

    ### check _TARGET_DIR is allowed.
    for ALLOW_DIR in $(echo ${ALLOW_DIRS[@]})
    do
        echo ${_TARGET_DIR} | grep -q "^${ALLOW_DIR}"
        if [ $? -ne 0 ];then
            IS_ALLOWED=false
            continue
        else
            IS_ALLOWED=true
            break
        fi
    done

    if [ "${IS_ALLOWED}" = "false" ];then
        _Message -e "TARGET_DIR:${_TARGET_DIR} is not allowed for housekeeping. Please add entry to ${SCRIPT_CONF_FILE}."
        _Message -w "Continue to the next entry."
        ERR_COUNT=$(( ERR_COUNT + 1 ))
        continue
    fi

    ### check _TARGET_DIR
    if [ ! -d "${_TARGET_DIR}" ];then
        _Message -e "TARGET_DIR:${_TARGET_DIR} is not found."
        _Message -w "Continue to the next entry."
        ERR_COUNT=$(( ERR_COUNT + 1 ))
        continue
    fi

    ### check _RETNTION_DAYS
    echo "${_RETNTION_DAYS}" | egrep -q "^[0-9][0-9]*$"
    if [ $? -ne 0 ];then
        _Message -e "RETNTION_DAYS:${_RETNTION_DAYS} is invalid."
        _Message -w "Continue to the next entry."
        ERR_COUNT=$(( ERR_COUNT + 1 ))
        continue
    fi

    ### check ACTION
    _ACTION=$(echo ${_ACTION} | tr [:upper:] [:lower:])
    case ${_ACTION} in
    delete )
        ACTION_CMD="rm ${REMOVE_OPT}"
        ;;
    compress )
        ACTION_CMD="gzip"

        case ${_TYPE} in
        "d" )
            _Message -e "ACTION:${_ACTION} is not supported for directory."
            _Message -w "Continue to the next entry."
            ERR_COUNT=$(( ERR_COUNT + 1 ))
            continue
            ;;
        * )
            ;;
        esac
        ;;
    none )
        ACTION_CMD="ls -ld"
        ;;
    * )
        _Message -e "ACTION:${_ACTION} is not supported. \"delete\", \"compress\", or \"none\" is supported."
        _Message -w "Continue to the next entry."
        ERR_COUNT=$(( ERR_COUNT + 1 ))
        continue
        ;;
    esac

    _Message -i "All setting are valid."
    for TARGET_FILE in $(find ${_TARGET_DIR} ${FIND_OPT} -type ${_TYPE} -name "${_FILE_PATTN}" -mtime +"${_RETNTION_DAYS}" | grep -v "\/\.")
    do
        _Message -i "\"${ACTION_CMD} ${TARGET_FILE}\" by ${_OWNER}."
        sudo -u ${_OWNER} ${ACTION_CMD} ${TARGET_FILE}
        if [ $? -ne 0 ];then
            _Message -e "\"${ACTION_CMD} ${TARGET_FILE}\" failed."
            _Message -w "Continue to the next entry."
            ERR_COUNT=$(( ERR_COUNT + 1 ))
        fi
    done
done < ${EXEC_CONFIG}
_Message -i "END:Housekeeping."

### delete temp config
rm -f ${EXEC_CONFIG}

if [ ${ERR_COUNT} -ne 0 ];then
    _Message -e "${ERR_COUNT} errors detected."
    _Failure
fi

# ------------------------------------------
# Post Process
# ------------------------------------------
_Success
