# func.vnx.remove.sh

remove_lun_to_sg(){ #ARG $OPT ${SG_LIST_ARRAY[@]}
	
	local SG_LIST_ARRAY=($1)
	
	text u2 "Remove Lun(s) to SG" '~'
	
	for SG in ${SG_LIST_ARRAY[@]}; do
		
		local HLU_LIST_ARRAY=($(loko '$1 == "_LUN_INFO_" && $6 ~ /(,|^)'"$SG"'.[0-9]*(,|$)/ {print $6}' $ARRAY_INFO_TMP | sed s/,/\\n/g | awk -F'.' '$1 == "'"$SG"'" {print $2}'))
		
		cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID storagegroup -gname $SG -removehlu -hlu $(list_sep "${HLU_LIST_ARRAY[*]}" | tr ',' ' ') -o"
		
	done
	
	text 1
}



delete_lun(){ #ARG $TYPE ${LUN_LIST_ARRAY[@]}
	
	local TYPE=$1
	local LUN_LIST_ARRAY=($2)
	
	text u2 "Delete Lun(s) [${TYPE}]" '~'
	
	if [[ $TYPE != 'P.Dev' ]]; then
		
		for LUN in ${LUN_LIST_ARRAY[@]}; do
			[[ $TYPE = 'T.Dev' ]] && cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID lun -destroy -l ${LUN} -o"
			[[ $TYPE = 'Meta' ]] && cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID metalun -destroy -metalun ${LUN} -o"
		done
	
	else
		cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID unbind $(list_sep "${LUN_LIST_ARRAY[*]}" | tr ',' ' ') -o"
		
		sleep 3
		
	fi
	
	text 1
}

delete_sg(){ #ARG ${SG_LIST_ARRAY[@]}
	
	local SG_LIST_ARRAY=($1)
	
	text u2 "Delete S.Group(s)" '~'
	
	for SG in ${SG_LIST_ARRAY[@]}; do
		cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID storagegroup -destroy -gname $SG -o"
	done
	
	text 1

}

remove_host_to_sg(){ #ARG ${SG_HOST_LIST_ARRAY[@]}
	
	local SG_HOST_LIST_ARRAY=($1)
	
	local SG_LIST_ARRAY=($(list_array "${SG_HOST_LIST_ARRAY[*]}" | loko '{print $1}' | sort -u))
	
	text u2 "Remove Host(s) to SG" '~'
	
	for SG in ${SG_LIST_ARRAY[@]}; do
		
		HOST_LIST_ARRAY=($(list_array "${SG_HOST_LIST_ARRAY[*]}" | loko '$1 == "'"$SG"'" {print $2}' | sed s/,/\\n/g ))
		
		for HOST in ${HOST_LIST_ARRAY[@]}; do
			cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID storagegroup -disconnecthost -host $HOST -gname $SG -o"
		done
		
	done
	
	text 1
}

delete_hosts_logins(){ #ARG ${HOST_WWN_LIST_ARRAY[@]}
	
	local TYPE=$1
	local HOST_WWN_LIST_ARRAY=($2)
	
	text u2 "Delete ${TYPE}(s)" '~'
	
	for HOST_WWN in ${HOST_WWN_LIST_ARRAY[@]}; do
		[[ $TYPE = 'Host' ]] && cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID port -removeHBA -host $HOST_WWN -o"
		[[ $TYPE = 'Login' ]] && cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID port -removeHBA -hbauid $HOST_WWN -o"
	done
	
	text 1
	
}

