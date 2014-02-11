#AUTHORIZED TO Goombah Tech Solutions 
#Script: Slony Automation
#   1 <--,
#  /|\   ,
# 2 4 3--,
#!/bin/bash
export SL_AT_Home
export SL_AT_Database
export SL_AT_Username
export SL_AT_Port
export PSQL
export schema
Query_Runner()
{
QUERY=$5
HOST=$1
DB=$4
PORT=$3
USER=$2
$PSQL/psql -h $HOST -U $USER -p $PORT -d $DB -F " " -Atc "$QUERY"
}
Cred_Lexer()
{
SL_AT_Node=$1
SL_AT_Host=`sed -n $SL_AT_Node'p' /tmp/.cred.txt|cut -d"\"" -f2`
SL_AT_Database=`sed -n $SL_AT_Node'p' /tmp/.cred.txt|cut -d"\"" -f4`
SL_AT_Username=`sed -n $SL_AT_Node'p' /tmp/.cred.txt|cut -d"\"" -f6`
SL_AT_Port=`sed -n $SL_AT_Node'p' /tmp/.cred.txt|cut -d"\"" -f8`
}
Put_Preamble()
{
Slonik_File=$1
i=1
FILE_NODES=`cat /tmp/.cred.txt|wc -l`
while [ "$i" -le "$FILE_NODES" ] 
do
Cred_Lexer $i
echo -e "node $i admin conninfo='host=$SL_AT_Host dbname=$SL_AT_Database user=$SL_AT_Username port=$SL_AT_Port';" >>$Slonik_File
i=`expr $i + 1`
done
}
Header()
{
printf "%150s\n" " "|tr ' ' '#' 
echo -e "\t\t\t\t\t\t#::Easy_Slony Automated Script $(date +%D)::#"
printf "%150s\n" " "|tr ' ' '#'
}

Slonik_Tools_Preamble()
{
echo -e "cluster name = $Schema;"
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "select 'node '||pa_server||' admin conninfo='''||pa_conninfo||''';' from _$Schema.sl_path where ctid not in(select ctid from _$Schema.sl_path e where ctid not in (select min(ctid) from _$Schema.sl_path e1 where e.pa_server=e1.pa_server)) order by 1;"
}

Notify_Exec()
{
echo -e "Please Find The Below $1 Slonik Script..."
cat /tmp/easy_slony_slonik_$1_$Date.slonik
echo -e "Do You Want To Execute [Y/N] ?"
read Slonik_Ch
if [ $Slonik_Ch = "y" -o $Slonik_Ch = "Y" ]; then
$Slonik_Location /tmp/easy_slony_slonik_$1_$Date.slonik
fi
}

clear
Last_Seq_Tab_Id=1
Last_Seq_Seq_ID=1
Last_Seq_Tab_Sub_Id=1
Cas_Ch="N"
Date=`date +%d_%m_%y`
>/tmp/.config.track
printf "%70s\n" " "|tr ' ' '='
echo -e   "\t::::::: Easy_Slon Slony Automation Script ::::::::"
printf "%70s\n" " "|tr ' ' '='

echo "Source PSQL Location ?[Ex:- /opt/PostgreSQL/8.4/bin]"
read PSQL

