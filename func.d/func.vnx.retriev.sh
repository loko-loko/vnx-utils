# func.vnx.retriev.sh

lun_r(){ #ARG ${SG_LIST_ARRAY[@]}
    
    local SG_LIST_ARRAY=($1)
    
    for SG in ${SG_LIST_ARRAY[@]}; do
        LUN_LIST_A=($(echo "$SG_INFO_LIST" | awk -v RS='' '/'"$SG"'/' | awk '/HLU Number/,/Shareable/' | egrep -v 'HLU Number|Shareable|\-\-\-\-\-' | awk '{print $2}'))
        LUN_LIST_ARRAY=("${LUN_LIST_ARRAY[@]}" "${LUN_LIST_A[@]}")
    done
    
    LUN_LIST_ARRAY=($(list_array "${LUN_LIST_ARRAY[*]}" | sort -u))
    
}

os_retriev_info(){
    #NOTE(LK): To customize 
    
    OS_T=$(echo $1 | tr 'a-z' 'A-Z')
    
    case $OS_T in
        AIX      ) INIT_T=3; FO_MODE=4; ARRAY_CP=0;;
        LINUX    ) INIT_T=3; FO_MODE=4; ARRAY_CP=0;;
        HP-UX    ) INIT_T=3; FO_MODE=4; ARRAY_CP=0;;
        SOLARIS  ) INIT_T=3; FO_MODE=4; ARRAY_CP=0;;
        WINDOWS  ) INIT_T=3; FO_MODE=4; ARRAY_CP=0;;
        *        ) arg_script_error "OS '${OS_T}' Unknown [Aix|Linux|Hp-Ux|Solaris|Windows]";;
    esac

}

select_mode_bay(){ #NO ARG
    
    text 1 " + Retrieving Bay List \c"
    
    if [[ $_OPT_MODE =~ Info|Remove ]]; then
        local BAY_LIST_ARRAY=($(awk '$0 ~ /CKM/ {print $1}' $VNX_LIST_FILE))
        
    elif [[ $_OPT_MODE == 'Create' ]]; then
        BAY_LIST_ARRAY=($(awk '$0 ~ /CKM/ && $2 == "Pool" {print $1}' $VNX_LIST_FILE))
    
    elif [[ $_OPT_MODE == 'Modify' ]]; then
        BAY_LIST_ARRAY=($(awk '$0 ~ /CKM/ && $3 == "E" {print $1}' $VNX_LIST_FILE))
    
    fi
    
    echo "[${#BAY_LIST_ARRAY[@]}]"
    
    choice_select_function 1 "${BAY_LIST_ARRAY[*]}" 'Bay' 'ID'
    
    _OPT_BAY='SID'
    
    bay_retrieving $VAR_RESULT
    
}

select_mode_device(){ #NO ARG
    
    if [[ $_OPT_DEVICE = 'SG' ]]; then
        
        text 1 " + Retrieving SG List \c"
        
        local SG_ALL_LIST_ARRAY=($($NAVICLI_PATH/naviseccli -h $BAY_ID storagegroup -list 2>&- | grep -i "Storage Group Name:" | awk -F':    ' '{print $NF}' | tr ' ' '_'))
        
        echo "[${#SG_ALL_LIST_ARRAY[@]}]"
        
        choice_select_function 1 "${SG_ALL_LIST_ARRAY[*]}" 'SG' 'Name'
        
        SG_LIST_ARRAY=("$VAR_RESULT")
        
    elif [[ $_OPT_DEVICE =~ ^ID|UID|NAME$ ]]; then
        
        L_TYPE=${_OPT_DEVICE}
        _OPT_DEVICE='LUN'
        
        case $L_TYPE in
            ID        ) local L_TYPE_EX="58,0123";;
            UID        ) local L_TYPE_EX="600601604B8134003804FA894F2FE711,60:06:01:60:4B:81";;
            NAME    ) local L_TYPE_EX="SASRG12L_0232,SASRG6L_0248";;
        esac
        
        text 1
        
        while [[ -z $LUN_LIST_ARG ]]; do
            text 1 " Enter Lun(s) ${L_TYPE} [ Example : ${L_TYPE_EX}... ] : \c"; read LUN_LIST_ARG
        done
        
        LUN_LIST_ARRAY=($(echo "$LUN_LIST_ARG" | sed s/,/\\n/g))
        
        [[ $L_TYPE = 'UID' ]] && LUN_LIST_ARRAY=($(list_array "${LUN_LIST_ARRAY[*]}" | tr -d : | sed -r 's/.{2}/&:/g;s/.$//' | tr 'a-z' 'A-Z'))
        
    elif [[ $_OPT_DEVICE = 'WWN' ]]; then
        
        text 1
        
        until [[ -n $WWN_LIST_ARG && $ERR_WWN_SX_1 = 0 ]]; do
            
            text 1 " Enter Login(s) [ Example : 500009750000879d,... ] : \c"; read WWN_LIST_ARG
            WWN_LIST_ARRAY=($(echo "$WWN_LIST_ARG" | tr 'A-Z' 'a-z' | tr -d : | sed s/,/\\n/g))
            wwn_arg_syntax_check "${WWN_LIST_ARRAY[*]}"
            
        done
        
        
        
    fi
    
    unset LUN_LIST_ARG
    unset WWN_LIST_ARG
    
}

