# Clariion VNX utils

## Information

The `vnx_utils.sh` script is coded in `bash` and runs on Linux. It requires the `naviseccli`.

The script works on `Clariion VNX`.

All array must be declare on text file `vnx_list.txt` :

```bash
#ID               TYPE  DNS               IP
CKM00000000001    Pool  vnx1spa,vnx2spb   1.1.1.1,1.1.1.2
CKM00000000002    Raid  vnx1spa,vnx2spb   1.1.1.6,1.1.1.7

# ID    : ID Array
# Type  : Pool or Raid
# DNS   : DNS of Array's SP
# IP    : IP of Array's SP
```

Script provide following features :
 * Audit (By `Login`, `Storage Group`, `Volume`)
 * Deletion (By `Storage Group`, `Volume`)
 * Creation (`Storage Group`, `Host`, `Volume`)

## Options

You can get all command and few examples, with `-help` or `-h` option.

```
.
.  Script Usage
.  ------------
.
.  [Selection Mode]
.  vnx_utils.sh -x  ( -v )
.
.  [Info/Audit Mode]
.  vnx_utils.sh [ -sid <Bay ID> | -dns <DNS> | -ip <IP> ] info [ -lun <Lun Name> | -lid <Lun ID> | -luid <Lun UID> | -sg <SG> | -wwn <WWN> ]
.
.  [Remove Mode]
.  vnx_utils.sh [ -sid <Bay ID> | -dns <DNS> | -ip <IP> ] remove [ -lun <Lun Name> | -lid <Lun ID> | -luid <Lun UID> | -sg <SG List> ] ( -total )
.
.  [Create Mode]
.  vnx_utils.sh [ -sid <Bay ID> | -dns <DNS> | -ip <IP> ] create -nlun [ -sg <Existing SG> | -nsg -name <Name> ] [ ( -node <Nb> ) -nhost [host1,1.1.1.1]c0507606e8470002,c0507606e8470005 ]
.
.  -x               : Selection Mode
.  info             : Info Mode
.  create           : Create Mode
.  remove           : Remove Mode
.
.  -sid             : Bay ID|SID
.  -dns             : Bay DNS
.  -ip              : Bay IP
.
.  -lun             : Lun(s) Name Argument
.  -lid             : Lun(s) ID Argument
.  -luid            : Lun(s) UID Argument
.  -sg              : Storage Group Argument
.  -wwn             : WWN(s) Argument
.
.  -only            : Only Device Info   [Info Mode]
.
.  -nlun            : New Lun            [Create Mode]
.  -nsg             : New S.Group        [Create Mode]
.  -nhost   [Arg]   : New Host           [Create Mode]
.  -name    [Arg]   : Name of New SG     [Create Mode]
.  -node    [Arg]   : Nb of Node         [Create Mode] (Df:1)
.  -initt   [Arg]   : Init. Type         [Create Mode] (Df:3)
.  -arraycp [Arg]   : Array Comm.        [Create Mode] (Df:0)
.  -fomode  [Arg]   : Fail Ov. Mode      [Create Mode] (Df:4)
.  -os      [Arg]   : Select OS          [Create Mode]
.
.  -total           : Total Delete       [Remove Mode]
.
.  -v               : Verbose Mode
.  -h               : Usage
.  -nop             : No Prompt
.  -debug   [Arg]   : Debug Mode
.
```

## Operation

Here are some examples of use in situation.

By default all mode except info work on `dry-run`. That is, the user must validate to execute the commands (Yes/No).

However it is possible to add `-nop` option for skip that.

### Audit

Example of an audit on a `storage group`.