Config()
{
echo -e "How Many Hosts/Nodes Participating In This Replication ? "
read NUM_NODES
FILE_NODES=`cat /tmp/.cred.txt|wc -l`
if [ "$NUM_NODES" -gt "$FILE_NODES" ]; then
echo -e "Please add more nodes to /tmp/.cred.txt .."
red_Lexer
fi
i=1
while [ "$i" -le "$FILE_NODES" ] 
do
Cred_Lexer $i
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "Select 'Node - $i Connected ..'"
if [ "$?" != "0" ]; then
echo -e "Node - $i is not connected properlly, Please check Host=$Host Username=$Username Port=$Port Database=$Database .. "
exit 1
fi
i=`expr $i + 1`
done
echo -e "Slony catalogs schema ? [Default:_replication] "
read Schema
if [ -z $Schema ]; then
Schema="replication"
fi
i=1
while [ "$i" -le "$FILE_NODES" ] 
do
Cred_Lexer $i
if [ "$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "Select count(*) from pg_catalog.pg_namespace where nspname='_$Schema'")" -ne "0" ]; then
echo -e "_$Schema is already present in Node $i i.e. Host=$SL_AT_Host Database=$SL_AT_Database Username=$SL_AT_Username Port=$SL_AT_Port .."
exit 1
fi
echo -e "Processed $i"
i=`expr $i + 1`
done
echo -e "DB level everything is perfect ... "
echo -e "Generating Scripts ... "
#Initializing cluster
printf "%150s\n" " "|tr ' ' '#' > /tmp/easy_slony_slonik_init_cluster_$Date.slonik
echo -e "\t\t\t\t\t#::Easy_Slony Automated Initializing cluster $(date +%D)::#" >>/tmp/easy_slony_slonik_init_cluster_$Date.slonik
printf "%150s\n" " "|tr ' ' '#'>> /tmp/easy_slony_slonik_init_cluster_$Date.slonik
echo -e "cluster name = $Schema;" >> /tmp/easy_slony_slonik_init_cluster_$Date.slonik
Put_Preamble "/tmp/easy_slony_slonik_init_cluster_$Date.slonik"

echo -e "Enter Master and slave nodes [Ex:- 1 to 2 3 ..] "
read Rep_Config
Master=`echo -e $Rep_Config|awk -F 'to' {'print $1'}`
Slaves=`echo -e $Rep_Config|awk -F 'to' {'print $2'}`
if [ $Master -gt $FILE_NODES ]; then
echo -e "Please Enter Valid Node Id.. $Master Must Be <= $FILE_NODES "
exit 1;
fi
for J in $Slaves
do
if [ $J -gt $FILE_NODES ]; then
echo -e "Please Enter Valid Node ID .. $J Must Be <= $FILE_NODES "
exit 1;
fi
done
echo -e "init cluster (id = $Master, comment = 'Primary Node For the Slave postgres');" >>/tmp/easy_slony_slonik_init_cluster_$Date.slonik
echo -e "#Setting Store Nodes ... " >>/tmp/easy_slony_slonik_init_cluster_$Date.slonik
for (( J=2; J<=$FILE_NODES; J++ ))
do
echo -e "store node (id = $J, event node = $Master, comment = 'Slave Node For The Primary postgres');" >>/tmp/easy_slony_slonik_init_cluster_$Date.slonik
done
echo -e "#Setting Store Paths ... ">>/tmp/easy_slony_slonik_init_cluster_$Date.slonik
echo -e "echo  'Stored all nodes in the slony catalogs';">>/tmp/easy_slony_slonik_init_cluster_$Date.slonik
#for J in $Slaves
for (( J=2; J<=$FILE_NODES; J++ ))
do
Cred_Lexer $Master
echo -e "store path(server = $Master, client = $J, conninfo = 'host=$SL_AT_Host dbname=$SL_AT_Database user=$SL_AT_Username port=$SL_AT_Port');">>/tmp/easy_slony_slonik_init_cluster_$Date.slonik
Cred_Lexer $J
echo -e "store path(server = $J, client = $Master, conninfo = 'host=$SL_AT_Host dbname=$SL_AT_Database user=$SL_AT_Username port=$SL_AT_Port');">>/tmp/easy_slony_slonik_init_cluster_$Date.slonik
done
echo -e "echo  'Stored all Store Paths for Failover and Switchover into slony catalogs ..';">>/tmp/easy_slony_slonik_init_cluster_$Date.slonik
printf "%150s\n" " "|tr ' ' '#' > /tmp/easy_slony_slonik_create_sets_$Date.slonik
echo -e "\t\t\t\t\t#::Easy_Slony Automated Creating Sets $(date +%D)::#" >>/tmp/easy_slony_slonik_create_sets_$Date.slonik
printf "%150s\n" " "|tr ' ' '#'>> /tmp/easy_slony_slonik_create_sets_$Date.slonik
echo -e "cluster name = $Schema;" >> /tmp/easy_slony_slonik_create_sets_$Date.slonik
Put_Preamble "/tmp/easy_slony_slonik_create_sets_$Date.slonik"
printf "%150s\n" " "|tr ' ' '#' > /tmp/easy_slony_slonik_subscribe_sets_$Date.slonik
echo -e "\t\t\t\t\t#::Easy_Slony Automated Subscribing Sets $(date +%D)::#" >>/tmp/easy_slony_slonik_subscribe_sets_$Date.slonik
printf "%150s\n" " "|tr ' ' '#'>> /tmp/easy_slony_slonik_subscribe_sets_$Date.slonik
echo -e "cluster name = $Schema;" >> /tmp/easy_slony_slonik_subscribe_sets_$Date.slonik
Put_Preamble "/tmp/easy_slony_slonik_subscribe_sets_$Date.slonik"
echo -e "What Are The Schemas Do You Want To Replication From The Master ? [Ex:- @ll (or) Schema1 Schema2 ...]"
read Rep_Schemas
Cred_Lexer $Master
Phase="First"
while [ $Phase != "Stop" ]
do
if [ $Phase = "Continue.." ]; then
echo -e "Enter Master and slave nodes [Ex:- 2 to 3 1 ..] "
read Rep_Config
Master=`echo -e $Rep_Config|awk -F 'to' {'print $1'}`
Slaves=`echo -e $Rep_Config|awk -F 'to' {'print $2'}`
if [ $Master -gt $FILE_NODES ]; then
echo -e "Please Enter Valid Node Id.. $Master Must Be <= $FILE_NODES"
exit 1;
fi
for J in $Slaves
do
if [ $J -gt $FILE_NODES ]; then
echo -e "Please Enter Valid Node ID .. $J Must Be <= $FILE_NODES "
exit 1;
else
Cred_Lexer $Master
echo -e "store path(server = $Master, client = $J, conninfo = 'host=$SL_AT_Host dbname=$SL_AT_Database user=$SL_AT_Username port=$SL_AT_Port');">>/tmp/easy_slony_slonik_init_cluster_$Date.slonik
Cred_Lexer $J
echo -e "store path(server = $J, client = $Master, conninfo = 'host=$SL_AT_Host dbname=$SL_AT_Database user=$SL_AT_Username port=$SL_AT_Port');">>/tmp/easy_slony_slonik_init_cluster_$Date.slonik
fi
done
echo -e "Do you want cascading replication ? [Y/N]"
read Cas_Ch
echo -e "What Are The Schemas Do You Want To Replication From The Master ? [Ex:- @ll (or) Schema1 Schema2 ...]"
read Rep_Schemas
Cred_Lexer $Master
fi

if [ $Cas_Ch = "y" -o $Cas_Ch = "Y" ]; then
Int_Master=`echo -e $Master|tr ' ' '\b'`
for J in $Slaves
do
echo -e "Enter Omit Copy For The Slave $J ? [true/false]\n**If Omit Copy=False Then It's A Complete Refreshment By Truncating Slave Tables.**"
read Omit_Copy
for Rep_Schema in `echo -e $Rep_Schemas|tr '[:upper:]' '[:lower:]'`
do
Cas_Sets=`cat /tmp/.config.track|grep -e "($Int_Master)=>($Rep_Schema)"|awk -F '=>' '{print $4}'`
for Cas_Set in $Cas_Sets 
do
echo -e "try { subscribe set (id = $Cas_Set, provider = $Int_Master , receiver = $J, forward = yes, omit copy = $Omit_Copy); } on error { exit 1; } echo  'Subscribed nodes to set $Cas_Set';" >>/tmp/easy_slony_slonik_subscribe_sets_$Date.slonik
done 
echo -e "($Int_Master)=>($J)=>($Rep_Schema)=>$Cas_Sets" >>/tmp/.config.track
done
done
else
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "DROP SEQUENCE EASY_SLONY_ROWNUM_$;" >/dev/null 2>/dev/null
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "CREATE SEQUENCE EASY_SLONY_ROWNUM_$;" >/dev/null 2>/dev/null
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "DROP SEQUENCE EASY_SLONY_ROWNUM_1$;" >/dev/null 2>/dev/null
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "CREATE SEQUENCE EASY_SLONY_ROWNUM_1$;" >/dev/null 2>/dev/null
for Rep_Schema in `echo -e $Rep_Schemas|tr '[:upper:]' '[:lower:]'`
do
if [ $Rep_Schema != "@ll" ]; then
echo -e "Preparing $Rep_Schema Tables Script ..."
#Primary Key's Create set
echo -e "Do you want $Rep_Schema Primary key Replicate ? [Y/N] "
read Pk_Ch
if [ $Pk_Ch = "y" -o $Pk_Ch = "Y" ]; then
START_SEQ_VAL=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT setval('EASY_SLONY_ROWNUM_$',$Last_Seq_Tab_Id);")
echo "After Cascade $START_SEQ_VAL-> $Last_Seq_Tab_Id"
START_SEQ_VAL1=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT setval('EASY_SLONY_ROWNUM_1$',$Last_Seq_Seq_ID);")
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT 'try { create set (id = '||nextval('EASY_SLONY_ROWNUM_$')-1||' ,origin = $Master, comment = ''Set for '||nspname||'''); } on error { echo  ''Could not create Subscription set'||currval('EASY_SLONY_ROWNUM_$')-1||' for upgrade!''; exit 1;}' FROM PG_CATALOG.PG_CONSTRAINT INNER JOIN PG_CLASS ON CONRELID=pg_class.oid INNER JOIN PG_NAMESPACE ON RELNAMESPACE=PG_NAMESPACE.OID WHERE CONTYPE='p' AND CONNAMESPACE IN (SELECT OID FROM PG_NAMESPACE WHERE NSPNAME = '$Rep_Schema');" >>/tmp/easy_slony_slonik_create_sets_$Date.slonik
fi

#Candidate Key's Create set

echo -e "Do you want $Rep_Schema Schema's Candidate key tables Replication ? [Y/N] "
read Can_Ch
if [ $Can_Ch = "y" -o $Can_Ch = "Y" ]; then
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "select 'try { create set (id = '||nextval('EASY_SLONY_ROWNUM_$')-1||' ,origin = $Master,comment = ''Set for '||nspname||'''); } on error { echo  ''Could not create Subscription set for Keyed Table '||currval('EASY_SLONY_ROWNUM_$')-1||' for upgrade!''; exit 1;}' from pg_constraint inner join pg_class on conrelid=pg_class.oid inner join pg_namespace on connamespace=pg_namespace.oid where contype='u' and (relname,nspname) in (select relname,nspname from pg_attribute inner join pg_class on attrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid and nspname ~ '$Rep_Schema' and attnotnull is true and attname !~ '^xmin|^xmax|^cmin|^cmax|^ctid|^tableoid' and relkind ='r' and relhaspkey is false) ;" >>/tmp/easy_slony_slonik_create_sets_$Date.slonik
fi

#Primary Key's Set add table

if [ $Pk_Ch = "y" -o $Pk_Ch = "Y" ]; then
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT SETVAL('EASY_SLONY_ROWNUM_$',$START_SEQ_VAL);" >/dev/null
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "select 'set add table (set id = '||nextval('EASY_SLONY_ROWNUM_$')-1||' ,origin = $Master, id = '||currval('EASY_SLONY_ROWNUM_$')-1||', full qualified name = '''||nspname||'.'||relname||''', comment = ''Table ' ||relname||' with primary key'');' from pg_constraint inner join pg_class on conrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid where contype='p' and connamespace in(select oid from pg_namespace where nspname ='$Rep_Schema');" >>/tmp/easy_slony_slonik_create_sets_$Date.slonik
fi

#Candidate Key's Set add table

if [ $Can_Ch = "y" -o $Can_Ch = "Y" ]; then
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "select 'set add table (set id = '||nextval('EASY_SLONY_ROWNUM_$')-1||' ,origin = $Master, id = '||currval('EASY_SLONY_ROWNUM_$')-1||', full qualified name = '''||nspname||'.'||relname||''', key='''||conname||''', comment=''Table '||nspname||'.'||relname||' with candidate primary key '||conname||''');' from pg_constraint inner join pg_class on conrelid=pg_class.oid inner join pg_namespace on connamespace=pg_namespace.oid where contype='u' and (relname,nspname) in (select relname,nspname from pg_attribute inner join pg_class on attrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid and nspname ~ '$Rep_Schema' and attnotnull is true and attname !~ '^xmin|^xmax|^cmin|^cmax|^ctid|^tableoid' and relkind ='r' and relhaspkey is false) ;" >>/tmp/easy_slony_slonik_create_sets_$Date.slonik
fi
Last_Seq_Tab_Id=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT setval('EASY_SLONY_ROWNUM_$',nextval('EASY_SLONY_ROWNUM_$')-1);")