remove_replication(){ 
	
	local MIRRORV_LUN_LIST_ARRAY=$(loko '$1 == "_MIRROR_INFO_" {print $2}' $ARRAY_INFO_TMP | sort -u)
	
	text u2 "Remove Replication" '~'
	
	for MIRRORV_LUN in ${MIRRORV_LUN_LIST_ARRAY[@]}; do
		
		local MIRRORV_INFO=$(loko '$1 == "_MIRROR_INFO_" && $2 == "'"$MIRRORV_LUN"'" {print $0}' $ARRAY_INFO_TMP | sort -u)
		local MIRRORV_NAME=$(echo "$MIRRORV_INFO" | loko '{print $8}' | sort -u)
		
		local MIRRORV_GN=$(echo "$MIRRORV_INFO" | loko '{print $10}' | sort -u)
		
		[[ $MIRRORV_GN != 'No' ]] && cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID mirrorview -removefromgroup -name ${MIRRORV_GN} -mirrorname ${MIRRORV_NAME} -o"
		
		local MIRRORV_LU_IMAGE_UID_R_LIST_ARRAY=($(echo "$MIRRORV_INFO" | loko '{print $7}' | sed s/,/\\n/g | sort -u))
		
		for MIRRORV_LU_IMAGE_UID_R in ${MIRRORV_LU_IMAGE_UID_R_LIST_ARRAY[@]}; do
			
			local MIRRORV_IMAGE_UID_R=$(echo $MIRRORV_LU_IMAGE_UID_R | cut -d'-' -f2)
			
			cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID mirrorview -fractureimage -name ${MIRRORV_NAME} -imageuid ${MIRRORV_IMAGE_UID_R}"
		
		done
		
		cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID mirrorview -destroy -name ${MIRRORV_IMAGE_UID_R} -force -o"
	
	done
	
	text 1
	
}

