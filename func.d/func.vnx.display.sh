# func.vnx.display.sh

s_usage(){
	text 1
	text u4 "Script Usage" '-'
	text 1 
	text 1 "[Selection Mode]"
	text 1 "$SCRIPT -x  ( -v )"
	text 1
	text 1 "[Info/Audit Mode]"
	text 1 "$SCRIPT [ -sid <Bay ID> | -dns <DNS> | -ip <IP> ] info [ -lun <Lun Name> | -lid <Lun ID> | -luid <Lun UID> | -sg <SG> | -wwn <WWN> ]"
	text 1
	text 1 "[Remove Mode]"
	text 1 "$SCRIPT [ -sid <Bay ID> | -dns <DNS> | -ip <IP> ] remove [ -lun <Lun Name> | -lid <Lun ID> | -luid <Lun UID> | -sg <SG List> ] ( -total )"
	text 1
	text 1 "[Create Mode]"
	text 1 "$SCRIPT [ -sid <Bay ID> | -dns <DNS> | -ip <IP> ] create -nlun [ -sg <Existing SG> | -nsg -name <Name> ] [ ( -node <Nb> ) -nhost [host1,1.1.1.1]c0507606e8470002,c0507606e8470005 ]"
	text 1
	text 1 "-x               : Selection Mode"
	text 1 "info             : Info Mode"
	text 1 "create           : Create Mode"
	text 1 "remove           : Remove Mode"
	text 1
	text 1 "-sid             : Bay ID|SID"
	text 1 "-dns             : Bay DNS"
	text 1 "-ip              : Bay IP"
	text 1
	text 1 "-lun             : Lun(s) Name Argument"
	text 1 "-lid             : Lun(s) ID Argument"
	text 1 "-luid            : Lun(s) UID Argument"
	text 1 "-sg              : Storage Group Argument"
	text 1 "-wwn             : WWN(s) Argument"
	text 1
	text 1 "-only            : Only Device Info   [Info Mode]"
	text 1
	text 1 "-nlun            : New Lun            [Create Mode]"
	text 1 "-nsg             : New S.Group        [Create Mode]"
	text 1 "-nhost   [Arg]   : New Host           [Create Mode]"
	text 1 "-name    [Arg]   : Name of New SG     [Create Mode]"
	text 1 "-node    [Arg]   : Nb of Node         [Create Mode] (Df:1)"
	text 1 "-initt   [Arg]   : Init. Type         [Create Mode] (Df:3)"
	text 1 "-arraycp [Arg]   : Array Comm.        [Create Mode] (Df:0)"
	text 1 "-fomode  [Arg]   : Fail Ov. Mode      [Create Mode] (Df:4)"
	text 1 "-os      [Arg]   : Select OS          [Create Mode]"
	text 1
	text 1 "-total           : Total Delete       [Remove Mode]"
	text 1
	text 1 "-v               : Verbose Mode"
	text 1 "-h               : Usage"
	text 1 "-nop             : No Prompt"
	text 1 "-debug   [Arg]   : Debug Mode"
	text 1
	
}

all_bay_display(){
	
	text 1
	text 1
	text u1 "VNX List [Referenced]" '.'
	text 1
	
	( text t1 ";| Bay.ID;| Type;| DNS;| IP;" '-'
	
	while read ID TYPE LUN_T DNS IP MODEL; do
		[[ $ID != '#ID' ]] &&  printf "${MG2};| $ID;| $TYPE;| $DNS;| $IP;\n"
	done < $VNX_LIST_FILE) | column -t -s';'
	
}

initiator_info_display(){
	
	text 1
	text 1
	text u1 "Initiator(s) Info" '.'
	text 1
		
	( text t1 ";| SP.N ;| SP.ID;| I.Reg;| I.Log;| I.N.Log;" '-'
		
	( while read SP_NAME SP_ID REGISTER_INITIATORS LOGGEDIN_INITATORS NOT_LOGGEDIN_INITATORS; do
		
		[[ ! $SP_NAME =~ _ ]] && printf "${MG2};| SP$SP_NAME;| $SP_ID;| $REGISTER_INITIATORS;| $LOGGEDIN_INITATORS;| $NOT_LOGGEDIN_INITATORS;\n"
		
	done < $ARRAY_INFO_TMP ) | sort -t'|' -n -k3 ) | column -t -s';'
}

display_lun_by_type(){
	
	local COUNT_TYPE_SIZE_LIST_ARRAY=($(loko '$1 == "_LUN_INFO_" {print $10}' $ARRAY_INFO_TMP | sort | uniq -c | awk '{printf "%sx%d\n", $1, $2/1024}'))
	
	echo ${COUNT_TYPE_SIZE_LIST_ARRAY[@]}
	
}