if [ $Pk_Ch = "y" -o $Pk_Ch = "Y" ]; then
echo -e "Do you want $Rep_Schema Schema's Sequences Replicate ? [Y/N] "
read Seq_Ch
if [ $Seq_Ch = "y" -o $Seq_Ch = "Y" ]; then
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT SETVAL('EASY_SLONY_ROWNUM_1$',$Last_Seq_Seq_ID);" >/dev/null
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT 'set add sequence (set id = '||nextval('EASY_SLONY_ROWNUM_1$')-1 ||', origin = $Master, id = '||currval('EASY_SLONY_ROWNUM_1$')-1||', full qualified name ='''||sequence_name||''', comment = ''Sequence '||sequence_name||''');' FROM
((SELECT DISTINCT case when position((nspname||'.')::varchar in TAB_SEQ_LIST.sequence_def)>0 then TAB_SEQ_LIST.sequence_def when position('.'::varchar in TAB_SEQ_LIST.sequence_def)>0 then TAB_SEQ_LIST.sequence_def else (select nspname from pg_class,pg_namespace where relkind='S' and relnamespace=pg_namespace.oid and relname=TAB_SEQ_LIST.sequence_def and pg_namespace.nspname=TAB_SEQ_LIST.nspname)::text||'.'||TAB_SEQ_LIST.sequence_def end as sequence_name FROM ( SELECT a.attrelid::regclass as table,attrelid ,nspname,(select trim(both '''' from rtrim(ltrim(regexp_replace(regexp_replace(regexp_replace(case when substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128) like 'nextval(%::regclass)' then substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128) end,'''''','''','g') ,'nextval',''),'::regclass','')::text,'(')::text,')')) FROM pg_catalog.pg_attrdef d WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef) as sequence_def FROM pg_catalog.pg_attribute a inner join pg_class on a.attrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid and nspname ~ '$Rep_Schema' AND a.attnum >0 AND NOT a.attisdropped ORDER BY a.attnum ) AS TAB_SEQ_LIST WHERE TAB_SEQ_LIST.sequence_def is not null and tab_seq_list.table in (select conrelid::regclass from pg_constraint where contype='p' and connamespace in (select oid from pg_namespace where nspname ~ '$Rep_Schema')))
UNION
(SELECT DISTINCT case when position((nspname||'.')::varchar in TAB_SEQ_LIST.sequence_def)>0 then TAB_SEQ_LIST.sequence_def when position('.'::varchar in TAB_SEQ_LIST.sequence_def)>0 then TAB_SEQ_LIST.sequence_def else (select nspname from pg_class,pg_namespace where relkind='S' and relnamespace=pg_namespace.oid and relname=TAB_SEQ_LIST.sequence_def and pg_namespace.nspname=TAB_SEQ_LIST.nspname)::text||'.'||TAB_SEQ_LIST.sequence_def end as sequence_name FROM ( SELECT a.attname as column,a.attrelid::regclass as table,attrelid ,nspname,(SELECT trim(both '''' from rtrim(ltrim(regexp_replace(regexp_replace(regexp_replace(case when substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128) like 'nextval(%::regclass)' then substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128) end,'''''','''','g') ,'nextval',''),'::regclass','')::text,'(')::text,')')) FROM pg_catalog.pg_attrdef d WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef) as sequence_def FROM pg_catalog.pg_attribute a inner join pg_class on a.attrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid and nspname ~ '$Rep_Schema' AND a.attnum >0 AND NOT a.attisdropped ORDER BY a.attnum ) AS TAB_SEQ_LIST WHERE TAB_SEQ_LIST.sequence_def is not null and (tab_seq_list.table,tab_seq_list.nspname) in (select attrelid::regclass,nspname from pg_attribute inner join pg_class on attrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid and nspname  ~ '$Rep_Schema' and attnotnull is true and attname !~ '^xmin|^xmax|^cmin|^cmax|^ctid|^tableoid' and relkind ='r' and relhaspkey is false))
) AS PK_CAN_SEQ; " >>/tmp/easy_slony_slonik_create_sets_$Date.slonik
fi
fi

Last_Seq_Seq_ID=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT setval('EASY_SLONY_ROWNUM_1$',nextval('EASY_SLONY_ROWNUM_1$')-1);")
else

if [ $Phase = "Continue.." ]; then
START_SEQ_VAL=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT setval('EASY_SLONY_ROWNUM_$',$Last_Seq_Tab_Id);")
START_SEQ_VAL1=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT setval('EASY_SLONY_ROWNUM_1$',$Last_Seq_Seq_ID);")
else
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT nextval('EASY_SLONY_ROWNUM_$')-1" >/dev/null 2>/dev/null
fi

#All Primary key tables Create set

echo -e "Do you want All Schema's Primary key Replicate ? [Y/N] "
read Pk_Ch
if [ $Pk_Ch = "y" -o $Pk_Ch = "Y" ]; then
Slon_Exsist=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "select count(*) from pg_proc inner join pg_namespace on pronamespace=pg_namespace.oid where proname like 'slonyversion%' and nspname like '_%';")
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT 'try { create set (id = '||nextval('EASY_SLONY_ROWNUM_$')-1||' ,origin = $Master, comment = ''Set for '||nspname||'''); } on error { echo  ''Could not create Subscription set'||currval('EASY_SLONY_ROWNUM_$')-1||' for upgrade!''; exit 1;}' FROM PG_CATALOG.PG_CONSTRAINT INNER JOIN PG_CLASS ON CONRELID=pg_class.oid INNER JOIN PG_NAMESPACE ON RELNAMESPACE=PG_NAMESPACE.OID WHERE CONTYPE='p' AND CONNAMESPACE IN (SELECT OID FROM PG_NAMESPACE WHERE NSPNAME !~ '^pg_catalog|^information_schema|^pg_toast|^pg_temp');" >>/tmp/easy_slony_slonik_create_sets_$Date.slonik
fi

#All Candidate key tables Create set

echo -e "Do you want All Schema's Candidate Key Tables Replication ? [Y/N] "
read Can_Ch
if [ $Can_Ch = "y" -o $Can_Ch = "Y" ]; then
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "select 'try { create set (id = '||nextval('EASY_SLONY_ROWNUM_$')-1||' ,origin = $Master,comment = ''Set for '||nspname||'''); } on error { echo  ''Could not create Subscription set for Keyed Table '||currval('EASY_SLONY_ROWNUM_$')-1||' for upgrade!''; exit 1;}' from pg_constraint inner join pg_class on conrelid=pg_class.oid inner join pg_namespace on connamespace=pg_namespace.oid where contype='u' and (relname,nspname) in (select relname,nspname from pg_attribute inner join pg_class on attrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid and nspname !~ '^pg_catalog|^information_schema|^pg_toast|^pg_temp' and attnotnull is true and attname !~ '^xmin|^xmax|^cmin|^cmax|^ctid|^tableoid' and relkind ='r' and relhaspkey is false);" >>/tmp/easy_slony_slonik_create_sets_$Date.slonik
fi

# All Primary key tables Set add table

if [ $Pk_Ch = "y" -o $Pk_Ch = "Y" ]; then
if [ $Phase = "Continue.." ]; then
START_SEQ_VAL=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT setval('EASY_SLONY_ROWNUM_$',$Last_Seq_Tab_Id);")
START_SEQ_VAL1=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT setval('EASY_SLONY_ROWNUM_1$',$Last_Seq_Seq_ID);")
else
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT setval('EASY_SLONY_ROWNUM_$',1)" >/dev/null 2>/dev/null
fi
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "select 'set add table (set id = '||nextval('EASY_SLONY_ROWNUM_$')-1||' ,origin = $Master, id = '||currval('EASY_SLONY_ROWNUM_$')-1||', full qualified name = '''||nspname||'.'||relname||''', comment = ''Table ' ||relname||' with primary key'');' from pg_constraint inner join pg_class on conrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid where contype='p' and connamespace in(select oid from pg_namespace where nspname !~ '^pg_catalog|^information_schema|^pg_toast|^pg_temp');" >>/tmp/easy_slony_slonik_create_sets_$Date.slonik
fi

#All Candidate key tables Set add table

if [ $Can_Ch = "y" -o $Can_Ch = "Y" ]; then
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database " select 'set add table (set id = '||nextval('EASY_SLONY_ROWNUM_$')-1||' ,origin = $Master, id = '||currval('EASY_SLONY_ROWNUM_$')-1||', full qualified name = '''||nspname||'.'||relname||''', key='''||conname||''',comment=''Table '||nspname||'.'||relname||' with candidate primary key '||conname||''');' from pg_constraint inner join pg_class on conrelid=pg_class.oid inner join pg_namespace on connamespace=pg_namespace.oid where contype='u' and (relname,nspname) in (select relname,nspname from pg_attribute inner join pg_class on attrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid and nspname !~ '^pg_catalog|^information_schema|^pg_toast|^pg_temp' and attnotnull is true and attname !~ '^xmin|^xmax|^cmin|^cmax|^ctid|^tableoid' and relkind ='r' and relhaspkey is false);" >>/tmp/easy_slony_slonik_create_sets_$Date.slonik
fi

if [ $Phase = "Continue.." ]; then
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT setval('EASY_SLONY_ROWNUM_1$',$Last_Seq_Seq_ID);" >/dev/null
else
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT SETVAL('EASY_SLONY_ROWNUM_1$',1);" >/dev/null
fi

#All Primary Key's set add sequence

if [ $Pk_Ch = "y" -o $Pk_Ch = "Y" ]; then
echo -e "Do you want All  Schema's Sequences Replicate ? [Y/N] "
read Seq_Ch
if [ $Seq_Ch = "y" -o $Seq_Ch = "Y" ]; then
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT 'set add sequence (set id = '||nextval('EASY_SLONY_ROWNUM_1$')-1 ||', origin = $Master, id = '||currval('EASY_SLONY_ROWNUM_1$')-1||', full qualified name ='''||sequence_name||''', comment = ''Sequence '||sequence_name||''');' FROM 
((SELECT DISTINCT case when position((nspname||'.')::varchar in TAB_SEQ_LIST.sequence_def)>0 then TAB_SEQ_LIST.sequence_def when position('.'::varchar in TAB_SEQ_LIST.sequence_def)>0 then TAB_SEQ_LIST.sequence_def else (select nspname from pg_class,pg_namespace where relkind='S' and relnamespace=pg_namespace.oid and relname=TAB_SEQ_LIST.sequence_def and pg_namespace.nspname=TAB_SEQ_LIST.nspname)::text||'.'||TAB_SEQ_LIST.sequence_def end as sequence_name FROM ( SELECT a.attrelid::regclass as table,attrelid ,nspname,(select trim(both '''' from rtrim(ltrim(regexp_replace(regexp_replace(regexp_replace(case when substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128) like 'nextval(%::regclass)' then substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128) end,'''''','''','g') ,'nextval',''),'::regclass','')::text,'(')::text,')')) FROM pg_catalog.pg_attrdef d WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef) as sequence_def FROM pg_catalog.pg_attribute a inner join pg_class on a.attrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid and nspname !~ '^pg_catalog|^information_schema|^pg_toast|^pg_temp' AND a.attnum >0 AND NOT a.attisdropped ORDER BY a.attnum ) AS TAB_SEQ_LIST WHERE TAB_SEQ_LIST.sequence_def is not null and tab_seq_list.table in (select conrelid::regclass from pg_constraint where contype='p' and connamespace in (select oid from pg_namespace where nspname !~ '^pg_catalog|^information_schema|^pg_toast|^pg_temp')))
UNION
(SELECT DISTINCT case when position((nspname||'.')::varchar in TAB_SEQ_LIST.sequence_def)>0 then TAB_SEQ_LIST.sequence_def when position('.'::varchar in TAB_SEQ_LIST.sequence_def)>0 then TAB_SEQ_LIST.sequence_def else (select nspname from pg_class,pg_namespace where relkind='S' and relnamespace=pg_namespace.oid and relname=TAB_SEQ_LIST.sequence_def and pg_namespace.nspname=TAB_SEQ_LIST.nspname)::text||'.'||TAB_SEQ_LIST.sequence_def end as sequence_name FROM ( SELECT a.attname as column,a.attrelid::regclass as table,attrelid ,nspname,(SELECT trim(both '''' from rtrim(ltrim(regexp_replace(regexp_replace(regexp_replace(case when substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128) like 'nextval(%::regclass)' then substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128) end,'''''','''','g') ,'nextval',''),'::regclass','')::text,'(')::text,')')) FROM pg_catalog.pg_attrdef d WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef) as sequence_def FROM pg_catalog.pg_attribute a inner join pg_class on a.attrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid and nspname !~ '^pg_catalog|^information_schema|^pg_toast|^pg_temp' AND a.attnum >0 AND NOT a.attisdropped ORDER BY a.attnum ) AS TAB_SEQ_LIST WHERE TAB_SEQ_LIST.sequence_def is not null and (tab_seq_list.table,tab_seq_list.nspname) in (select attrelid::regclass,nspname from pg_attribute inner join pg_class on attrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid and nspname  !~ '^pg_catalog|^information_schema|^pg_toast|^pg_temp' and attnotnull is true and attname !~ '^xmin|^xmax|^cmin|^cmax|^ctid|^tableoid' and relkind ='r' and relhaspkey is false))
) AS PK_CAN_SEQ;" >>/tmp/easy_slony_slonik_create_sets_$Date.slonik
fi
fi

break
fi
done

for J in $Slaves
do
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT SETVAL('EASY_SLONY_ROWNUM_$',1);" >/dev/null 2>/dev/null
Cred_Lexer $Master
echo -e "Enter Omit Copy For The Slave $J ? [true/false]\n**If Omit Copy=False Then It's A Complete Refreshment By Truncating Slave Tables.**"
read Omit_Copy
if [ $Rep_Schema != "@ll" ]; then
if [ $Phase = "Continue.." ]; then
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT SETVAL('EASY_SLONY_ROWNUM_$',$Last_Seq_Tab_Sub_Id);" >/dev/null 2>/dev/null
fi
for Rep_Schema in `echo -e $Rep_Schemas|tr '[:upper:]' '[:lower:]'`
do

if [ $Pk_Ch = "y" -o $Pk_Ch = "Y" ]; then
Track_Seq=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT nextval('EASY_SLONY_ROWNUM_$')-1;")
#Sets_Configured=""
Sets_Configured=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT array_to_string(array_agg((nextval('EASY_SLONY_ROWNUM_$')-2)::text),' ') from PG_CATALOG.PG_CONSTRAINT INNER JOIN PG_CLASS ON CONRELID=pg_class.oid INNER JOIN PG_NAMESPACE ON RELNAMESPACE=PG_NAMESPACE.OID WHERE CONTYPE='p' AND CONNAMESPACE IN (SELECT OID FROM PG_NAMESPACE WHERE NSPNAME = '$Rep_Schema');")
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT SETVAL('EASY_SLONY_ROWNUM_$',$Track_Seq);" >/dev/null 2>/dev/null
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT 'try { subscribe set (id = '||nextval('EASY_SLONY_ROWNUM_$')-1||', provider = $Master, receiver = $J, forward = yes, omit copy = $Omit_Copy); } on error { exit 1; } echo  ''Subscribed nodes to set '||currval('EASY_SLONY_ROWNUM_$')-1||''';' FROM PG_CATALOG.PG_CONSTRAINT INNER JOIN PG_CLASS ON CONRELID=pg_class.oid INNER JOIN PG_NAMESPACE ON RELNAMESPACE=PG_NAMESPACE.OID WHERE CONTYPE='p' AND CONNAMESPACE IN (SELECT OID FROM PG_NAMESPACE WHERE NSPNAME = '$Rep_Schema');" >>/tmp/easy_slony_slonik_subscribe_sets_$Date.slonik
fi

if [ $Can_Ch = "y" -o $Can_Ch = "Y" ]; then
Track_Seq=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT nextval('EASY_SLONY_ROWNUM_$')-1;")
Sets_Configured=$Sets_Configured" $(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT array_to_string(array_agg((nextval('EASY_SLONY_ROWNUM_$')-2)::text),' ') from pg_constraint inner join pg_class on conrelid=pg_class.oid inner join pg_namespace on connamespace=pg_namespace.oid where contype='u' and (relname,nspname) in (select relname,nspname from pg_attribute inner join pg_class on attrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid and nspname = '$Rep_Schema' and attnotnull is true and attname !~ '^xmin|^xmax|^cmin|^cmax|^ctid|^tableoid' and relkind ='r' and relhaspkey is false) ;")"
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT SETVAL('EASY_SLONY_ROWNUM_$',$Track_Seq);" >/dev/null 2>/dev/null
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT 'try { subscribe set (id = '||nextval('EASY_SLONY_ROWNUM_$')-1||', provider = $Master, receiver = $J, forward = yes, omit copy = $Omit_Copy); } on error { exit 1; } echo  ''Subscribed nodes to set '||currval('EASY_SLONY_ROWNUM_$')-1||''';' from pg_constraint inner join pg_class on conrelid=pg_class.oid inner join pg_namespace on connamespace=pg_namespace.oid where contype='u' and (relname,nspname) in (select relname,nspname from pg_attribute inner join pg_class on attrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid and nspname  ~ '$Rep_Schema' and attnotnull is true and attname !~ '^xmin|^xmax|^cmin|^cmax|^ctid|^tableoid' and relkind ='r' and relhaspkey is false) ;" >>/tmp/easy_slony_slonik_subscribe_sets_$Date.slonik
fi
echo -e "($Master)=>($J)=>($Rep_Schema)=>$Sets_Configured" >>/tmp/.config.track
done
else
if [ $Phase = "Continue.." ]; then
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT SETVAL('EASY_SLONY_ROWNUM_$',$Last_Seq_Tab_Sub_Id);" >/dev/null 2>/dev/null
else
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT SETVAL('EASY_SLONY_ROWNUM_$',1);" >/dev/null 2>/dev/null
fi

if [ $Pk_Ch = "y" -o $Pk_Ch = "Y" ]; then
Sets_Configured=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT array_to_string(array_agg((nextval('EASY_SLONY_ROWNUM_$')-1)::text),' ') from PG_CATALOG.PG_CONSTRAINT INNER JOIN PG_CLASS ON CONRELID=pg_class.oid INNER JOIN PG_NAMESPACE ON RELNAMESPACE=PG_NAMESPACE.OID WHERE CONTYPE='p' AND CONNAMESPACE IN (SELECT OID FROM PG_NAMESPACE WHERE NSPNAME !~ '^pg_catalog|^information_schema|^pg_toast|^pg_temp');")
fi

if [ $Phase = "Continue.." ]; then
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT SETVAL('EASY_SLONY_ROWNUM_$',$Last_Seq_Tab_Sub_Id);" >/dev/null 2>/dev/null
else
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT SETVAL('EASY_SLONY_ROWNUM_$',1);" >/dev/null 2>/dev/null
fi

if [ $Pk_Ch = "y" -o $Pk_Ch = "Y" ]; then
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT 'try { subscribe set (id = '||nextval('EASY_SLONY_ROWNUM_$')-1||', provider = $Master, receiver = $J, forward = yes, omit copy =$Omit_Copy ); } on error { exit 1; } echo  ''Subscribed nodes to set '||currval('EASY_SLONY_ROWNUM_$')-1||''';' FROM PG_CATALOG.PG_CONSTRAINT INNER JOIN PG_CLASS ON CONRELID=pg_class.oid INNER JOIN PG_NAMESPACE ON RELNAMESPACE=PG_NAMESPACE.OID WHERE CONTYPE='p' AND CONNAMESPACE IN (SELECT OID FROM PG_NAMESPACE WHERE NSPNAME !~ '^pg_catalog|^information_schema|^pg_toast|^pg_temp');" >>/tmp/easy_slony_slonik_subscribe_sets_$Date.slonik
Track_Seq=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT nextval('EASY_SLONY_ROWNUM_$')-1;")
fi

if [ $Can_Ch = "y" -o $Can_Ch = "Y" ]; then
Sets_Configured=$Sets_Configured" $(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT array_to_string(array_agg((nextval('EASY_SLONY_ROWNUM_$')-2)::text),' ') from pg_constraint inner join pg_class on conrelid=pg_class.oid inner join pg_namespace on connamespace=pg_namespace.oid where contype='u' and (relname,nspname) in (select relname,nspname from pg_attribute inner join pg_class on attrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid and nspname !~ '^pg_catalog|^information_schema|^pg_toast|^pg_temp' and attnotnull is true and attname !~ '^xmin|^xmax|^cmin|^cmax|^ctid|^tableoid' and relkind ='r' and relhaspkey is false) ;")"
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT SETVAL('EASY_SLONY_ROWNUM_$',$Track_Seq);" >/dev/null 2>/dev/null
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "SELECT 'try { subscribe set (id = '||nextval('EASY_SLONY_ROWNUM_$')-1||', provider = $Master, receiver = $J, forward = yes, omit copy = $Omit_Copy ); } on error { exit 1; } echo  ''Subscribed nodes to set '||currval('EASY_SLONY_ROWNUM_$')-1||''';' from pg_constraint inner join pg_class on conrelid=pg_class.oid inner join pg_namespace on connamespace=pg_namespace.oid where contype='u' and (relname,nspname) in (select relname,nspname from pg_attribute inner join pg_class on attrelid=pg_class.oid inner join pg_namespace on relnamespace=pg_namespace.oid and nspname !~ '^pg_catalog|^information_schema|^pg_toast|^pg_temp' and attnotnull is true and attname !~ '^xmin|^xmax|^cmin|^cmax|^ctid|^tableoid' and relkind ='r' and relhaspkey is false) ;" >>/tmp/easy_slony_slonik_subscribe_sets_$Date.slonik
fi
echo -e "($Master)=>($J)=>($Rep_Schema)=>$Sets_Configured" >>/tmp/.config.track
fi
#echo -e "($Master)=>($J)=>($Rep_Schema)=>$Sets_Configured" >>/tmp/.config.track
done
fi

echo "Do You Want To Configure Any More? [Y/N] "
read Phase_Read
if [ $Phase_Read = "y" -o $Phase_Read = "Y" ]; then
Phase="Continue.."
else
Phase="Stop"
fi
if [ $Cas_Ch != "y" -a $Cas_Ch != "Y" ]; then
Last_Seq_Tab_Id=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "Select nextval('EASY_SLONY_ROWNUM_$')-1;")
Last_Seq_Seq_ID=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "Select nextval('EASY_SLONY_ROWNUM_1$')-1;")
Last_Seq_Tab_Sub_Id=$Last_Seq_Tab_Id
Last_Seq_Seq_ID=$Last_Seq_Tab_Id
#echo -e "Last value $Last_Seq_Tab_Id"
fi
#echo -e "Last value $Last_Seq_Tab_Id"
done
##Starting Slon Processes
#echo -e "Where Is Your 'slon' Process Location ? [Ex: /opt/PostgreSQL/8.4/bin/slon] "
#read  Slon_Location

##Executing Slonik Files
echo -e "Everything is ready to replicate, Check once again created slonik files ..."
echo -e "Provide 'Slonik' Process Location [Ex:- /opt/PostgreSQL/8.4/bin/slonik]"
read Slonik_Location
echo -e "Initializing Cluster ..."
$Slonik_Location /tmp/easy_slony_slonik_init_cluster_$Date.slonik
echo -e "Creating Sets ..."
$Slonik_Location /tmp/easy_slony_slonik_create_sets_$Date.slonik
i=1
while [ "$i" -le "$FILE_NODES" ]
do
Cred_Lexer $i
echo -e "Where Is Your Node $i 'slon' Process Location ? [Ex: /opt/PostgreSQL/8.4/bin/slon] "
read  Slon_Location
echo "$Slon_Location -s 1000 -d2 $Schema 'host=$SL_AT_Host dbname=$SL_AT_Database user=$SL_AT_Username port=$SL_AT_Port' > /tmp/node$i.log 2>&1 &" >/tmp/Slon_Node$i-Deamon.sh
sh /tmp/Slon_Node$i-Deamon.sh
i=`expr $i + 1`
done
echo -e "Subscribing Sets ..."
printf  "Please Wait .. Slony is stabilizing "
i=1
while [ $i -le 30 ] 
do
printf "."
sleep 1s
i=`expr $i + 1`
done
echo 
$Slonik_Location /tmp/easy_slony_slonik_subscribe_sets_$Date.slonik
}

Maintenance()
{
while [ "Ok" = "Ok" ]
do
printf "%57s\n" "Slony Maintenance Tools"
printf  "%90s\n" " "|tr ' ' "-"
echo -e "{1}  Add Node      \t{7}  Execute Script    \t{13} Restart Node     \t{19} Start Slon"
echo -e "{2}  Create Set    \t{8}  Failover          \t{14} Store Node       \t{0} Quit"
echo -e "{3}  Drop Node     \t{9}  Initcluster       \t{15} Subscribe Set    "
echo -e "{4}  Drop Sequence \t{10} Merge Sets        \t{16} Uninstall Nodes  "
echo -e "{5}  Drop Set      \t{11} Move Set          \t{17} Unsubscribe Set  "
echo -e "{6}  Drop Table    \t{12} Print Premble     \t{18} Update Nodes     "
echo -e "\n\nPlease enter your choice ?"
read Slon_Tool

if [ -z $Slonik_Location ]; then

if [ $Slon_Tool -eq "0" ]; then
exit 1;
fi
if [ $Slon_Tool -ne 19 -a $Slon_Tool -ne 20 ]; then
echo -e "Provide 'Slonik' Process Location [Ex:- /opt/PostgreSQL/8.4/bin/slonik]"
read Slonik_Location
fi
if [ $Slon_Tool -ne 9 -a $Slon_Tool -ne 19 -a $Slon_Tool -ne 20 ]; then
echo -e "Enter Node Number For The Slony Catalogs ? "
read Node
Cred_Lexer $Node
echo -e "Enter Slony Catalog Schema (Exclude "'_'" Symbol as well)? "
read Schema
Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "Select count(*) from _$Schema.sl_set" >/dev/null
fi
fi
if [ $? -ne 0 ]; then
exit 1;
fi
case "$Slon_Tool" in
1)	>/tmp/easy_slony_slonik_add_node_$Date.slonik 
	echo -e "Enter The New Node Number ?"
	read Add_Node
	echo -e "Enter Node Connection Information ?"
	echo -e "host = ?"
	read host
	echo -e "dbname = ?"
	read dbname
	echo -e "user = ?"
	read user
	echo -e "port = ?"
	read port
	Header >> /tmp/easy_slony_slonik_add_node_$Date.slonik
	Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_add_node_$Date.slonik
	echo -e "node $Add_Node admin conninfo='host=$host dbname=$dbname user=$user port=$port';"  >>/tmp/easy_slony_slonik_add_node_$Date.slonik
	echo -e "What is the Event/Origin Node for this ? "
	read Event_Node
	echo -e "store node (id = $Add_Node, event node = $Event_Node, comment = 'Slave Node For The Primary postgres');" >>/tmp/easy_slony_slonik_add_node_$Date.slonik
	Event_Node_Conninfo=$(Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "select pa_conninfo from _$Schema.sl_path where pa_server=$Event_Node limit 1;")
	echo -e "store path (server = $Add_Node, client = $Event_Node, conninfo = 'host=$host dbname=$dbname user=$user port=$port');" >>/tmp/easy_slony_slonik_add_node_$Date.slonik
	echo -e "store path (server = $Event_Node, client = $Add_Node, conninfo = '$Event_Node_Conninfo');" >>/tmp/easy_slony_slonik_add_node_$Date.slonik
	Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "select 'store path (server = $Add_Node, client = '||pa_server||', conninfo = ''host=$host dbname=$dbname user=$user port=$port'');' from _$Schema.sl_path where ctid not in(select ctid from _$Schema.sl_path e where ctid not in (select min(ctid) from _$Schema.sl_path e1 where e.pa_server=e1.pa_server)) and pa_server!=$Event_Node order by 1;" >>/tmp/easy_slony_slonik_add_node_$Date.slonik
	Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "select 'store path (server = '||pa_server||', client = $Add_Node, conninfo = '''||pa_conninfo||''');' from _$Schema.sl_path where ctid not in(select ctid from _$Schema.sl_path e where ctid not in (select min(ctid) from _$Schema.sl_path e1 where e.pa_server=e1.pa_server)) and pa_server!=$Event_Node order by 1;" >>/tmp/easy_slony_slonik_add_node_$Date.slonik   
	Notify_Exec "add_node"
	if [ $? -eq 0 ]; then
	echo -e "Given node has been added successfully to the replication set ... Please start the slony deamons for this node"
	fi
	;;

2)  	>/tmp/easy_slony_slonik_create_set_$Date.slonik
	echo -e "Enter the set id ?"
	read Set_Id
	echo -e "Enter Origin for this set ?"
	read Set_Origin
	echo -e "Is it Primary Key or Candidate Key ? [P/C]"
	read Kind_Table
	if [ $Kind_Table = "p" -o $Kind_Table = "P" ]; then
	echo -e "Enter Primary Key Table Details [Ex:- <schema.table>::<schema.sequnces>]\n**If table don't have any sequence then specify <schema.table>::NO**"
	read Primary_Table_Details
	Table=$(echo $Primary_Table_Details|awk -F'::' '{print $1}')
	Sequence=$(echo $Primary_Table_Details|awk -F'::' '{print $2}'|tr '[:upper:]' '[:lower:]')
	elif [ $Kind_Table = "c" -o $Kind_Table = "C" ]; then
	echo -e "Enter Candidate Key Table Details [Ex:- <schema.table>::<Table key>::<schema.sequnces>]\n**If table don't have any sequence then specify <schema.table>::<Table key>::NO**"
	read Candidate_Table_Details
	Table=$(echo $Candidate_Table_Details|awk -F'::' '{print $1}')
	Key=$(echo $Candidate_Table_Details|awk -F'::' '{print $2}')
	Sequence=$(echo $Candidate_Table_Details|awk -F'::' '{print $3}'|tr '[:upper:]' '[:lower:]')
	fi
	Header >>/tmp/easy_slony_slonik_create_set_$Date.slonik
	Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_create_set_$Date.slonik
	echo -e "try { create set (id = $Set_Id, origin = $Set_Origin, comment = 'Set $Set_Id for migration'); } on error { echo 'Error while creating the set $Set_Id'; exit 1; }" >>/tmp/easy_slony_slonik_create_set_$Date.slonik
	if [ $Kind_Table = "p" -o $Kind_Table = "P" ]; then
	echo -e "set add table ( set id = $Set_Id, origin = $Set_Origin, id = $Set_Id, full qualified name = '$Table', comment = 'Easy_Slon Automated Table $Table with primary key'); echo 'Set $Set_Id has been created'; " >>/tmp/easy_slony_slonik_create_set_$Date.slonik
	elif [ $Kind_Table = "c" -o $Kind_Table = "C" ]; then
	echo -e "set add table (set id = $Set_Id ,origin = $Set_Origin , id = $Set_Id, full qualified name = '$Table', key='$Key', comment='Easy_Slon Automated Table $Table with candidate key $Key'); echo 'Set $Set_Id has been created' ;">>/tmp/easy_slony_slonik_create_set_$Date.slonik
	fi
	if [ $Sequence != "no" ] ; then
	echo -e "set add sequence (set id = $Set_Id, origin = $Set_Origin, id = $Set_Id, full qualified name = '$Sequence', comment = 'Easy_Slon Automated Sequence $Sequence'); echo 'Sequence $Sequence has been created';" >>/tmp/easy_slony_slonik_create_set_$Date.slonik
	fi
	Notify_Exec "create_set"
	;;
3)	>/tmp/easy_slony_slonik_drop_node_$Date.slonik
	echo -e "Enter Node Number to Drop ?"
	read Drop_Node
	echo -e "Enter it's Event/Orgin's Node ?"
	read Drop_Nodes_Origin
	Header >>/tmp/easy_slony_slonik_drop_node_$Date.slonik
	Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_drop_node_$Date.slonik
	echo -e "try { drop node (id = $Drop_Node, event node = $Drop_Nodes_Origin); } on error { echo 'Failed to drop node $Drop_Node from cluster'; exit 1; } echo 'Node $Drop_Node has been Droped';" >>/tmp/easy_slony_slonik_drop_node_$Date.slonik
	Notify_Exec "drop_node"
	;;
4)	>/tmp/easy_slony_slonik_drop_sequence_$Date.slonik
	echo -e "Enter Sequence Id to Drop ?"
	read Drop_Seq_Id
	echo -e "Enter It's Set Id ?"
	read Drop_Seq_Ids_Set_Id
	Header >>/tmp/easy_slony_slonik_drop_sequence_$Date.slonik
	Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_drop_sequence_$Date.slonik
	echo -e "try { SET DROP SEQUENCE (id = $Drop_Seq_Id, origin = $Drop_Seq_Ids_Set_Id); } on error { echo 'Failed to drop sequence $Drop_Seq_Id from cluster!'; exit 1; } echo 'Sequence $Drop_Seq_Id has been Dropped From the Set $Drop_Seq_Ids_Set_Id';" >>/tmp/easy_slony_slonik_drop_sequence_$Date.slonik
        Notify_Exec "drop_sequence"
	;;
5)	>/tmp/easy_slony_slonik_drop_set_$Date.slonik
	echo -e "Enter Set Id to Drop ?"
        read Drop_Set_Id
        echo -e "Enter It's Origin Node?"
        read Drop_Set_Ids_Origin
        Header >>/tmp/easy_slony_slonik_drop_set_$Date.slonik
        Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_drop_set_$Date.slonik
        echo -e "try { DROP SET (id = $Drop_Set_Id, origin = $Drop_Set_Ids_Origin); } on error { echo 'Failed to drop Set $Drop_Set_Id from cluster'; exit 1; } echo 'Set $Drop_Set_Id has been Dropped From the Origin $Drop_Set_Ids_Origin';" >>/tmp/easy_slony_slonik_drop_set_$Date.slonik
	Notify_Exec "drop_set"
	;;
6)	>/tmp/easy_slony_slonik_drop_table_$Date.slonik
        echo -e "Enter Table Id to Drop ?"
        read Drop_Table_Id
        echo -e "Enter It's Set Id ?"
        read Drop_Table_Ids_Set_Id
        Header >>/tmp/easy_slony_slonik_drop_table_$Date.slonik
        Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_drop_table_$Date.slonik
        echo -e "try { SET DROP TABLE (id = $Drop_Table_Id, origin = $Drop_Table_Ids_Set_Id); } on error { echo 'Could not drop table $Drop_Table_Id for migration!'; exit 1; } echo 'Table $Drop_Seq_Id has been Dropped From the Set $Drop_Table_Ids_Set_Id';" >>/tmp/easy_slony_slonik_drop_table_$Date.slonik
        Notify_Exec "drop_table"
	;;
7)	>/tmp/easy_slony_slonik_execute_script_$Date.slonik
	Header >>/tmp/easy_slony_slonik_execute_script_$Date.slonik
	Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_execute_script_$Date.slonik
	echo -e "Enter The Set Id Which Will Effect The Script ?"
	read Slonik_Execute_Script_Set_Id
	echo -e "Enter The Exact SQL File Location ?"
	read Slonik_Execute_Script_SQL_Location
	echo -e "Enter the Origin/Event Node ?"
	read Slonik_Execute_Script_Event_Node
	echo -e "execute script ( set id = $Slonik_Execute_Script_Set_Id, filename = '$Slonik_Execute_Script_SQL_Location', event node = $Slonik_Execute_Script_Event_Node );" >>/tmp/easy_slony_slonik_execute_script_$Date.slonik
	Notify_Exec "execute_script"
	;;
8)	>/tmp/easy_slony_slonik_failover_$Date.slonik
	Header >>/tmp/easy_slony_slonik_failover_$Date.slonik
	Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_failover_$Date.slonik
	echo -e "What Is The Node Id Do You Want To Fail ?"
	read Slonik_Failover_Fail_Id
	echo -e "What Is The Node Number Do You Want To Bring UP ?"
	read Slonik_Failover_Bring_Id
	echo -e "try {failover (id = $Slonik_Failover_Fail_Id, backup node = $Slonik_Failover_Bring_Id );} on error { echo 'Failure Of The Failover For The Set $Slonik_Failover_Fail_Id  to $Slonik_Failover_Bring_Id ';exit 1; }echo 'Failover Has been performed from $Slonik_Failover_Fail_Id to $Slonik_Failover_Bring_Id';" >>/tmp/easy_slony_slonik_failover_$Date.slonik
	Notify_Exec "failover"
	;;	
9)	>/tmp/easy_slony_slonik_init_clusterst_$Date.slonik
	Header >>/tmp/easy_slony_slonik_init_clusterst_$Date.slonik
	echo -e "Please Enter the Slony Catalog Schema name ? [Ex:- rep]"
	read Slony_Catalog
	echo -e "Please Enter The Node Information In '/tmp/.cred.txt' ? [Ex:- Host=\"127.0.0.1\" Database=\"dest1\" Username=\"postgres\" Port=\"5434\" ]"
	echo -e "Please Enter The Master Node Id ?\n**Make Sure All The Required Nodes Has Been Added Into '/tmp/.cred.txt' file**"
	read Init_Master_Id
	echo -e "cluster name = $Slony_Catalog;" >>/tmp/easy_slony_slonik_init_clusterst_$Date.slonik
	Put_Preamble "/tmp/easy_slony_slonik_init_clusterst_$Date.slonik"
	echo -e "Please Enter It's Slave Node Id ?"
	read Slave_Node_Id
	echo -e "init cluster (id = $Init_Master_Id , comment = 'Primary Node For the Slave postgres');" >>/tmp/easy_slony_slonik_init_clusterst_$Date.slonik
	echo -e "store node (id = $Slave_Node_Id, event node = $Init_Master_Id , comment = 'Slave Node For The Primary postgres');" >>/tmp/easy_slony_slonik_init_clusterst_$Date.slonik
	Cred_Lexer $Init_Master_Id
	echo -e "store path(server = $Init_Master_Id, client = $Slave_Node_Id, conninfo = 'host=$SL_AT_Host dbname=$SL_AT_Database user=$SL_AT_Username port=$SL_AT_Port');" >>/tmp/easy_slony_slonik_init_clusterst_$Date.slonik
	Cred_Lexer $Slave_Node_Id
	echo -e "store path(server = $Slave_Node_Id, client = $Init_Master_Id , conninfo = 'host=$SL_AT_Host dbname=$SL_AT_Database user=$SL_AT_Username port=$SL_AT_Port');" >>/tmp/easy_slony_slonik_init_clusterst_$Date.slonik
	echo -e "echo 'Nodes Has been configured';" >>/tmp/easy_slony_slonik_init_clusterst_$Date.slonik
	Notify_Exec "init_clusterst"
	;;	
10)	>/tmp/easy_slony_slonik_merge_set_$Date.slonik
	Header >>/tmp/easy_slony_slonik_merge_set_$Date.slonik
	Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_merge_set_$Date.slonik
	echo -e "Enter Target Set Id ?"
	read Slonik_Merge_Target_Set_Id
	echo -e "Enter Source Set Id ?"
	read Slonik_Source_Set_Id
	echo -e "Enter Target Set Id's Origin Node Id ?"
	read Slonik_Target_Set_Id_Origin_Id
	echo -e "try { merge set (id = $Slonik_Merge_Target_Set_Id, add id = $Slonik_Source_Set_Id, origin = $Slonik_Target_Set_Id_Origin_Id); } on error {echo 'Merge set is failed from the target id $Slonik_Merge_Target_Set_Id to $Slonik_Source_Set_Id for the node $Slonik_Target_Set_Id_Origin_Id'; exit 1; } echo 'Merge set has been accomplished from $Slonik_Merge_Target_Set_Id to $Slonik_Source_Set_Id  @Node $Slonik_Target_Set_Id_Origin_Id.';" >>/tmp/easy_slony_slonik_merge_set_$Date.slonik
	Notify_Exec "merge_set"
	;;	