select_mode_retrieve(){
    
    local OPT_MODE_LIST_ARRAY=("Info" "Create" "Remove" "Modify")
    
    choice_select_function 2 "${OPT_MODE_LIST_ARRAY[*]}" 'Mode' 'Option'
    _OPT_MODE=$VAR_RESULT
    
    text 1
    select_mode_bay
    text 1
    
    if [[ $_OPT_MODE = 'Info' ]]; then
        
        local OPT_DEVICE_LIST_ARRAY=('Lun(s)_ID' 'Lun(s)_UID' 'Lun(s)_Name' 'Storage_Group' 'Login(s)_(WWN)')
        choice_select_function 2 "${OPT_DEVICE_LIST_ARRAY[*]}" 'Device Type' 'Option'
        _OPT_DEVICE=$VAR_RESULT
        text 1
        
    elif [[ $_OPT_MODE = 'Remove' ]]; then
        
        _OPT_RMV_MODE='Normal'
        
        local OPT_DEVICE_LIST_ARRAY=('Lun(s)_ID' 'Lun(s)_UID' 'Lun(s)_Name' 'Storage_Group')
        choice_select_function 2 "${OPT_DEVICE_LIST_ARRAY[*]}" 'Device Type' 'Option'
        _OPT_DEVICE=$VAR_RESULT
        text 1
        
    elif [[ $_OPT_MODE = 'Create' ]]; then
        
        while [[ -z $RESP_NEW_SG ]] || [[ ! $RESP_NEW_SG =~ ^(YES|Y|NO|N)$ ]]; do
            text 1 "<> Do You Want Create New S.Group ? [Y|N] : \c"; read RESP_NEW_SG
            RESP_NEW_SG=$(echo $RESP_NEW_SG | tr 'a-z' 'A-Z')
        done
        
        while [[ -z $RESP_NEW_HOST ]] || [[ ! $RESP_NEW_HOST =~ ^(YES|Y|NO|N)$ ]]; do
            text 1 "<> Do You Want Register New Host(s) ? [Y|N] : \c"; read RESP_NEW_HOST
            RESP_NEW_HOST=$(echo $RESP_NEW_HOST | tr 'a-z' 'A-Z')
        done
        
        if [[ $RESP_NEW_HOST =~ Y ]]; then
            _NEW_HOST=1
            _NEW_NAME=1
            
            while [[ -z $RESP_NEW_CLUST ]] || [[ ! $RESP_NEW_CLUST =~ ^(YES|Y|NO|N)$ ]]; do
                text 1 "<> Do You Want Create New Cluster ? [Y|N] : \c"; read RESP_NEW_CLUST
                RESP_NEW_CLUST=$(echo $RESP_NEW_CLUST | tr 'a-z' 'A-Z')
            done
            
        fi
        
        if [[ $RESP_NEW_SG =~ YES|Y ]]; then
            local NAME_T_ARRAY=("S.Group")
            _NEW_SG=1
            _NEW_NAME=1
            RESP_NEW_LUN='Y'
            
        else
            
            while [[ -z $RESP_NEW_LUN ]] || [[ ! $RESP_NEW_LUN =~ ^(YES|Y|NO|N)$ ]]; do
                text 1
                text 1 "<> Do You Want Create New Lun(s) ? [Y|N] : \c"; read RESP_NEW_LUN
                RESP_NEW_LUN=$(echo $RESP_NEW_LUN | tr 'a-z' 'A-Z')
            done
            
        fi
        
        text 1
        
        [[ $RESP_NEW_HOST =~ N && $RESP_NEW_SG =~ N && $RESP_NEW_LUN =~ N ]] && exit_S 0
        
        if [[ $_NEW_NAME = 1 ]]; then
            
            [[ $RESP_NEW_CLUST =~ Y ]] && { EXAMPLE_T='parva6754343-44'; TYPE_T='Cluster'; } || { EXAMPLE_T='s00va9867677'; TYPE_T='Server'; }
            
            until [[ -n $NEW_NAME && $ERR_NAME_1 = 0 ]]; do
                ERR_NAME_1=0
                text 1 "<> Enter New Name of ${TYPE_T} [$(list_sep "${NAME_T_ARRAY[*]}" '|')] [Ex : ${EXAMPLE_T}] : \c"; read NEW_NAME
                NEW_NAME=$(echo $NEW_NAME | tr 'A-Z' 'a-z')
                
                [[ $NEW_NAME =~ sg_|_sg  ]] && { text err "Enter Only Name of ${TYPE_T} [Ex : ${EXAMPLE_T}]" 0; text 1; ERR_NAME_1=1; }
            done
            
            text 1
            
        fi
        
        if [[ $RESP_NEW_HOST =~ Y ]]; then
            
            if [[ $RESP_NEW_CLUST =~ Y ]]; then
                
                unset NODE_COUNT
                
                _NEW_CLUST=1
                
                while [[ -z $NODE_COUNT ]] || [[ ! $NODE_COUNT =~ ^[0-9]+$ ]]; do
                    text 1 "<> Enter Number of Node : \c"; read NODE_COUNT
                done
                
                text 1
                
            fi
            
            [[ $NODE_COUNT != 1 ]] && { local NODE_D="Node"; } || { local NODE_D="Server"; }
            
            for NODE_C in $(seq 1 ${NODE_COUNT}); do
                
                [[ $NODE_COUNT = 1 ]] && NODE_C='' || NODE_C=" ${NODE_C}"
                
                until [[ -n $NODE_NAME && $ERR_NAME_1 = 0 ]]; do
                    ERR_NAME_1=0
                    text 1 "<> Enter Name of ${NODE_D}${NODE_C} [Ex : parva457841] : \c"; read NODE_NAME
                    NODE_NAME=$(echo $NODE_NAME | tr 'A-Z' 'a-z')
                    
                    NAME_EXIST_C=$(list_array "${NEW_HOST_IP_WWN_LIST_ARRAY[*]}" | awk -F\] '{print $1}' | tr -d \[ | awk -F',' '$1 == "'"$NODE_NAME"'" {print 1}' | sort -u)
                    
                    [[ $NAME_EXIST_C = 1 ]] && { text err "Name $NODE_NAME already Enter. Nodes can't have the same Name" 0; text 1; ERR_NAME_1=1; }
                    [[ $NODE_NAME =~ sg_|_sg  ]] && { text err "Enter Only Name of ${NODE_D}. [Ex : s00va9867676]" 0; text 1; ERR_NAME_1=1; }
                    [[ $NODE_NAME = $NEW_NAME ]] && { text err "The Name of Cluster and Node can't are the same" 0; text 1; ERR_NAME_1=1; }
                    
                done
                
                until [[ -n $NODE_IP && $ERR_IP_1 = 0 ]]; do
                    ERR_IP_1=0
                    text 1 "<> Enter IP of ${NODE_D}${NODE_C} [Ex : 1.1.1.1] : \c"; read NODE_IP
                    
                    IP_EXIST_C=$(list_array "${NEW_HOST_IP_WWN_LIST_ARRAY[*]}" | awk -F\] '{print $1}' | tr -d \[ | awk -F',' '$2 == "'"$NODE_IP"'" {print 1}' | sort -u)
                    
                    [[ $IP_EXIST_C = 1 ]] && { text err "IP $NODE_IP already Enter. Nodes can't have the same IP" 0; text 1; ERR_IP_1=1; }
                    
                    ip_arg_syntax_check "${NODE_IP}"; [[ $ERR_IP_SX_1 = 1 ]] && ERR_IP_1=1
                    
                done
                
                until [[ -n $NODE_WWN && $ERR_WWN_SX_1 = 0 ]]; do
                    
                    text 1 "<> Enter Logins of ${NODE_D}${NODE_C} [Ex : 500009750000879d,..] : \c"; read NODE_WWN
                    
                    NODE_WWN_LIST_ARRAY=($(echo "$NODE_WWN" | sed s/,/\\n/g | tr -d : | sed -r 's/.{2}/&:/g;s/.$//' | tr 'a-z' 'A-Z' | sort -u))
                    
                    if [[ -n $NODE_WWN ]]; then
                        
                        wwn_arg_syntax_check "${NODE_WWN_LIST_ARRAY[*]}"
                        
                        [[ $(modulo_c "${#NODE_WWN_LIST_ARRAY[@]}") != 0 ]] && { text err "2 Logins Min (Peer/Odd Fabric) and Peer Number Only (2/4/6.. Logins)" 0; text 1; ERR_WWN_SX_1=1; }
                        
                        for NODE_WWN in ${NODE_WWN_LIST_ARRAY[@]}; do
                            WWN_EXIST_C=$(list_array "${NEW_HOST_IP_WWN_LIST_ARRAY[*]}" | awk -F\] '{print $2}' | sed s/,/\\n/g | awk '$1 == "'"$NODE_WWN"'" {print 1}' | sort -u)
                            [[ $WWN_EXIST_C = 1 ]] && { text err "WWN ${NODE_WWN} already Enter. Nodes can't have the same Logins" 0; text 1; ERR_WWN_SX_1=1; break; }
                        done
                        
                    fi
                    
                done
                
                NEW_HOST_IP_WWN_LIST_ARRAY=("${NEW_HOST_IP_WWN_LIST_ARRAY[@]}" "[${NODE_NAME},${NODE_IP}]$(list_sep "${NODE_WWN_LIST_ARRAY[*]}")")
                
                unset NODE_NAME
                unset NODE_IP
                unset NODE_WWN
                
                text 1
                
            done
            
            node_arg_check "${NEW_HOST_IP_WWN_LIST_ARRAY[*]}"
            
        fi
        
        [[ $RESP_NEW_LUN =~ Y ]] && _NEW_LUN=1
        
        text 1
        
        [[ $RESP_NEW_SG =~ N ]] && _OPT_DEVICE='Storage_Group'
        
    elif [[ $_OPT_MODE = 'Modify' ]]; then
        _OPT_MDF_MODE='lun_size'
    
    
    fi
    
    [[ $_OPT_DEVICE = 'Lun(s)_ID' ]] && _OPT_DEVICE='ID'
    [[ $_OPT_DEVICE = 'Lun(s)_UID' ]] && _OPT_DEVICE='UID'
    [[ $_OPT_DEVICE = 'Lun(s)_Name' ]] && _OPT_DEVICE='NAME'
    [[ $_OPT_DEVICE = 'Storage_Group' ]] && _OPT_DEVICE='SG'
    [[ $_OPT_DEVICE = 'Login(s)_(WWN)' ]] && _OPT_DEVICE='WWN'
    
    select_mode_device
    
}


