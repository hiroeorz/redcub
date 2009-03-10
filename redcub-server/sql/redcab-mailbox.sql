#create logfile group log_1 add undofile 'undo_1.dat' engine ndb;
#alter logfile group lg_1 add undofile 'undo_2.dat' engine ndb;
#alter logfile group lg_1 add undofile 'undo_3.dat' engine ndb;
#alter logfile group lg_1 add undofile 'undo_4.dat' engine ndb;

###################################################################

create table sendqueues (
	message_id varchar(256) NOT NULL PRIMARY KEY,
	helo_name varchar(128) NOT NULL,
	mail_from varchar(128) NOT NULL,
	recipients varchar(512) NOT NULL,
	orig_to varchar(128) NOT NULL,
	receive_date DateTime,
        data BLOB)ENGINE=NDBCLUSTER;

create table localqueues (
	message_id varchar(256) NOT NULL PRIMARY KEY,
	helo_name varchar(128) NOT NULL,
	mail_from varchar(128) NOT NULL,
	recipients varchar(512) NOT NULL,
	orig_to varchar(128) NOT NULL,
	receive_date DateTime,
        data BLOB)ENGINE=NDBCLUSTER;

###################################################################

create table mails (
	id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	message_id VARCHAR(128) NOT NULL UNIQUE,
	mail_from_id INTEGER NOT NULL,
	mail_to_id INTEGER NOT NULL,
	receive_date DateTime,
	subject VARCHAR(128),
	mail_data_id INTEGER NOT NULL)
	ENGINE=NDBCLUSTER;

###################################################################

create tablespace maildatas_ts add datafile 'maildata.dat'
	use logfile group lg_1 engine ndb;
alter tablespace hostnames_ts add datafile 'maildata_1.dat' engine ndb;
alter tablespace hostnames_ts add datafile 'maildata_2.dat' engine ndb;
alter tablespace hostnames_ts add datafile 'maildata_3.dat' engine ndb;

create table datas(
       id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
       message_id VARCHAR(128) NOT NULL UNIQUE,
       data BLOB,
       receive_date DateTime,
       subject VARCHAR(512),
       body TEXT)
       tablespace maildatas_ts storage disk ENGINE=NDB;

###################################################################

create table hosts (
	id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(128) UNIQUE)
	ENGINE=NDBCLUSTER;

###################################################################

create table addresses (
	id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	value VARCHAR(256) UNIQUE)
	ENGINE=NDBCLUSTER;

###################################################################

create table users (
	id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(256) NOT NULL UNIQUE,
	password VARCHAR(256) NOT NULL)
	ENGINE=NDBCLUSTER;

###################################################################
