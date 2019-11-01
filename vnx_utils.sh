#!/bin/bash
###########################################
#  vnx_utils.sh                           #
#  by L.Koné[LoKo]                        #
###########################################

MG='.'

SCRIPT_VERSION='0.01'
SCRIPT_DATE='03/2016'
SCRIPT_HOME="$(dirname "$0")"
SCRIPT=$(basename $0)
SCRIPT_NAME=${SCRIPT%%.*}
WEEK_NUMBER=$(date '+%V' 2>&-)

NAVICLI_PATH='/opt/Navisphere/bin'

SG_WEEK_TMP="SG_${SCRIPT_NAME}_week_${WEEK_NUMBER}_temp"

[[ $(whoami) != 'root' ]] && { echo -e  "! Must be root to run $0"; exit 1; }

SRC_FILE_LIST_ARRAY=(
    "func.d/func.global.sh"
    "func.d/func.vnx.retriev.sh"
    "func.d/func.vnx.create.sh"
    "func.d/func.vnx.remove.sh"
    "func.d/func.vnx.modify.sh"
    "func.d/func.vnx.display.sh"
    "func.d/func.vnx.check.sh"
)

for SRC_FILE in ${SRC_FILE_LIST_ARRAY[@]}; do
    [[ ! -e ${SCRIPT_HOME}/${SRC_FILE} ]] && { echo -e " ! source \"${SCRIPT_HOME}/${SRC_FILE}\" not find. Exit()"; exit 1; }
    source ${SCRIPT_HOME}/${SRC_FILE}
done

VNX_LIST_FILE="/sansto/etc/vnx/vnx_utils_list.txt"

[[ ! -e ${VNX_LIST_FILE} ]] && { echo -e " ! file \"${VNX_LIST_FILE}\" not find. Exit()"; exit 1; }

alias_var_d

TMP_DIR="/sansto/tmp/vnx/vnx_utils"
LOG_DIR="/sansto/logs/vnx/vnx_utils"
TMP_FILE_LIST_ARRAY=(
    "ARRAY_INFO_TMP"
    "RETURNCMD_LOG_FILE_TMP"
    "GETALL_LUN_INFO_TMP"
    "LUN_LIST_INFO_TMP"
)

declare_log_file
display_check
user_info_r
declare_tmp_file
log_dir_check

case $1 in
    -h       ) s_usage; exit_S 1086;;
    -v       )  text 1 "Version : $SCRIPT_VERSION ($SCRIPT_DATE)"; exit_S 1086;;
    -bay     ) all_bay_display; text 1; exit_S 1086;;
esac

trap on_sigint SIGINT

_OPT_RMV_MODE=0
_OPT_MDF_MODE=0
_OPT_BAY=0
_VERBOSE=0
_NO_PROMPT=0
_DEBUG_MODE=0
_ONLY_MODE=0
_CR_MOD=0
_RM_MOD=0
_MD_MOD=0
_SL_MOD=0
_INF_MOD=0
_NEW_LUN=0
_NEW_SG=0
_NEW_NAME=0
_EXIST_SG_TMP=0
_NEW_HOST=0
_E_HOST=0
_NOP_MODE=0
_F_MODE=0
_NEW_CLUST=0
_OS_MODE=0
_MAN_SELECT=0
_INIT_T=0
_FO_MODE=0
_ARRAY_CP=0

OS_TYPE=0
INIT_T=3
FO_MODE=4
ARRAY_CP=0

NODE_COUNT=1

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#                                                                                                                                                           #
# -- RETRIEVE SCRIPT ARGUMENTS ---------------------------------------------------------------------------------------------------------------------------- #
#    ^^^^^^^^^^^^^^^^^^^^^^^^^                                                                                                                              #
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

OPT_LIST_ARRAY=("-ip" "-dns" "-sid" "-sn" "-lun" "-lid" "-luid" "-sg" "-wwn" "-nsg" "-os" "-initt" "-arraycp" "-fomode" "-nhost" "-lun_size" "-node" "create" "remove" "modify" "-name" "info" "-v" "-debug" "-total" "-nop" "-l" "-x" "-f" "-n" "-s" "-w" "-c" "-r" "-i" "-m" "-u" "-t" "-f")
ALL_ARG_LIST_ARRAY=($*)