bay_retrieving(){ #ARG $BAY_ARG
    
    local BAY_ARG=$1
    
    [[ $_OPT_BAY = 'SID' ]] && local BAY_INFO=$(awk -v SID=$BAY_ARG '{LSID=length(SID);SID_LST=substr($1,(15-LSID),LSID)};SID == SID_LST {print $0}' $VNX_LIST_FILE)
    [[ $_OPT_BAY = 'DNS' ]] && local BAY_INFO=$(awk '$0 !~ /#/ && $4 ~ /(^|,)'"$BAY_ARG"'($|,)/ {print $0}' $VNX_LIST_FILE)
    [[ $_OPT_BAY = 'IP' ]] && local BAY_INFO=$(awk '$0 !~ /#/ && $5 ~ /(^|,)'"$BAY_ARG"'($|,)/ {print $0}' $VNX_LIST_FILE)
    
    [[ -z $BAY_INFO ]] && { text err "${_OPT_BAY} ${BAY_ARG} is not referenced"; all_bay_display; text 1; exit_S 1086; }
    
    local BAY_SERIAL=$(echo "$BAY_INFO" | awk '{print $1}')
    local BAY_TYPE=$(echo "$BAY_INFO" | awk '{print $2}')
    local BAY_LUN_TYPE=$(echo "$BAY_INFO" | awk '{print $3}')
    local BAY_DNS_LIST_ARRAY=($(echo "$BAY_INFO" | awk '$2 != "N/A" {print $4}' | sed s/,/\\n/g))
    local BAY_IP_LIST_ARRAY=($(echo "$BAY_INFO" | awk '$3 != "N/A" {print $5}' | sed s/,/\\n/g))
    local BAY_DNS_IP_LIST_ARRAY=("${BAY_DNS_LIST_ARRAY[@]}" "${BAY_IP_LIST_ARRAY[@]}")
    
    printf "_BAY_INFO_;$BAY_SERIAL;$(list_sep "${BAY_DNS_LIST_ARRAY[*]:-No}");$(list_sep "${BAY_IP_LIST_ARRAY[*]:-No}");\n" >> $ARRAY_INFO_TMP
    
    ping_test "${BAY_DNS_IP_LIST_ARRAY[*]}"; BAY_ID=$IP_DNS; BAY_T=$BAY_TYPE; BAY_LT=$BAY_LUN_TYPE; BAY_SID=${BAY_SERIAL:10:4}
    
    $NAVICLI_PATH/naviseccli -h $BAY_ID > /dev/null 2>&1; [[ $? != 0 ]] && { text err "Authentification Error"; text 1; exit_S 1086; }

}


command_retrieving(){ #NO ARG
    
    echo -e "${MG1}  [R] Commands  \t: \c"
    
    echo -e "[SG]\c"
    SG_INFO_LIST=$($NAVICLI_PATH/naviseccli -h $BAY_ID storagegroup -list 2>&- | grep -v ^$ | awk '/^Storage Group Name:/ { print "\n" } { print }')
    
    echo -e "[WWN]\c"
    WWN_INFO_LIST=$($NAVICLI_PATH/naviseccli -h $BAY_ID port -list -all 2>&- | grep -v ^$ | awk '/HBA UID:/ { print "\n" } { print }')
    
    echo -e "[Mir.V]\c"
    MIRROR_VIEW_LIST=$($NAVICLI_PATH/naviseccli -h $BAY_ID mirror -sync -list 2>&- | grep -v ^$ | awk '/MirrorView Name/ {print "\n"} {print}')
    
    if [[ $(echo "$MIRROR_VIEW_CHECK" | grep -i 'Request failed.  Management Server' | wc -w) = 0 ]]; then
        _MIRRORV_C='Yes'
        MIRRORV_OWNERGP_LIST=$(naviseccli -h $BAY_ID mirror -sync -list -ownergroupname 2>&-)

    else
        _MIRRORV_C='No'
    
    fi
    
    echo ' [done]'
    
}