11)	>/tmp/easy_slony_slonik_move_set_$Date.slonik
	Header >>/tmp/easy_slony_slonik_move_set_$Date.slonik
	Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_move_set_$Date.slonik
	echo -e "Enter Set Id To Move ?"
	read Slonik_Move_Set_Id
	echo -e "Enter Origin Node For This Set ?"
	read Slonik_Move_Set_Origin_Id
	echo -e "Enter Target Node To Move This Set ?"
	read Slonik_Move_Set_Target_Id
	echo -e "lock set (id = $Slonik_Move_Set_Id, origin = $Slonik_Move_Set_Origin_Id); sync (id = $Slonik_Move_Set_Origin_Id); wait for event (origin = $Slonik_Move_Set_Origin_Id, confirmed = $Slonik_Move_Set_Target_Id, wait on = $Slonik_Move_Set_Target_Id); move set (id = $Slonik_Move_Set_Id, old origin = $Slonik_Move_Set_Origin_Id, new origin = $Slonik_Move_Set_Target_Id); echo 'Set $Slonik_Move_Set_Id Has Been Moved From Origin Node $Slonik_Move_Set_Origin_Id To $Slonik_Move_Set_Target_Id ';" >>/tmp/easy_slony_slonik_move_set_$Date.slonik
	Notify_Exec "move_set"
	;;