option_script_r

for ARG in $(seq 1 ${#ARG_LIST_ARRAY[@]}); do
    
    ARG=${2:-'-'}
    
    case $1 in
        
        -x          ) check_arg $1 0 $ARG 1 $_SL_MOD; _SL_MOD=1; shift 1;;
        
        -ip         ) check_arg $1 1 $ARG 1 $_OPT_BAY; BAY_ARG=$2; _OPT_BAY='IP'; shift 2;;
        -dns        ) check_arg $1 1 $ARG 1 $_OPT_BAY; BAY_ARG=$2; _OPT_BAY='DNS'; shift 2;;
        -sid        ) check_arg $1 1 $ARG 1 $_OPT_BAY; BAY_ARG=$2; _OPT_BAY='SID'; shift 2;;
        
        -l|-lun     ) check_arg $1 1 $ARG 1 $_OPT_DEVICE; _OPT_DEVICE='LUN'; L_TYPE='NAME'; LUN_LIST_ARRAY=($(list_cl "$(echo $2 | tr 'a-z' 'A-Z')")); shift 2;;
        -lid        ) check_arg $1 1 $ARG 1 $_OPT_DEVICE; _OPT_DEVICE='LUN'; L_TYPE='ID'; LUN_LIST_ARRAY=($(list_cl "$(echo $2 | tr 'a-z' 'A-Z')")); shift 2;;
        -luid       ) check_arg $1 1 $ARG 1 $_OPT_DEVICE; _OPT_DEVICE='LUN'; L_TYPE='UID'; LUN_LIST_ARRAY=($(list_cl "$2" | tr -d : | sed -r 's/.{2}/&:/g;s/.$//' | tr 'a-z' 'A-Z')); shift 2;;
        -s|-sg      ) check_arg $1 1 $ARG 1 $_OPT_DEVICE; _OPT_DEVICE='SG'; SG_LIST_ARRAY=($(list_cl "$2")); shift 2;;
        -w|-wwn     ) check_arg $1 1 $ARG 1 $_OPT_DEVICE; _OPT_DEVICE='WWN'; WWN_LIST_ARRAY=($(list_cl "$2" | tr -d : | sed -r 's/.{2}/&:/g;s/.$//' | tr 'a-z' 'A-Z')); shift 2;;
        
        -nsg        ) check_arg $1 0 $ARG 1 $_NEW_SG; _CR_MOD=1; _NEW_SG=1; shift 1;;
        -nlun       ) check_arg $1 0 $ARG 1 $_NEW_LUN; _CR_MOD=1; _NEW_LUN=1; shift 1;;
        -nhost      ) check_arg $1 0 $ARG 1 $NEW_WWN; NEW_WWN=$2; _CR_MOD=1; _NEW_HOST=1; shift 2;;
        -name       ) check_arg $1 1 $ARG 1 $NEW_NAME; NEW_NAME=$(echo $2 | tr 'A-Z' 'a-z'); _CR_MOD=1; _NEW_NAME=1; shift 2;;
        -node       ) check_arg $1 1 $ARG 1 $_NEW_CLUST; NODE_COUNT=$2; _CR_MOD=1; _NEW_CLUST=1; shift 2;;
        -os         ) check_arg $1 1 $ARG 1 $OS_TYPE; OS_TYPE=$2; _CR_MOD=1; _OS_MODE=1; shift 2;;
        -initt      ) check_arg $1 1 $ARG 1 $_INIT_T; INIT_T=$2; _CR_MOD=1; _MAN_SELECT=1; _INIT_T=1; shift 2;;
        -arraycp    ) check_arg $1 1 $ARG 1 $_ARRAY_CP; ARRAY_CP=$2; _CR_MOD=1; _MAN_SELECT=1; _ARRAY_CP=1; shift 2;;
        -fomode     ) check_arg $1 1 $ARG 1 $_FO_MODE; FO_MODE=$2; _CR_MOD=1; _MAN_SELECT=1; _FO_MODE=1; shift 2;;
        
        -total      ) check_arg $1 0 $ARG 1 $_OPT_RMV_MODE; _OPT_RMV_MODE='Total'; _RM_MOD=1; shift 1;;
        
        -lun_size   ) check_arg $1 0 $ARG 1 $_OPT_MDF_MODE; _OPT_MDF_MODE='lun_size'; _MD_MOD=1; shift 1;;
        
        -c|create   ) check_arg $1 0 $ARG 1 $_OPT_MODE; _OPT_MODE='Create'; shift 1;;
        -r|remove   ) check_arg $1 0 $ARG 1 $_OPT_MODE; _OPT_MODE='Remove'; shift 1;;
        -i|info     ) check_arg $1 0 $ARG 1 $_OPT_MODE; _OPT_MODE='Info'; shift 1;;
        -m|modify   ) check_arg $1 0 $ARG 1 $_OPT_MODE; _OPT_MODE='Modify'; shift 1;;
        
        # -v|-verb  ) check_arg $1 0 $ARG 1 $_VERBOSE; _VERBOSE=1; shift 1;;
        -o|-only    ) check_arg $1 0 $ARG 1 $_ONLY_MODE; _ONLY_MODE=1; shift 1;;
        -f          ) check_arg $1 0 $ARG 1 $_F_MODE; _F_MODE=1; shift 1;;
        -nop        ) check_arg $1 0 $ARG 1 $_NOP_MODE; _NOP_MODE=1; shift 1;;
        -debug      ) check_arg $1 1 $ARG 1 $_DEBUG_MODE; _DEBUG_MODE=1; _DEBUG_LEVEL=$2; shift 2;;
        
        ''          ) shift 1;;
        *           ) arg_script_error "Argument '$1' not reconize";;
    esac
    