general_info_display(){
	
	local BAY_INFO_CHECK=$(loko '$1 == "_BAY_INFO_" {print 1}' $ARRAY_INFO_TMP)
	
	if [[ $BAY_INFO_CHECK = 1 ]]; then
		
		local BAY_SERIAL=$(loko '$1 == "_BAY_INFO_" {print $2}' $ARRAY_INFO_TMP)
		local BAY_DNS_LIST=$(loko '$1 == "_BAY_INFO_" {print $3}' $ARRAY_INFO_TMP)
		local BAY_IP_LIST=$(loko '$1 == "_BAY_INFO_" {print $4}' $ARRAY_INFO_TMP)
		
		text 1
		text 1
		text u1 "General Informations" '.'
		text 1
		text 1 " Bay ID\t\t: $BAY_SERIAL"
		[[ $BAY_DNS_LIST != 'No' ]] && text 1 " SP DNS(s)\t\t: $BAY_DNS_LIST"
		[[ $BAY_IP_LIST != 'No' ]] && text 1 " SP IP(s)\t\t: $BAY_IP_LIST"
		text 1 " Mir.V [License]\t: $_MIRRORV_C"
		
	fi
}


luns_display() {
	
	local T_SIZE=$(loko '$1 == "_LUN_INFO_" {TOTAL_SIZE+=$10} END{print TOTAL_SIZE}' $ARRAY_INFO_TMP | cut -d. -f1)
	local L_COUNT=$(loko '$1 == "_LUN_INFO_" {print 1}' $ARRAY_INFO_TMP | wc -l)
	
	[[ $_OPT_MODE = 'Create' ]] && LUN_T='New ' || LUN_T=''
	
	text 1
	text 1
	text u1 "${LUN_T}Lun(s) Informations" '.'
	text 1
	text 1 " T.Size [T.Nb]\t: $(lun_size "$T_SIZE") [$L_COUNT]"
	text 1 " Lun by Type\t\t: $(display_lun_by_type)"
	text 1
	
	[[ $_MIRRORV_C = 'Yes' ]] && MIRROR_V_T="| Mir.V" || MIRROR_V_T=''
	
	( text t1 ";| Name;| ID;| Type;| Size;| P/R.ID;| S.Group[HLU];| SP(CR:DF);| UID;${MIRROR_V_T};" '-'
			
	( while IFS=';' read DAT LUN_NAME LUN_ID LUN_TYPE LUN_STATE SG_HLU_LIST CURRENT_SP DEFAULT_SP CAPACITY_BLOCK CAPACITY_MB POOL_RAID RAID_TYPE TIERING_POLICY INITIAL_TIER LUN_UID SG_NB CONSUM MIRROR_V; do
		
		if [[ $DAT = '_LUN_INFO_' ]]; then
			
			local SG_HLU_LIST_ARRAY=($(echo "$SG_HLU_LIST" | sed s/,/\\n/g | awk -F'.' '{printf "%s[%s]", $1, $2}' | sort -u))
			local SG_HLU_LIST=$(list_sep "${SG_HLU_LIST_ARRAY[*]}")
			
			[[ $SG_HLU_LIST = "No[]" ]] && SG_HLU_LIST='No'
			
			if [[ $_MIRRORV_C = 'Yes' ]]; then
				if [[ $MIRROR_V = 'Yes' ]]; then
					local MIRROR_V_TYPE=($(loko '$1 == "_MIRROR_INFO_" && $2 == "'"$LUN_ID"'" {print $5}' $ARRAY_INFO_TMP | sort -u))
					MIRROR_V="| ${MIRROR_V}[${MIRROR_V_TYPE}]"

				else
					MIRROR_V="| ${MIRROR_V}"
				
				fi
				
			else
				MIRROR_V=''
			
			fi
			
			printf "${MG2};| $LUN_NAME;| $LUN_ID;| $LUN_TYPE;| $(lun_size "$CAPACITY_MB");| $POOL_RAID;| $SG_HLU_LIST;| SP${CURRENT_SP}:SP${DEFAULT_SP};| $(echo $LUN_UID | tr -d :);${MIRROR_V};\n"
			
		fi
		
	done < $ARRAY_INFO_TMP) | sort -t'|' -nr -k5 ) | column -t -s';'

}	


