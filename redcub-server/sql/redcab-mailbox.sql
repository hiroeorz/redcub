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
        data LONGBLOB)ENGINE=NDBCLUSTER;

create table localqueues (
	message_id varchar(256) NOT NULL PRIMARY KEY,
	helo_name varchar(128) NOT NULL,
	mail_from varchar(128) NOT NULL,
	recipients varchar(512) NOT NULL,
	orig_to varchar(128) NOT NULL,
	receive_date DateTime,
        data LONGBLOB)ENGINE=NDBCLUSTER;

###################################################################

create table mails (
	id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	user_id INTEGER NOT NULL,
	message_id VARCHAR(128) NOT NULL UNIQUE,
	mail_from_id INTEGER NOT NULL,
	filter_id INTEGER DEFAULT NULL,
	receive_date DateTime,
	state INTEGER NOT NULL DEFAULT 0,
	subject VARCHAR(256) DEFAULT '',
        body_part VARCHAR(128) DEFAULT '')
	ENGINE=NDBCLUSTER;

###################################################################

create tablespace maildatas_ts add datafile 'maildata.dat'
	use logfile group lg_1 engine ndb;
alter tablespace maildatas_ts add datafile 'maildata_1.dat' engine ndb;
alter tablespace maildatas_ts add datafile 'maildata_2.dat' engine ndb;
alter tablespace maildatas_ts add datafile 'maildata_3.dat' engine ndb;

create table datas(
       id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
       mail_id BIGINT NOT NULL,       
       message_id VARCHAR(128) NOT NULL UNIQUE,
       receive_date DateTime,
       header TEXT,
       body TEXT)
       tablespace maildatas_ts storage disk ENGINE=NDB;

#create table datas(
#       id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
#       mail_id BIGINT NOT NULL,
#       message_id VARCHAR(128) NOT NULL UNIQUE,
#       data LONGBLOB,
#       receive_date DateTime,
#       subject VARCHAR(512),
#       body TEXT)
#       ENGINE=NDBCLUSTER;

###################################################################

create tablespace attached_file_ts add datafile 'attached_file.dat'
	use logfile group lg_1 engine ndb;
alter tablespace attached_file_ts add datafile 'attached_file_1.dat' engine ndb;
alter tablespace attached_file_ts add datafile 'attached_file_2.dat' engine ndb;
alter tablespace attached_file_ts add datafile 'attached_file_3.dat' engine ndb;

create table attached_files (
       id BIGINT PRIMARY KEY AUTO_INCREMENT,
       mail_id BIGINT NOT NULL,
       filename VARCHAR(256) NOT NULL,
       filetype VARCHAR(32) NOT NULL DEFAULT 'test/plain',
       file LONGBLOB)
       tablespace attached_file_ts storage disk ENGINE=NDB;

###################################################################

create table hosts (
	id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(128) UNIQUE)
	ENGINE=NDBCLUSTER;

###################################################################

create table addresses (
	id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	value VARCHAR(256) UNIQUE,
	address_part VARCHAR(128) NOT NULL,
	name_part VARCHAR(128) DEFAULT NULL)
	ENGINE=NDBCLUSTER;

###################################################################

create table users (
	id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(128) NOT NULL UNIQUE,
	person_name VARCHAR(256) NOT NULL UNIQUE,
	crypted_password VARCHAR(256) NOT NULL,
	salt VARCHAR(128) NOT NULL,
	mailaddress VARCHAR(128) NOT NULL)
	ENGINE=NDBCLUSTER;

###################################################################

create table filters (
       id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
       user_id BIGINT NOT NULL,
       exec_no INTEGER NOT NULL,
       name VARCHAR(128) NOT NULL,
       target VARCHAR(128) NOT NULL,
       keyword VARCHAR(256))
       ENGINE=NDBCLUSTER;

###################################################################
