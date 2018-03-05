# EGL AWS Snapshot Services Utility

  * Note: For a quick and simple snapshot, use version 1 located here: https://github.com/Enterprise-Group-Ltd/aws-services-snapshot/tree/master/v1  
          Version 1 is quick and easy while version 2 requires a PostgreSQL database and significant setup.   

This shell script snapshots the current state of AWS resources and writes it to JSON files and PostreSQL tables

This utility produces snapshots that:

* Answer the question: "What do we have in this AWS account?"
* Provide disaster recovery data source capability from account or service deletion or other causes
* Provide data source capability for account or service clone/backup  
* Create an audit trail of AWS service(s) state 

This utility provides service snapshot functionality unavailable in the AWS console or directly via the AWS CLI API. 

This utility can: 

* Capture the current state of selected or all AWS Services in a selected or all AWS regions
* Write the current service state to JSON files 
* Write the current service state to PostgreSQL tables
* Be scheduled 

This utility produces a summary report listing:

* AWS account and alias
* AWS region
* Driver file name
* The number of regions snapshotted
* The number of services snapshotted
* Snapshot files location
* List of regions snapshotted
* List of services snapshotted

This utility creates a unique directory on the EC2 instance and a unique schema on the PostgreSQL database for each run. 

The unique EC2 directory contains:
* Summary report
* Error report (if any)
* Log (if set with -g parameter)
* Subdirectory `snapshot-files` containing the JSON results files for each AWS CLI command executed 

The unique PostreSQL schema contains:
* AWS services and AWS CLI commands tables used in that run
* JSON results tables for each AWS CLI command executed 


## Getting Started

1. Follow the [AWS Services Snapshot EC2 instance create and configure instructions](https://github.com/Enterprise-Group-Ltd/aws-services-snapshot/blob/master/docs/postgresql-install.md) 
2. Install or update the AWS CLI utilities
    * The AWS CLI utilities are pre-installed on AWS EC2 Linux instances
    * To update on an AWS EC2 instance: `$ sudo pip install --upgrade awscli` 
3. Create an AWS CLI named profile that includes the required IAM permissions 
    * See the "[Prerequisites](#prerequisites)" section of the bash shell script for the required IAM permissions
    * To create an AWS CLI named profile: `$ aws configure --profile MyProfileName`
    * AWS CLI named profile documentation is here: [Named Profiles](http://docs.aws.amazon.com/cli/latest/userguide/cli-multiple-profiles.html)
4. Install the [bash](https://www.gnu.org/software/bash/) shell
    * The bash shell is included in most distributions and is pre-installed on AWS EC2 Linux instances
5. Install [jq](https://github.com/stedolan/jq) 
    * To install jq on AWS EC2: `$ sudo yum install jq -y`
6. Download this utility script or create a local copy and run it on the local or EC2 Linux instance
    * Example: `$ bash ./aws-services-snapshot.sh -p AWS_CLI_profile -r AWS_region`  

  * Note: To select which AWS services and AWS CLI commands to snapshot, edit the Excel workbook `driver_aws_cli_commands-X-X-X.xlsx` and copy the contents of the XL workbook tabs into the corresponding database tables in schema: `aws_sps__commands`  


## [Prerequisites](#prerequisites)

* [bash](https://www.gnu.org/software/bash/) - Linux shell 
* [jq](https://github.com/stedolan/jq) - JSON wrangler
* [AWS CLI](https://aws.amazon.com/cli/) - command line utilities (pre-installed on AWS AMIs) 
* [PostgreSQL](https://www.postgresql.org/) - database with JSON capabilities
* [Microsoft Excel](https://products.office.com/en-us/excel) file: `driver_aws_cli_commands-X-X-X.xlsx` (this file is used to create the contents of the postgresql tables `_driver_aws_services`, `_driver_aws_cli_commands` and `_driver_aws_cli_commands_recursive` ) 
* AWS CLI profile with IAM permissions for the AWS CLI commands:
  * aws ec2 describe-instances (used to test for valid -r region )
  * aws sts get-caller-identity (used to pull account number )
  * aws iam list-account-aliases (used to pull account alias )
* AWS CLI profile with IAM permissions for the AWS CLI 'service describe', 'service list', and 'service get' commands included in the postgresql tables `_driver_aws_cli_commands` and `_driver_aws_cli_commands_recursive` 


## Deployment

To execute the utility:

  * Example: `$ bash ./aws-services-snapshot.sh -p AWS_CLI_profile -d MyDriverFile -r AWS_region`  

To directly execute the utility:  

1. Set the execute flag: `$ chmod +x aws-services-snapshot.sh`
2. Execute the utility  
    * Example: `$ ./aws-services-snapshot.sh -p AWS_CLI_profile -d MyDriverFile -r AWS_region`    

## Output

* Summary report 
* JSON 'all regions - all services' file
* JSON 'all services' file for each region
* JSON snapshot files for each service
* PostgreSQL tables for each AWS CLI service command
* Info log (execute with the `-g y` parameter)  
  * Example: `$ bash ./aws-services-snapshot.sh -p AWS_CLI_profile -d MyDriverFile -r AWS_region -g y`  
* Debug log (execute with the `-g z` parameter)  
  * Example: `$ bash ./aws-services-snapshot.sh -p AWS_CLI_profile -d MyDriverFile -r AWS_region -g z`  
* Console verbose mode (execute with the `-b y` parameter)  
  * Example: `$ bash ./aws-services-snapshot.sh -p AWS_CLI_profile -d MyDriverFile -r AWS_region -b y`  

## Contributing

Please read [CONTRIBUTING.md](https://github.com/Enterprise-Group-Ltd/aws-services-snapshot/blob/master/CONTRIBUTING.md) for the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. 

## Authors

* **Douglas Hackney** - [dhackney](https://github.com/dhackney)

## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/Enterprise-Group-Ltd/aws-services-snapshot/blob/master/LICENSE) file for details

## Acknowledgments

* Key jq answers by [jq170727](https://stackoverflow.com/users/8379597/jq170727) 
* [Progress bar](https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script)  
* [Dynamic headers fprint](https://stackoverflow.com/questions/5799303/print-a-character-repeatedly-in-bash)
* [Menu](https://stackoverflow.com/questions/30182086/how-to-use-goto-statement-in-shell-script)
* [Remove duplicate lines and retain line order](https://unix.stackexchange.com/questions/30173/how-to-remove-duplicate-lines-inside-a-text-file)
* [Setup PostreSQL 9.X on Amazon Linux](http://imperialwicket.com/aws-install-postgresql-90-on-amazon-linux/) 
* Countless other jq and bash/shell man pages, Q&A, posts, examples, tutorials, etc. from various sources  

