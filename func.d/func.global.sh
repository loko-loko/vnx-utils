# func.global.sh

debug_mode(){ set -x; }

on_sigint(){ text 1; text 1; text 1 "${CLR_RED} <!> SigInt Signal Received. Exit() ${CLR_END}"; text log "SigInt Signal Received"; text 1; exit_S 1086; }

list_sep(){ local LIST=($1); local CHAR=${2:-','}; echo "${LIST[@]}" | sed s/\ /$CHAR/g; }

list_array(){ local ARRAY=($1); local LIST; for LIST in ${ARRAY[@]}; do echo $LIST; done; }

list_cl(){ local LIST=$1; local CHAR=${2:-','}; echo $LIST | sed s/${CHAR}/\\n/g; }

log_dir_check(){ if [[ ! -d $LOG_DIR ]]; then mkdir $LOG_DIR 2>&-; fi; }

arg_script_error(){ text arg "${1:-'Bad Argument'}"; s_usage; exit_S 1085; }

cmd_check(){ local L_CMD=$1; [[ $L_CMD != 0 ]] && { echo "[!fail]"; exit_S $L_CMD; } || echo "[done]"; }

modulo_c(){ local VAR=$1; expr $VAR % 2 2>&-; }

display_check(){
    LINES=$(tput lines)
    COLUMNS=$(tput cols)
    
    ((COLUMNS<76 || LINES<11 )) &&  { text 1 "Script work with a min of 75 cols and 10 lines. Check it"; exit_S 1086; }
}

user_info_r(){
    
    local USER_LOGIN_INFO_LIST=$(ps auxwww 2>&- | grep sshd | grep pts)
    local CURRENT_USER_PTS=$(echo "$USER_LOGIN_INFO_LIST" | awk '$8 == "S+" {print $7}' | cut -d\/ -f2)
    
    CURRENT_USER=$(echo "$USER_LOGIN_INFO_LIST" | awk '$NF ~ /pts\/'"$CURRENT_USER_PTS"'$/ {print $1}')
}

declare_tmp_file(){
   
    [[ ! -e $TMP_DIR ]] && mkdir -p $TMP_DIR
  
    for TMP_FILE in ${TMP_FILE_LIST_ARRAY[@]}; do
        
        local TMP_FILE_NAME_RESIZE=$(echo $TMP_FILE | awk -F'_' '{printf "%s_%s", $1, $2}' | tr 'A-Z' 'a-z')
        local TMP_FILE_NAME="${SCRIPT_NAME}_${TMP_FILE_NAME_RESIZE}.$$.tmp"
        
        eval "${TMP_FILE}"="${TMP_DIR}/${TMP_FILE_NAME}"
        
    done
}

delete_tmp_file(){
    
    for TMP_FILE in ${TMP_FILE_LIST_ARRAY[@]}; do
        [[ -e ${!TMP_FILE} ]] && rm -f ${!TMP_FILE}
    done
}

delete_tmp_old_file(){ find ${TMP_DIR} -type f -name "${SCRIPT_NAME}_*.[0-9]*.tmp" -exec rm -f {} \; ; }

user_restrict(){ #ARG ${RESTRICT_USER_LIST_ARRAY[@]}
    
    local RESTRICT_USER_LIST_ARRAY=($1)
    local RESTRICT_MSG="User $RESTRICT_USER not accepted"
    
    for RESTRICT_USER in ${RESTRICT_USER_LIST_ARRAY[@]}; do
        [[ $RESTRICT_USER = $CURRENT_USER ]] && { text 1; text 1 "${CLR_RED} <!> ${RESTRICT_MSG} <!> ${CLR_END}"; text 1; exit_S 1086; }
    done
}

declare_log_file(){
    
    local YEAR_N=$(date '+%Y' 2>&-)
    
    LOG_FILE="$LOG_DIR/log_${SCRIPT_NAME}_${YEAR_N}_W${WEEK_NUMBER}.log"
    
    [[ ! -e $LOG_DIR ]] && mkdir -p $LOG_DIR
    [[ ! -e $LOG_FILE ]] && > $LOG_FILE
    
}

