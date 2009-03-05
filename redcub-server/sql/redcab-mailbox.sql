#create logfile group log_1 add undofile 'undo_1.dat' engine ndb;
#alter logfile group lg_1 add undofile 'undo_2.dat' engine ndb;
#alter logfile group lg_1 add undofile 'undo_3.dat' engine ndb;
#alter logfile group lg_1 add undofile 'undo_4.dat' engine ndb;

###################################################################

create table mails (
	id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	message_id VARCHAR(128) NOT NULL UNIQUE,
	host_id INTEGER NOT NULL,
	mail_from INTEGER NOT NULL,
	mail_to INTEGER NOT NULL,
	receive_date DateTime,
	data_part VARCHAR(128),
	data_size INTEGER)
	ENGINE=NDBCLUSTER;

###################################################################

create tablespace maildatas_ts add datafile 'maildata.dat'
	use logfile group lg_1 engine ndb;
alter tablespace hostnames_ts add datafile 'maildata_1.dat' engine ndb;
alter tablespace hostnames_ts add datafile 'maildata_2.dat' engine ndb;
alter tablespace hostnames_ts add datafile 'maildata_3.dat' engine ndb;

create table maildatas(
       id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
       mail_id INTEGER NOT NULL,
       message_id VARCHAR(128) NOT NULL UNIQUE,
       data BLOB)
       tablespace maildatas_ts storage disk ENGINE=NDB;

###################################################################

create table hosts (
	id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(128) UNIQUE)
	ENGINE=NDBCLUSTER;

###################################################################

create table addresses (
	id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	address VARCHAR(256) UNIQUE)
	ENGINE=NDBCLUSTER;

###################################################################

create table users (
	id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(256) NOT NULL UNIQUE,
	password VARCHAR(256) NOT NULL)
	ENGINE=NDBCLUSTER;

###################################################################