```
$ ./vnx_utils.sh -sid 0001 info -sg SG_server01
.
.  <+> Script Start [Info LUN] [31/08/2017][14:52:27] <+>
.
.   [R] Commands        : [SG][WWN][Mir.V] [done]
.
.   [R] Lun(s)          : [003/003] [ooooooooooo] 100% [done]
.   [R] S.Group(s)      : [002/002] [ooooooooooo] 100% [done]
.
.
.  General Informations
........................................
.
.   Bay ID              : CKM00142500001
.   SP DNS(s)           : VNX0001_SPA,VNX0001_SPB
.   SP IP(s)            : 10.1.1.1,10.1.1.2
.   Mir.V [License]     : Yes
.
.
.
.  Login(s) Informations
........................................
.
.   | HBA.Name[Nb]                                        | SP.Port(s)  | Host      | IP        | SG           | F  | A    | Log  | Def
.   | ------------                                        | ----------  | ----      | --        | --           | -  | -    | ---  | ---
.   | C0:50:00:00:00:C5:00:00:10:00:00:00:00:00:00:10[2]  | A-8,B-8     | server02  | 10.1.0.2  | SG_server02  | 4  | 0    | Yes  | Yes
.   | C0:50:00:00:00:C5:00:00:10:00:00:00:00:00:00:12[2]  | A-3,B-3     | server02  | 10.1.0.2  | SG_server02  | 4  | 0    | Yes  | Yes
.   | C0:50:00:00:00:EC:00:00:10:00:00:00:00:00:00:14[2]  | A-3,B-3     | server01  | 10.1.0.1  | SG_server01  | 4  | 1    | Yes  | Yes
.   | C0:50:00:00:00:EC:00:00:10:00:00:00:00:00:00:16[2]  | A-8,B-8     | server01  | 10.1.0.1  | SG_server01  | 4  | 0,1  | Yes  | Yes
.
.
.
.  S.Group(s) Informations
........................................
.
.  <> Storage Group     : SG_server01
.     ~~~~~~~~~~~~~
.   Lun(s) Count        : 4
.   HBA(s) Count        : 2
.   Host(s) List        : server01
.
.  <> Storage Group     : SG_server02
.     ~~~~~~~~~~~~~
.   Lun(s) Count        : 5
.   HBA(s) Count        : 2
.   Host(s) List        : server02
.
.
.
.  Lun(s) Informations
........................................
.
.   T.Size [T.Nb]       : 436 GB [4]
.   Lun by Type         : 1x1 2x108 1x217
.
.   | Name      | ID    | Type  | Size    | P/R.ID   | S.Group[HLU]                  | SP(CR:DF)  | UID                               | Mir.V
.   | ----      | --    | ----  | ----    | ------   | ------------                  | ---------  | ---                               | -----
.   | LUN_4440  | 4440  | TDv   | 217 GB  | POOL_01  | SG_server02[4]SG_server01[3]  | SPB:SPB    | 60060160000000000000000000000001  | No
.   | LUN_6290  | 6290  | TDv   | 108 GB  | POOL_02  | SG_server02[1]SG_server01[0]  | SPB:SPB    | 60060160000000000000000000000002  | No
.   | LUN_6287  | 6287  | TDv   | 108 GB  | POOL_02  | SG_server02[2]SG_server01[1]  | SPA:SPA    | 60060160000000000000000000000003  | No
.   | LUN_6842  | 6842  | TDv   | 1 GB    | POOL_02  | SG_server02[3]SG_server01[2]  | SPB:SPB    | 60060160000000000000000000000004  | No
.
.  <-> Script End [31/08/2017][14:52:57] <->
.
```


### Creation

Example of a creation of new `storage group` and `volumes` mapping (Already present on Array).

```
$ ./vnx_utils.sh -sid 0001 create -nlun -nsg -name server01
.
.  <+> Script Start [Create] [10/10/2017][10:02:15] <+>
.
.   [R] Commands        : [SG][WWN][Mir.V] [done]
.
.   [R] Free Lun(s)     : [ 44 Free Lun(s) on 765 Lun(s) ]
.
.
.  Available Lun(s)
........................................
.
.   T.Size [C]          : 7708 GB [44]
.
.   | Size    | Count
.   | ----    | -----
.   | 653 GB  | 5
.   | 435 GB  | 4
.   | 217 GB  | 3
.   | 108 GB  | 6
.   | 54 GB   | 26
.
.  <> Enter Lun(s) to Create : 2x108
.
.   [R] Lun(s)          : [002/002] [ooooooooooo] 100% [done]
.
.
.  General Informations
........................................
.
.   Bay ID              : CKM00142500001
.   SP DNS(s)           : VNX0001_SPA,VNX0001_SPB
.   SP IP(s)            : 10.1.1.1,10.1.1.2
.   Mir.V [License]     : Yes
.
.
.  New Lun(s) Informations
........................................
.
.   T.Size [T.Nb]       : 217 GB [2]
.   Lun by Type         : 2x108
.
.   | Name      | ID    | Type  | Size    | P/R.ID   | S.Group[HLU]  | SP(CR:DF)  | UID                               | Mir.V
.   | ----      | --    | ----  | ----    | ------   | ------------  | ---------  | ---                               | -----
.   | LUN_7195  | 7195  | TDv   | 108 GB  | POOL_02  | No            | SPA:SPA    | 60060160000000000000000000000001  | No
.   | LUN_7194  | 7194  | TDv   | 108 GB  | POOL_02  | No            | SPB:SPB    | 60060160000000000000000000000002  | No
.
.
.  Commands to Execute
........................................
.
.  <> Create New SG
.     ~~~~~~~~~~~~~
.   /opt/Navisphere/bin/naviseccli -h VNX0001_SPA storagegroup -create -gname SG_server01
.
.  <> Add Lun(s) to S.Group(s)
.     ~~~~~~~~~~~~~~~~~~~~~~~~
.   /opt/Navisphere/bin/naviseccli -h VNX0001_SPA storagegroup -addhlu -gname SG_server01 -hlu 0 -alu 7194
.   /opt/Navisphere/bin/naviseccli -h VNX0001_SPA storagegroup -addhlu -gname SG_server01 -hlu 1 -alu 7195
.
.
.  <> Do You Want Execute Command(s) ? [Yes/No] : yes
.
.  Commands Execution Start
........................................
.
.  <> Create New SG
.     ~~~~~~~~~~~~~
.   [10:02:45] /opt/Navisphere/bin/naviseccli -h VNX0001_SPA storagegroup -create -gname SG_server01 [cmd OK]
.
.  <> Add Lun(s) to S.Group(s)
.     ~~~~~~~~~~~~~~~~~~~~~~~~
.   [10:02:48] /opt/Navisphere/bin/naviseccli -h VNX0001_SPA storagegroup -addhlu -gname SG_server01 -hlu 0 -alu 7194 [cmd OK]
.   [10:02:52] /opt/Navisphere/bin/naviseccli -h VNX0001_SPA storagegroup -addhlu -gname SG_server01 -hlu 1 -alu 7195 [cmd OK]
.
.
.  <-> Script End [10/10/2017][10:02:56] <->
.
```