12)	>/tmp/easy_slony_slonik_print_preamble_$Date.slonik
	Header >>/tmp/easy_slony_slonik_print_preamble_$Date.slonik
	Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_print_preamble_$Date.slonik
	cat /tmp/easy_slony_slonik_print_preamble_$Date.slonik
	;;
13)	>/tmp/easy_slony_slonik_restart_node_$Date.slonik
	Header >>/tmp/easy_slony_slonik_restart_node_$Date.slonik
	Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_restart_node_$Date.slonik
	echo -e "Enter Node Number To Restart ?\n**If You Want To Restart All Nodes Then Give 'all'**"
	read Node_Restart
	if [ `echo $Node_Restart|tr '[:upper:]' '[:lower:]'` != 'all' ]; then
	echo -e "restart node $Node_Restart; echo 'Node $Node_Restart Has Been Restarted ';" >>/tmp/easy_slony_slonik_restart_node_$Date.slonik
	else
	Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "Select 'restart node '||no_id||'; echo ''Node '||no_id||' Has Been Restarted '';' from _$Schema.sl_node" >>/tmp/easy_slony_slonik_restart_node_$Date.slonik	
	fi
	Notify_Exec "restart_node"
	;;
14)	>/tmp/easy_slony_slonik_store_node_$Date.slonik
	Header >>/tmp/easy_slony_slonik_store_node_$Date.slonik
	Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_store_node_$Date.slonik
	echo -e "Enter Node Id To Store In The Replication Cluster ?"
	read Store_Node
        echo -e "Enter Node Connection Information ?"
        echo -e "host = ?"
        read host
        echo -e "dbname = ?"
        read dbname
        echo -e "user = ?"
        read user
        echo -e "port = ?"
        read port
	Event_Node=1
	echo -e "node $Store_Node admin conninfo='host=$host dbname=$dbname user=$user port=$port';"  >>/tmp/easy_slony_slonik_store_node_$Date.slonik
	echo -e "store node (id = $Store_Node, event node = $Event_Node, comment = 'Slave Node For The Primary postgres');" >>/tmp/easy_slony_slonik_store_node_$Date.slonik
	Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "select distinct 'store path (server = '||$Store_Node||', client = '||pa_server||', conninfo = ''host=$host dbname=$dbname user=$user port=$port'');' from _$Schema.sl_path where $Store_Node != pa_server order by 1;" >>/tmp/easy_slony_slonik_store_node_$Date.slonik
	Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "select  distinct 'store path (server = '||b.pa_server||', client = '||'$Store_Node'||', conninfo = '''||b.pa_conninfo||''');' from _$Schema.sl_path b where b.pa_server!=$Store_Node order by 1;" >>/tmp/easy_slony_slonik_store_node_$Date.slonik
	echo -e "Find the generated Add Slonik Script"
        echo -e "echo 'Node $Store_Node Has Been Added Into The Replication Cluster ..'" >>/tmp/easy_slony_slonik_store_node_$Date.slonik
	Notify_Exec "store_node"
	;;