done

> $ARRAY_INFO_TMP

if [[ $_DEBUG_MODE = 1 ]]; then
    [[ $_DEBUG_LEVEL != 0 && $_DEBUG_LEVEL != 1 ]] && arg_script_error "Bad Level for 'Debug Mode' [0|1]"
    [[ $_DEBUG_LEVEL = 1 ]] && debug_mode
    
fi

if [[ $_SL_MOD = 1 ]]; then
    [[ $_CR_MOD = 1 || $_RM_MOD = 1 || $_MD_MOD = 1 || $_ONLY_MODE = 1 || $_NO_PROMPT = 1 || -n $_OPT_DEVICE || -n $BAY_ID || -n $_OPT_MODE ]] && arg_script_error
    _SCRIPT_MODE='Select'; _OPT_MODE='Selection'
    
else
    _SCRIPT_MODE='Arg'; opt_mode_arg_check
    bay_retrieving $BAY_ARG
    [[ $_OPT_MODE = 'Modify' ]] && [[ $BAY_LT != 'E' ]] && { text err "Modify Mode not Work with this Bay"; text 1; exit_S 1086; }
    
fi

text 1

OPTION_DISPLAY="$_OPT_MODE"

[[ -n $_OPT_DEVICE ]] && OPTION_DISPLAY="${OPTION_DISPLAY} ${_OPT_DEVICE}"
[[ $_OPT_RMV_MODE != 0 ]] && OPTION_DISPLAY="${OPTION_DISPLAY} - ${_OPT_RMV_MODE}"
[[ $_VERBOSE = 1 ]] && OPTION_DISPLAY="${OPTION_DISPLAY} - Verb 1"
[[ $_DEBUG_MODE = 1 ]] && OPTION_DISPLAY="${OPTION_DISPLAY} - Debug ${_DEBUG_LEVEL}"
[[ $_F_MODE = 1 ]] && OPTION_DISPLAY="${OPTION_DISPLAY} - F.Mode"

text on "${OPTION_DISPLAY}"
text log "Start Script; ${OPTION_DISPLAY}"

[[ $_SCRIPT_MODE = 'Select' ]] && select_mode_retrieve

[[ $_OPT_DEVICE = 'LUN' ]] && text log "[$_OPT_DEVICE] $(list_sep "${LUN_LIST_ARRAY[*]}")"
[[ $_OPT_DEVICE = 'SG' ]] && text log "[$_OPT_DEVICE] $(list_sep "${SG_LIST_ARRAY[*]}")"
[[ $_OPT_DEVICE = 'WWN' ]] && text log "[$_OPT_DEVICE] $(list_sep "${WWN_LIST_ARRAY[*]}")"

