

These instructions are an update of this post: http://imperialwicket.com/aws-install-postgresql-90-on-amazon-linux/


## Create and configure the AWS Services Snapshot utility EC2 instance

The high level steps are:

1. Launch an EC2 instance
2. Launch an EBS volume and mount it for our database cluster
3. Add the pgrpms repository and disable PostgreSQL in the Amazon repositories
4. Install and configure PostgreSQL access, ports, and listeners
5. Start the PostgreSQL server
6. Create Users for external access

Note:
These instructions
  * Use the nano editor
  * Assume familiarity with the AWS EC2 console and Linux
  * Assume a VPC EC2 install 
  * Assume the existing ability to connect to an EC2 instance  

---

## Create an AWS EC2 Linux instance

1. Open the AWS EC2 console 

2. Select "Launch Instance" and select the current Amazon Linux AMI, which will be at the top of the list

3. Select the instance size 
  * Note: The AWS snapshot utility was developed using a t2.small instance; you may require a larger instance size for production use 
create new EC2 instance using latest AWS Linux AMI

4. Configure the instance details
  * Note: The subnet and role must include all required network access and permissions for the EC2 instance  

5. Storage:
  * Root: SSD general purpose storage
  * Add a second disk volume: 10GB SSD general purpose
  * Note: For scheduled use in a production environment, you may require more storage on the second disk volume

6. Security Group: 
  * If required, create "postgresql" security group allowing port 5432 and add it to the EC2 instance 

7. Connect to your EC2 instance, and execute the following commands
  * Note: “/dev/sdb” must match the assigned device, and the volume will be mounted at “/pgdata” 
```shell  
sudo su -
yes | mkfs -t ext3 /dev/sdb
mkdir /pgdata
mount /dev/sdb /pgdata
exit
exit
```  


Open a new SSH session on the instance

Set the volume to auto-mount on EC2 instance reboot:
  * Note: Tthis section uses AWS docs here: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-using-volumes.html 

Get the file system type of the mounted device:
```shell
mount
```

Display the available devices:
```shell
df
```

Get the UUID of the device:
```shell
ls -al /dev/disk/by-uuid/
```

Backup the fstab file:
```shell
sudo cp /etc/fstab /etc/fstab.orig
```

Edit the fstab file:
```shell
sudo nano /etc/fstab
```

Sample fstab entry:
```
UUID=de9a1ccd-a2dd-44f1-8be8-0123456abcdef       /pgdata   ext3    defaults,nofail        0       2
```

Test the mounts:
```shell
sudo mount -a
```


## Update the yum repositories
We want to install the latest stable postgresql from pgrpms.org. We could just download the rpm and manually install from the file, but that inevitably results in some dependency issues. I prefer to configure an alternate yum repository for a particular keyword. So we need to update the configuration for the Amazon repositories
  * Note: Be sure to update both “main” and “updates” sections and do not forget the asterisk
```shell
nano /etc/yum.repos.d/amzn-main.repo
```

At the bottom of the `[amzn-main]` section, after `enabled=1`, add `exclude=postgresql*`
```shell
nano /etc/yum.repos.d/amzn-updates.repo
```

At the bottom of the `[amzn-updates]` section, after `enabled=1`, add `exclude=postgresql*`


Download the postgresql 9.6 repo:  
```shell
rpm -ivh https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-6-x86_64/pgdg-ami201503-96-9.6-2.noarch.rpm
```

Update the repo manager with the new repo:  
```shell
yum update
```


## Install and configure PostgreSQL 9.6 on AWS Linux
After updating the yum repository configurations, “yum install postgresql96” should provide us with the latest postgresql packages from pgrmps.org. Notice that a few dependencies will come from the amazon repositories, but most of the pertinent postgresql* packages are coming from pgrpms. It is extremely likely that you do not need all of these packages. Limit the installation however you feel is appropriate.

Typical install:
```shell
yum install postgresql96 postgresql96-contrib postgresql96-devel postgresql96-server
```

Now we need to initialize the database cluster, edit the configuration and start the server. First remove the `/pgdata/lost+found` directory. PostgreSQL’s initdb will fail to initialize a database cluster in /pgdata/ when there are files/directories present. Then we will change ownership of the /pgdata directory to the postgres user and group, and change to the postgres user. As the postgres user, we can configure and launch the server.

**Be careful with this**  
Remove the lost+found to enable install:
```shell
sudo rm -rf /pgdata/lost+found
```

Change the user:group ownership for the postgresql data directory:
```shell
sudo chown -R postgres:postgres /pgdata
```

Change to root Linux user:
```shell
sudo su -
```

Change to postgres Linux user:
```shell
su postgres -
```

Initialize the database:
```shell
/usr/pgsql-9.6/bin/initdb -D /pgdata
```

The following commands require the postgres Linux user  
To change to the postgres Linux user:
```shell
sudo su - postgres
```
  * Note: For the postgres Linux user, the console prompt should be: `-bash-4.2$`

Edit the postgresql.conf file (be sure you are still using the postgres user):
```shell
nano /pgdata/postgresql.conf
```

Update the lines:
```
#listen_addresses = 'localhost' ...
#port = 5432 ...
```

To read:
```
listen_addresses = '*' ...
port = 5432
```

Edit the pg_hba.conf file (be sure you are still using the postgres user):
```shell
nano /pgdata/pg_hba.conf
```

