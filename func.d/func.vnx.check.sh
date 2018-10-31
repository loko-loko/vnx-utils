# func.vnx.check.sh

lun_size_check(){ #ARG $LUN_SIZE_GB
	
	LUN_SIZE_GB=$1
	
	case $LUN_SIZE_GB in
		5[04][03456][0123456789]	) LUN_SIZE_GB=5400;  LUN_SIZE_BC=10737418240;;
		2[01][067][0123456789]		) LUN_SIZE_GB=2160;  LUN_SIZE_BC=4294967296;;
		10[078][0123456789]			) LUN_SIZE_GB=1080;  LUN_SIZE_BC=2147483648;;
		6[045][0123456789]			) LUN_SIZE_GB=648;   LUN_SIZE_BC=1370603520;;
		4[03][0123456789]			) LUN_SIZE_GB=432;   LUN_SIZE_BC=913735680;; 
		3[02][0123456789]			) LUN_SIZE_GB=324;   LUN_SIZE_BC=685301760;; 
		2[01][0123456789]			) LUN_SIZE_GB=216;   LUN_SIZE_BC=456867840;; 
		10[0123456789]				) LUN_SIZE_GB=108;   LUN_SIZE_BC=228433920;; 
		5[0123456789]				) LUN_SIZE_GB=54;    LUN_SIZE_BC=114216960;; 
		2[0123456789]				) LUN_SIZE_GB=27;    LUN_SIZE_BC=57108480;;  
		1[012345]					) LUN_SIZE_GB=13;    LUN_SIZE_BC=28554240;;  
		[678]						) LUN_SIZE_GB=7;     LUN_SIZE_BC=14277120;;
		1							) LUN_SIZE_GB=1;     LUN_SIZE_BC=2097152;;  
		*							) return 86;;
	esac
	
    return 0
    
}

lun_count_syntax_check(){
	
	local NEW_COUNT_SIZE_LIST_ARRAY=($1)
	
	for NEW_COUNT_SIZE in ${NEW_COUNT_SIZE_LIST_ARRAY[@]}; do
			
		local NEW_LUN_COUNT=$(echo "$NEW_COUNT_SIZE" | awk -F 'x' '{print $1}')
		local NEW_LUN_SIZE=$(echo "$NEW_COUNT_SIZE" | awk -F 'x' '{print $2}')
		
		lun_size_check "$NEW_LUN_SIZE"; RETURN_CMD=$?
		
		[[ $RETURN_CMD != 0 ]] && { text war "Bad Size"; SIZE_CHECK=1; break; }
		[[ -z $NEW_LUN_SIZE && ! $NEW_LUN_SIZE =~ [0-9]+ ]] && { text war "Bad Syntax [ Example : 2x108,5x54 ... ]"; SIZE_CHECK=1; break; }
		[[ -z $NEW_LUN_COUNT && ! $NEW_LUN_COUNT =~ [0-9]+ ]] && { text war "Bad Syntax [ Example : 2x108,5x54 ... ]"; COUNT_CHECK=1; break; }
		
	done
	
}

size_check(){
	
	local SIZE_LIST_ARRAY=($1)
	
	for SIZE in ${SIZE_LIST_ARRAY[@]}; do
		[[ $SIZE = $NEW_LUN_SIZE ]] && return 80
	done
	
}


