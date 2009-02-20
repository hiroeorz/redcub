#create logfile group log_1 add undofile 'undo_1.dat' engine ndb;
#alter logfile group lg_1 add undofile 'undo_2.dat' engine ndb;
#alter logfile group lg_1 add undofile 'undo_3.dat' engine ndb;
#alter logfile group lg_1 add undofile 'undo_4.dat' engine ndb;

create table send_mailqueue (
	message_id varchar(256) NOT NULL PRIMARY KEY,
	helo_name varchar(128) NOT NULL,
	sender varchar(128) NOT NULL,
	recipients varchar(512) NOT NULL,
	orig_to varchar(128) NOT NULL,
	receive_date DateTime,
        data BLOB)ENGINE=NDBCLUSTER;

create table local_mailqueue (
	message_id varchar(256) NOT NULL PRIMARY KEY,
	helo_name varchar(128) NOT NULL,
	sender varchar(128) NOT NULL,
	recipients varchar(512) NOT NULL,
	orig_to varchar(128) NOT NULL,
	receive_date DateTime,
        data BLOB)ENGINE=NDBCLUSTER;
