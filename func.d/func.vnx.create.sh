# func.vnx.create.sh


create_sg(){ #ARG $MODE ${SG_LIST_ARRAY[@]}
	
	local MODE=$1
	
	[[ $MODE = 'tmp' ]] && { local TEXT_T="SG tmp for Week ${WEEK_NUMBER}"; local NEW_SG_LIST_ARRAY=${SG_WEEK_TMP}; }
	[[ $MODE = 'new' ]] && { local TEXT_T="New SG"; local NEW_SG_LIST_ARRAY=($2); }
	
	text u2 "Create ${TEXT_T}" '~'
	
	for NEW_SG in ${NEW_SG_LIST_ARRAY[@]}; do
		cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID storagegroup -create -gname $NEW_SG"
	done
	
	text 1
	
}

create_lun(){ #ARG $MODE ${LUN_LIST_ARRAY[@]}
	
	local LUN_LIST_ARRAY=($1)
	
	text u2 "Create Lun(s)" '~'
	
	for LUN in ${LUN_LIST_ARRAY[@]}; do
		
		if [[ $BAY_LT == 'N' || $_OPT_MODE == 'Modify' ]]; then
			
			LUN_INFO=$(loko '$1 == "_LUN_TO_CREATE_" && $2 == "'"$LUN"'" {print $0}' $ARRAY_INFO_TMP | sort -u)
			
			LUN_NAME=$(echo "$LUN_INFO" | loko '{print $3}')
			DEFAULT_SP=$(echo "$LUN_INFO" | loko '{print $8}')
			CAPACITY_BLOCK=$(echo "$LUN_INFO" | loko '{print $5}')
			LUN_POOL=$(echo "$LUN_INFO" | loko '{print $7}')
		
		elif [[ $BAY_LT == 'E' ]]; then
			
			LUN_INFO=$(loko '$1 == "_LUN_INFO_" && $3 == "'"$LUN"'" {print $0}' $ARRAY_INFO_TMP | sort -u)
			
			LUN_NAME=$(echo "$LUN_INFO" | loko '{print $2}')
			DEFAULT_SP=$(echo "$LUN_INFO" | loko '{print $8}')
			CAPACITY_BLOCK=$(echo "$LUN_INFO" | loko '{print $9}')
			LUN_POOL=$(echo "$LUN_INFO" | loko '{print $11}')
		
		fi
		
		cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID lun -create -type Thin -capacity $CAPACITY_BLOCK -sq bc -poolName $LUN_POOL -sp $DEFAULT_SP -l $LUN -name $LUN_NAME"
		
	done
	
	text 1
	
}

create_new_lun(){ #ARG ${FIRST_LUN} ${COUNT}

	local FIRST_LUN=$1
	local COUNT_LUN=$2
	
	local LAST_LUN=$((FIRST_LUN+COUNT_LUN))
	
	for $LUN in $(seq ${FIRST_LUN} ${LAST_LUN}); do
	
		LUN_NAME=$()
	
	done
	
}