storages_display() { #ARG ${SG_LIST_ARRAY[*]}
	
	local SG_LIST_ARRAY=($1)
	
	(
		
		text 1
		text 1
		text u1 "S.Group(s) Informations" '.'
		text 1
		
		for SG in ${SG_LIST_ARRAY[@]}; do
			
			local LUN_LIST_ARRAY=($(loko '$1 == "_SG_INFO_" && $2 == "'"$SG"'" && $5 != "No" {print $5}' $ARRAY_INFO_TMP | sed s/,/\\n/g | sort -u))
			local HBA_LIST_ARRAY=($(loko '$1 == "_SG_INFO_" && $2 == "'"$SG"'" && $4 != "No" {print $4}' $ARRAY_INFO_TMP | sed s/,/\\n/g | sort -u))
			local HOST_LIST_ARRAY=($(loko '$1 == "_SG_INFO_" && $2 == "'"$SG"'" && $6 != "No" {print $6}' $ARRAY_INFO_TMP | sed s/,/\\n/g | sort -u))
			
			text u3 "Storage Group" '~' "$SG"
			text 1 " Lun(s) Count\t: ${#LUN_LIST_ARRAY[@]}"
			text 1 " HBA(s) Count\t: ${#HBA_LIST_ARRAY[@]}"
			[[ -n ${HOST_LIST_ARRAY[@]} ]] && text 1 " Host(s) List\t: $(list_sep "${HOST_LIST_ARRAY[*]}")"
			text 1
			
		done
		
	)
	
}