15)	>/tmp/easy_slony_slonik_subscribe_set_$Date.slonik
	echo -e "Enter The Set Id To Subscribe ?"
	read Subscribe_Set
	echo -e "Enter The Set Id's Origin Node Id ?"
	read Subscribe_Set_Origin
	echo -e "Enter The Set Id's Reciever Node Id ?"
	read Subscirbe_Set_Reciever
	echo -e "Enter Omit Copy ? [true/false]\n**If Omit Copy=False Then It's A Complete Refreshment By Truncating Slave Tables.**"
	read Omit_Copy
	echo -e "Enter Forward Option ? [yes/no]\n**If Forward=Yes Then We Can Do Cascading Replication**"
	read Forward
	Header >>/tmp/easy_slony_slonik_subscribe_set_$Date.slonik
	Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_subscribe_set_$Date.slonik
	echo -e "try { subscribe set (id = $Subscribe_Set, provider = $Subscribe_Set_Origin, receiver = $Subscirbe_Set_Reciever, forward = $Forward, omit copy = $Omit_Copy); } on error { exit 1; } echo 'Node $Subscribe_Set Has Been Successfully Subscribed From Node $Subscribe_Set_Origin To Node $Subscirbe_Set_Reciever';" >>/tmp/easy_slony_slonik_subscribe_set_$Date.slonik
	Notify_Exec "subscribe_set"
	;;