mirror_view_retrieving(){ #ARG $LUN_MIRROR_INFO
    
    local MIRRORV_INFO_D=$(echo "$LUN_MIRROR_INFO" | awk '/Image UID:/ {print "\n"} {print}')
    
    local MIRRORV_NAME=$(echo "$MIRRORV_INFO_D" | grep -i "MirrorView Name:" | awk '{print $NF}')
    local MIRRORV_UID=$(echo "$MIRRORV_INFO_D" | grep -i "MirrorView UID:" | awk '{print $NF}')
    local MIRRORV_STATUS=$(echo "$MIRRORV_INFO_D" | grep -i "Remote Mirror Status:" | awk -F ':  ' '{print $NF}' | tr ' ' '_')
    local MIRRORV_STATE=$(echo "$MIRRORV_INFO_D" | grep -i "MirrorView State:" | awk '{print $NF}')
    local MIRRORV_FAULT=$(echo "$MIRRORV_INFO_D" | grep -i "MirrorView Faulted:" | awk '{print $NF}')
    local MIRRORV_COUNT=$(echo "$MIRRORV_INFO_D" | grep -i "Image Count:" | awk '{print $NF}')
    
    local IMAGE_STATE=$(echo "$MIRRORV_INFO_D" | grep -i "Image State:" | awk '{print $NF}')
    local IMAGE_SYNC_P=$(echo "$MIRRORV_INFO_D" | grep -i "Synchronizing Progress(%):" | awk '{print $NF}')
    
    local MIRRORV_LU_UID_LIST_ARRAY=($(echo "$MIRRORV_INFO_D" | grep -i "Logical Unit UID:" | awk '{print $NF}'))
    
    for MIRRORV_LU_UID in ${MIRRORV_LU_UID_LIST_ARRAY[@]}; do
        
        local MIRRORV_UID_INFO=$(echo "$MIRRORV_INFO_D" | awk -v RS='' '/'"$MIRRORV_LU_UID"'/')
        
        if [[ $LUN_UID = $MIRRORV_LU_UID ]]; then 
            local IMAGE_PRIM=$(echo "$MIRRORV_UID_INFO" | grep -i 'Is Image Primary:' | awk '{print $NF}')
            local MIRRORV_LU_UID_L=$MIRRORV_LU_UID
            local IMAGE_UID_L=$(echo "$MIRRORV_UID_INFO" | grep -i 'Image UID:' | awk '{print $NF}')
            
        else
            local MIRRORV_LU_UID_R=$MIRRORV_LU_UID
            local IMAGE_UID_R=$(echo "$MIRRORV_UID_INFO" | grep -i 'Image UID:' | awk '{print $NF}')
            
            local MIRRORV_LU_UID_R_LIST_A=("${MIRRORV_LU_UID_R_LIST_A[@]}" "${MIRRORV_LU_UID_R}-${IMAGE_UID_R}")
            
        fi
        
    done
    
    MIRRORV_OWNERGP=$(echo "$MIRRORV_OWNERGP_LIST" | awk -v RS='' '$0 ~ /MirrorView Name:/ && $3 == "'"$MIRRORV_NAME"'"' | grep -i 'Owner Group Name:' | awk '{print $NF}')
    
    [[ $MIRRORV_OWNERGP = 'N/A' ]] && MIRRORV_OWNERGP='No'
    [[ $IMAGE_PRIM = 'YES' ]] && IMAGE_TYPE='SRC' || IMAGE_TYPE='TGT'
    
    if [[ $MIRRORV_STATUS = 'Mirrored/No_Secondary_Images' ]]; then
        MIRRORV_LU_UID_R_LIST_A=("No.Remote.Image")
        IMAGE_SYNC_P='-'
    
    fi
    
    printf "_MIRROR_INFO_;$LUN_ID;$LUN_UID;$MIRRORV_LU_UID;$IMAGE_TYPE;$IMAGE_UID_L;$(list_sep "${MIRRORV_LU_UID_R_LIST_A[*]}");$MIRRORV_NAME;$MIRRORV_UID;$MIRRORV_OWNERGP;$MIRRORV_STATUS;$MIRRORV_STATE;$MIRRORV_FAULT;$MIRRORV_COUNT;$IMAGE_STATE;$IMAGE_SYNC_P\n" >> $ARRAY_INFO_TMP
    
}


