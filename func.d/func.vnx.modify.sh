# func.vnx.modify.sh


modify_script_execution(){ #ARG $EX_MODE

    local EX_MODE=$1

    
    
    
    local LUN_ID_TO_MD_ARRAY=($(loko '$1 == "_LUN_INFO_" {print $3}' $ARRAY_INFO_TMP))
    
    delete_lun 'T.Dev' "${LUN_ID_TO_MD_ARRAY[*]}"
    
    local LUN_LIST_ARRAY=($(loko '$1 == "_LUN_TO_CREATE_" {print $2}' $ARRAY_INFO_TMP | sort -u))
    
    create_lun "${LUN_LIST_ARRAY[*]}"

}