logins_display() { #ARG ${WWN_LIST_ARRAY[*]}
	
	local WWN_LIST_ARRAY=($1)
	
	text 1
	text 1
	text u1 "Login(s) Informations" '.'
	text 1
	
	( text t1 ";| HBA.Name[Nb];| SP.Port(s);| Host;| IP;| SG;| F;| A;| Log;| Def;" '-'
	
	( for WWN in ${WWN_LIST_ARRAY[@]}; do
		
		local WWN_INFO=$(loko '$1 == "_WWN_INFO_" && $2 == "'"$WWN"'" {print $0}' $ARRAY_INFO_TMP)
		
		local WWN_SP_LIST_ARRAY=($(echo "$WWN_INFO" | loko '{print $3}' | sort -u)); local WWN_SP_LIST=$(list_sep "${WWN_SP_LIST_ARRAY[*]}")
		local WWN_HOST_LIST_ARRAY=($(echo "$WWN_INFO" | loko '{print $4}' | sort -u)); local WWN_HOST_LIST=$(list_sep "${WWN_HOST_LIST_ARRAY[*]}")
		local WWN_IP_LIST_ARRAY=($(echo "$WWN_INFO" | loko '{print $5}' | sort -u)); local WWN_IP_LIST=$(list_sep "${WWN_IP_LIST_ARRAY[*]}")
		local WWN_SG_LIST_ARRAY=($(echo "$WWN_INFO" | loko '{print $6}' | sort -u)); local WWN_SG_LIST=$(list_sep "${WWN_SG_LIST_ARRAY[*]}")
		local WWN_FAILOVER_M_LIST_ARRAY=($(echo "$WWN_INFO" | loko '{print $7}' | sort -u)); local WWN_FAILOVER_M_LIST=$(list_sep "${WWN_FAILOVER_M_LIST_ARRAY[*]}")
		local WWN_ARRAY_C_LIST_ARRAY=($(echo "$WWN_INFO" | loko '{print $8}' | sort -u)); local WWN_ARRAY_C_LIST=$(list_sep "${WWN_ARRAY_C_LIST_ARRAY[*]}")
		local WWN_LOG_IN_LIST_ARRAY=($(echo "$WWN_INFO" | loko '{print $9}' | sort -u)); local WWN_LOG_IN_LIST=$(list_sep "${WWN_LOG_IN_LIST_ARRAY[*]}")
		local WWN_DEFINED_LIST_ARRAY=($(echo "$WWN_INFO" | loko '{print $10}' | sort -u)); local WWN_DEFINED_LIST=$(list_sep "${WWN_DEFINED_LIST_ARRAY[*]}")
		
		[[ ${#WWN_LOG_IN_LIST_ARRAY[@]} > 1 ]] && WWN_LOG_IN_LIST='Y/N'
		[[ ${#WWN_DEFINED_LIST_ARRAY[@]} > 1 ]] && WWN_DEFINED_LIST='Y/N'
		
		printf "${MG2};| $WWN[${#WWN_SP_LIST_ARRAY[@]}];| ${WWN_SP_LIST};| ${WWN_HOST_LIST};| ${WWN_IP_LIST};| ${WWN_SG_LIST};| ${WWN_FAILOVER_M_LIST};| ${WWN_ARRAY_C_LIST};| ${WWN_LOG_IN_LIST};| ${WWN_DEFINED_LIST};\n"
		
	done) | sort -t'|' -n -k4 -k3 ) | column -t -s';'
	
}


pool_display() { #ARG ${POOL_ID_LIST_ARRAY[@]}

	local POOL_ID_LIST_ARRAY=($1)
	
	text 1
	text 1
	text u1 "Pool(s) Informations" '.'
	text 1
	
	( text t1 ";| Name;| ID;| L.Nb;| User.C;| Csm.C;| Av.C;| C[%];| Ov[%];" '-'
	
	( for POOL_ID in ${POOL_ID_LIST_ARRAY[@]}; do
	
		local POOL_INFO=$(loko '$1 == "_POOL_INFO_" && $2 == "'"$POOL_ID"'" {print $0}' $ARRAY_INFO_TMP)
		
		local POOL_NAME=$(echo "$POOL_INFO" | loko '{print $3}')
		
		local USR_CAP_BC=$(echo "$POOL_INFO" | loko '{print $5}')
		local CSM_CAP_BC=$(echo "$POOL_INFO" | loko '{print $6}')
		local AVL_CAP_BC=$(echo "$POOL_INFO" | loko '{print $7}')
		
		local PRC_FULL=$(echo "$POOL_INFO" | loko '{print $8}' | cut -d. -f1)
		local PRC_OVER=$(echo "$POOL_INFO" | loko '{print $9}' | cut -d. -f1)
		
		local LUN_LIST_ARRAY=($(echo "$POOL_INFO" | loko '{print $10}' | sed s/,/\\n/g))
		
		printf "${MG2};| ${POOL_NAME};| ${POOL_ID};| ${#LUN_LIST_ARRAY[@]};| $(lun_size_block "${USR_CAP_BC}");| $(lun_size_block "${CSM_CAP_BC}");| $(lun_size_block "${AVL_CAP_BC}");| ${PRC_FULL};| ${PRC_OVER};\n"
		
	done) | sort -t'|' -n -k3 ) | column -t -s';'
	

}


mirror_display() {
	
	text 1
	text 1
	text u1 "Mirror View Informations" '.'
	text 1
	
	( text t1 ";| L.ID;| Img.T;| L.UID(R).[Img.UID(R)];| MV.Name;| MV.Group;| MV.State;| MV.%;" '-'
			
	( while IFS=';' read DAT LUN_ID LUN_UID MIRRORV_LU_UID IMAGE_TYPE IMAGE_UID_L MIRRORV_LU_IMAGE_UID_R MIRRORV_NAME MIRRORV_UID MIRRORV_OWNERGP MIRRORV_STATUS MIRRORV_STATE MIRRORV_FAULT MIRRORV_COUNT IMAGE_STATE IMAGE_SYNC_P; do
		
		[[ $DAT = '_MIRROR_INFO_' ]] && printf "${MG2};| $LUN_ID;| $IMAGE_TYPE;| $(echo "${MIRRORV_LU_IMAGE_UID_R}" | tr -d :);| $MIRRORV_NAME;| $MIRRORV_OWNERGP;| $MIRRORV_STATE;| $IMAGE_SYNC_P;\n"
		
	done < $ARRAY_INFO_TMP) | sort -t'|' -n -k2 ) | column -t -s';'

}	


new_available_luns_display() { #ARG ${LUN_SIZE_LIST_ARRAY[*]}
	
	local LUN_SIZE_LIST_ARRAY=($1)
	
	local T_SIZE=$(loko '$1 == "_LUN_WITHOUT_SG_" {print $3}' $ARRAY_INFO_TMP | loko '{TOTAL+=$1} END{print TOTAL}')
	local T_COUNT=$(loko '$1 == "_LUN_WITHOUT_SG_" {print $3}' $ARRAY_INFO_TMP | wc -l)
	
	text 1
	text 1
	text u1 "Available Lun(s)" '.'
	text 1
	text 1 " T.Size [C]\t\t: $T_SIZE GB [$T_COUNT]"
	text 1
	
	( text t1 ";| Size;| Count;" '-'
	
	( list_array "${LUN_SIZE_LIST_ARRAY[*]}" | awk -F ';' '{printf "%s;| %s GB;| %s;\n", "'"${MG2}"'", $2, $1}' ) | sort -t'|' -nr -k2 ) | column -t -s';'
	
}


error_display(){ #NO ARG
	
	[[ $_OPT_DEVICE = 'WWN' && $_LOGIN_CHECK != 1 ]] && { text err "No Login(s) Find"; exit_S 0; }
	
}


warning_display(){ #NO ARG
	
	[[ $_WAR_LUN_NO_EMPTY = 1 ]] && text war "New Lun(s) not Empty. Script recreate it"
	[[ $_PDEV_CHECK = 1 ]] && text war "Physical Device(s) find"
	[[ $WAR_LUN_SG_1 = 1 ]] && text war "Lun(s) with several S.Group"
	[[ $WAR_LUN_SG_2 = 1 ]] && text war "Lun(s) with not same S.Group(s)"
	[[ $WAR_LUN_SG_4 = 1 ]] && text war "Lun(s) with other S.Group not delete"
	[[ $WAR_HOST_DF = 1 ]] && text war "Host(s) Already Exist. New WWN will be added in"
	[[ $WAR_LUN_SG_5 = 1 ]] && text war "$WAR_LUN_SG_5_DISPLAY"
	
}