lun_retrieving(){ #ARG ${LUN_LIST_ARRAY[@]}
    
    local LUN_LIST_ARRAY=($1)
    local COUNT_DONE=0
    
    local LUN
    
    echo -ne "${MG1}  [R] Lun(s)  \t: Lun(s) Info ..\r"
    
    [[ $_OPT_MODE != 'Create' ]] || [[ $_OPT_MODE = 'Create' && $BAY_LT = N ]] && $NAVICLI_PATH/naviseccli -h $BAY_ID getall -lun 2>&- | grep -v ^$ | awk '$1 == "LOGICAL" { print "\n" } { print }' > $GETALL_LUN_INFO_TMP
    [[ $_OPT_MODE = 'Create' && $BAY_LT = N ]] && SG_INFO_LIST=$($NAVICLI_PATH/naviseccli -h $BAY_ID storagegroup -list 2>&- | grep -v ^$ | awk '/^Storage Group Name:/ { print "\n" } { print }')
    
    $NAVICLI_PATH/naviseccli -h $BAY_ID lun -list 2>&- | grep -v ^$ | awk '$1 == "LOGICAL" { print "\n" } { print }'  > $LUN_LIST_INFO_TMP
    
    load_B ${#LUN_LIST_ARRAY[@]} $COUNT_DONE '[R] Lun(s)   '
    
    for LUN in ${LUN_LIST_ARRAY[@]}; do
        
        if [[ $L_TYPE = 'ID' ]]; then
            
            [[ ! $LUN =~ ^[0-9]+$ ]] && { text 1; text err "Lun with $L_TYPE $LUN have bad syntax. Check it"; exit_S 0; }
            
            LUN=$(expr $LUN + 0)
            
            local LUN_GETALL_INFO=$(awk -v RS='' '$0 ~ /^LOGICAL UNIT NUMBER/ && $4 == "'"$LUN"'" { print }' $GETALL_LUN_INFO_TMP)
            local LUN_INFO=$(awk -v RS='' '$0 ~ /^LOGICAL UNIT NUMBER/ && $4 == "'"$LUN"'" { print }' $LUN_LIST_INFO_TMP)
            
        elif [[ $L_TYPE = 'UID' ]]; then
            local LUN_GETALL_INFO=$(awk -v RS='' '/'"$LUN"'/' $GETALL_LUN_INFO_TMP)
            local LUN_INFO=$(awk -v RS='' '/'"$LUN"'/' $LUN_LIST_INFO_TMP)
            
        elif [[ $L_TYPE = 'NAME' ]]; then
            local LUN_GETALL_INFO=$(awk -v RS='' '$0 ~ /Name * '"$LUN"$'/' $GETALL_LUN_INFO_TMP)
            local LUN_INFO=$(awk -v RS='' '$0 ~ /Name:  '"$LUN"$'/' $LUN_LIST_INFO_TMP)
            
        fi
        
        if [[ $_OPT_MODE != 'Create' ]] && [[ -z $LUN_GETALL_INFO ]]; then
            
            [[ $_F_MODE = 0 ]] && { text 1; text err "Lun with $L_TYPE $LUN not exist. Check it"; exit_S 0; }
            
        else
        
            local LUN_NAME=$(echo "$LUN_GETALL_INFO" | egrep -i '^Name' | awk '{print $NF}')
            local LUN_ID=$(echo "$LUN_GETALL_INFO" | grep -i 'logical unit number' | awk '{print $NF}')
            local LUN_UID=$(echo "$LUN_GETALL_INFO" | grep -i 'UID:' | awk '{print $NF}')
            local LUN_STATE=$(echo "$LUN_GETALL_INFO" | grep -i '^State:' | awk '{print $NF}' | tr -d :)
            local CURRENT_SP=$(echo "$LUN_GETALL_INFO" | grep -i 'current owner' | awk '{print $NF}')
            local DEFAULT_SP=$(echo "$LUN_GETALL_INFO" | grep -i 'default owner' | awk '{print $NF}')
            local CAPACITY_BLOCK=$(echo "$LUN_GETALL_INFO" | grep -i 'LUN Capacity(Blocks):' | awk '{print $NF}')
            local CAPACITY_MB=$(echo "$LUN_GETALL_INFO" | grep -i 'LUN Capacity(Megabytes):' | awk '{print $NF}' | cut -d. -f1)
            local SG_LIST_ARRAY=($(echo "$LUN_GETALL_INFO" | grep -i 'LU Storage Groups' | awk -F":" '{print $NF}' | sed s/\"\ \"/\\n/g | tr -d '" '))
            
            if [[ $_MIRRORV_C = 'Yes' ]]; then
                
                LUN_MIRROR_INFO=$(echo "$MIRROR_VIEW_LIST" | awk -v RS='' '/'"$LUN_UID"'/')
                
                [[ -n $LUN_MIRROR_INFO ]] && { local MIRROR_CHECK='Yes'; mirror_view_retrieving "$MIRROR_VIEW_LIST"; } || local MIRROR_CHECK='No'
            
            fi
            
            if [[ -z $LUN_INFO ]]; then
                local LUN_TYPE='PDv'
                local RAID_TYPE=$(echo "$LUN_GETALL_INFO" | grep -i 'RAID Type:' | awk '{print $NF}')
                local RAID_GROUP_ID=$(echo "$LUN_GETALL_INFO" | grep -i 'RAIDGroup ID:' | awk '{print $NF}')
                
                [[ $RAID_GROUP_ID = 'N/A' ]] && RAID_GROUP_ID='-'
                
            else
                local LUN_TYPE='TDv'
                local POOL=$(echo "$LUN_INFO" | grep -i 'pool name' | awk '{print $NF}')
                local LUN_CONSUM=$(echo "$LUN_INFO" | awk '/Consumed Capacity \(GBs\):/ {print $NF}')
                local TIERING_POLICY=$(echo "$LUN_INFO" | grep -i 'tiering policy' | awk '{print $(NF - 1) $NF}')
                local INITIAL_TIER=$(echo "$LUN_INFO" | grep -i 'initial tier' | awk '{print $(NF - 1) $NF}')
                
                [[ ! $LUN_CONSUM =~ [0-9]+ ]] && LUN_CONSUM='-'
                
            fi
            
            META_CHECK=$(echo "$LUN_GETALL_INFO" | grep -i 'Is Meta LUN:' | awk '{print $NF}')
            
            [[ $META_CHECK = 'YES' ]] && LUN_TYPE="${LUN_TYPE}[M]"
            
            
            if [[ -z ${SG_LIST_ARRAY[@]} ]]; then
                local SG_HLU_LIST='No'
                
            else
                
                unset SG_HLU_LIST_ARRAY
                
                for SG in ${SG_LIST_ARRAY[@]}; do
                    local LUN_HLU=$(echo "$SG_INFO_LIST" | awk -v RS='' '/'"$SG"'/' | awk '$2 == "'"$LUN_ID"'" {print $1}' | sort -u)
                    local SG_HLU_LIST_ARRAY=("${SG_HLU_LIST_ARRAY[@]}" "$SG.$LUN_HLU")
                done
                
                local SG_HLU_LIST=$(list_sep "${SG_HLU_LIST_ARRAY[*]}")
                
            fi
            
            [[ $LUN_TYPE =~ TDv ]] && printf "_LUN_INFO_;$LUN_NAME;$LUN_ID;$LUN_TYPE;$LUN_STATE;$SG_HLU_LIST;$CURRENT_SP;$DEFAULT_SP;$CAPACITY_BLOCK;$CAPACITY_MB;${POOL:-'No'};No;$TIERING_POLICY;$INITIAL_TIER;$LUN_UID;${#SG_HLU_LIST_ARRAY[@]};$LUN_CONSUM;$MIRROR_CHECK\n" >> $ARRAY_INFO_TMP
            [[ $LUN_TYPE =~ PDv ]] && printf "_LUN_INFO_;$LUN_NAME;$LUN_ID;$LUN_TYPE;$LUN_STATE;$SG_HLU_LIST;$CURRENT_SP;$DEFAULT_SP;$CAPACITY_BLOCK;$CAPACITY_MB;$RAID_GROUP_ID;$RAID_TYPE;No;No;$LUN_UID;${#SG_HLU_LIST_ARRAY[@]};-;$MIRROR_CHECK\n" >> $ARRAY_INFO_TMP
            
        fi
        
        ((COUNT_DONE++))
        
        load_B ${#LUN_LIST_ARRAY[@]} $COUNT_DONE '[R] Lun(s)   '
        
    done
    
}


storage_retrieving(){ #ARG ${SG_LIST_ARRAY[@]}
    
    local SG_LIST_ARRAY=($1)
    
    local COUNT_DONE=0
    
    load_B ${#SG_LIST_ARRAY[@]} $COUNT_DONE '[R] S.Group(s)'
    
    for SG in ${SG_LIST_ARRAY[@]}; do
            
        SG_INFO=$(echo "$SG_INFO_LIST" | awk -v RS='' '/'"$SG"'/')
        WWN_INFO=$(echo "$WWN_INFO_LIST" | awk -v RS='' '/'"$SG"'/' | awk '$0 ~ /SP Name:/ { print "\n" } { print }')
        
        SG=$(echo "$SG_INFO" | grep -i 'Storage Group Name' | awk '{print $NF}')
        SG_UID=$(echo "$SG_INFO" | grep -i 'Storage Group UID:' | awk '{print $NF}')
        
        HBA_UID_LIST_ARRAY=$(echo "$SG_INFO" | awk '/HBA UID/,/HLU\/ALU Pairs|Shareable/' | egrep -v 'HBA UID|\-\-\-\-\-\-|Pairs:|Shareable:' | awk '{print $1}' | sort -u)
        LUN_LIST_ARRAY=($(echo "$SG_INFO" | awk '/HLU Number/,/Shareable/' | egrep -v 'HLU Number|Shareable|\-\-\-\-\-' | awk '{print $2}' | sort -n))
        LAST_HLU=$(echo "$SG_INFO" | awk '/HLU Number/,/Shareable/' | egrep -v 'HLU Number|Shareable|\-\-\-\-\-' | awk '{print $1}' | sort -n | sed -n '$p')
        HOST_LIST_ARRAY=($(echo "$WWN_INFO" | grep -i 'Server Name:' | awk '{print $NF}' | cut -d. -f1 | sort -u))
        
        HBA_UID_LIST=$(list_sep "${HBA_UID_LIST_ARRAY[*]}")
        LUN_LIST=$(list_sep "${LUN_LIST_ARRAY[*]}")
        HOST_LIST=$(list_sep "${HOST_LIST_ARRAY[*]}")
        
        printf "_SG_INFO_;$SG;$SG_UID;${HBA_UID_LIST:-No};${LUN_LIST:-No};${HOST_LIST:-No};${LAST_HLU:-'No'}\n" >> $ARRAY_INFO_TMP
        
        ((COUNT_DONE++))
        
        load_B ${#SG_LIST_ARRAY[@]} $COUNT_DONE '[R] S.Group(s)'
        
    done

}

logins_retrieving(){
    
    local WWN_LIST_ARRAY=($1)
    
    local COUNT_DONE=0
    
    load_B ${#WWN_LIST_ARRAY[@]} $COUNT_DONE '[R] Login(s)  '
    
    for WWN in ${WWN_LIST_ARRAY[@]}; do
        
        local WWN_INFO=$(echo "$WWN_INFO_LIST" | awk -v RS='' '/'"$WWN"'/' | awk '$0 ~ /SP Name:/ { print "\n" } { print }')
        
        [[ -z $WWN_INFO ]] && { text 1; text err "$WWN not exist. Check it"; exit_S 0; }
        
        local WWN_UID=$(echo "$WWN_INFO" | grep -i 'HBA UID:' | awk '{print $NF}')
        local WWN_HOST=$(echo "$WWN_INFO" | grep -i 'Server Name:' | awk '{print $NF}')
        local WWN_HOST_IP=$(echo "$WWN_INFO" | grep -i 'Server IP Address:' | awk '{print $NF}')
        
        local SP_N_ARRAY_LIST=$(echo "$WWN_INFO" | grep -i 'SP Name:' | awk '{print $NF}')
        local SP_P_ARRAY_LIST=$(echo "$WWN_INFO" | grep -i 'SP Port ID:' | awk '{print $NF}')
        
        local SP_NP_ARRAY_LIST=$(paste <(echo "$SP_N_ARRAY_LIST") <(echo "$SP_P_ARRAY_LIST") | awk '{print $1";"$2}')
        
        
        for SP_NP in ${SP_NP_ARRAY_LIST[@]}; do
            
            local SP_N=$(echo "$SP_NP" | cut -d';' -f1)
            local SP_P=$(echo "$SP_NP" | cut -d';' -f2)
            
            local PORT_INFO=$(echo "$WWN_INFO" | awk -v RS='' '/SP '"$SP_N"'/ && /SP Port ID:            '"$SP_P"'/')
            
            local FAILOVER_M=$(echo "$PORT_INFO" | grep -i 'Failover mode:' | awk '{print $NF}')
            local ARRAY_C=$(echo "$PORT_INFO" | grep -i 'ArrayCommPath:' | awk '{print $NF}')
            local LOG_IN=$(echo "$PORT_INFO" | grep -i 'Logged In:' | awk '{print $NF}')
            local DEFINED=$(echo "$PORT_INFO" | grep -i 'Defined:' | awk '{print $NF}')
            
            local SG_LIST_ARRAY=($(echo "$PORT_INFO" | grep -i 'StorageGroup Name:' | awk '{print $NF}' | sort -u))
            local SG_LIST=$(list_sep "${SG_LIST_ARRAY[*]}" ',')
            
            [[ $LOG_IN = 'YES' ]] && LOG_IN='Yes' || LOG_IN='No'
            [[ $DEFINED = 'YES' ]] && DEFINED='Yes' || DEFINED='No'
            
            printf "_WWN_INFO_;$WWN_UID;${SP_N}-${SP_P};$WWN_HOST;$WWN_HOST_IP;$SG_LIST;$FAILOVER_M;$ARRAY_C;$LOG_IN;$DEFINED\n" >> $ARRAY_INFO_TMP
            
        done
        
        ((COUNT_DONE++)); load_B ${#WWN_LIST_ARRAY[@]} $COUNT_DONE '[R] Login(s)  '
        
    done

}

lun_no_sg_retrieving(){
    
    echo -ne "${MG1}  [R] Free Lun(s) \t: Free Lun(s) List ..\r"
    
    $NAVICLI_PATH/naviseccli -h $BAY_ID getall -lun 2>&- | grep -v ^$ | awk '$1 == "LOGICAL" { print "\n" } { print }' > $GETALL_LUN_INFO_TMP
    
    local LUN_ALL_COUNT=$(awk '/LOGICAL UNIT NUMBER/ {print $NF}' $GETALL_LUN_INFO_TMP | wc -l)
    local LUN_WITHOUT_SG_INFO=$(awk -v RS='' '/LU Storage Groups:          /' $GETALL_LUN_INFO_TMP)
    
    local POOL_ID_LIST_ARRAY=($(echo "$LUN_WITHOUT_SG_INFO" | awk '/^Name/ {print $NF}' | cut -d'_' -f3 | tr -d 0))
    local LUN_LIST_ARRAY=($(echo "$LUN_WITHOUT_SG_INFO" | awk '/LOGICAL UNIT NUMBER/ {print $NF}'))
    local SIZE_LIST_ARRAY=($(echo "$LUN_WITHOUT_SG_INFO" | awk '/LUN Capacity\(Megabytes\):/ {print $NF/1024}' | cut -d. -f1))
    local SP_CR_LIST_ARRAY=($(echo "$LUN_WITHOUT_SG_INFO" | awk '/Current owner:/ {print $NF}'))
    local SP_DF_LIST_ARRAY=($(echo "$LUN_WITHOUT_SG_INFO" | awk '/Default Owner:/ {print $NF}'))
    
    paste <(list_array "${LUN_LIST_ARRAY[*]}") <(list_array "${SIZE_LIST_ARRAY[*]}")  <(list_array "${SP_CR_LIST_ARRAY[*]}")  <(list_array "${SP_DF_LIST_ARRAY[*]}") <(list_array "${POOL_ID_LIST_ARRAY[*]}") | awk '{printf "_LUN_WITHOUT_SG_;%s;%s;%s;%s;%s\n", $1, $2, $3, $4, $5}' >> $ARRAY_INFO_TMP
    
    echo -e "${MG1}  [R] Free Lun(s) \t: [ ${#LUN_LIST_ARRAY[@]} Free Lun(s) on $LUN_ALL_COUNT Lun(s) ]"
    
}

lun_empty_check(){ # ${LUN_LIST_ARRAY[@]}
    
    local LUN_LIST_ARRAY=($1)
    
    local COUNT_DONE=0
    
    echo -ne "${MG1}  [R] Lun(s)  \t: Lun(s) ..\r"
    
    $NAVICLI_PATH/naviseccli -h $BAY_ID lun -list 2>&- | grep -v ^$ | awk '$1 == "LOGICAL" { print "\n" } { print }'  > $LUN_LIST_INFO_TMP
    
    load_B ${#LUN_LIST_ARRAY[@]} $COUNT_DONE '[R] Empty Lun(s)'
    
    for LUN in ${LUN_LIST_ARRAY[@]}; do
        
        LUN_INFO=$(cat $LUN_LIST_INFO_TMP | awk -v RS='' '/'"$LUN"'/')
        
        PRIVATE_CHECK=$(echo "$LUN_INFO" | awk '/Is Private/ {print $NF}')
        
        if [[ $PRIVATE_CHECK == "No" ]]; then
        
            LUN_CONSUM=$(echo "$LUN_INFO" | awk '/Consumed Capacity \(GBs\):/ {print $NF}')
            LUN_POOL=$(echo "$LUN_INFO" | grep -i 'pool name' | awk '{print $NF}')
            
            printf "_NEW_LUN_INFO_;$LUN;$LUN_CONSUM;$LUN_POOL\n"  >> $ARRAY_INFO_TMP
            
        fi
        
        ((COUNT_DONE++)); load_B ${#LUN_LIST_ARRAY[@]} $COUNT_DONE '[R] Lun(s)'
        
    done
    
}

initiator_info_retrieving(){
    
    echo -ne "${MG1}  [R] Init(s)  \t: Init(s) Info ..\r"
    
    INIT_ALL_INFO=$($NAVICLI_PATH/naviseccli -h $BAY_ID port -list -initiatorcount 2>&-)
    
    SP_NAME=$(echo "$INIT_ALL_INFO" | grep -i 'sp name:' | awk '{print $NF}')
    SP_ID=$(echo "$INIT_ALL_INFO" | grep -i 'sp port id:' | awk '{print $NF}')
    REGISTER_INITIATORS=$(echo "$INIT_ALL_INFO" | egrep -wi '^registered initiators:' | awk '{print $NF}')
    LOGGEDIN_INITATORS=$(echo "$INIT_ALL_INFO" | egrep -wi '^logged-in initiators:' | awk '{print $NF}')
    NOT_LOGGEDIN_INITATORS=$(echo "$INIT_ALL_INFO" | egrep -wi '^not logged-in initiators:' | awk '{print $NF}')
    
    paste <(echo "$SP_NAME") <(echo "$SP_ID") <(echo "$REGISTER_INITIATORS") <(echo "$LOGGEDIN_INITATORS") <(echo "$NOT_LOGGEDIN_INITATORS") >> $ARRAY_INFO_TMP
    
    echo -e "${MG1}  [R] Init(s)  \t: Init(s) Info [done]"
    
}

host_retrieving(){ # ${HOST_LIST_ARRAY[@]}
    
    local HOST_LIST_ARRAY=($1)
    
    local COUNT_DONE=0
    
    load_B ${#HOST_LIST_ARRAY[@]} $COUNT_DONE '[R] Host(s)  '
    
    for HOST in ${HOST_LIST_ARRAY[@]}; do
        
        HOST_INFO=$(echo "$WWN_INFO_LIST" | awk -v RS='' '/'"$HOST"'/')
        
        HOST_IP_A=($(echo "$HOST_INFO" | awk '/^Server IP Address:/ {print $NF}' | sort -u))
        HOST_SG_A=($(echo "$HOST_INFO" | awk '/StorageGroup Name:/ {print $NF}' | sort -u))
        
        [[ ${#HOST_IP_A[@]} > 1 ]] && { text 1; text err "The same host have several IP. Check it"; exit_S 0; }
        [[ ${#HOST_SG_A[@]} > 1 ]] && { text 1; text err "The same host have several SG. Check it"; exit_S 0; }
        
        # [[ ${HOST_SG_A[@]} != "${SG_LIST_ARRAY[@]}" ]] && { text 1; text war "The Existing Host is not on the same SG. Check it"; }
        
        printf "_HOST_INFO_;$HOST;${HOST_IP_A[@]};${HOST_SG_A[@]}\n" >> $ARRAY_INFO_TMP
        
        ((COUNT_DONE++)); load_B ${#HOST_LIST_ARRAY[@]} $COUNT_DONE '[R] Host(s)  '
        
    done
    
}

pool_retrieving(){
    
    echo -ne "${MG1}  [R] Pool(s)  \t: Info ..\r"
    
    local POOL_LIST_INFO=$($NAVICLI_PATH/naviseccli -h $BAY_ID storagepool -list 2>&-)
    local POOL_ID_LIST_ARRAY=($(echo "$POOL_LIST_INFO" | grep -i 'Pool ID:' | awk -F ':  ' '{print $NF}'))
    
    local COUNT_DONE=0
    
    load_B ${#POOL_ID_LIST_ARRAY[@]} $COUNT_DONE '[R] Pool(s)  '
    
    for POOL_ID in ${POOL_ID_LIST_ARRAY[@]}; do
        
        local POOL_INFO=$(echo "$POOL_LIST_INFO" | awk -v RS='' '$0 ~ /Pool ID:  '"$POOL_ID"$'/')
        
        local POOL_NAME=$(echo "$POOL_INFO" | grep -i 'Pool Name:' | awk -F ':  ' '{print $NF}' | tr ' ' '_')
        local LUN_LIST_ARRAY=($(echo "$POOL_INFO" | grep -i 'LUNs:' | awk -F ':  ' '{print $NF}' | sed s/,\ /\\n/g | sort -n))
        local LAST_LUN_ID=$(list_array "${LUN_LIST_ARRAY[*]}" | tail -1)
        
        local RAW_CAP_BC=$(echo "$POOL_INFO" | grep -i 'Raw Capacity (Blocks):' | awk -F ':  ' '{print $NF}')
        local USR_CAP_BC=$(echo "$POOL_INFO" | grep -i 'User Capacity (Blocks):' | awk -F ':  ' '{print $NF}')
        local CSM_CAP_BC=$(echo "$POOL_INFO" | grep -i 'Consumed Capacity (Blocks):' | awk -F ':  ' '{print $NF}')
        local AVL_CAP_BC=$(echo "$POOL_INFO" | grep -i 'Available Capacity (Blocks):' | awk -F ':  ' '{print $NF}')
        
        local PRC_FULL=$(echo "$POOL_INFO" | grep -i 'Percent Full:' | awk -F ':  ' '{print $NF}')
        local PRC_OVER=$(echo "$POOL_INFO" | grep -i 'Percent Subscribed:' | awk -F ':  ' '{print $NF}')
        
        printf "_POOL_INFO_;${POOL_ID};${POOL_NAME};${RAW_CAP_BC};${USR_CAP_BC};${CSM_CAP_BC};${AVL_CAP_BC};${PRC_FULL};${PRC_OVER};$(list_sep "${LUN_LIST_ARRAY[*]}");${LAST_LUN_ID}\n" >> $ARRAY_INFO_TMP
        
        ((COUNT_DONE++)); load_B ${#POOL_ID_LIST_ARRAY[@]} $COUNT_DONE '[R] Pool(s)  '
        
    done

}

rg_retrieving(){
    
    echo -ne "${MG1}  [R] R.Group(s)  \t: Info ..\r"
    
    local RG_LIST_INFO=$($NAVICLI_PATH/naviseccli -h $BAY_ID getrg 2>&-)
    local RG_ID_LIST_ARRAY=($(echo "$RG_LIST_INFO" | grep -i 'RaidGroup ID:' | awk -F ':' '{print $NF}' | tr -d ' '))
    
    local COUNT_DONE=0
    
    load_B ${#RG_ID_LIST_ARRAY[@]} $COUNT_DONE '[R] R.Group(s)  '
    
    for RG_ID in ${RG_ID_LIST_ARRAY[@]}; do
        
        local RG_INFO=$(echo "$RG_LIST_INFO" | awk -v RS='' '$0 ~ /RaidGroup ID:/ && $3 == "'"$RG_ID"'"')
        
        local RG_TYPE=$(echo "$RG_INFO" | grep -i 'RaidGroup Type:' | awk -F ':' '{print $NF}' | tr -d ' ')
        local LUN_LIST_ARRAY=($(echo "$RG_INFO" | grep -i 'List of luns:' | awk -F ':                              ' '{print $NF}' | sed s/\ /\\n/g | sort -n))
        
        local LAST_LUN_ID=$(list_array "${LUN_LIST_ARRAY[*]}" | tail -1)
        
        local RAW_CAP_BC=$(echo "$RG_INFO" | grep -i 'Raw Capacity (Blocks):' | awk -F ':' '{print $NF}' | tr -d ' ')
        local FREE_CAP_BC=$(echo "$RG_INFO" | grep -i 'Free Capacity (Blocks,non-contiguous):' | awk -F ':' '{print $NF}' | tr -d ' ')
        local FREE_CONT_CAP_BC=$(echo "$RG_INFO" | grep -i 'Free contiguous group of unbound segments:' | awk -F ':' '{print $NF}' | tr -d ' ')
        
        printf "_RG_INFO_;${RG_ID};${RG_TYPE};${RAW_CAP_BC};${FREE_CAP_BC};${FREE_CONT_CAP_BC};$(list_sep "${LUN_LIST_ARRAY[*]}");${LAST_LUN_ID}\n" >> $ARRAY_INFO_TMP
        
        ((COUNT_DONE++)); load_B ${#RG_ID_LIST_ARRAY[@]} $COUNT_DONE '[R] R.Group(s)  '
        
    done


}

lun_to_create(){ #ARG ${NEW_LUN_LIST_ARRAY[@]} $SG_NAME $POOL_ID
    
    local NEW_LUN_LIST_ARRAY=($1)
    local SG_NAME=$2
    local POOL_ID_ARG=$3
    
    local POOL_NAME=$(loko '$1 == "_POOL_INFO_" && $2 == "'"$POOL_ID_ARG"'" {print $3}' $ARRAY_INFO_TMP)
    local POOL_LUN_ID_ARRAY=($(awk -F';' '$1 == "_POOL_INFO_" {print $10}' $ARRAY_INFO_TMP | sed s/,/\\n/g | awk '$1 > 1000' | sort -n))
    
    local POOL_ID=$(echo "$POOL_NAME" | cut -d_ -f3)
    local POOL_NEXT_ID=$((POOL_ID+1))
    
    local LUN_ID_AV_ARRAY=($(diff <(echo "$(for i in $(seq ${POOL_ID}001 ${POOL_NEXT_ID}000);do echo $i; done)") <(echo "${POOL_LUN_ID_ARRAY[@]}" | sed s/\ /\\n/g) | awk '$1 == "<" {print $2}'))
    
    COUNT=0
    
    for NEW_LUN in ${NEW_LUN_LIST_ARRAY[@]}; do
        
        local LUN_COUNT=$(echo "$NEW_LUN" | awk -F'x' '{print $1}')
        
        for CNT in $(seq 1 ${LUN_COUNT}); do
            
            MODULO_CHECK=$(modulo_c "${LUN_ID_AV_ARRAY[$COUNT]}")
            
            [[ $MODULO_CHECK == 0 ]] && local LUN_SP='A' || local LUN_SP='B'
            
            local LUN_SIZE_GB=$(echo "$NEW_LUN" | awk -F'x' '{print $2}')
            
            lun_size_check $LUN_SIZE_GB
            
            local POOL_ID_FMT=$(printf "%02d" $POOL_ID)
            local LUN_NAME="LUN_PL_${POOL_ID_FMT}_${LUN_ID_AV_ARRAY[$COUNT]}"
            
            printf "_LUN_TO_CREATE_;${LUN_ID_AV_ARRAY[$COUNT]};$LUN_NAME;$LUN_SIZE_GB;$LUN_SIZE_BC;$SG_NAME;$POOL_NAME;$LUN_SP\n" >> $ARRAY_INFO_TMP
            
            ((COUNT++))
            
        done
        
    done

}

lun_to_modify(){ #ARG $DIVIDE_CHECK $NEW_LUN_SIZE_BK
    
    local DIVIDE_CHECK=$1
    local NEW_LUN_SIZE_BK=$2
    
    local POOL_LUN_ID_ARRAY=($(awk -F';' '$1 == "_POOL_INFO_" {print $10}' $ARRAY_INFO_TMP | sed s/,/\\n/g | awk '$1 > 1000' | sort -n))
    
    local LUN_INFO_TO_MD_ARRAY=($(loko '$1 == "_LUN_INFO_" {print $0}' $ARRAY_INFO_TMP))
    
    COUNT=0
    
    for LUN_INFO in ${LUN_INFO_TO_MD_ARRAY[@]}; do
        
        local LUN_NAME=$(echo "$LUN_INFO" | awk -F';' '{print $2}')
        local LUN_ID=$(echo "$LUN_INFO" | awk -F';' '{print $3}')
        local LUN_SIZE_MB=$(echo "$LUN_INFO" | awk -F';' '{print $10}')
        local LUN_SIZE_BK=$(echo "$LUN_INFO" | awk -F';' '{print $9}')
        local LUN_POOL=$(echo "$LUN_INFO" | awk -F';' '{print $11}')
        
        local POOL_ID=$(echo "$LUN_POOL" | cut -d_ -f3)
        local POOL_NEXT_ID=$((POOL_ID+1))
        
        local LUN_ID_AV_ARRAY=($(diff <(echo "$(for i in $(seq ${POOL_ID}001 ${POOL_NEXT_ID}000);do echo $i; done)") <(echo "${POOL_LUN_ID_ARRAY[@]}" | sed s/\ /\\n/g) | awk '$1 == "<" {print $2}'))
        
        [[ $DIVIDE_CHECK == 0 ]] && local LUN_COUNT=$(echo "$LUN_SIZE_BK/$NEW_LUN_SIZE_BK" | bc) || local LUN_COUNT=1
        
        for CNT in $(seq 1 ${LUN_COUNT}); do
            
            local POOL_ID_FMT=$(printf "%02d" $POOL_ID)
            local LUN_NAME="LUN_PL_${POOL_ID_FMT}_${LUN_ID_AV_ARRAY[$COUNT]}"
            
            local MODULO_CHECK=$(modulo_c "${LUN_ID_AV_ARRAY[$COUNT]}")
            
            [[ $MODULO_CHECK == 0 ]] && local LUN_SP='A' || local LUN_SP='B'
            
            printf "_LUN_TO_CREATE_;${LUN_ID_AV_ARRAY[$COUNT]};$LUN_NAME;No;$NEW_LUN_SIZE_BK;No;$LUN_POOL;$LUN_SP\n" >> $ARRAY_INFO_TMP
            
            ((COUNT++))
            
        done
        
        [[ $DIVIDE_CHECK == 1 ]] && break
        
    done
}