alias_var_d(){
    
    shopt -s expand_aliases
    
    alias loko='awk -F\;'
    alias loka='awk -F\:'
    
    CLR_BLUE="\033[44m"
    CLR_BW="\033[7m"
    CLR_UND="\033[4m"
    CLR_RED="\033[33m\033[41m"
    CLR_YEL="\033[30m\033[43m"
    CLR_STR="\033[1m"
    CLR_END="\033[0m"
    
    MG1="${CLR_STR}${MG} ${CLR_END}"
    MG2="${CLR_STR}${MG}${CLR_END}"
    
}

check_arg(){ #ARG $E_OPT $ARG_S $E_ARG $UNIQ_S $OPT_VAR
    
    local E_OPT=$1
    local ARG_S=$2
    local E_ARG=$3
    local UNIQ_S=$4
    local OPT_VAR=$5
    
    if [[ $ARG_S = 1 ]]; then
        
        [[ $E_ARG = '-' ]] && arg_script_error "'$E_OPT' Option need an argument."
        
        for OPT in ${OPT_LIST_ARRAY[@]}; do            
            [[ $E_ARG = $OPT ]] && arg_script_error "'$E_OPT' Option need an argument"
        done
        
    fi
    
    if [[ $UNIQ_S = 1 ]]; then
        [[ -n $OPT_VAR && $OPT_VAR != 0 ]] && arg_script_error "'$E_OPT' Option is already declare or is not accept awith another Option."
    fi
    
}

log_write(){ local TEXT=$1; local TYPE=${2:-'Info'}; echo -e "[$DATE][$TIME][$CURRENT_USER][$BAY_SID] #> ${TYPE} : ${TEXT}" >> $LOG_FILE 2>&1; }

t_line(){ local VAR=$1; local L_C=$2; C=0; while [[ $C != $L_C ]]; do echo -e "${VAR}\c"; ((C++)); done; echo; }

text(){ #ARG $OPT $TEXT $UNDER_TYPE $TEXT2
    
    local OPT=$1
    local TEXT=$2
    local UNDER_TYPE=$3
    local TEXT2=$4
    
    [[ $OPT = 'log' ]] && local TYPE=$3
    [[ $OPT = 'err' || $OPT = 'war' ]] && local LOG_W=${3:-1}
    
    local TIME=$(date "+%H:%M:%S")
    local DATE=$(date "+%d/%m/%Y")
    
    [[ $OPT = u* ]] && local TEXT_UNDER=$(echo $TEXT | tr 'a-zA-Z0-9()[]:.\/ ' "$UNDER_TYPE")
    [[ $OPT = t* ]] && local TEXT_UNDER=$(echo $TEXT | tr 'a-zA-Z0-9()[]%:.\/' "$UNDER_TYPE")
    
    case $OPT in
        1    ) echo -e "${MG1} $TEXT";;
        2    ) echo -e "${MG1}[$TIME] $TEXT";;
        3    ) echo -e "${MG1} --> Quit [$DATE][$TIME]";;
        u1   ) echo -e "${MG1}${CLR_STR} $TEXT\n$(t_line "${MG2}" 40)${CLR_END}";;
        u2   ) echo -e "${MG1} <> $TEXT\n${MG1}    $TEXT_UNDER";;
        u3   ) echo -e "${MG1} <> $TEXT\t: $(echo $TEXT2 | sed s/\\./\ /g)"; echo -e "${MG1}    $TEXT_UNDER";;
        u4   ) echo -e "${MG1} $TEXT\n${MG1} $TEXT_UNDER";;
        t1   ) echo -e "${MG2}$TEXT\n${MG2}$TEXT_UNDER\n";;
        on   ) echo -e "${MG1}${CLR_STR} <+> Script Start [$TEXT] [$DATE][$TIME] <+>${CLR_END}";;
        off  ) echo -e "${MG1}${CLR_STR} <-> Script End [$DATE][$TIME] <->${CLR_END}\n${MG1}";;
        arg  ) echo -e "${MG1}\n${MG1} ${CLR_RED} <!> Error ! $TEXT ${CLR_END}";;
        inf  ) echo -e "${MG1}\n${MG1} ${CLR_BW} <Info> $TEXT ${CLR_END}"; log_write "$TEXT";;
        war  ) echo -e "${MG1}\n${MG1} ${CLR_YEL} <!> Warning ! $TEXT ${CLR_END}"; [[ $LOG_W = 1 ]] && log_write "$TEXT" 'Warning';;
        err  ) echo -e "${MG1}\n${MG1} ${CLR_RED} <!> Error ! $TEXT ${CLR_END}"; [[ $LOG_W = 1 ]] && log_write "$TEXT" 'Error';;
        log  ) log_write "$TEXT" "$TYPE";;
    esac
    
}