lun_count_argument_check(){ #ARG ${NEW_COUNT_SIZE_LIST_ARRAY[@]}
	
	local NEW_COUNT_SIZE_LIST_ARRAY=($1)
	local NEW_SIZE_LIST_ARRAY=($(list_array "${NEW_COUNT_SIZE_LIST_ARRAY[*]}" | awk -F'x' '{print $2}' | sort -u))
	
	lun_count_syntax_check "${NEW_COUNT_SIZE_LIST_ARRAY[*]}"
	
    local TOTAL_COUNT=$(echo "${NEW_COUNT_SIZE_LIST_ARRAY[@]}" | sed s/\ /\\n/g | awk -F'x' '{ALL+=$1} END{print ALL}')
    
	if [[ $SIZE_CHECK != 1 && $COUNT_CHECK != 1 ]]; then
		
		for NEW_SIZE in ${NEW_SIZE_LIST_ARRAY[@]}; do
			local COUNT_SIZE=($(list_array "${NEW_COUNT_SIZE_LIST_ARRAY[*]}" | awk -F'x' '$2 == "'"$NEW_SIZE"'" {TOTAL+=$1} END{print TOTAL}'))
			local COUNT_SIZE_LIST_ARRAY=("${COUNT_SIZE_LIST_ARRAY[@]}" "${COUNT_SIZE};${NEW_SIZE}")
		done
		
		for COUNT_SIZE in ${COUNT_SIZE_LIST_ARRAY[@]}; do
			
			local NEW_LUN_COUNT=$(echo "$COUNT_SIZE" | loko '{print $1}')
			local NEW_LUN_SIZE=$(echo "$COUNT_SIZE" | loko '{print $2}')
			
			size_check "${SIZE_LIST_ARRAY[*]}"
			[[ $? != 80 ]] && { text war "Value $NEW_LUN_SIZE GB not available"; SIZE_CHECK=1; break; }
			
			for LUN_SIZE in ${LUN_SIZE_LIST_ARRAY[@]}; do
				
				local LUN_COUNT=$(echo "$LUN_SIZE" | loko '{print $1}')
				local LUN_SIZE=$(echo "$LUN_SIZE" | loko '{print $2}')
				
				if [[ $NEW_LUN_SIZE = $LUN_SIZE ]]; then
					
					(( NEW_LUN_COUNT > LUN_COUNT )) && { text war "Only $LUN_COUNT Lun(s) of $NEW_LUN_SIZE GB Available"; COUNT_CHECK=1; break; } 
					
                    local LUN_LIST_A=($(loko '$1 == "_LUN_WITHOUT_SG_" && $3 == "'"$LUN_SIZE"'" {print $2}' $ARRAY_INFO_TMP | sort -n))
                    
					LUN_LIST_ARRAY=("${LUN_LIST_ARRAY[@]}" "${LUN_LIST_A[@]:0:${NEW_LUN_COUNT}}")
					
				fi
				
			done
			
			[[ $COUNT_CHECK = 1 ]] && break
			
		done
		
	fi
	
}


storage_check(){ #ARG $MODE ${SG_LIST_ARRAY[@]}
	
	local MODE=$1
	
	local SG_ALL_LIST_ARRAY=($(echo "$SG_INFO_LIST" | awk '/^Storage Group Name:/ {print $NF}' | tr 'A-Z' 'a-z'))
	
	if [[ $MODE != 'tmp' ]]; then
		
		local SG_LIST_ARRAY=($2)
		
		for SG in ${SG_LIST_ARRAY[@]}; do
			
			local D_SG=$(echo $SG | tr 'A-Z' 'a-z')
			local SG_CHECK=$(list_array "${SG_ALL_LIST_ARRAY[*]}" | awk '$1 == "'"$D_SG"'" {print $0}')
			
			[[ $MODE = 'exs' && -z $SG_CHECK ]] && { text err "S.Group \"$SG\" not found. Check it"; exit_S 0; }
			[[ $MODE = 'new' && -n $SG_CHECK ]] && { text err "New S.Group \"$SG\" already exist. Check it"; exit_S 0; }
			
		done
		
	else
		
		local SG_WEEK_TMP=$(echo "$SG_WEEK_TMP" | tr 'A-Z' 'a-z')
		local SG_TMP_CHECK=$(list_array "${SG_ALL_LIST_ARRAY[*]}" | awk '$1 == "'"$SG_WEEK_TMP"'" {print $0}')
		
		[[ -n $SG_TMP_CHECK ]] && _EXIST_SG_TMP=1
		
	fi
	
}

host_check(){
	
	local HOST_LIST_ARRAY=($1)
	local HOST_ALL_LIST_ARRAY=($(echo "$WWN_INFO_LIST" | awk '/^Server Name:/ {print $NF}' | tr 'A-Z' 'a-z' | sort -u))
	
	WAR_HOST_DF=0
	ERR_HOST_DF=0
	
	for HOST in ${HOST_LIST_ARRAY[@]}; do
		
		local HOST_CHECK=$(list_array "${HOST_ALL_LIST_ARRAY[*]}" | awk '$1 == "'"$HOST"'" {print $0}')
		
		# [[ $_E_HOST = 1 && -z $HOST_CHECK ]] && { text err "Host \"$HOST\" not found. Check it"; exit_S 0; }
		
		if [[ $_NEW_HOST = 1 && -n $HOST_CHECK ]]; then
			
			HOST_SG=$(echo "$WWN_INFO" | awk -v RS='' '$0 ~ /Server Name/ && $0 ~ /'"tiths512"'/' | grep -i 'StorageGroup Name:' | awk '{print $NF}' | sort -u)
			
			[[ $HOST_SG != ${SG_LIST_ARRAY[@]} ]] && ERR_HOST_DF=1
			
			WAR_HOST_DF=1
			
		fi
		
	done

}


