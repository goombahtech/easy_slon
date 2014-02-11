Pre-requisites
==============

1. A file “/tmp/.cred.txt” with the Node details..

Here is the way to define “/tmp/.cred.txt” file.
Host="Host" Database="dbname" Username="username" Port="port"

Ex:-

Host="127.0.0.1" Database="dest1" Username="postgres" Port="5434"
Host="127.0.0.1" Database="dest2" Username="postgres" Port="5434"

2. Make sure your nodes are able to connect from the machine, where you we have /tmp/.cred.txt file.

3. Make sure you have the required permissons on this file, from which you are running the easy_slon.sh script.

Test Run
========

======================================================================
	::::::: Easy_Slon Slony Automation Script ::::::::
======================================================================
Source PSQL Location ?[Ex:- /opt/PostgreSQL/8.4/bin]
/opt/PostgreSQL/9.2/bin



..............................
	Slony Automation
..............................
{..} Slony Configuration
{++} Slony Maintenance
{**} Exit

What do you want to do ? 
..
How Many Hosts/Nodes Participating In This Replication ? 
2
Node - 1 Connected ..
Node - 2 Connected ..
Slony catalogs schema ? [Default:_replication] 

Processed 1
Processed 2
DB level everything is perfect ... 
Generating Scripts ... 
Enter Master and slave nodes [Ex:- 1 to 2 3 ..] 
1 to 2
What Are The Schemas Do You Want To Replication From The Master ? [Ex:- @ll (or) Schema1 Schema2 ...]
public
Preparing public Tables Script ...
Do you want public Primary key Replicate ? [Y/N] 
Y
Do you want public Schema's Candidate key tables Replication ? [Y/N] 
Y
Do you want public Schema's Sequences Replicate ? [Y/N] 
Y
Enter Omit Copy For The Slave 2 ? [true/false]
**If Omit Copy=False Then It's A Complete Refreshment By Truncating Slave Tables.**
false
Do You Want To Configure Any More? [Y/N] 
N
Everything is ready to replicate, Check once again created slonik files ...
Provide 'Slonik' Process Location [Ex:- /opt/PostgreSQL/8.4/bin/slonik]
/opt/PostgreSQL/9.2/bin/slonik
Initializing Cluster ...
/tmp/edb_slonik_init_cluster_11_02_14.slonik:11: Stored all nodes in the slony catalogs
/tmp/edb_slonik_init_cluster_11_02_14.slonik:14: Stored all Store Paths for Failover and Switchover into slony catalogs ..
Creating Sets ...
Where Is Your Node 1 'slon' Process Location ? [Ex: /opt/PostgreSQL/8.4/bin/slon] 
/opt/PostgreSQL/9.2/bin/slon
Where Is Your Node 2 'slon' Process Location ? [Ex: /opt/PostgreSQL/8.4/bin/slon] 
/opt/PostgreSQL/9.2/bin/slon
Subscribing Sets ...
Please Wait .. Slony is stabilizing ..............................
/tmp/edb_slonik_subscribe_sets_11_02_14.slonik:7: Subscribed nodes to set 1


Scripts Location
================

1. Check /tmp/ location for the slonik scripts which is created for the above setup.

2. Test Run files
 
[root@localhost tmp]# ls -lrth *.slonik *.sh *.log
-rw-r--r--. 1 root root 1.1K Feb 11 09:18 easy_slony_slonik_init_cluster_11_02_14.slonik
-rw-r--r--. 1 root root  813 Feb 11 09:18 easy_slony_slonik_create_sets_11_02_14.slonik
-rw-r--r--. 1 root root  693 Feb 11 09:18 easy_slony_slonik_subscribe_sets_11_02_14.slonik
-rw-r--r--. 1 root root  131 Feb 11 09:19 Slon_Node1-Deamon.sh
-rw-r--r--. 1 root root  131 Feb 11 09:19 Slon_Node2-Deamon.sh
-rw-r--r--. 1 root root  15K Feb 11 09:20 node1.log
-rw-r--r--. 1 root root  26K Feb 11 09:20 node2.log