option_script_r(){
    
    for OPT in ${OPT_LIST_ARRAY[@]}; do
        local ARG=$(list_array "${ALL_ARG_LIST_ARRAY[*]}" | loko '$0 == "'"$OPT"'" {print $0}')
        ARG_LIST_ARRAY=("${ARG_LIST_ARRAY[@]}" "$ARG")
    done
}

ping_test(){ #ARG ${IP_DNS_LIST_ARRAY[@]}
    
    local IP_DNS_LIST_ARRAY=($1)
    local COUNT=0
    
    for IP_DNS in ${IP_DNS_LIST_ARRAY[@]}; do
        ping -c 1 $IP_DNS >&- 2>&-
        [[ $? = 0 ]] && break
        ((COUNT++))
        [[ $COUNT = ${#IP_DNS_LIST_ARRAY[@]} ]] && { text err "Bay not responding"; text 1; exit_S 1086; }
    done
}

load_B(){ #ARG $TOTAL_OBJECT $OBJECT $TYPE
    
    local TOTAL_OBJECT=$1
    local OBJECT=$2
    local TYPE=$3
    
    local PERCENT=$((OBJECT * 100 / TOTAL_OBJECT))
    
    if [[ $PERCENT = 0 ]]; then LOAD_BAR='[...........]'
    elif ((PERCENT>=1 && PERCENT<10)); then LOAD_BAR='[o..........]'
    elif ((PERCENT>=10 && PERCENT<20)); then LOAD_BAR='[oo.........]'
    elif ((PERCENT>=20 && PERCENT<30)); then LOAD_BAR='[ooo........]'
    elif ((PERCENT>=30 && PERCENT<40)); then LOAD_BAR='[oooo.......]'
    elif ((PERCENT>=40 && PERCENT<50)); then LOAD_BAR='[ooooo......]'
    elif ((PERCENT>=50 && PERCENT<60)); then LOAD_BAR='[oooooo.....]'
    elif ((PERCENT>=60 && PERCENT<70)); then LOAD_BAR='[ooooooo....]'
    elif ((PERCENT>=70 && PERCENT<80)); then LOAD_BAR='[oooooooo...]'
    elif ((PERCENT>=80 && PERCENT<90)); then LOAD_BAR='[ooooooooo..]'
    elif ((PERCENT>=90 && PERCENT<100)); then LOAD_BAR='[oooooooooo.]'
    elif [[ $PERCENT = 100 ]]; then LOAD_BAR='[ooooooooooo]'; fi
    
    local FORMAT_PERCENT=$(printf "%02d" $PERCENT)
    local FORMAT_TOTAL_OBJECT=$(printf "%03d" $TOTAL_OBJECT)
    local FORMAT_OBJECT=$(printf "%03d" $OBJECT)
    
    if [[ $TOTAL_OBJECT != $OBJECT ]]; then
        echo -ne "${MG1}  $TYPE\t: [$FORMAT_OBJECT/$FORMAT_TOTAL_OBJECT] $LOAD_BAR ${FORMAT_PERCENT}%\r"
    else
        echo -e "${MG1}  $TYPE\t: [$FORMAT_OBJECT/$FORMAT_TOTAL_OBJECT] $LOAD_BAR ${FORMAT_PERCENT}% [done]"
    fi
}

exit_S(){ #ARG $CODE_EXIT
    
    CODE_EXIT=$1
    
    [[ $CODE_EXIT = 1085 ]] && exit 1
    
    [[ $_DEBUG_MODE = 1 ]] && { text 1; cat $ARRAY_INFO_TMP; }
    
    delete_tmp_file
    
    if [[ $CODE_EXIT = 1086 ]]; then
        text log "Exit Script"
        exit 1
        
    elif [[ $CODE_EXIT != 0 ]]; then
        
        text 1; text 1 "${CLR_RED} <!> Last Command Return Error Code [$CODE_EXIT] ${CLR_END} [Log File : $LOG_FILE]"
        text 1; text 3; text 1
        
        text log "Last Command Return Error $CODE_EXIT" 'Error'
        text log "Exit Script"
        exit 1
        
    fi
    
    text 1; text off; text 1
    text log "End Script Execution"
    exit 0
    
}

cmd_exc_wait(){
    
    local COMMAND=$1
    local CMD_PID=$2
    local COUNT=0
    local WAIT_V=''
    local MARG=1
    local COLUMNS=$(tput cols)
    local CMD_LENGHT=${#COMMAND}
    local DISPL_LENGHT=$((${#MG1}+${#TIME}+MARG+2+2+2+5+3))
    local CMD_D_LENGHT=$((CMD_LENGHT+DISPL_LENGHT))
    
    if ((CMD_D_LENGHT>COLUMNS)); then
        local CMD_RESIZE=$((COLUMNS-DISPL_LENGHT))
        local CMD_DISPLAY=${COMMAND:0:${CMD_RESIZE}}
        local CMD_DISPLAY="${CMD_DISPLAY}."
    else
        local CMD_DISPLAY=${COMMAND}
    fi
    
    text log "$COMMAND" 'Command'
    
    while [[ $CMD_STATUS != 'done' ]]; do
        
        for MAC_WAIT in 'o--' '-o-' '--o' '-o-'; do
            ((COUNT>100)) && WAIT_V='[w]'
            echo -ne "${MG1}  [${TIME}] $CMD_DISPLAY [${MAC_WAIT}]${WAIT_V}\r"
            sleep 0.2
        done
        
        ((COUNT++))
        
        if ((COUNT<10)); then
            local CMD_STATUS=$(jobs -l 2>&- | awk '$2 == "'"$CMD_PID"'" {print $3}' | tr 'A-Z' 'a-z')
            
        elif ((COUNT<100)); then
            [[ $COUNT =~ 0$|2$|4$|6$|8$ ]] && local CMD_STATUS=$(jobs -l 2>&- | awk '$2 == "'"$CMD_PID"'" {print $3}' | tr 'A-Z' 'a-z')
            
        else
            [[ $COUNT =~ 0$|5$ ]] && local CMD_STATUS=$(jobs -l 2>&- | awk '$2 == "'"$CMD_PID"'" {print $3}' | tr 'A-Z' 'a-z')
            
        fi
        
        [[ -z $CMD_STATUS ]] && CMD_STATUS='done'
        
    done
    
    text 1 " [${TIME}] $COMMAND \c"
    
}

cmd_exc() { #ARG $EX_MODE $CMD_TYPE $COMMAND
    
    local EX_MODE=$1
    local CMD_TYPE=$2
    local COMMAND=$3
    local CMD_RETRY_COUNT=0
    local CMD_RETRY_COUNT_MAX=20
    local CMD_RETRY_TIME=30
    
    unset _CMD_LOCK
    
    if [[ $EX_MODE = 'DISPLAY' ]]; then
        text 1 " $COMMAND"
        
    elif [[ $EX_MODE = 'RUN' ]]; then
        
        until [[ $_CMD_LOCK = 0 || $CMD_RETRY_COUNT = $CMD_RETRY_COUNT_MAX ]]; do
            
            local TIME=$(date "+%H:%M:%S")
            
            { 
                $COMMAND > $RETURNCMD_LOG_FILE_TMP 2>&1; local CMD_RETURN=$?
                echo "_LAST_RETURN_CMD_;${CMD_RETURN}" >> $RETURNCMD_LOG_FILE_TMP
            } &
            
            local CMD_PID=$!; cmd_exc_wait "$COMMAND" "$CMD_PID"
            
            CMD_RETURN=$(cat $RETURNCMD_LOG_FILE_TMP | loko '$1 == "_LAST_RETURN_CMD_" {print $2}')
            
            cat $RETURNCMD_LOG_FILE_TMP | egrep -vi '^_LAST_RETURN_CMD_|step|^$' >> $LOG_FILE
            
            [[ $CMD_RETURN != 0 ]] && cmd_locked_check || _CMD_LOCK=0
            
            if [[ $_CMD_LOCK = 1 ]]; then
                echo "![Locked][Retry in ${CMD_RETRY_TIME}s]"
                text log "Last cmd locked. Lock Retry to $CMD_RETRY_TIME" 'Error'
                sleep $CMD_RETRY_TIME
                ((CMD_RETRY_COUNT++))
                
            fi
            
        done
        
        [[ $CMD_TYPE = C ]] && new_lun_list_r "$COMMAND"
        
        if [[ $CMD_RETURN = 0 ]]; then
            echo '[cmd OK]'
            
        else
            echo '![cmd Fail]'
            
            if [[ $CMD_TYPE = C && "$COMMAND" =~ commit ]]; then
                
                BIND_CHECK=$(cat $RETURNCMD_LOG_FILE_TMP | grep -i "Bind failed can't match new devices with requested attributes" | wc -l)
                [[ $BIND_CHECK != 0 ]] && return 1 || exit_S $CMD_RETURN
                
            fi
            
            if [[ "$COMMAND" =~ (unbind |free -all )-dev ]]; then
                
                UNBIND_FREE_ERR_CHECK=$(cat $RETURNCMD_LOG_FILE_TMP | grep -i "The device is already in the requested state" | wc -l)
                
                [[ $UNBIND_FREE_ERR_CHECK != 0 ]] && return 2 || return 1
                
            else
                exit_S $CMD_RETURN
            
            fi
        fi
        
    fi
}

cmd_locked_check(){
    
    _CMD_LOCK=0
    
    local CMD_LOCK_CHECK=$(cat $RETURNCMD_LOG_FILE_TMP | grep -i 'locked by another process')
    
    [[ -n $CMD_LOCK_CHECK ]] && _CMD_LOCK=1
}

file_write(){ #ARG $EX_MODE $MODE $TMP_FILE $TEXT
    
    local EX_MODE=$1
    local MODE=$2
    local TMP_FILE=$3
    local TEXT=$4
    
    if [[ $EX_MODE = 'DISPLAY' ]]; then    
        [[ $MODE = 'D' ]] && { text 1 "() Create file with $TEXT [$TMP_FILE] :"; text 1; }
        [[ $MODE = 'X' ]] && text 1 "  + $TEXT"
        
    elif [[ $EX_MODE = 'RUN' ]]; then
        [[ $MODE = 'D' ]] && { text 1 "() Create file with $TEXT [$TMP_FILE] \c"; > $TMP_FILE; }
        [[ $MODE = 'X' ]] && printf "$TEXT\n" >> $TMP_FILE
        
    fi
}

sc_exec(){
    
    local EX_MODE=$1
    local T_TITLE=$2
    local T_TEXT=$3
    local TMP_FILE=$4
    local VAR_LIST_ARRAY=($5)
    local SC_COMMAND=$6
    local SC_MODE=$7
    
    text u2 "$T_TITLE" '~'
    
    file_write $EX_MODE D $TMP_FILE "$T_TEXT"
    
    for VAR in ${VAR_LIST_ARRAY[@]}; do
        file_write $EX_MODE X $TMP_FILE "$(echo "$SC_COMMAND" | sed s/\(!VAR\)/$VAR/g)"
    done
    
    [[ $EX_MODE = 'RUN' ]] && { L_CMD=$?; cmd_check $L_CMD; }
    
    text 1
    cmd_exc $EX_MODE $SC_MODE "symconfigure -sid $BAY_SID -f $TMP_FILE prepare -nop"
    cmd_exc $EX_MODE $SC_MODE "symconfigure -sid $BAY_SID -f $TMP_FILE commit -nop"
    text 1
    
    [[ $EX_MODE = 'RUN' ]] && rm -f $TMP_FILE
    
}

choice_select_function(){ #ARG $SELECT_MODE $ARRAY_LIST $TYPE $SELECT_TYPE
    
    local ARRAY_LIST=($2)
    local SELECT_MODE=$1
    local TYPE=$3
    local SELECT_TYPE=$4
    
    local ARRAY_SELECT=()
    
    local VAR_NAME
    
    choice_select(){ #ARG $ARRAY_SELECT
        
        ARRAY_SELECT=("Return" $1)
        
        unset VAR_RESULT
        
        text 1
        [[ $SELECT_MODE = 2 ]] && { text 1 "<> Select $TYPE :"; text 1; }
        
        for CNT in ${!ARRAY_SELECT[@]}; do
            
            if [[ $CNT != 0 ]]; then
                [[ $SELECT_TYPE = 'Option' ]] && echo -e "${MG1}  [$CNT] <> $(echo "${ARRAY_SELECT[$CNT]}" | sed s/_/\ /g)"
                [[ $SELECT_TYPE != 'Option' ]] && echo -e "${MG1}  [$CNT] <> ${ARRAY_SELECT[$CNT]}"
            fi
            
        done
        
        text 1
        
        while [[ -z $VAR_RESULT ]]; do
            
            [[ $SELECT_MODE = 1 ]] && { echo -e "${MG1} Choice [0 to Change] : \c"; read CHOICE; }
            [[ $SELECT_MODE = 2 ]] && { echo -e "${MG1} Choice : \c"; read CHOICE; }
            
            for CNT in ${!ARRAY_SELECT[@]}; do
                [[ $SELECT_MODE = 1 ]] && [[ $CHOICE = 0 ]] && VAR_RESULT='!0'
                [[ $CHOICE = $CNT ]] && [[ $CHOICE != 0 ]] && VAR_RESULT="${ARRAY_SELECT[$CNT]}"
            done
            
        done
        
        [[ $VAR_RESULT = '!0' ]] && var_select "${ARRAY_LIST[*]}"
    }
    
    var_select(){ #ARG $ARRAY_LIST
        
        ARRAY_LIST=($1)
        
        unset VAR_RESULT
        unset CHOICE
        unset VAR_NAME
        
        text 1
        
        echo -e "${MG1} Enter $TYPE $SELECT_TYPE [Type 'List' for Full Listing] : \c"; read VAR_NAME
        
        if [[ $VAR_NAME = 'List' ]]; then 
            choice_select "${ARRAY_LIST[*]}"
        else 
            ARRAY_SELECT=($(list_array "${ARRAY_LIST[*]}" | grep -i $VAR_NAME 2>&-))
            [[ ${#ARRAY_SELECT[@]} > 1 ]] && choice_select "${ARRAY_SELECT[*]}"
            [[ ${#ARRAY_SELECT[@]} = 1 ]] && VAR_RESULT="${ARRAY_SELECT[@]}"
        fi
    }
    
    if [[ $SELECT_MODE = 1 ]]; then
        
        var_select "${ARRAY_LIST[*]}"
        
        while [[ -z $VAR_RESULT ]]; do
            echo -e "${MG1}\n${MG1}  <!> $TYPE [$VAR_NAME] not find"
            var_select "${ARRAY_LIST[*]}"
        done
        
    elif [[ $SELECT_MODE = 2 ]]; then
        choice_select "${ARRAY_LIST[*]}"
        
    fi
    
    text 1
    
    echo -e "${MG1}  ${CLR_BW} $TYPE Selected : $VAR_RESULT ${CLR_END}"
}

lun_size(){ #ARG $SIZE
    
    local SIZE=$1
    
    if ((SIZE < 1024)); then
        SIZE=$SIZE; local VAL='MB'
    elif ((SIZE >= 1024 || SIZE < 1048576)); then
        SIZE=$((SIZE/1024)); local VAL='GB'
    elif ((SIZE >= 1048576 || SIZE<1073741824)); then 
        SIZE=$((SIZE / 1024 / 1024)); local VAL='TB'
    fi
    
    echo "${SIZE} ${VAL}"
}

lun_size_tracks(){ #ARG $SIZE_T
    
    local SIZE_T=$1
    
    [[ $BAY_T = 12 ]] && local RATIO=0.9375 || local RATIO=1.875
    [[ $SIZE_T != 0    ]] && local SIZE_MB=$(echo "$SIZE_T" / 15 \* $RATIO | bc | cut -d. -f1) || local SIZE_MB=0
    [[ $SIZE_MB = 0 ]] && echo "${SIZE_T} TR" || lun_size "$SIZE_MB"
    
}

lun_size_block(){ #ARG $SIZE_BC

    local SIZE_BC=$1
    local SIZE=$(echo $SIZE_BC / 2 / 1024 / 1024 | bc)
    
    ((SIZE < 1024)) && echo "${SIZE} GB" || echo "$(echo $SIZE / 1024 | bc) TB"
    
}

time_display(){ local TIME_V=$1; echo "${TIME_V:0:2}/${TIME_V:3:2}/${TIME_V:6:4} ${TIME_V:11:2}:${TIME_V:14:2}"; }