add_lun_to_sg(){ #ARG $MODE ${SG_LIST_ARRAY[@]} ${LUN_LIST_ARRAY[@]}
	
	local MODE=$1
	local SG_LIST_ARRAY=($2)
	local LUN_LIST_ARRAY=($3)
	
	text u2 "Add Lun(s) to S.Group(s)" '~'
	
	for SG in ${SG_LIST_ARRAY[@]}; do
		
		if [[ $MODE = 'exs' ]]; then
			SG_LAST_HLU=$(loko '$1 == "_SG_INFO_" && $2 == "'"$SG"'" {print $NF}' $ARRAY_INFO_TMP | sort -u | tr -d \')
			
			[[ $SG_LAST_HLU != 'No' ]] && HLU_COUNT=$((SG_LAST_HLU+1))
			[[ $SG_LAST_HLU = 'No' || $_NEW_SG = 1 ]] && HLU_COUNT=0
			
		elif [[ $MODE = 'tmp' ]]; then
			if [[ $_EXIST_SG_TMP = 1 ]]; then
				SG_LAST_HLU=$(echo "$SG_INFO_LIST" | awk -v RS='' '/'"$SG"'/' | awk '/HLU Number/,/Shareable/' | egrep -v 'HLU Number|Shareable|\-\-\-\-\-' | awk '{print $1}' | sort -n | sed -n '$p')
				[[ -z $SG_LAST_HLU ]] && HLU_COUNT=0 || HLU_COUNT=$((SG_LAST_HLU+1))
			else
				HLU_COUNT=0
			fi
			
		fi
		
		for LUN in ${LUN_LIST_ARRAY[@]}; do
			cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID storagegroup -addhlu -gname $SG -hlu $HLU_COUNT -alu $LUN"
			((HLU_COUNT++))
		done
		
	done
	
	text 1
	
}


login_register(){ 
	
	local NEW_HOST_LIST_ARRAY=($(loko '$1 == "_NEW_CLUST_INFO_" {print $3}' $ARRAY_INFO_TMP | sort -u))
	
	text u2 "Register Login(s)" '~'
	
	for NEW_HOST in ${NEW_HOST_LIST_ARRAY[@]}; do
		
		local NEW_WWN_LIST_ARRAY=($(loko '$1 == "_NEW_CLUST_INFO_" && $3 == "'"$NEW_HOST"'" {print $5}' $ARRAY_INFO_TMP | sort -u))
		local HOST_IP=$(loko '$1 == "_HOST_INFO_" && $2 == "'"$NEW_HOST"'" {print $3}' $ARRAY_INFO_TMP)
		local HOST_SG=$(loko '$1 == "_HOST_INFO_" && $2 == "'"$NEW_HOST"'" {print $4}' $ARRAY_INFO_TMP)
		
		for NEW_WWN in ${NEW_WWN_LIST_ARRAY[@]}; do
			
			local WWN_SP_LIST_ARRAY=($(loko '$1 == "_WWN_INFO_" && $2 ~ /'"$NEW_WWN"'/ {print $3}' $ARRAY_INFO_TMP | sort -u))
			local NEW_WWN=$(loko '$1 == "_WWN_INFO_" && $2 ~ /'"$NEW_WWN"'/ {print $2}' $ARRAY_INFO_TMP | sort -u)
			
			for WWN_SP in ${WWN_SP_LIST_ARRAY[@]}; do
				
				local SP_N=$(echo "$WWN_SP" | cut -d'-' -f1)
				local SP_P=$(echo "$WWN_SP" | cut -d'-' -f2)
				
				cmd_exc $EX_MODE R "$NAVICLI_PATH/naviseccli -h $BAY_ID storagegroup -setpath -gname $HOST_SG -hbauid $NEW_WWN -type $INIT_T -ip $HOST_IP -host $NEW_HOST -sp $SP_N -spport $SP_P -arraycommpath $ARRAY_CP -failovermode $FO_MODE -o"
				
			done
			
		done
	
	done
	
	text 1
	
}



create_script_execution(){ #ARG $EX_MODE
	
	local EX_MODE=$1
	
	[[ $_NEW_SG = 1 ]] && create_sg 'new' "${SG_LIST_ARRAY[*]}"
	
	if [[ $_NEW_LUN = 1 ]]; then
		
		if [[ $_WAR_LUN_NO_EMPTY = 1 && $BAY_LT = E ]]; then
			
			local LUN_NE_LIST_ARRAY=($(loko '$1 == "_LUN_INFO_" && $17 != "1.753" {print $3}' $ARRAY_INFO_TMP | sort -u))
			
			delete_lun 'T.Dev' "${LUN_NE_LIST_ARRAY[*]}"
			create_lun "${LUN_NE_LIST_ARRAY[*]}"
			
		fi
		
		[[ $_NEW_SG = 0 ]] && local SG_LIST_ARRAY=($(loko '$1 == "_SG_INFO_" {print $2}' $ARRAY_INFO_TMP | sort -u)) || local SG_LIST_ARRAY=(${NEW_SG})
		
		if [[ $BAY_LT = N ]]; then
			local LUN_LIST_ARRAY=($(loko '$1 == "_LUN_TO_CREATE_" {print $2}' $ARRAY_INFO_TMP | sort -u))
			create_lun "${LUN_LIST_ARRAY[*]}"
		
		else
			local LUN_LIST_ARRAY=($(loko '$1 == "_LUN_INFO_" {print $3}' $ARRAY_INFO_TMP | sort -u))
		
		fi
		
		add_lun_to_sg 'exs' "${SG_LIST_ARRAY[*]}" "${LUN_LIST_ARRAY[*]}"
		
	fi
	
	if [[ $_NEW_HOST = 1 ]]; then
		
		login_register
		
	fi
	
}
