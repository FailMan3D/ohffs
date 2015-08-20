#include "./../build-deps/ssat/src/ssat.sqlh"
create database ohffs;

create table namenodes (
	id UUID not null primary key
		#ifdef _ssat_DBMS_Pg
			default NewID()
		#endif

	,parent_id UUID
		#ifdef _ssat_DBMS_Maria
			foreign key references namenodes(id)
		#endif

	,nodename VARCHAR(255) not null

	,root_p BOOLEAN -- NULL or TRUE, never FALSE

	#ifdef _ssat_DBMS_Pg
		,check(
			(parent_id is null and root_p = true)
			or
			(parent_id is not null and root_p is null)
		)
	#endif

	,unique(parent_id,nodename) -- unique filenames within a root
	,unique(root_p,nodename) -- unique root-node names
);

#ifdef _ssat_DBMS_Maria
	-- MariaDB CHECK trigger goes here
#endif

create table secents (
	id UUID not null primary key
		#ifdef _ssat_DBMS_Pg
			default newID()
		#endif
);

create table inodes (
	id UUID not null primary key
		#ifdef _ssat_DBMS_Pg
		default NewID()
	#endif
	
	owner UUID not null
		#if defined(_ssat_DBMS_Maria)
			foreign key
		#endif
			references secents(id)

	,"group" UUID not null
		#if defined(_ssat_DBMS_Maria)
			foreign key
		#endif
			references secents(id)
	
	,deltime TIMESTAMP -- deletion time (like old Wang Labs minicomputers) 
	,created TIMESTAMP not null -- creation time
		#if defined(_ssat_DBMS_Pg)
			-- PostgreSQL default
		#elif defined(_ssat_DBMS_Maria)
			default current_timestamp
		#endif

	,changed TIMESTAMP -- ctime (data mod time)
	,metamod TIMESTAMP -- mtime (metadata mod time)
	,acctime TIMESTAMP -- atime (last read time)
);

create table acls (
	inode_id UUID not null
		#ifdef _ssat_DBMS_Pg
			default NewID()
		#endif
	
	,priority INTEGER unique not null -- should auto_increment across each inode_id

	,secent_id UUID
		#ifdef _ssat_DBMS_Maria
			foreign key
		#endif
			references secents(id)
	
	,posix_tag ENUM('user','group','other','mask')
	,posix_qualifier UUID not null
		#ifdef _ssat_DBMS_Maria
			foreign key
		#endif
			references secents(id)
	,posix_read BOOL -- mapped to nfs4_read_data or nfs4_
	,posix_write BOOL
	,posix_exec BOOL

	,nfs4_tag ENUM('user','group','owner@','group@','everyone@')
	,nfs4_qualifier UUID not null
		#ifdef _ssat_DBMS_Maria
			foreign key
		#endif
			references secents(id)
	,nfs4_fr BOOL -- read file
	,nfs4_dr BOOL -- list directory
	,nfs4_fw BOOL -- write file
	,nfs4_dc BOOL -- create file in directory (merge w/ da?)
	,nfs4_fa BOOL -- append file
	,nfs4_da BOOL -- create subdirectory (merge w/ dc?)
	,nfs4_fx BOOL -- execute file
	,nfs4_dx BOOL -- chdir into directory
	,nfs4_fd BOOL -- delete file
	,nfs4_dd BOOL -- delete directory
	,nfs4_dd_child BOOL -- delete file or directory children
	,rwx_delete_beforetime BOOL

	-- Attributes
	,nfs4_f_attr_r BOOL
	,nfs4_d_attr_r BOOL
	,nfs4_f_attr_w BOOL
	,nfs4_d_attr_w BOOL

	-- XAttrs (they will eventually have their own ACLs)
	,nfs4_f_xattr_r BOOL
	,nfs4_d_xattr_r BOOL
	,nfs4_f_xattr_w BOOL
	,nfs4_d_xattr_w BOOL
	
	-- ACL type
	,nfs4_read_acl BOOL
	,nfs4_write_acl BOOL
	,nfs4_write_owner BOOL
	,nfs4_synchronize BOOL

	,nfs4_inherit_file BOOL
	,nfs4_inherit_dir BOOL
	,nfs4_inherit_only BOOL
	,nfs4_inherit_noprop BOOL

	,acl_type ENUM('allow','deny')
);