16)	>/tmp/easy_slony_slonik_uninstall_nodes_$Date.slonik
	echo -e "Enter Node Id To Uninstall ?\n**Please Check The Node Has Been Dropped From The Cluster Or Not .. If You Want To Uninstall All Nodes Then Provide 'all'** "
	read Uninstall_Node
	Header >>/tmp/easy_slony_slonik_uninstall_nodes_$Date.slonik
	Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_uninstall_nodes_$Date.slonik
	if [ `echo $Uninstall_Node|tr '[:upper:]' '[:lower:]'` != 'all' ]; then
        echo -e "uninstall node (id=$Uninstall_Node); echo 'Node $Uninstall_Node Has Been Uninstalled ';" >>/tmp/easy_slony_slonik_uninstall_nodes_$Date.slonik
        else
        Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "Select 'uninstall node (id='||no_id||'); echo ''Node '||no_id||' Has Been Uninstalled '';' from _$Schema.sl_node" >>/tmp/easy_slony_slonik_uninstall_nodes_$Date.slonik
        fi
	Notify_Exec  "uninstall_nodes"
        ;;
17)	>/tmp/easy_slony_slonik_unsubscribe_set_$Date.slonik
	Header >> /tmp/easy_slony_slonik_unsubscribe_set_$Date.slonik
	Slonik_Tools_Preamble >> /tmp/easy_slony_slonik_unsubscribe_set_$Date.slonik 	
	echo -e "Enter Set Id To Unsubscribe ?"
	read Unsubscribe_Set
	echo -e "Enter Set Id's Receiver/Destination Node Id ?"
	read Receiver_Id
	echo -e "try { unsubscribe set (id = $Unsubscribe_Set, receiver = $Receiver_Id); } on error { echo 'Unsubscribe Set $Unsubscribe_Set Has Been Failed From $Receiver_Id'; exit 1; } echo 'Set $Unsubscribe_Set Has Been Unsubscribed From The Node $Receiver_Id';"  >> /tmp/easy_slony_slonik_unsubscribe_set_$Date.slonik
	Notify_Exec "unsubscribe_set"
        ;;
