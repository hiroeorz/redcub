#create logfile group log_1 add undofile 'undo_1.dat' engine ndb;
#alter logfile group lg_1 add undofile 'undo_2.dat' engine ndb;
#alter logfile group lg_1 add undofile 'undo_3.dat' engine ndb;
#alter logfile group lg_1 add undofile 'undo_4.dat' engine ndb;

###################################################################

#create tablespace mailbox_ts add datafile 'mailbox.dat'
#	use logfile group lg_1 engine ndb;
#alter tablespace mailbox_ts add datafile 'mailbox_1.dat' engine ndb;
#alter tablespace mailbox_ts add datafile 'mailbox_2.dat' engine ndb;
#alter tablespace mailbox_ts add datafile 'mailbox_3.dat' engine ndb;

create table mails (
	id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	message_id VARCHAR(128) NOT NULL UNIQUE,
	host_id INTEGER NOT NULL,
	mail_from INTEGER NOT NULL,
	mail_to INTEGER NOT NULL,
	receive_date DateTime,
	data_part VARCHAR(128),
	data_size INTEGER)
	tablespace mailbox_ts storage disk ENGINE=NDB;

###################################################################

create tablespace hostnames_ts add datafile 'hostnames.dat'
	use logfile group lg_1 engine ndb;
alter tablespace hostnames_ts add datafile 'hostnames_1.dat' engine ndb;
alter tablespace hostnames_ts add datafile 'hostnames_2.dat' engine ndb;
alter tablespace hostnames_ts add datafile 'hostnames_3.dat' engine ndb;

create table hosts (
	id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(128) UNIQUE)
	tablespace mailbox_ts storage disk ENGINE=NDB;

###################################################################

create tablespace addresses_ts add datafile 'addresses.dat'
	use logfile group lg_1 engine ndb;
alter tablespace addresses_ts add datafile 'addresses_1.dat' engine ndb;
alter tablespace addresses_ts add datafile 'addresses_2.dat' engine ndb;
alter tablespace addresses_ts add datafile 'addresses_3.dat' engine ndb;

create table addresses (
	id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	address VARCHAR(256) UNIQUE)
	tablespace addresses_ts storage disk ENGINE=NDB;

###################################################################

create tablespace users_ts add datafile 'redcab_users.dat'
	use logfile group lg_1 engine ndb;
alter tablespace users_ts add datafile 'redcab_users_1.dat' engine ndb;
alter tablespace users_ts add datafile 'redcab_users_2.dat' engine ndb;
alter tablespace users_ts add datafile 'redcab_users_3.dat' engine ndb;

create table users (
	id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(256) NOT NULL UNIQUE,
	password VARCHAR(256) NOT NULL)
	tablespace users_ts storage disk ENGINE=NDB;