SG_ARG_LIST_ARRAY=("${SG_LIST_ARRAY[@]}")

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#                                                                                                                                                       #
# -- RETRIEVE INFORMATIONS ---------------------------------------------------------------------------------------------------------------------------- #
#    ^^^^^^^^^^^^^^^^^^^^^                                                                                                                              #
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

text 1

command_retrieving

text 1

[[ $_OPT_DEVICE != 'LUN' ]] && L_TYPE='ID'

if [[ $_OPT_MODE = 'Create' ]]; then
    
    [[ $_NEW_SG = 0 ]] && { storage_check 'exs' "${SG_LIST_ARRAY[*]}"; storage_retrieving "${SG_LIST_ARRAY[*]}"; } || { SG_LIST_ARRAY=("SG_${NEW_NAME}"); storage_check 'new' "${SG_LIST_ARRAY[*]}"; }
    
    if [[ $_NEW_HOST = 1 ]]; then
        
        NEW_WWN_LIST_ARRAY=($(loko '$1 == "_NEW_CLUST_INFO_" {print $5}' $ARRAY_INFO_TMP | sort -u))
        
        logins_retrieving "${NEW_WWN_LIST_ARRAY[*]}"
        
        DEFINED_CHECK=$(loko '$1 == "_WWN_INFO_" && $NF == "Yes" {print 1}' $ARRAY_INFO_TMP | sort -u)
        WWN_LIST_ARRAY=($(loko '$1 == "_WWN_INFO_" {print $2}' $ARRAY_INFO_TMP | sort -u))
        
        NEW_HOST_LIST_ARRAY=($(loko '$1 == "_NEW_CLUST_INFO_" {print $3}' $ARRAY_INFO_TMP | sort -u))
        
        host_check "${NEW_HOST_LIST_ARRAY[*]}"
        
        [[ $ERR_HOST_DF = 1 ]] && { logins_display "${WWN_LIST_ARRAY[*]}"; text err "Host Already Exist. Use the same SG of Existing Host to add New WWN in this One. Check it"; exit_S 0; }
        
        for NEW_HOST in ${NEW_HOST_LIST_ARRAY[@]}; do
            NEW_IP=($(loko '$1 == "_NEW_CLUST_INFO_" && $3 == "'"$NEW_HOST"'" {print $4}' $ARRAY_INFO_TMP | sort -u))
            printf "_HOST_INFO_;$NEW_HOST;$NEW_IP;${SG_LIST_ARRAY[@]}\n" >> $ARRAY_INFO_TMP
        done
        
    fi
    
    if [[ $_NEW_LUN = 1 ]]; then
        
        if [[ $BAY_LT = E ]]; then
        
            lun_no_sg_retrieving
            
            LUN_SIZE_LIST_ARRAY=($(loko '$1 == "_LUN_WITHOUT_SG_" {print $3}' $ARRAY_INFO_TMP | sort -n | uniq -c | awk '{printf "%s;%s\n", $1, $2}'))
            SIZE_LIST_ARRAY=($(list_array "${LUN_SIZE_LIST_ARRAY[*]}" | loko '{print $2}' | sort -u))
            
            new_available_luns_display "${LUN_SIZE_LIST_ARRAY[*]}"
        
        else
            
            pool_retrieving
            
            POOL_ID_LIST_ARRAY=($(loko '$1 == "_POOL_INFO_" {print $2}' $ARRAY_INFO_TMP | sort -u))
            POOL_LIST_ARRAY=($(loko '$1 == "_POOL_INFO_" {print $3}' $ARRAY_INFO_TMP | sort -u))
            
            pool_display "${POOL_ID_LIST_ARRAY[*]}"
            
            if [[ ${#POOL_ID_LIST_ARRAY[@]} > 1 ]]; then
                choice_select_function 2 "${POOL_LIST_ARRAY[*]}" 'Pool' 'Name'
                POOL_ID_SELECT=$(loko '$1 == "_POOL_INFO_" && $3 == "'"$VAR_RESULT"'" {print $2}' $ARRAY_INFO_TMP | sort -u)
            else
                POOL_ID_SELECT=${POOL_ID_LIST_ARRAY[@]}
            fi
        
        fi
        
        while [[ -z ${NEW_COUNT_SIZE_LIST_ARRAY[@]} || $SIZE_CHECK != 0 || $COUNT_CHECK != 0 ]]; do
            
            text 1
            text 1 "<> Enter Lun(s) to Create : \c"; read NEW_COUNT_SIZE_LIST_ARG
            
            unset LUN_LIST_ARRAY
            unset COUNT_SIZE_LIST_ARRAY
            
            SIZE_CHECK=0
            COUNT_CHECK=0
            
            NEW_COUNT_SIZE_LIST_ARRAY=($(echo $NEW_COUNT_SIZE_LIST_ARG | sed s/\,/\\n/g))
            
            [[ $BAY_LT = E ]] && lun_count_argument_check "${NEW_COUNT_SIZE_LIST_ARRAY[*]}" || lun_count_syntax_check "${NEW_COUNT_SIZE_LIST_ARRAY[*]}" 
            
        done
        
        if [[ $BAY_LT = E ]]; then
            text 1
            lun_retrieving "${LUN_LIST_ARRAY[*]}"
            _WAR_LUN_NO_EMPTY=$(loko '$1 == "_LUN_INFO_" && $17 != "1.753" {print 1}' $ARRAY_INFO_TMP | sort -u)
            
        else
            lun_to_create "${NEW_COUNT_SIZE_LIST_ARRAY[*]}" "${SG_LIST_ARRAY[*]}" $POOL_ID_SELECT
            
        fi
    
    fi
    
elif [[ $_OPT_MODE = 'Modify' ]]; then
    
    lun_no_sg_retrieving
    
    LUN_SIZE_LIST_ARRAY=($(loko '$1 == "_LUN_WITHOUT_SG_" {print $3}' $ARRAY_INFO_TMP | sort -n | uniq -c | awk '{printf "%s;%s\n", $1, $2}'))
    SIZE_LIST_ARRAY=($(list_array "${LUN_SIZE_LIST_ARRAY[*]}" | loko '{print $2}' | sort -u))
    
    new_available_luns_display "${LUN_SIZE_LIST_ARRAY[*]}"
    
    while [[ -z ${NEW_COUNT_SIZE_LIST_ARRAY[@]} || $SIZE_CHECK != 0 || $COUNT_CHECK != 0 ]]; do
        
        text 1
        text 1 "<> Enter Lun(s) to Modify : \c"; read NEW_COUNT_SIZE_LIST_ARG
        
        unset LUN_LIST_ARRAY
        unset COUNT_SIZE_LIST_ARRAY
        
        SIZE_CHECK=0
        COUNT_CHECK=0
        
        NEW_COUNT_SIZE_LIST_ARRAY=($(echo $NEW_COUNT_SIZE_LIST_ARG | sed s/\,/\\n/g))
        
        [[ $BAY_LT = E ]] && lun_count_argument_check "${NEW_COUNT_SIZE_LIST_ARRAY[*]}" || lun_count_syntax_check "${NEW_COUNT_SIZE_LIST_ARRAY[*]}" 
        
    done
    
    while [[ -z ${NEW_LUN_SIZE} || $SIZE_CHECK != 0 ]]; do
        
        text 1
        text 1 "<> Enter New Size of Lun(s) : \c"; read NEW_LUN_SIZE
        
        SIZE_CHECK=0
        
        lun_size_check "$NEW_LUN_SIZE"; RETURN_CMD=$?
        
        LUN_SIZE_GB_ARG=$LUN_SIZE_GB
        LUN_SIZE_BK_ARG=$LUN_SIZE_BC
        
        DIVIDE_CHECK=0
        
        for NEW_COUNT in ${NEW_COUNT_SIZE_LIST_ARRAY[@]}; do
            
            SIZE=$(echo "$NEW_COUNT" | awk -F'x' '{print $2}')
            
            ((LUN_SIZE_GB_ARG == SIZE)) && { text 'err' "Can't modify Size by same Size"; SIZE_CHECK=1; break; }
            
            if ((LUN_SIZE_GB_ARG > SIZE)); then
                
                TOTAL_SIZE_GB=$(echo "${NEW_COUNT_SIZE_LIST_ARRAY[@]}" | sed s/\ /\\n/g | awk -F'x' '{ALL+=$1*$2} END{print ALL}')
                
                lun_size_check "$TOTAL_SIZE_GB"; RETURN_CMD=$?
                
                if [[ $RETURN_CMD == 0 ]]; then
                
                    LUN_SIZE_GB_TOTAL=$LUN_SIZE_GB
                    LUN_SIZE_BK_TOTAL=$LUN_SIZE_BC
                    
                    [[ $LUN_SIZE_GB_TOTAL != $LUN_SIZE_GB_ARG ]] && { text 'err' "Bad Size Conversion (Total:$LUN_SIZE_GB_TOTAL, Needed:$LUN_SIZE_GB_ARG)"; SIZE_CHECK=1; break; }
                    
                    DIVIDE_CHECK=1
                    
                else
                    text 'err' "Bad Size Conversion (Total:$TOTAL_SIZE_GB)"; SIZE_CHECK=1; break;
                    
                fi
            fi
            
        done
        
    done
    
    text 1
    
    lun_retrieving "${LUN_LIST_ARRAY[*]}"
    pool_retrieving
    
    lun_to_modify $DIVIDE_CHECK "$LUN_SIZE_BK_ARG"
    
else
    
    if [[ $_OPT_DEVICE = 'LUN' ]]; then
        
        lun_retrieving "${LUN_LIST_ARRAY[*]}"
        
        if [[ $_ONLY_MODE = 0 ]]; then
            SG_LIST_ARRAY=($(loko '$1 == "_LUN_INFO_" && $6 != "No" {print $6}' $ARRAY_INFO_TMP | sed s/,/\\n/g | awk -F'.' '{print $1}' | sort -u))
            [[ -n ${SG_LIST_ARRAY[@]} ]] && storage_retrieving "${SG_LIST_ARRAY[*]}"
        
        fi
        
    elif [[ $_OPT_DEVICE = 'SG' ]]; then
        
        storage_check 'exs' "${SG_LIST_ARRAY[*]}"
        
        if [[ $_ONLY_MODE = 0 ]]; then
            lun_r "${SG_LIST_ARRAY[*]}"
            [[ -n ${LUN_LIST_ARRAY[@]} ]] && { lun_retrieving "${LUN_LIST_ARRAY[*]}"; SG_LIST_ARRAY=($(loko '$1 == "_LUN_INFO_" && $6 != "No" {print $6}' $ARRAY_INFO_TMP | sed s/,/\\n/g | awk -F'.' '{print $1}' | sort -u)); }
        
        fi
        
        storage_retrieving "${SG_LIST_ARRAY[*]}"
        
        if [[ $_ONLY_MODE = 0 ]]; then
            WWN_LIST_ARRAY=($(loko '$1 == "_SG_INFO_" && $4 != "No" {print $4}' $ARRAY_INFO_TMP | sed s/,/\\n/g | sort -u))
            [[ -n ${WWN_LIST_ARRAY[@]} ]] && logins_retrieving "${WWN_LIST_ARRAY[*]}"
        fi
        
    elif [[ $_OPT_DEVICE = 'WWN' ]]; then
        
        logins_retrieving "${WWN_LIST_ARRAY[*]}"
        WWN_LIST_ARRAY=($(loko '$1 == "_WWN_INFO_" {print $2}' $ARRAY_INFO_TMP | sort -u))
        
        if [[ $_ONLY_MODE = 0 ]]; then
            SG_LIST_ARRAY=($(loko '$1 == "_WWN_INFO_" && $6 != "No" {print $6}' $ARRAY_INFO_TMP | sed s/,/\\n/g | sort -u))
            
            lun_r "${SG_LIST_ARRAY[*]}"
            
            [[ -n ${LUN_LIST_ARRAY[@]} ]] && { lun_retrieving "${LUN_LIST_ARRAY[*]}"; SG_LIST_ARRAY=($(loko '$1 == "_LUN_INFO_" && $6 != "No" {print $6}' $ARRAY_INFO_TMP | sed s/,/\\n/g | awk -F'.' '{print $1}' | sort -u)); }
            [[ -n ${SG_LIST_ARRAY[@]} ]] && storage_retrieving "${SG_LIST_ARRAY[*]}"
        
        fi
    else
        
        [[ $_INIT_INFO = 1 ]] && initiator_info_retrieving
        
    fi
    
fi


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#                                                                                                                                        #
# -- CHECKS ---------------------------------------------------------------------------------------------------------------------------- #
#    ^^^^^^                                                                                                                              #
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

global_info_check

if [[ $_OPT_MODE = 'Remove' ]]; then
    
    lun_sg_check
    
    if [[ -n ${SG_LIST_ARRAY[@]} ]]; then
        
        if [[ $_OPT_DEVICE = 'LUN' ]]; then
            SG_ARG_LIST_ARRAY=("${SG_LIST_ARRAY[@]}")
            WWN_LIST_ARRAY=($(loko '$1 == "_SG_INFO_" && $9 != "No" {print $9}' $ARRAY_INFO_TMP | sed 's/,/\n/g' | sort -u))
            
            WAR_LUN_SG_5=1
            WAR_LUN_SG_5_DISPLAY="SG(s) $(list_sep "${SG_LIST_ARRAY[*]}") delete because all Lun(s) will be remove"
            
            [[ -n ${WWN_LIST_ARRAY[@]} ]] && { text 1; logins_retrieving "${WWN_LIST_ARRAY[*]}"; }
            
        fi
        
        sg_argument_check
        
    fi
  
fi

general_info_display

[[ -n ${WWN_LIST_ARRAY[@]} ]] && logins_display "${WWN_LIST_ARRAY[*]}"
[[ $_NEW_SG = 0 && -n ${SG_LIST_ARRAY[@]} ]] && storages_display "${SG_LIST_ARRAY[*]}"
[[ -n ${LUN_LIST_ARRAY[@]} ]] && luns_display

[[ $_MIRRORV_CHECK = 1 ]] && mirror_display
[[ $_INIT_INFO = 1 ]] && initiator_info_display
[[ $_OPT_MODE = 'Info' ]] && exit_S 0

error_display

storage_check 'tmp' "${SG_LIST_ARRAY[*]}"


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#                                                                                                                                                    #
# -- COMMANDS EXECUTION ---------------------------------------------------------------------------------------------------------------------------- #
#    ^^^^^^^^^^^^^^^^^^                                                                                                                              #
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

text 1; text 1; text u1 "Commands to Execute" '.'; text 1

[[ $_OPT_MODE = 'Create' ]] && create_script_execution 'DISPLAY'
[[ $_OPT_MODE = 'Remove' ]] && remove_script_execution 'DISPLAY'
[[ $_OPT_MODE = 'Modify' ]] && modify_script_execution 'DISPLAY'

warning_display

text 1

if [[ $_NOP_MODE = 0 || -z $_NOP_MODE ]]; then
    
    while [[ -z $RESP_EX ]] || [[ ! $RESP_EX =~ Y|YES && ! $RESP_EX =~ N|NO ]]; do
        text 1 "<> Do You Want Execute Command(s) ? [Yes/No] : \c"; read RESP_EX
        RESP_EX=$(echo $RESP_EX | tr 'a-z' 'A-Z')
    done
    
else
    RESP_EX='YES'
    
fi


if [[ $RESP_EX =~ Y|YES ]]; then
    display_check
    text 1
    text u1 "Commands Execution Start" '.'
    text 1
    
    if [[ $_OPT_MODE = 'Create' ]]; then
    
            create_script_execution 'RUN'
      
        if [[ $BAY_LT = N ]]; then
            NEW_DEVICE_LIST_ARRAY=($(loko '$1 == "_LUN_TO_CREATE_" {print $2}' $ARRAY_INFO_TMP | sort -u))
            lun_retrieving "${NEW_DEVICE_LIST_ARRAY[*]}"
            luns_display
            
        fi
    fi
    
    [[ $_OPT_MODE = 'Remove' ]] && remove_script_execution 'RUN'
    [[ $_OPT_MODE = 'Modify' ]] && modify_script_execution 'RUN'
    
    exit_S 0
    
elif [[ $RESP_EX =~ N|NO ]]; then
    exit_S 0

fi