18) 	>/tmp/easy_slony_slonik_update_node_$Date.slonik
	Header >>/tmp/easy_slony_slonik_update_node_$Date.slonik
	Slonik_Tools_Preamble >>/tmp/easy_slony_slonik_update_node_$Date.slonik
	echo -e "Enter Node Id To Update Slony Catalog Functions ?\n**If You Want To Update All Nodes Then Provide 'all'**"
	read Update_Node
	if [ `echo $Update_Node|tr '[:upper:]' '[:lower:]'` != 'all' ]; then
        echo -e "update functions (id=$Update_Node); echo 'Node $Update_Node Has Been Updated ';" >>/tmp/easy_slony_slonik_update_node_$Date.slonik
        else
        Query_Runner $SL_AT_Host $SL_AT_Username $SL_AT_Port $SL_AT_Database "Select 'update functions (id='||no_id||'); echo ''Node '||no_id||' Has Been Updated '';' from _$Schema.sl_node" >>/tmp/easy_slony_slonik_update_node_$Date.slonik
        fi
        Notify_Exec "update_node"
        ;;
19)	echo -e "Enter Slon Process Location ? [Ex:- /opt/PostgreSQL/8.4/bin/slon]"
	read Slon_Location
	echo -e "Enter Slon Catalog Schema ?\n**Exclude '_' Symbol While Providing Schema Name**"
	read Schema
	echo -e "Enter Node Id Slon Deamon ?"
	read Node_Id	
	>/tmp/easy_slony_slonik_start_slon_Node$Node_Id
	Header >>/tmp/easy_slony_slonik_start_slon_Node$Node_Id
	echo -e "Enter Node $Node_Id Host Details"
	echo -e "Host ?"
	read Host
	echo -e "Dbname ?"
	read Dbname
	echo -e "User ?"
	read User
	echo -e "Port ?"
	read Port
	echo -e "Slony Log Location ?[Ex:- /var/log/slon]"
	read Slon_Log_Location
	echo "$Slon_Location -s 1000 -d2 $Schema 'host=$Host dbname=$Dbname user=$User port=$Port' > $Slon_Log_Location/Node$Node_Id.log 2>&1 &" >>/tmp/easy_slony_slonik_start_slon_Node$Node_Id
	cat /tmp/easy_slony_slonik_start_slon_Node$Node_Id
	echo -e "Do You Want To Execute [Y/N] ?"
	read Slon_Ch
	if [ $Slon_Ch = "y" -o $Slon_Ch = "Y" ]; then
        sh /tmp/easy_slony_slonik_start_slon_Node$Node_Id
        fi
	;;
0)	exit 1;
	;;
*)	echo -e "Invalid Option .. Please Try Again "
	;;
esac
done
}
echo -e "\n"
printf  "\n%30s" " "|tr ' ' "."
echo -e "\n\tSlony Automation"
printf  "%30s\n" " "|tr ' ' "."
echo -e "{..} Slony Configuration"
echo -e "{++} Slony Maintenance"
echo -e "{**} Exit"
echo -e "\nWhat do you want to do ? "
read Choice
case "$Choice" in
..) Config ;;
++) Maintenance ;;
**) exit 1 ;;
esac