remove_script_execution(){ #ARG $EX_MODE
	
	local EX_MODE=$1
	
	[[ $_MIRRORV_CHECK = 1 ]] && remove_replication
	
	[[ -n ${SG_O_LIST_ARRAY[@]} ]] && remove_lun_to_sg "${SG_O_LIST_ARRAY[*]}"
	
	if [[ -n ${SG_LIST_ARRAY[@]} ]]; then
		
		unset SG_HOST_LIST_ARRAY
		unset HOST_LIST_ARRAY
		unset WWN_LIST_ARRAY
		unset LUN_LIST_ARRAY
		
		for SG in ${SG_LIST_ARRAY[@]}; do
			
			local SG_HOST_LIST_A=($(loko '$1 == "_SG_INFO_" && $6 != "No" && $2 == "'"$SG"'" {printf "%s;%s\n", $2, $6}' $ARRAY_INFO_TMP | sort -u))
			local HOST_LIST_A=($(loko '$1 == "_SG_INFO_" && $6 != "No" && $2 == "'"$SG"'" {print $6}' $ARRAY_INFO_TMP | sed s/,/\\n/g | sort -u))
			local WWN_LIST_A=($(loko '$1 == "_SG_INFO_" && $4 != "No" && $2 == "'"$SG"'" {print $4}' $ARRAY_INFO_TMP | sed s/,/\\n/g | sort -u))
			local LUN_LIST_A=($(loko '$1 == "_LUN_INFO_" && $6 ~ /(,|^)'"$SG"'.[0-9]*(,|$)/ {print $3}' $ARRAY_INFO_TMP | sort -u))
			
			local SG_HOST_LIST_ARRAY=("${SG_HOST_LIST_ARRAY[@]}" "${SG_HOST_LIST_A[@]}")
			local HOST_LIST_ARRAY=("${HOST_LIST_ARRAY[@]}" "${HOST_LIST_A[@]}")
			local WWN_LIST_ARRAY=("${WWN_LIST_ARRAY[@]}" "${WWN_LIST_A[@]}")
			local LUN_LIST_ARRAY=("${LUN_LIST_ARRAY[@]}" "${LUN_LIST_A[@]}")
			
		done
		
		SG_HOST_LIST_ARRAY=($(list_array "${SG_HOST_LIST_ARRAY[*]}" | sort -u))
		HOST_LIST_ARRAY=($(list_array "${HOST_LIST_ARRAY[*]}" | sort -u))
		WWN_LIST_ARRAY=($(list_array "${WWN_LIST_ARRAY[*]}" | sort -u))
		LUN_LIST_ARRAY=($(list_array "${LUN_LIST_ARRAY[*]}" | sort -u))
		
		[[ -n ${SG_HOST_LIST_ARRAY[@]} ]] && remove_host_to_sg "${SG_HOST_LIST_ARRAY[*]}"
		[[ -n ${WWN_LIST_ARRAY[@]} ]] && delete_hosts_logins 'Login' "${WWN_LIST_ARRAY[*]}"
		[[ -n ${LUN_LIST_ARRAY[@]} ]] && remove_lun_to_sg "${SG_LIST_ARRAY[*]}"
		
		delete_sg "${SG_LIST_ARRAY[*]}"
		
	fi
	
	unset LUN_LIST_ARRAY
	unset TDEV_LIST_ARRAY
	unset PDEV_LIST_ARRAY
	
	if [[ $WAR_LUN_SG_4 = 1 ]]; then
		local LUN_LIST_ARRAY=($(loko '$1 == "_LUN_INFO_" && $NF <= "'"${#SG_ARG_LIST_ARRAY[@]}"'" {print $3}' $ARRAY_INFO_TMP | sort -u | sort -n))
	else
		local LUN_LIST_ARRAY=($(loko '$1 == "_LUN_INFO_" {print $3}' $ARRAY_INFO_TMP | sort -u | sort -n))
	fi
	
	if [[ -n ${LUN_LIST_ARRAY[@]} ]]; then
		
		if [[ $_OPT_RMV_MODE = 'Normal' ]]; then
			
			[[ $_EXIST_SG_TMP = 0 ]] && create_sg 'tmp'
			
			add_lun_to_sg 'tmp' "${SG_WEEK_TMP}" "${LUN_LIST_ARRAY[*]}"
			
		elif [[ $_OPT_RMV_MODE = 'Total' ]]; then
			
			for LUN in ${LUN_LIST_ARRAY[@]}; do
				
				local TDEV_LIST_A=($(loko '$1 == "_LUN_INFO_" && $3 == "'"$LUN"'" && $4 == "TDv" {print $3}' $ARRAY_INFO_TMP | sort -n))
				local PDEV_LIST_A=($(loko '$1 == "_LUN_INFO_" && $3 == "'"$LUN"'" && $4 == "PDv" {print $3}' $ARRAY_INFO_TMP | sort -n))
				local META_LIST_A=($(loko '$1 == "_LUN_INFO_" && $3 == "'"$LUN"'" && $4 ~ /M/ {print $3}' $ARRAY_INFO_TMP | sort -n))
				
				local TDEV_LIST_ARRAY=("${TDEV_LIST_ARRAY[@]}" "${TDEV_LIST_A[@]}")
				local PDEV_LIST_ARRAY=("${PDEV_LIST_ARRAY[@]}" "${PDEV_LIST_A[@]}")
				local META_LIST_ARRAY=("${META_LIST_ARRAY[@]}" "${META_LIST_A[@]}")
				
			done
			
			TDEV_LIST_ARRAY=($(list_array "${TDEV_LIST_ARRAY[*]}" | sort -u | sort -n))
			PDEV_LIST_ARRAY=($(list_array "${PDEV_LIST_ARRAY[*]}" | sort -u | sort -n))
			META_LIST_ARRAY=($(list_array "${META_LIST_ARRAY[*]}" | sort -u | sort -n))
			
			if [[ -n ${TDEV_LIST_ARRAY[@]} ]]; then
                delete_lun 'T.Dev' "${TDEV_LIST_ARRAY[*]}"
                
                [[ $BAY_LT != 'N' ]] && create_lun "${TDEV_LIST_ARRAY[*]}"
                
            fi
            
			[[ -n ${PDEV_LIST_ARRAY[@]} ]] && delete_lun 'P.Dev' "${PDEV_LIST_ARRAY[*]}"
			[[ -n ${META_LIST_ARRAY[@]} ]] && delete_lun 'Meta' "${META_LIST_ARRAY[*]}"
			
		fi
		
	fi
}