Update the bottom of the file to read:
```
    # TYPE  DATABASE        USER            CIDR-ADDRESS            METHOD
    # "local" is for Unix domain socket connections only
    local   all             postgres                                trust
    local   all             ec2-user                                trust
    # IPv4 local connections:
    host    all             dbadmin         0.0.0.0/0               md5  
    host    all             ec2-user        0.0.0.0/0               md5
    # IPv6 local connections:
    host    all             all             ::1/128                 md5
```
  * Note: for PostgreSQL clients such as Navicat, set the role password as "encrypted" in the client for any PostreSQL USER with a METHOD set to md5 in the pg_hba.conf file


Start the server:
```shell
/usr/pgsql-9.6/bin/pg_ctl -D /pgdata -l logfile start
```

### Create users for external access  

Create the dbadmin as a superuser:
```shell
/usr/pgsql-9.6/bin/createuser dbadmin
Shall the new role be a superuser? (y/n) y
```

Alternatively, use psql to create the role dbadmin:
```shell
/usr/pgsql-9.6/bin/psql -p 5432
```
```sql
CREATE ROLE dbadmin WITH SUPERUSER LOGIN;  
ALTER USER dbadmin WITH PASSWORD 'aVerySecurePassword';
```

Create the ec2-user as a superuser:
```shell
/usr/pgsql-9.6/bin/createuser ec2-user
Shall the new role be a superuser? (y/n) n
Shall the new role be allowed to create databases? (y/n) n
Shall the new role be allowed to create more new roles? (y/n) n
```

Alternatively, use psql to create the role ec2-user:
```shell
/usr/pgsql-9.6/bin/psql -p 5432
```
```sql
CREATE ROLE ec2-user WITH SUPERUSER LOGIN;
ALTER USER ec2-user WITH PASSWORD 'aVerySecurePassword';
```



Connect to the database as postgres, and set the new user passwords (Be sure you are still logged in as postgres) 
```shell
/usr/pgsql-9.6/bin/psql -p 5432
```
```sql
postgres=# ALTER USER dbadmin WITH PASSWORD 'aVerySecurePassword';
postgres=# ALTER USER ec2-user WITH PASSWORD 'aVerySecurePassword';
```

Create the snapshot database:
```sql
postgres=# CREATE DATABASE aws_snapshot WITH OWNER ec2-user;
```

Create a password for the postgres user: 
```sql
ALTER USER postgres WITH PASSWORD 'aVerySecurePassword';
```

Exit psql:
```psql
\q
```

or 
```psql
\quit
```

Create a .pgpass file for user ec2-user to enable auto-login for the default AWS EC2 Linux user:

Change to the postgres Linux user:
```shell
sudo su - postgres
```

Create a .pgpass file:
```shell
nano /home/ec2-user/.pgpass
```

Enter this text: 
```
    # file to provide logon info to postgreSQL
    # format:
    # hostname:port:database:username:password
    #
    localhost:5432:aws_snapshot:ec2-user:aVerySecurePassword
```

Set permissions on the .pgpass file:
```shell
chmod 600 /home/ec2-user/.pgpass
```

Set the database to start on instance reboot:
```shell
sudo chkconfig postgresql-9.6 on
```

Confirm database is set to start on reboot:
```shell
chkconfig --list postgresql-9.6
```

If that does not work (it did not work for me), use this to start postgresql on boot: 

Create shell script to start postgresql:

Change to postgres Linux user:
```shell
sudo su - postgres
```
Create the bash shell script file:
```shell
sudo nano /etc/init.d/start-postgresql.sh
```

Enter this text: 
```bash
    #! /bin/bash
    #
    # starts postgresql using non-default data directory
    #
    sudo su -c "/usr/pgsql-9.6/bin/pg_ctl start -D /pgdata" postgres > 'start-postgresql.log'
```

Set the shell script to execute:
```shell
sudo chmod +x /etc/init.d/start-postgresql.sh
```

Set the script to run on boot:
```shell
sudo crontab -e
```

Add this line:
```
@reboot /etc/init.d/start-postgresql.sh
```

Save and exit the file: 
```
[esc]:wq
```

## Create and populate the AWS services and AWS CLI commands tables

Using a PostgreSQL client such as Navicat, connect to the database as PostgreSQL role `ec2-user`

Execute the SQL script: [setup-aws-snapshot-db.sql](https://github.com/Enterprise-Group-Ltd/aws-services-snapshot/blob/master/setup-aws-snapshot-db.sql) 

Copy the contents of the Excel workbook `driver_aws_cli_commands-X-X-X.xlsx` tab `aws_cli_commands` into the empty postgresql table `aws_snapshot.aws_sps__commands._driver_aws_cli_commands` and commit the transactions

Copy the contents of the Excel workbook `driver_aws_cli_commands-X-X-X.xlsx` tab `aws_cli_commands_recursive` into the empty postgresql table `aws_snapshot.aws_sps__commands._driver_aws_cli_commands_recursive` and commit the transactions    

Copy the contents of the Excel workbook `driver_aws_cli_commands-X-X-X.xlsx` tab `aws_services` into the empty postgresql table `aws_snapshot.aws_sps__commands._driver_aws_services` and commit the transactions

## Setup is now complete

## Selecting which AWS services and AWS CLI commands to snapshot
To select which AWS services and AWS CLI commands to snapshot, edit the Excel workbook `driver_aws_cli_commands-X-X-X.xlsx` and copy the contents of the tabs into the database tables in schema: `aws_sps__commands`  


## Misc:

To restart the DB:
```shell
sudo su - postgres
/usr/pgsql-9.6/bin/pg_ctl restart -D /pgdata
```

To reload the hba.conf configuration:
```shell
sudo su - postgres
/usr/pgsql-9.6/bin/pg_ctl reload -D /pgdata
```


To start psql:
```shell
sudo -u postgres psql
```