### Deletion

Example of a deletion of `storage group` and its `volumes`. 

By default volumes are not deleted and stored in a temporary `storage group` with the ID of the week.

```
$ ./vnx_utils.sh -sid 0001 remove -sg SG_server01
.
.  <+> Script Start [Remove SG - Normal] [10/10/2017][10:04:36] <+>
.
.   [R] Commands        : [SG][WWN][Mir.V] [done]
.
.   [R] Lun(s)          : [002/002] [ooooooooooo] 100% [done]
.   [R] S.Group(s)      : [001/001] [ooooooooooo] 100% [done]
.
.
.  General Informations
........................................
.
.   Bay ID              : CKM00142500001
.   SP DNS(s)           : VNX0001_SPA,VNX0001_SPB
.   SP IP(s)            : 10.1.1.1,10.1.1.2
.   Mir.V [License]     : Yes
.
.
.  S.Group(s) Informations
........................................
.
.  <> Storage Group     : SG_server01
.     ~~~~~~~~~~~~~
.   Lun(s) Count        : 2
.   HBA(s) Count        : 0
.
.
.
.  Lun(s) Informations
........................................
.
.   T.Size [T.Nb]       : 217 GB [2]
.   Lun by Type         : 2x108
.
.   | Name      | ID    | Type  | Size    | P/R.ID   | S.Group[HLU]    | SP(CR:DF)  | UID                               | Mir.V
.   | ----      | --    | ----  | ----    | ------   | ------------    | ---------  | ---                               | -----
.   | LUN_7195  | 7195  | TDv   | 108 GB  | POOL_02  | SG_server01[1]  | SPA:SPA    | 60060160000000000000000000000001  | No
.   | LUN_7194  | 7194  | TDv   | 108 GB  | POOL_02  | SG_server01[0]  | SPB:SPB    | 60060160000000000000000000000002  | No
.
.
.  Commands to Execute
........................................
.
.  <> Remove Lun(s) to SG
.     ~~~~~~~~~~~~~~~~~~~
.   /opt/Navisphere/bin/naviseccli -h VNX0001_SPA storagegroup -gname SG_server01 -removehlu -hlu 0 1 -o
.
.  <> Delete S.Group(s)
.     ~~~~~~~~~~~~~~~~~
.   /opt/Navisphere/bin/naviseccli -h VNX0001_SPA storagegroup -destroy -gname SG_server01 -o
.
.  <> Add Lun(s) to S.Group(s)
.     ~~~~~~~~~~~~~~~~~~~~~~~~
.   /opt/Navisphere/bin/naviseccli -h VNX0001_SPA storagegroup -addhlu -gname SG_vnx_utils_week_41_temp -hlu 18 -alu 7194
.   /opt/Navisphere/bin/naviseccli -h VNX0001_SPA storagegroup -addhlu -gname SG_vnx_utils_week_41_temp -hlu 19 -alu 7195
.
.
.  <> Do You Want Execute Command(s) ? [Yes/No] : yes
.
.  Commands Execution Start
........................................
.
.  <> Remove Lun(s) to SG
.     ~~~~~~~~~~~~~~~~~~~
.   [10:04:55] /opt/Navisphere/bin/naviseccli -h VNX0001_SPA storagegroup -gname SG_server01 -removehlu -hlu 0 1 -o [cmd OK]
.
.  <> Delete S.Group(s)
.     ~~~~~~~~~~~~~~~~~
.   [10:04:59] /opt/Navisphere/bin/naviseccli -h VNX0001_SPA storagegroup -destroy -gname SG_server01 -o [cmd OK]
.
.  <> Add Lun(s) to S.Group(s)
.     ~~~~~~~~~~~~~~~~~~~~~~~~
.   [10:05:02] /opt/Navisphere/bin/naviseccli -h VNX0001_SPA storagegroup -addhlu -gname SG_vnx_utils_week_41_temp -hlu 18 -alu 7194 [cmd OK]
.   [10:05:06] /opt/Navisphere/bin/naviseccli -h VNX0001_SPA storagegroup -addhlu -gname SG_vnx_utils_week_41_temp -hlu 19 -alu 7195 [cmd OK]
.
.
.  <-> Script End [10/10/2017][10:05:11] <->
```