opt_mode_arg_check(){ #NO ARG
	
	[[ $_OPT_BAY = 0 ]] && arg_script_error "Bay needed [sid|dns|ip]"
	[[ $_OPT_BAY = 'SID' ]] && (( ${#BAY_ARG} < 3 )) && { text err "3 Digit Min with SID Option"; text 1; exit_S 1086; }
	
	[[ -z $_OPT_MODE ]] && arg_script_error "Select Mode (Create|Modify|Remove|Info)"
	[[ $_NO_PROMPT = 1 && $_OPT_MODE != 'Create' ]] && arg_script_error "'No Prompt' Option available only for Create Mode"
	[[ $_ONLY_MODE = 1 && $_OPT_MODE != 'Info' ]] && arg_script_error "'Only' Option available only for Info Mode"
	
	if [[ $_OPT_MODE = 'Info' ]]; then
		
		[[ $_CR_MOD = 1 || $_RM_MOD = 1 || $_MD_MOD = 1 ]] && arg_script_error
		[[ $_INF_MOD = 0 && -z $_OPT_DEVICE ]] || [[ $_INF_MOD = 1 && -n $_OPT_DEVICE ]] && arg_script_error "Select Device (Lun|SG|WWN) or Choose Option (Init)"
		
	elif [[ $_OPT_MODE = 'Remove' ]]; then
		
		[[ $_OPT_RMV_MODE = 0 ]] && _OPT_RMV_MODE='Normal'
		[[ $_INF_MOD = 1 || $_CR_MOD = 1 || $_MD_MOD = 1 ]] && arg_script_error
		[[ -z $_OPT_DEVICE ]] && arg_script_error "Select Device (Lun|SG|WWN)"
		
		
	elif [[ $_OPT_MODE = 'Create' ]]; then
		
		[[ $_INF_MOD = 1 || $_RM_MOD = 1 || $_MD_MOD = 1 || $_CR_MOD != 1 ]] && arg_script_error
		[[ $_NEW_SG = 0 && -z $_OPT_DEVICE ]] && arg_script_error "Enter a Existing SG or New SG"
		[[ -n $_OPT_DEVICE && $_OPT_DEVICE != 'SG' ]] && arg_script_error "Only SG with Create Option"
		[[ $_NEW_NAME = 1 && -n $_OPT_DEVICE ]] && arg_script_error "Enter a New Name of SG or a Existing SG. Not both"
		[[ $_NEW_NAME = 0 ]] && [[ $_NEW_SG = 1 ]] && arg_script_error "Enter a New Name '-name' with 'New SG' Option"
		[[ $_NEW_NAME = 1 && $NEW_NAME =~ sg_|_sg ]] && arg_script_error "Enter Only Name of Server with '-name'. Example 'parva478745'"
		
		[[ ! $INIT_T =~ ^(0|1|2|3|4)$ ]] && arg_script_error "Error with 'Init Type Mode' Argument [0|1|2|3|4]"
		[[ ! $ARRAY_CP =~ ^(0|1)$ ]] && arg_script_error "Error with 'Array Commpath Mode' Argument [0|1]"
		[[ ! $FO_MODE =~ ^(0|1|2|3|4)$ ]] && arg_script_error "Error with 'Fail Over Mode' Argument [0|1|2|3|4]"
		
		[[ $_NEW_HOST = 0 && $_NEW_CLUST = 1 ]] && arg_script_error "'-node' Option work only with '-nhost' Option"
		
		if [[ $_NEW_HOST = 1 ]]; then
			
			[[ ! $NODE_COUNT =~ ^[0-9]+$ ]] && arg_script_error "Error with 'Node' Argument [Only Digit]"
			[[ $NODE_COUNT != 1 ]] && local NODE_STX_ERR="Syntax [host1,1.1.1.1]c0507606e8470002,c0507606e8470005-[host2,1.2.1.2]10578..." || NODE_STX_ERR="Syntax [host,1.1.1.1]c0507606e8470002,c0507606e8470005"
			
			NEW_HOST_IP_WWN_LIST_ARRAY=($(list_cl "$NEW_WWN" '-'))
			
			[[ ${#NEW_HOST_IP_WWN_LIST_ARRAY[@]} != $NODE_COUNT ]] && arg_script_error "Node Count ($NODE_COUNT) not Match with 'New Host' Argument. ${NODE_STX_ERR}"
			
			if [[ $_OS_MODE = 1 ]]; then
				[[ $_MAN_SELECT = 1 ]] && arg_script_error "Choose '-os' Option or '-initt|-arraycp|-fomode' Options"
				os_retriev_info "${OS_TYPE}"
			fi
			
			node_arg_check "${NEW_HOST_IP_WWN_LIST_ARRAY[*]}"
			
		fi
		
	elif [[ $_OPT_MODE = 'Modify' ]]; then
		
        [[ $_INF_MOD = 1 || $_RM_MOD = 1 || $_CR_MOD = 1 || $_MD_MOD != 1 ]] && arg_script_error
        [[ $_OPT_MDF_MODE = 0 ]] && arg_script_error "Select action"
        
	fi
}

node_arg_check(){ #ARG ${NEW_HOST_IP_WWN_LIST_ARRAY[@]}
	
	local NEW_HOST_IP_WWN_LIST_ARRAY=($1)
	
	for NEW_HOST_IP_WWN in ${NEW_HOST_IP_WWN_LIST_ARRAY[@]}; do
		
		local HOST_NAME=$(echo $NEW_HOST_IP_WWN | awk -F\[ '{print $2}' | awk -F\] '{print $1}' | tr -d \[ | tr 'A-Z' 'a-z' | awk -F',' '{print $1}')
		local HOST_IP=$(echo $NEW_HOST_IP_WWN | awk -F\[ '{print $2}' | awk -F\] '{print $1}' | tr -d \[ | tr 'A-Z' 'a-z' | awk -F',' '{print $2}')
		local NEW_WWN_LIST_ARRAY=($(echo $NEW_HOST_IP_WWN | awk -F\[ '{print $2}' | awk -F\] '{print $2}' | sed s/,/\\n/g | tr -d : | sed -r 's/.{2}/&:/g;s/.$//' | tr 'a-z' 'A-Z'))
		
		[[ -z $HOST_NAME ]] && arg_script_error "Error with 'New Host' Argument [!Host]. ${NODE_STX_ERR}"
		[[ -z $HOST_IP ]] && arg_script_error "Error with 'New Host' Argument [!IP]. ${NODE_STX_ERR}"
		[[ -z ${NEW_WWN_LIST_ARRAY[@]} ]] && arg_script_error "Error with 'New Host' Argument [!WWN]. ${NODE_STX_ERR}"

		wwn_arg_syntax_check "${NEW_WWN_LIST_ARRAY[*]}"; [[ $ERR_WWN_SX_1 = 1 ]] && exit_S 1085
		ip_arg_syntax_check "${HOST_IP}"; [[ $ERR_IP_SX_1 = 1 ]] && exit_S 1085
		
		for NEW_WWN in ${NEW_WWN_LIST_ARRAY[@]}; do
			printf "_NEW_CLUST_INFO_;$NODE_COUNT;$HOST_NAME;$HOST_IP;$NEW_WWN\n" >> $ARRAY_INFO_TMP
		done
		
	done
	
}

ip_arg_syntax_check(){ #ARG ${HOST_IP[@]}
	
	local HOST_IP_LIST_ARRAY=($1)
	
	ERR_IP_SX_1=0
	
	for HOST_IP in ${HOST_IP_LIST_ARRAY[@]}; do
		[[ ! $HOST_IP =~ ^[0-9]+.[0-9]+.[0-9]+.[0-9]+$ ]] && { text err "Bad IP. [Ex : 1.1.1.1]"; text 1; ERR_IP_SX_1=1; break; }
	done
	
}

wwn_arg_syntax_check(){ #ARG ${NEW_WWN_LIST_ARRAY[@]}
	
	local NEW_WWN_LIST_ARRAY=($1)
	
	ERR_WWN_SX_1=0
	
	for NEW_WWN in ${NEW_WWN_LIST_ARRAY[@]}; do
		[[ ! $NEW_WWN =~ ^([1-9]|C) || ${#NEW_WWN} != 23 ]] && { text err "Bad WWN [Ex : 500009750000879d or c0:00:09:75:00:00:87:9d]"; text 1; ERR_WWN_SX_1=1; break; }
	done
}

lun_sg_check(){ #NO ARG
	
	local COUNT=0
	local LUN_SG
	local LUN_SGS_LIST
	
	WAR_LUN_SG_1=0
	WAR_LUN_SG_2=0
	WAR_LUN_SG_3=0
	
	unset CHECK_VAR_ARRAY
	
	local LUN_SGS_LIST_ARRAY=($(loko '$1 == "_LUN_INFO_" {print $6}' $ARRAY_INFO_TMP | sed s/\\.[0-9]*//g | sort -u))
	local LUN_SG_FIRST_LIST_ARRAY=($(list_cl "${LUN_SGS_LIST_ARRAY[0]}" ','))
	
	for LUN_SGS_LIST in ${LUN_SGS_LIST_ARRAY[@]}; do
		
		local LUN_SG_LIST_ARRAY=($(list_cl "$LUN_SGS_LIST" ','))
		
		[[ ${#LUN_SG_LIST_ARRAY[@]} > 1 ]] && WAR_LUN_SG_1=1
		
		for LUN_SG in ${LUN_SG_LIST_ARRAY[@]}; do
			
			for LUN_SG_FIRST in ${LUN_SG_FIRST_LIST_ARRAY[@]}; do
				[[ $LUN_SG_FIRST = $LUN_SG ]] && local CHECK_VAR_ARRAY=("${CHECK_VAR_ARRAY[@]}" "1")
			done
			
			CHECK_VAR_ARRAY=($(list_array "${CHECK_VAR_ARRAY[*]}" | uniq))
			
		done
		
		((COUNT++))
		
	done
	
	[[ ${#LUN_SGS_LIST_ARRAY[@]} != ${#CHECK_VAR_ARRAY[@]} ]] && WAR_LUN_SG_2=1
	
	if [[ $_OPT_DEVICE = 'LUN' ]]; then
		
		local LUN_LIST_ARRAY=($(loko '$1 == "_LUN_INFO_" {print $3}' $ARRAY_INFO_TMP | sort -n))
		SG_LIST_ARRAY=($(loko '$1 == "_SG_INFO_" {print $2}' $ARRAY_INFO_TMP | sort -u))
		
		for SG in ${SG_LIST_ARRAY[@]}; do
			local SG_LUN_LIST_ARRAY=($(loko '$1 == "_SG_INFO_" && $2 == "'"$SG"'" {print $5}' $ARRAY_INFO_TMP | sed s/,/\\n/g | sort -u | sort -n))
			local LUN_SG_CHECK=$(diff <(list_array "${SG_LUN_LIST_ARRAY[*]}") <(list_array "${LUN_LIST_ARRAY[*]}") | grep \<)
			
			[[ -z $LUN_SG_CHECK ]] && { WAR_LUN_SG_3=1; local SG_LIST_A=("${SG_LIST_A[@]}" "$SG"); } || local SG_O_LIST_A=("${SG_O_LIST_A[@]}" "$SG")
		done
		
		SG_LIST_ARRAY=($(list_array "${SG_LIST_A[*]}" | sort -u))
		SG_O_LIST_ARRAY=($(list_array "${SG_O_LIST_A[*]}" | sort -u))
		
	fi
}

sg_argument_check(){ #NO ARG
	
	WAR_LUN_SG_4=0
	
	local SG_ALL_LIST_ARRAY=($(loko '$1 == "_SG_INFO_" {print $2}' $ARRAY_INFO_TMP | sort -u))
	
	[[ ${#SG_ARG_LIST_ARRAY[@]} != ${#SG_ALL_LIST_ARRAY[@]} ]] && { SG_LIST_ARRAY=("${SG_ARG_LIST_ARRAY[@]}"); WAR_LUN_SG_4=1; }
	
}


global_info_check() { #NO ARG
	
	_MIRRORV_CHECK=$(loko '$1 == "_MIRROR_INFO_" {print 1}' $ARRAY_INFO_TMP | uniq)
	
}